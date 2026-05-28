// Copyright © 2026 Alex Kovács. All rights reserved.

public import Foundation

extension JSONEncoder {
  
  /// Encoder that sorts keys and doesn't eescape slashes and, only in debug builds, prints pretty.
  public static func entityEncoder(dateEncodingStrategy: DateEncodingStrategy? = nil) -> JSONEncoder {
    var formatting: JSONEncoder.OutputFormatting = .withoutEscapingSlashes
    #if DEBUG
      formatting.insert(.prettyPrinted)
    #endif
    formatting.insert(.sortedKeys)
    
    let encoder = JSONEncoder()
    encoder.outputFormatting = formatting
    if let dateEncodingStrategy {
      encoder.dateEncodingStrategy = dateEncodingStrategy
    }
    
    return encoder
  }
}
