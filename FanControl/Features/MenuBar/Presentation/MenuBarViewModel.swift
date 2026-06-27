//
//  MenuBarViewModel.swift
//  FanControl
//
//  Created by Bexon Pak on 6/26/26.
//

import Cocoa
import Combine

@MainActor
class MenuBarViewModel: ObservableObject {
  @Published var fanCount: Int = 0
  @Published var fanSpeeds: [Int: Double] = [:]
  @Published var fanMinSpeeds: [Int: Double] = [:]
  @Published var fanMaxSpeeds: [Int: Double] = [:]
  @Published var fanModes: [Int: FanMode] = [:]
  
  @Published var isAuthorized: Bool = false
  
  private let smc: SMCService
  private var timer: Timer?
  
  init(smc: SMCService) {
    self.smc = smc
  }
  var targetSpeeds: [Int: Int] = [:]
  
  private static let settingsKey = "FanControlSavedSettings"
  
  private var bundleHelperPath: String {
    Bundle.main.bundlePath + "/Contents/MacOS/smc-helper"
  }
  
  private var persistentHelperDir: String {
    let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    return appSupport.appendingPathComponent("FanControl").path
  }
  
  var helperPath: String {
    persistentHelperDir + "/smc-helper"
  }
  
  func startMonitoring() {
    checkAuthorization()
    reloadFanData()
    restoreSavedSettings()
    timer = Timer(timeInterval: 2.0, target: self, selector: #selector(timerFired), userInfo: nil, repeats: true)
    RunLoop.main.add(timer!, forMode: .common)
  }
  
  @objc private func timerFired() {
    reloadFanSpeeds()
  }
  
  func stopMonitoring() {
    timer?.invalidate()
    timer = nil
  }
  
  func checkAuthorization() {
    guard FileManager.default.fileExists(atPath: helperPath) else {
      isAuthorized = false
      return
    }
    if let attributes = try? FileManager.default.attributesOfItem(atPath: helperPath) {
      let ownerId = attributes[.ownerAccountID] as? Int ?? -1
      let posixPermissions = attributes[.posixPermissions] as? Int ?? 0
      let isSetuid = (posixPermissions & 0o4000) != 0
      isAuthorized = (ownerId == 0 && isSetuid)
    } else {
      isAuthorized = false
    }
  }
  
  func authorize() {
    guard FileManager.default.fileExists(atPath: bundleHelperPath) else { return }
    
    let shellCmd = "mkdir -p '\(persistentHelperDir)' && cp -f '\(bundleHelperPath)' '\(helperPath)' && chown root:wheel '\(helperPath)' && chmod +s '\(helperPath)'"
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
    task.arguments = ["-e", "do shell script \"\(shellCmd)\" with administrator privileges"]
    
    do {
      try task.run()
      task.waitUntilExit()
      isAuthorized = task.terminationStatus == 0
    } catch {
      print("Authorization failed: \(error)")
    }
  }
  
  func reloadFanData() {
    guard let count = smc.getValue("FNum") else { return }
    fanCount = Int(count)
    for i in 0..<fanCount {
      if let min = smc.getValue("F\(i)Mn") {
        fanMinSpeeds[i] = min
      }
      if let max = smc.getValue("F\(i)Mx") {
        fanMaxSpeeds[i] = max
      }
    }
    reloadFanSpeeds()
  }
  
  func reloadFanSpeeds() {
    for i in 0..<fanCount {
      if let speed = smc.getValue("F\(i)Ac") {
        fanSpeeds[i] = speed
      }
      if let modeVal = smc.getValue(smc.fanModeKey(i)) {
        fanModes[i] = Int(modeVal) == 1 ? .forced : .automatic
      }
    }
  }
  
  func setFanToAutomatic(_ id: Int) {
    guard isAuthorized else { return }
    runHelper(arguments: ["set-mode", "\(id)", "0"])
    saveFanSetting(id: id, mode: 0, speed: nil)
  }
  
  func setFanSpeed(_ id: Int, speed: Int) {
    guard isAuthorized else { return }
    let maxSpeed = Int(fanMaxSpeeds[id] ?? 100)
    let clampedSpeed = min(max(speed, 0), maxSpeed)
    targetSpeeds[id] = clampedSpeed
    runHelper(arguments: ["set-mode", "\(id)", "1"])
    runHelper(arguments: ["set-speed", "\(id)", "\(clampedSpeed)"])
    saveFanSetting(id: id, mode: 1, speed: clampedSpeed)
  }
  
  func resetAll() {
    guard isAuthorized else { return }
    runHelper(arguments: ["reset"])
    targetSpeeds.removeAll()
    UserDefaults.standard.removeObject(forKey: Self.settingsKey)
    reloadFanData()
  }
  
  private func runHelper(arguments: [String]) {
    guard FileManager.default.fileExists(atPath: helperPath) else { return }
    
    let task = Process()
    task.executableURL = URL(fileURLWithPath: helperPath)
    task.arguments = arguments
    
    do {
      try task.run()
      task.waitUntilExit()
    } catch {
      print("Failed to run smc-helper: \(error)")
    }
  }
  
  private func saveFanSetting(id: Int, mode: Int, speed: Int?) {
    var settings = loadSavedSettings()
    settings[id] = SavedFanSetting(mode: mode, speed: speed)
    if let data = try? JSONEncoder().encode(settings) {
      UserDefaults.standard.set(data, forKey: Self.settingsKey)
    }
  }
  
  private func loadSavedSettings() -> [Int: SavedFanSetting] {
    guard let data = UserDefaults.standard.data(forKey: Self.settingsKey),
          let settings = try? JSONDecoder().decode([Int: SavedFanSetting].self, from: data) else {
      return [:]
    }
    return settings
  }
  
  private func restoreSavedSettings() {
    guard isAuthorized else { return }
    let settings = loadSavedSettings()
    let fanIds = settings.keys.sorted()
    for id in fanIds {
      guard let setting = settings[id] else { continue }
      if setting.mode == 0 {
        runHelper(arguments: ["set-mode", "\(id)", "0"])
      } else {
        let maxSpeed = Int(fanMaxSpeeds[id] ?? 100)
        let speed = min(max(setting.speed ?? maxSpeed, 0), maxSpeed)
        targetSpeeds[id] = speed
        runHelper(arguments: ["set-mode", "\(id)", "1"])
        runHelper(arguments: ["set-speed", "\(id)", "\(speed)"])
      }
    }
  }
}

private struct SavedFanSetting: Codable {
  let mode: Int
  let speed: Int?
}
