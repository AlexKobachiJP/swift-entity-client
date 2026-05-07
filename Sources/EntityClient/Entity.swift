// Copyright © 2026 Alex Kovács. All rights reserved.

public import CloudFileClient

public struct Entity: Sendable & Identifiable {
  public var id: String
  public var jsonDigest: @Sendable () throws -> JsonDigest
  public var file: FileEntity?
  public init(id: String, jsonDigest: @Sendable @escaping () throws -> JsonDigest, file: FileEntity? = nil) {
    self.id = id
    self.jsonDigest = jsonDigest
    self.file = file
  }
}
