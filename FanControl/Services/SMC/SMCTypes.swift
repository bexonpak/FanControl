//
//  SMCDataType.swift
//  FanControl
//
//  Created by Bexon Pak on 6/27/26.
//

import Foundation
import IOKit

internal enum SMCDataType: String {
  case UI8 = "ui8 "
  case UI16 = "ui16"
  case UI32 = "ui32"
  case SP1E = "sp1e"
  case SP3C = "sp3c"
  case SP4B = "sp4b"
  case SP5A = "sp5a"
  case SPA5 = "spa5"
  case SP69 = "sp69"
  case SP78 = "sp78"
  case SP87 = "sp87"
  case SP96 = "sp96"
  case SPB4 = "spb4"
  case SPF0 = "spf0"
  case FLT = "flt "
  case FPE2 = "fpe2"
  case FP2E = "fp2e"
  case FDS = "{fds"
}

internal enum SMCKeys: UInt8 {
  case kernelIndex = 2
  case readBytes = 5
  case writeBytes = 6
  case readIndex = 8
  case readKeyInfo = 9
  case readPLimit = 11
  case readVers = 12
}

internal struct SMCKeyData_t {
  typealias SMCBytes_t = (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                          UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                          UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                          UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                          UInt8, UInt8, UInt8, UInt8)
  
  struct vers_t {
    var major: CUnsignedChar = 0
    var minor: CUnsignedChar = 0
    var build: CUnsignedChar = 0
    var reserved: CUnsignedChar = 0
    var release: CUnsignedShort = 0
  }
  
  struct LimitData_t {
    var version: UInt16 = 0
    var length: UInt16 = 0
    var cpuPLimit: UInt32 = 0
    var gpuPLimit: UInt32 = 0
    var memPLimit: UInt32 = 0
  }
  
  struct keyInfo_t {
    var dataSize: IOByteCount32 = 0
    var dataType: UInt32 = 0
    var dataAttributes: UInt8 = 0
  }
  
  var key: UInt32 = 0
  var vers = vers_t()
  var pLimitData = LimitData_t()
  var keyInfo = keyInfo_t()
  var padding: UInt16 = 0
  var result: UInt8 = 0
  var status: UInt8 = 0
  var data8: UInt8 = 0
  var data32: UInt32 = 0
  var bytes: SMCBytes_t = (UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                           UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                           UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                           UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                           UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                           UInt8(0), UInt8(0))
}

internal struct SMCVal_t {
  var key: String
  var dataSize: UInt32 = 0
  var dataType: String = ""
  var bytes: [UInt8] = Array(repeating: 0, count: 32)
  
  init(_ key: String) {
    self.key = key
  }
}
