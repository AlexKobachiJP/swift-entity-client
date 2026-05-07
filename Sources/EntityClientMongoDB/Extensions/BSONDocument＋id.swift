// Copyright © 2026 Alex Kovács. All rights reserved.

public import MongoSwift

extension BSONDocument: @retroactive Identifiable {
  public var id: BSONObjectID {
    guard let objectId = self["_id"]?.objectIDValue else {
      preconditionFailure()
    }
    return objectId
  }
}
