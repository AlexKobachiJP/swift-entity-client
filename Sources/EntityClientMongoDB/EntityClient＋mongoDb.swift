// Copyright © 2026 Alex Kovács. All rights reserved.

import ConfigClientDependency
import Entity
public import EntityClient
import Foundation
import MongoDBHelpers
public import Logging
import Path
import Tracing

extension EntityClient {
  public static func mongoDb() -> Self {
    @ConfigValue(key: "mongodb.uri", isSecret: true, .required) var mongoDbUri: String
    return .mongoDb(mongoDbUri: mongoDbUri)
  }
}
  
extension EntityClient {
  public static func mongoDb(mongoDbUri: String, pageSize: Int = 200, logger: Logger = Logger(label: "mongodb")) -> Self {
    .init { path in
      let (stream, continuation) = EntityPageStream.makeStream()
      
      let task = Task {
        do {
          let components = path.components
          guard components.count == 2 else {
            fatalError("Invalid path: '\(path)'. Path must be of form '<database name>/<collection name>'.")
          }
          
          let database = components[0].string
          let collection = components[1].string
          
          let atlas = try MongoDBAtlas(mongoDbUri: mongoDbUri, database: database, logger: logger)
          try await atlas.connectWithTracingSpan(operation: "find", collection: collection) { db, span in
            var pageNumber = 0
            var lastDocument: Document?
            
            repeat {
              try Task.checkCancellation()
              let query: Document = lastDocument.map { ["_id": $0.idQuery(operator: "$gt") ] } ?? [:];
              let documents = try await db[collection]
                .find(query)
                .sort(["_id": .ascending])
                .limit(pageSize)
                .drain()
              
              lastDocument = documents.count < pageSize ? nil : documents.last
              
              let encoder = ExtendedJSONEncoder()
              encoder.format = .canonical
              let data = try encoder.encode(documents)
              span.attributes.set("http.response.body.size", value: data.count.toSpanAttribute())
              
              let nextPath = lastDocument.map { path.appending(path: .init(stringLiteral: $0.idString)) }
              
              pageNumber += 1
              let page = EntityPage(
                path: RelativeBaseRelativeFilePath(base: path, path: .empty),
                number: pageNumber,
                size: pageSize,
                data: data,
                nextPage: nextPath.map { .path(value: $0) }
              )
              continuation.yield(.left(page))
              
              for document in documents {
                let entity = Entity(id: document.idString) {
                  try document.jsonData().jsonDigest()
                }
                continuation.yield(.right(entity))
              }
            } while lastDocument != nil
          }

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
