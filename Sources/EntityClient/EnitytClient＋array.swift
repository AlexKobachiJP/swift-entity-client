// Copyright © 2026 Alex Kovács. All rights reserved.

public import Entity
import CloudFileClient
import CodingHelpers
public import Foundation
public import Path

extension EntityClient {
  public static func array(basePath: RelativeFilePath = .empty, _ array: [Entity]) -> Self {
    .init { path in
      let (stream, continuation) = EntityPageStream.makeStream()
      
      Task {
        do {
          let page = EntityPage(
            path: RelativeBaseRelativeFilePath(base: basePath, path: path),
            number: 1,
            size: array.count,
            data: try array.jsonString.utf8Data
          )
          continuation.yield(.left(page))
          
          for entity in array {
            continuation.yield(.right(entity))
          }
          
          continuation.finish()
        } catch {
          continuation.finish(throwing: error)
        }
      }
      
      return stream
    }
  }

  
  public static func array<T: Encodable & Identifiable<String> & Sendable>(
    basePath: RelativeFilePath = .empty,
    _ array: [T],
    encoder: JSONEncoder = .entityEncoder(dateEncodingStrategy: .iso8601)
  ) -> Self {
    let entityArray = array.map { element in
      Entity(id: element.id) {
        try element.encode(using: encoder).jsonDigest()
      }
    }
    return .array(basePath: basePath, entityArray)
  }
}
