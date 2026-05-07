// Copyright © 2026 Alex Kovács. All rights reserved.

public import CloudFileClient
public import FileLocation
public import Path
public import SwiftExtensions

public typealias EntityPageStream = AsyncThrowingStream<Either<EntityPage<RelativeBaseRelativeFilePath>, Entity>, any Error>

public struct EntityClient: Sendable {
  public var fileLocation: IdentifiedLocation?
  public var fileClient: CloudFileClient?
  
  public init(enumeration: @escaping @Sendable (_ path: RelativeFilePath) -> EntityPageStream) {
    _enumeration = enumeration
  }
  
  private let _enumeration: @Sendable (_ path: RelativeFilePath) -> EntityPageStream
}

extension EntityClient {
  public func enumeration(at path: RelativeFilePath) throws -> EntityPageStream {
    _enumeration(path)
  }
}
