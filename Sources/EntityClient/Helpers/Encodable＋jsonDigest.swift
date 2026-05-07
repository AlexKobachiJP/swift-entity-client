// Copyright © 2026 Alex Kovács. All rights reserved.

import JsonHelpers

extension Encodable {
  public func jsonDigest() throws -> JsonDigest {
    let jsonData = try jsonData()
    return jsonData.jsonDigest()
  }
}
