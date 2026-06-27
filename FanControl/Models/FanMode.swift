//
//  FanMode.swift
//  FanControl
//
//  Created by Bexon Pak on 6/27/26.
//

public enum FanMode: Int, Codable {
  case automatic = 0
  case forced = 1
  case auto3 = 3

  public var isAutomatic: Bool {
    self == .automatic || self == .auto3
  }
}
