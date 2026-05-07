// Copyright © 2026 Alex Kovács. All rights reserved.

import Crypto
public import Foundation
import SwiftExtensions

extension Data {
  public func jsonDigest() -> JsonDigest{
    var sha256Hasher = SHA256()
    sha256Hasher.update(data: self)
    let sha256 = sha256Hasher.finalize().hexEncodedString()
    return .init(digest: .init(value: sha256), json: utf8String)
  }
}
