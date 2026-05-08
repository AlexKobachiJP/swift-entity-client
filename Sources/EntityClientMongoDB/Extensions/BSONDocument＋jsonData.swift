// Copyright © 2026 Alex Kovács. All rights reserved.

public import Foundation
public import MongoSwift

extension BSONDocument {
  public func jsonData(sortKeys: Bool = true) throws -> Data {
    let encoder = ExtendedJSONEncoder()
    #if DEBUG
      encoder.format = .relaxed
    #else
      encoder.format = .canonical
    #endif
    
    // ExtendedJSONEncoder does not sort keys or pretty print the JSON...
    let jsonData = try encoder.encode(self)
    
    // ...so we re-serialize the object using JSON serialization.
    let json = try JSONSerialization.jsonObject(with: jsonData)
    
    var options: JSONSerialization.WritingOptions = .withoutEscapingSlashes
    #if DEBUG
      options.insert(.prettyPrinted)
    #endif
    if sortKeys {
      options.insert(.sortedKeys)
    }
    
    return try JSONSerialization.data(withJSONObject: json, options: options)
  }
}
