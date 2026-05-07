// Copyright © 2026 Alex Kovács. All rights reserved.

import MongoSwift

extension BSONDocument {
  enum DecodingError: Swift.Error {
    case documentHasIdProperty
  }
  
  func decode<T: Decodable & Identifiable>(_ type: T.Type) throws -> T {
    var document = self
    if let oid = document["_id"]?.objectIDValue {
      guard document["id"] == nil else {
        throw DecodingError.documentHasIdProperty
      }
      document["id"] = .string(oid.hex)
      document["_id"] = nil
    }
    return try BSONDecoder().decode(type, from: document)
  }
}

extension BSONDocument? {
  func decode<T: Decodable & Identifiable>(_ type: T.Type) throws -> T? {
    try self.map { try $0.decode(type) }
  }
}
