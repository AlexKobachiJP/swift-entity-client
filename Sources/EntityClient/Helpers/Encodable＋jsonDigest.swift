// Copyright © 2026 Alex Kovács. All rights reserved.

import Foundation

extension Encodable {
  public func jsonDigest() throws -> JsonDigest {
    let jsonData = try JSONEncoder.entityEncoder().encode(self)
    return jsonData.jsonDigest()
  }
}
