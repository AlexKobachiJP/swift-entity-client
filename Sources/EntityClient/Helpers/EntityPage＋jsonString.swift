// Copyright © 2026 Alex Kovács. All rights reserved.

public import CloudFileClient
public import JsonHelpers

extension EntityPage: @retroactive CustomJsonStringConvertible {
  public var jsonString: String {
    var json = """
      {
        "path": "\(path.string)",
        "number": \(number),
      """

    if let size {
      json += """
          "size": \(size),
        """
    }
    
    json += """
        "body": \(data.utf8String),
      }
      """
    
    return json
  }
}
