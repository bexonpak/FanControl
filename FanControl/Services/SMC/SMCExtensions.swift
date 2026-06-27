//
//  SMCExtensions.swift
//  FanControl
//
//  Created by Bexon Pak on 6/27/26.
//

import Foundation

extension FourCharCode {
  init(fromString str: String) {
    precondition(str.count == 4)
    
    self = str.utf8.reduce(0) { sum, character in
      return sum << 8 | UInt32(character)
    }
  }
  
  func toString() -> String {
    return String(describing: UnicodeScalar(self >> 24 & 0xff)!) +
    String(describing: UnicodeScalar(self >> 16 & 0xff)!) +
    String(describing: UnicodeScalar(self >> 8  & 0xff)!) +
    String(describing: UnicodeScalar(self       & 0xff)!)
  }
}

extension UInt16 {
  init(bytes: (UInt8, UInt8)) {
    self = UInt16(bytes.0) << 8 | UInt16(bytes.1)
  }
}

extension UInt32 {
  init(bytes: (UInt8, UInt8, UInt8, UInt8)) {
    self = UInt32(bytes.0) << 24 | UInt32(bytes.1) << 16 | UInt32(bytes.2) << 8 | UInt32(bytes.3)
  }
}

extension Int {
  init(fromFPE2 bytes: (UInt8, UInt8)) {
    self = (Int(bytes.0) << 6) + (Int(bytes.1) >> 2)
  }
}

extension Float {
  init?(_ bytes: [UInt8]) {
    if bytes.count < 4 { return nil }
    self = bytes.withUnsafeBytes {
      return $0.load(fromByteOffset: 0, as: Self.self)
    }
  }
  
  var bytes: [UInt8] {
    withUnsafeBytes(of: self, Array.init)
  }
}
