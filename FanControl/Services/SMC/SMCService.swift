//
//  SMCService.swift
//  FanControl
//
//  Created by Bexon Pak on 6/27/26.
//

import Foundation

public protocol SMCService: AnyObject {
  func getValue(_ key: String) -> Double?
  func getStringValue(_ key: String) -> String?
  func fanModeKey(_ id: Int) -> String
  func setFanMode(_ id: Int, mode: FanMode) -> Bool
  func setFanSpeed(_ id: Int, speed: Int) -> Bool
  func resetFanControl() -> Bool
  func close() -> kern_return_t
}
