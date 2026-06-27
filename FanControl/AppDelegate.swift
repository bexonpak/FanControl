//
//  AppDelegate.swift
//  FanControl
//
//  Created by Bexon Pak on 6/26/26.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
  
  private let menuBarController = MenuBarController()
  
  func applicationDidFinishLaunching(_ aNotification: Notification) {
    menuBarController.start()
  }
  
  func applicationWillTerminate(_ aNotification: Notification) {
    menuBarController.stop()
  }
  
  func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
  
}

