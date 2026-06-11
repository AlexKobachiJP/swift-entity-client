// Copyright © 2026 Alex Kovács. All rights reserved.

public import Entity
import CloudFileClient
import CodingHelpers
public import Foundation
public import Path

extension EntityClient {
  public static func array<T: Encodable & Identifiable<String> & Sendable>(
    basePath: RelativeFilePath = .empty,
    _ array: [T],
    encoder: JSONEncoder = .entityEncoder(dateEncodingStrategy: .iso8601)
  ) -> Self {
    .init { path in
      let (stream, continuation) = EntityPageStream.makeStream()
      
      Task {
        do {
          let page = EntityPage(
            path: RelativeBaseRelativeFilePath(base: basePath, path: path),
            number: 1,
            size: array.count,
            data: try array.encode(using: encoder)
          )
          continuation.yield(.left(page))
          
          for element in array {
            let entity = Entity(id: element.id) {
              try element.encode(using: encoder).jsonDigest()
            }
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
}
