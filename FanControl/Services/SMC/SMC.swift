//
//  SMC.swift
//  FanControl
//
//  Created by Bexon Pak on 6/27/26.
//

import Foundation
import IOKit

public class SMC: SMCService {
  private var conn: io_connect_t = 0
  private var _fanModeKeyIsLower: Bool?
  
  nonisolated
  public init() {
    var result: kern_return_t
    var iterator: io_iterator_t = 0
    let device: io_object_t
    
    let matchingDictionary: CFMutableDictionary = IOServiceMatching("AppleSMC")
    result = IOServiceGetMatchingServices(kIOMainPortDefault, matchingDictionary, &iterator)
    if result != kIOReturnSuccess {
      print("Error IOServiceGetMatchingServices(): " + (String(cString: mach_error_string(result), encoding: String.Encoding.ascii) ?? "unknown error"))
      return
    }
    
    device = IOIteratorNext(iterator)
    IOObjectRelease(iterator)
    if device == 0 {
      print("Error: No AppleSMC device found.")
      return
    }
    
    result = IOServiceOpen(device, mach_task_self_, 0, &conn)
    IOObjectRelease(device)
    if result != kIOReturnSuccess {
      print("Error IOServiceOpen(): " + (String(cString: mach_error_string(result), encoding: String.Encoding.ascii) ?? "unknown error"))
      return
    }
  }
  
  deinit {
    let result = self.close()
    if result != kIOReturnSuccess && conn != 0 {
      print("error close smc connection: " + (String(cString: mach_error_string(result), encoding: String.Encoding.ascii) ?? "unknown error"))
    }
  }
  
  public func close() -> kern_return_t {
    if conn != 0 {
      let res = IOServiceClose(conn)
      conn = 0
      return res
    }
    return kIOReturnSuccess
  }
  
  public func getValue(_ key: String) -> Double? {
    var result: kern_return_t = 0
    var val: SMCVal_t = SMCVal_t(key)
    
    result = read(&val)
    if result != kIOReturnSuccess {
      return nil
    }
    
    if val.dataSize > 0 {
      if val.bytes.first(where: { $0 != 0 }) == nil &&
          val.key != "FS! " &&
          !val.key.hasSuffix("Md") &&
          !val.key.hasSuffix("md") {
        return nil
      }
      
      switch val.dataType {
      case SMCDataType.UI8.rawValue:
        return Double(val.bytes[0])
      case SMCDataType.UI16.rawValue:
        return Double(UInt16(bytes: (val.bytes[0], val.bytes[1])))
      case SMCDataType.UI32.rawValue:
        return Double(UInt32(bytes: (val.bytes[0], val.bytes[1], val.bytes[2], val.bytes[3])))
      case SMCDataType.SP1E.rawValue:
        let result: Double = Double(UInt16(val.bytes[0]) * 256 + UInt16(val.bytes[1]))
        return Double(result / 16384)
      case SMCDataType.SP3C.rawValue:
        let result: Double = Double(UInt16(val.bytes[0]) * 256 + UInt16(val.bytes[1]))
        return Double(result / 4096)
      case SMCDataType.SP4B.rawValue:
        let result: Double = Double(UInt16(val.bytes[0]) * 256 + UInt16(val.bytes[1]))
        return Double(result / 2048)
      case SMCDataType.SP5A.rawValue:
        let result: Double = Double(UInt16(val.bytes[0]) * 256 + UInt16(val.bytes[1]))
        return Double(result / 1024)
      case SMCDataType.SP69.rawValue:
        let result: Double = Double(UInt16(val.bytes[0]) * 256 + UInt16(val.bytes[1]))
        return Double(result / 512)
      case SMCDataType.SP78.rawValue:
        let intValue: Double = Double(Int(val.bytes[0]) * 256 + Int(val.bytes[1]))
        return Double(intValue / 256)
      case SMCDataType.SP87.rawValue:
        let intValue: Double = Double(Int(val.bytes[0]) * 256 + Int(val.bytes[1]))
        return Double(intValue / 128)
      case SMCDataType.SP96.rawValue:
        let intValue: Double = Double(Int(val.bytes[0]) * 256 + Int(val.bytes[1]))
        return Double(intValue / 64)
      case SMCDataType.SPA5.rawValue:
        let result: Double = Double(UInt16(val.bytes[0]) * 256 + UInt16(val.bytes[1]))
        return Double(result / 32)
      case SMCDataType.SPB4.rawValue:
        let intValue: Double = Double(Int(val.bytes[0]) * 256 + Int(val.bytes[1]))
        return Double(intValue / 16)
      case SMCDataType.SPF0.rawValue:
        let intValue: Double = Double(Int(val.bytes[0]) * 256 + Int(val.bytes[1]))
        return intValue
      case SMCDataType.FLT.rawValue:
        let value: Float? = Float(val.bytes)
        if value != nil {
          return Double(value!)
        }
        return nil
      case SMCDataType.FPE2.rawValue:
        return Double(Int(fromFPE2: (val.bytes[0], val.bytes[1])))
      default:
        return nil
      }
    }
    
    return nil
  }
  
  public func getStringValue(_ key: String) -> String? {
    var result: kern_return_t = 0
    var val: SMCVal_t = SMCVal_t(key)
    
    result = read(&val)
    if result != kIOReturnSuccess {
      return nil
    }
    
    if val.dataSize > 0 {
      if val.bytes.first(where: { $0 != 0}) == nil {
        return nil
      }
      
      switch val.dataType {
      case SMCDataType.FDS.rawValue:
        let c1  = String(UnicodeScalar(val.bytes[4]))
        let c2  = String(UnicodeScalar(val.bytes[5]))
        let c3  = String(UnicodeScalar(val.bytes[6]))
        let c4  = String(UnicodeScalar(val.bytes[7]))
        let c5  = String(UnicodeScalar(val.bytes[8]))
        let c6  = String(UnicodeScalar(val.bytes[9]))
        let c7  = String(UnicodeScalar(val.bytes[10]))
        let c8  = String(UnicodeScalar(val.bytes[11]))
        let c9  = String(UnicodeScalar(val.bytes[12]))
        let c10 = String(UnicodeScalar(val.bytes[13]))
        let c11 = String(UnicodeScalar(val.bytes[14]))
        let c12 = String(UnicodeScalar(val.bytes[15]))
        
        return (c1 + c2 + c3 + c4 + c5 + c6 + c7 + c8 + c9 + c10 + c11 + c12).trimmingCharacters(in: .whitespaces)
      default:
        return nil
      }
    }
    
    return nil
  }
  
  public func fanModeKey(_ id: Int) -> String {
#if arch(arm64)
    if _fanModeKeyIsLower == nil {
      var probe = SMCVal_t("F0md")
      _fanModeKeyIsLower = read(&probe) == kIOReturnSuccess && probe.dataSize > 0
    }
    return _fanModeKeyIsLower! ? "F\(id)md" : "F\(id)Md"
#else
    return "F\(id)Md"
#endif
  }
  
  public func setFanMode(_ id: Int, mode: FanMode) -> Bool {
#if arch(arm64)
    if mode == .forced {
      return unlockFanControl(fanId: id)
    } else {
      let modeKey = fanModeKey(id)
      let targetKey = "F\(id)Tg"
      
      if self.getValue(modeKey) != nil {
        var modeVal = SMCVal_t(modeKey)
        let readResult = read(&modeVal)
        guard readResult == kIOReturnSuccess else {
          print(smcError("read", key: modeKey, result: readResult))
          return false
        }
        if modeVal.bytes[0] != 0 {
          modeVal.bytes[0] = 0
          if !writeWithRetry(modeVal) { return false }
        }
      }
      
      var targetValue = SMCVal_t(targetKey)
      let result = read(&targetValue)
      guard result == kIOReturnSuccess else {
        print(smcError("read", key: targetKey, result: result))
        return false
      }
      
      let bytes = Float(0).bytes
      targetValue.bytes[0] = bytes[0]
      targetValue.bytes[1] = bytes[1]
      targetValue.bytes[2] = bytes[2]
      targetValue.bytes[3] = bytes[3]
      
      return writeWithRetry(targetValue)
    }
#else
    // Intel
    if self.getValue("F\(id)Md") != nil {
      var result: kern_return_t = 0
      var value = SMCVal_t("F\(id)Md")
      
      result = read(&value)
      if result != kIOReturnSuccess {
        print("Error read fan mode: " + (String(cString: mach_error_string(result), encoding: String.Encoding.ascii) ?? "unknown error"))
        return false
      }
      
      value.bytes = [UInt8(mode.rawValue), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                     UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                     UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                     UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                     UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                     UInt8(0), UInt8(0)]
      
      result = write(value)
      if result != kIOReturnSuccess {
        print("Error write: " + (String(cString: mach_error_string(result), encoding: String.Encoding.ascii) ?? "unknown error"))
        return false
      }
    }
    
    let fansMode = Int(self.getValue("FS! ") ?? 0)
    var newMode: UInt8 = 0
    
    if fansMode == 0 && id == 0 && mode == .forced {
      newMode = 1
    } else if fansMode == 0 && id == 1 && mode == .forced {
      newMode = 2
    } else if fansMode == 1 && id == 0 && mode == .automatic {
      newMode = 0
    } else if fansMode == 1 && id == 1 && mode == .forced {
      newMode = 3
    } else if fansMode == 2 && id == 1 && mode == .automatic {
      newMode = 0
    } else if fansMode == 2 && id == 0 && mode == .forced {
      newMode = 3
    } else if fansMode == 3 && id == 0 && mode == .automatic {
      newMode = 2
    } else if fansMode == 3 && id == 1 && mode == .automatic {
      newMode = 1
    }
    
    if fansMode == newMode {
      return true
    }
    
    var result: kern_return_t = 0
    var value = SMCVal_t("FS! ")
    
    result = read(&value)
    if result != kIOReturnSuccess {
      print("Error read fan mode: " + (String(cString: mach_error_string(result), encoding: String.Encoding.ascii) ?? "unknown error"))
      return false
    }
    
    value.bytes = [0, newMode, UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                   UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                   UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                   UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                   UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                   UInt8(0), UInt8(0)]
    
    result = write(value)
    if result != kIOReturnSuccess {
      print("Error write: " + (String(cString: mach_error_string(result), encoding: String.Encoding.ascii) ?? "unknown error"))
      return false
    }
    return true
#endif
  }
  
  public func setFanSpeed(_ id: Int, speed: Int) -> Bool {
    guard let maxSpeed = self.getValue("F\(id)Mx") else { return false }
    let targetSpeed = min(speed, Int(maxSpeed))
    
#if arch(arm64)
    var modeVal = SMCVal_t(fanModeKey(id))
    let modeResult = read(&modeVal)
    guard modeResult == kIOReturnSuccess else {
      print("Error read fan mode: " + (String(cString: mach_error_string(modeResult), encoding: String.Encoding.ascii) ?? "unknown error"))
      return false
    }
    if modeVal.bytes[0] != 1 {
      if !unlockFanControl(fanId: id) { return false }
    }
#endif
    
    var result: kern_return_t = 0
    var value = SMCVal_t("F\(id)Tg")
    
    result = read(&value)
    if result != kIOReturnSuccess {
      print("Error read fan value: " + (String(cString: mach_error_string(result), encoding: String.Encoding.ascii) ?? "unknown error"))
      return false
    }
    
    if value.dataType == "flt " {
      let bytes = Float(targetSpeed).bytes
      value.bytes[0] = bytes[0]
      value.bytes[1] = bytes[1]
      value.bytes[2] = bytes[2]
      value.bytes[3] = bytes[3]
    } else if value.dataType == "fpe2" {
      value.bytes[0] = UInt8(targetSpeed >> 6)
      value.bytes[1] = UInt8((targetSpeed << 2) ^ ((targetSpeed >> 6) << 8))
      value.bytes[2] = UInt8(0)
      value.bytes[3] = UInt8(0)
    }
    
#if arch(arm64)
    return writeWithRetry(value)
#else
    result = write(value)
    if result != kIOReturnSuccess {
      print("Error write: " + (String(cString: mach_error_string(result), encoding: String.Encoding.ascii) ?? "unknown error"))
      return false
    }
    return true
#endif
  }
  
  // MARK: - Apple Silicon Fan Control
  
#if arch(arm64)
  private func smcError(_ operation: String, key: String, result: kern_return_t) -> String {
    let errorDesc = String(cString: mach_error_string(result), encoding: String.Encoding.ascii) ?? "unknown error"
    return "[\(key)] \(operation) failed: \(errorDesc) (0x\(String(result, radix: 16)))"
  }
  
  private func writeWithRetry(_ value: SMCVal_t, maxAttempts: Int = 10, delayMicros: UInt32 = 50_000) -> Bool {
    let mutableValue = value
    var lastResult: kern_return_t = kIOReturnSuccess
    for attempt in 0..<maxAttempts {
      lastResult = write(mutableValue)
      if lastResult == kIOReturnSuccess {
        return true
      }
      if attempt < maxAttempts - 1 {
        usleep(delayMicros)
      }
    }
    print(smcError("write", key: value.key, result: lastResult))
    return false
  }
  
  private func unlockFanControl(fanId: Int) -> Bool {
    let modeKey = fanModeKey(fanId)
    var modeVal = SMCVal_t(modeKey)
    let modeRead = read(&modeVal)
    guard modeRead == kIOReturnSuccess else {
      print(smcError("read", key: modeKey, result: modeRead))
      return false
    }
    modeVal.bytes[0] = 1
    if write(modeVal) == kIOReturnSuccess {
      return true
    }
    
    var ftstVal = SMCVal_t("Ftst")
    let ftstResult = read(&ftstVal)
    guard ftstResult == kIOReturnSuccess, ftstVal.dataSize > 0 else {
      return false
    }
    
    if ftstVal.bytes[0] == 1 {
      return retryModeWrite(fanId: fanId, maxAttempts: 20)
    }
    
    ftstVal.bytes[0] = 1
    if !writeWithRetry(ftstVal, maxAttempts: 100) {
      return false
    }
    
    usleep(3_000_000)
    
    return retryModeWrite(fanId: fanId, maxAttempts: 300)
  }
  
  private func retryModeWrite(fanId: Int, maxAttempts: Int) -> Bool {
    let modeKey = fanModeKey(fanId)
    var modeVal = SMCVal_t(modeKey)
    let result = read(&modeVal)
    guard result == kIOReturnSuccess else {
      print(smcError("read", key: modeKey, result: result))
      return false
    }
    modeVal.bytes[0] = 1
    return writeWithRetry(modeVal, maxAttempts: maxAttempts, delayMicros: 100_000)
  }
  
#endif
  
  public func resetFanControl() -> Bool {
    var success = true
    var hasFtst = false
    var ftstVal = SMCVal_t("Ftst")
    
#if arch(arm64)
    let ftstReadResult = read(&ftstVal)
    hasFtst = (ftstReadResult == kIOReturnSuccess && ftstVal.dataSize > 0)
    
    if hasFtst {
      if ftstVal.bytes[0] != 1 {
        ftstVal.bytes[0] = 1
        if !writeWithRetry(ftstVal, maxAttempts: 100) {
          print("Failed to unlock Ftst for reset")
        } else {
          usleep(1_000_000)
        }
      }
    }
#endif
    
    guard let count = getValue("FNum") else { return false }
    for i in 0..<Int(count) {
      if !setFanMode(i, mode: .automatic) {
        success = false
      }
    }
    
#if arch(arm64)
    if hasFtst {
      ftstVal.bytes[0] = 0
      if !writeWithRetry(ftstVal, maxAttempts: 100) {
        success = false
      }
    }
#endif
    
    return success
  }
  
  // MARK: - Low-Level connection methods
  
  private func read(_ value: UnsafeMutablePointer<SMCVal_t>) -> kern_return_t {
    var result: kern_return_t = 0
    var input = SMCKeyData_t()
    var output = SMCKeyData_t()
    
    input.key = FourCharCode(fromString: value.pointee.key)
    input.data8 = SMCKeys.readKeyInfo.rawValue
    
    result = call(SMCKeys.kernelIndex.rawValue, input: &input, output: &output)
    if result != kIOReturnSuccess {
      return result
    }
    
    value.pointee.dataSize = UInt32(output.keyInfo.dataSize)
    value.pointee.dataType = output.keyInfo.dataType.toString()
    input.keyInfo.dataSize = output.keyInfo.dataSize
    input.data8 = SMCKeys.readBytes.rawValue
    
    result = call(SMCKeys.kernelIndex.rawValue, input: &input, output: &output)
    if result != kIOReturnSuccess {
      return result
    }
    
    memcpy(&value.pointee.bytes, &output.bytes, Int(value.pointee.dataSize))
    return kIOReturnSuccess
  }
  
  private func write(_ value: SMCVal_t) -> kern_return_t {
    var input = SMCKeyData_t()
    var output = SMCKeyData_t()
    
    input.key = FourCharCode(fromString: value.key)
    input.data8 = SMCKeys.writeBytes.rawValue
    input.keyInfo.dataSize = IOByteCount32(value.dataSize)
    input.bytes = (value.bytes[0], value.bytes[1], value.bytes[2], value.bytes[3], value.bytes[4], value.bytes[5],
                   value.bytes[6], value.bytes[7], value.bytes[8], value.bytes[9], value.bytes[10], value.bytes[11],
                   value.bytes[12], value.bytes[13], value.bytes[14], value.bytes[15], value.bytes[16], value.bytes[17],
                   value.bytes[18], value.bytes[19], value.bytes[20], value.bytes[21], value.bytes[22], value.bytes[23],
                   value.bytes[24], value.bytes[25], value.bytes[26], value.bytes[27], value.bytes[28], value.bytes[29],
                   value.bytes[30], value.bytes[31])
    
    let result = self.call(SMCKeys.kernelIndex.rawValue, input: &input, output: &output)
    if result != kIOReturnSuccess {
      return result
    }
    
    if output.result != 0x00 {
      return kIOReturnError
    }
    
    return kIOReturnSuccess
  }
  
  private func call(_ index: UInt8, input: inout SMCKeyData_t, output: inout SMCKeyData_t) -> kern_return_t {
    if conn == 0 { return kIOReturnNotOpen }
    let inputSize = MemoryLayout<SMCKeyData_t>.stride
    var outputSize = MemoryLayout<SMCKeyData_t>.stride
    return IOConnectCallStructMethod(conn, UInt32(index), &input, inputSize, &output, &outputSize)
  }
}
