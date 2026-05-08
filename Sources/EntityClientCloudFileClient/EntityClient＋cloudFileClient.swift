// Copyright © 2026 Alex Kovács. All rights reserved.

public import CloudFileClient
public import EntityClient
public import FileClient
public import FileLocation
import JsonHelpers

extension EntityClient {
  public static func location(_ location: IdentifiedLocation, cloudFileClientProducer: CloudFileClientProducer) -> EntityClient {
    let fileClient: CloudFileClient = cloudFileClientProducer(location.value)
    var entityClient = cloudFileClient(fileClient)
    entityClient.fileLocation = location
    return entityClient
  }
  
  public static func cloudFileClient(_ fileClient: CloudFileClient) -> EntityClient {
    var entityClient = EntityClient { path in
      let (stream, continuation) = EntityPageStream.makeStream()
      
      let task = Task {
        try await fileClient.enumeration(at: path) { enumeration, _ in
          for try await result in enumeration {
            try Task.checkCancellation()
            
            switch result.currentResult {
            case .success(let enumeration):
              switch enumeration {
              case .left(let page):
                continuation.yield(.left(page))
              case .right(let cloudFile):
                if let file = cloudFile.fileEntity {
                  let entity = Entity(id: file.id, jsonDigest: file.jsonValue.jsonDigest, file: file)
                  continuation.yield(.right(entity))
                }
              }
              result.nextAction.set(once: .proceed)
            case .failure(_, let error):
              result.nextAction.set(once: .stop)
              continuation.finish(throwing: error)
            }
          }
          continuation.finish()
        }
      }
      
      continuation.onTermination = { _ in
        task.cancel()
      }
      
      return stream
    }
    
    entityClient.fileClient = fileClient
    return entityClient
  }
}
