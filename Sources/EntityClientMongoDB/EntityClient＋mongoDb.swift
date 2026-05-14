// Copyright © 2026 Alex Kovács. All rights reserved.

public import EntityClient
@preconcurrency import MongoSwift
import Path

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
