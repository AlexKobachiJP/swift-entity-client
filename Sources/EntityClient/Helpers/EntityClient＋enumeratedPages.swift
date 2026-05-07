// Copyright © 2026 Alex Kovács. All rights reserved.

public import CloudFileClient
public import Path
import Synchronization
public import TransparentWrapper

extension EntityClient {
  public struct FailedEnumeration: Error {
    public var error: any Error
    public var pages: [EntityPage<RelativeBaseRelativeFilePath>]
  }
  
  public func enumeratedEntityPages(
    at path: RelativeFilePath = .empty,
    page pageOperation: (@Sendable (EntityPage<RelativeBaseRelativeFilePath>) async throws -> Void)? = nil,
    entity entityOperation: (@Sendable (Entity) async throws -> Void)? = nil,
  ) async throws -> Result<[EntityPage<RelativeBaseRelativeFilePath>], FailedEnumeration> {
    let pages: Mutex<[EntityPage<RelativeBaseRelativeFilePath>]> = .init([])
    do {
      for try await value in try enumeration(at: path) {
        switch value {
        case .left(let page):
          pages.withLock { $0.append(page) }
          try await pageOperation?(page)
        case .right(let entity):
          try await entityOperation?(entity)
        }
      }
      return .success(pages.withLock { $0 })
    } catch {
      return .failure(FailedEnumeration(error: error, pages: pages.withLock { $0 }))
    }
  }
  
  public func enumeratedEntities(
    at path: RelativeFilePath = .empty,
    page pageOperation: (@Sendable (EntityPage<RelativeBaseRelativeFilePath>) async throws -> Void)? = nil,
    entity entityOperation: (@Sendable (Entity) async throws -> Void)? = nil,
    pages pagesOperation: (@Sendable (NonEmpty<[EntityPage<RelativeBaseRelativeFilePath>]>) async throws -> Void)? = nil,
  ) async throws -> [Entity] {
    let entities: Mutex<[Entity]> = .init([])
    let pageEnumerationResult = try await enumeratedEntityPages(
      at: path,
      page: pageOperation,
      entity: { entity in
        entities.withLock { $0.append(entity) }
        try await entityOperation?(entity)
      }
    )
    switch pageEnumerationResult {
    case .success(let pages):
      if let pages = NonEmpty(value: pages) {
        try await pagesOperation?(pages)
      }
      return entities.withLock { $0 }
    case .failure(let failure):
      if let pages = NonEmpty(value: failure.pages) {
        try await pagesOperation?(pages)
      }
      throw failure.error
    }
  }
}
