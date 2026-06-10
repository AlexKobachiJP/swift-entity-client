// Copyright © 2026 Alex Kovács. All rights reserved.

public import CodingHelpers
import CloudFileClient
public import Foundation
import Path

extension EntityClient {
  public static func array<T: Encodable & Identifiable<String> & Sendable>(_ array: [T], encoder: JSONEncoder = .init(dateEncodingStrategy: .iso8601)) -> Self {
    .init { path in
      let (stream, continuation) = EntityPageStream.makeStream()
      
      Task {
        do {
          let page = EntityPage(
            path: RelativeBaseRelativeFilePath(base: .empty, path: path),
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
