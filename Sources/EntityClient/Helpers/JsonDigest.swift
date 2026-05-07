// Copyright © 2026 Alex Kovács. All rights reserved.

public import FileHasher

public struct JsonDigest: Sendable {
  public var digest: Sha256String
  public var json: String
  public init(digest: Sha256String, json: String) {
    self.digest = digest
    self.json = json
  }
  }
