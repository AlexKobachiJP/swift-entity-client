// Copyright © 2026 Alex Kovács. All rights reserved.

public import EntityClient
import Foundation
@preconcurrency import MongoSwift
import Path
import Tracing

import struct CloudFileClient.EntityPage

extension EntityClient {
  public static func mongoDb(mongoDbUri: String, pageSize: Int = 200) -> EntityClient {
    .init { path in
      let (stream, continuation) = EntityPageStream.makeStream()
      
      let task = Task {
        do {
          let connectionString = mongoDbUri.trimmingCharacters(in: .init(charactersIn: "\""))
          let client: MongoClient = try MongoClient(connectionString, using: .singletonMultiThreadedEventLoopGroup)
          defer {
            try? client.syncClose()
          }
          
          let components = path.components
          guard components.count == 2 else {
            fatalError("Invalid path: '\(path)'. Path must be of form '<database name>/<collection name>'.")
          }
          
          let database = components[0].string
          let collection = components[1].string
          
          var pageNumber = 0
          var lastId: BSONObjectID?
          
          repeat {
            let span = InstrumentationSystem.tracer.startSpan("MongoDB find \(collection)", ofKind: .client)
            defer {
              span.end()
            }
            span.attributes.set("db.system", value: "mongodb".toSpanAttribute())
            span.attributes.set("db.namespace", value: "\(database).\(collection)".toSpanAttribute())
            span.attributes.set("db.collection.name", value: collection.toSpanAttribute())
            span.attributes.set("db.operation.name", value: "find".toSpanAttribute())
            if let components = URLComponents(string: connectionString), let host = components.host {
              span.attributes.set("server.address", value: host.toSpanAttribute())
            }
            
            try Task.checkCancellation()
            let query: BSONDocument = if let lastId { ["_id": [ "$gt": .objectID(lastId)] ] } else { [:] };
            let options = FindOptions(limit: pageSize, sort: [ "_id": .int32(1) ])
            let documents = try await client
              .db(database)
              .collection(collection)
              .find(query, options: options)
              .toArray();
            
            lastId = documents.count < pageSize ? nil : documents.last?.id
            
            let encoder = ExtendedJSONEncoder()
            encoder.format = .canonical
            let data = try encoder.encode(documents)
            span.attributes.set("http.response.body.size", value: data.count.toSpanAttribute())
            
            let nextPath = lastId.map { path.appending(path: .init(stringLiteral: $0.hex)) }
            
            pageNumber += 1
            let page = EntityPage(
              path: RelativeBaseRelativeFilePath(base: path, path: .empty),
              number: pageNumber,
              size: pageSize,
              data: data,
              nextPage: nextPath.map { .path($0) }
            )
            continuation.yield(.left(page))
            
            for document in documents {
              let entity = Entity(id: document.id.hex) {
                try document.jsonData().jsonDigest()
              }
              continuation.yield(.right(entity))
            }
          } while lastId != nil
          
          continuation.finish()
        } catch {
          continuation.finish(throwing: error)
        }
      }
      
      continuation.onTermination = { _ in
        task.cancel()
      }
      
      return stream
    }
  }
}
