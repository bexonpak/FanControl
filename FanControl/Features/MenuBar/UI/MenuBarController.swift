//
//  MenuBarController.swift
//  FanControl
//
//  Created by Bexon Pak on 6/26/26.
//

import Cocoa
import Combine

@MainActor
class MenuBarController: NSObject, NSMenuDelegate {
  private var statusItem: NSStatusItem!
  private let viewModel = MenuBarViewModel(smc: SMC())
  private var cancellables = Set<AnyCancellable>()
  private var fanPresetViews: [Int: FanControlMenuItemView] = [:]
  private var aboutWindowController: NSWindowController?
  
  func start() {
    statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    setupStatusItemImage()
    viewModel.startMonitoring()
    observeViewModel()
    buildMenu()
  }
  
  func stop() {
    viewModel.stopMonitoring()
    if let item = statusItem {
      NSStatusBar.system.removeStatusItem(item)
    }
    statusItem = nil
  }
  
  private func setupStatusItemImage() {
    if let button = statusItem.button {
      let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .regular)
      if let image = NSImage(systemSymbolName: "fanblades.fill", accessibilityDescription: "Fan Control") {
        image.isTemplate = true
        button.image = image
        button.image?.withSymbolConfiguration(config)
      }
    }
  }
  
  private func observeViewModel() {
    viewModel.$fanSpeeds
      .receive(on: DispatchQueue.main)
      .sink { [weak self] speeds in
        for (id, _) in speeds {
          self?.fanPresetViews[id]?.refreshSpeed()
        }
      }
      .store(in: &cancellables)
    
    viewModel.$isAuthorized
      .receive(on: DispatchQueue.main)
      .sink { [weak self] _ in
        self?.buildMenu()
        for (_, view) in self?.fanPresetViews ?? [:] {
          view.setControlsEnabled(self?.viewModel.isAuthorized ?? false)
        }
      }
      .store(in: &cancellables)
  }
  
  private func buildMenu() {
    let menu = NSMenu()
    menu.delegate = self
    menu.minimumWidth = 200
    
    if !viewModel.isAuthorized {
      let authItem = NSMenuItem(title: "🔑 Authorize Fan Control", action: #selector(authorize), keyEquivalent: "")
      authItem.target = self
      menu.addItem(authItem)
      menu.addItem(NSMenuItem.separator())
    }
    
    if viewModel.fanCount == 0 {
      let item = menu.addItem(withTitle: "No fans detected", action: nil, keyEquivalent: "")
      item.isEnabled = false
      statusItem.menu = menu
      return
    }
    
    for i in 0..<viewModel.fanCount {
      let presetView = FanControlMenuItemView(fanId: i, viewModel: viewModel)
      presetView.setControlsEnabled(viewModel.isAuthorized)
      fanPresetViews[i] = presetView
      
      let menuItem = NSMenuItem()
      menuItem.view = presetView
      menuItem.target = self
      
      menu.addItem(menuItem)
      menu.addItem(NSMenuItem.separator())
    }
    
    if viewModel.isAuthorized {
      let resetItem = NSMenuItem(title: "Reset All", action: #selector(resetAll), keyEquivalent: "r")
      resetItem.target = self
      menu.addItem(resetItem)
    }
    menu.addItem(NSMenuItem.separator())
    let aboutItem = NSMenuItem(title: "About", action: #selector(showAbout), keyEquivalent: "")
    aboutItem.target = self
    menu.addItem(aboutItem)
    menu.addItem(NSMenuItem.separator())
    let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
    quitItem.target = self
    menu.addItem(quitItem)
    
    statusItem.menu = menu
  }
  
  func menuWillOpen(_ menu: NSMenu) {
    for (_, view) in fanPresetViews {
      view.resetSliderTracking()
    }
  }
  
  func menuDidClose(_ menu: NSMenu) {
    buildMenu()
  }
  
  @objc private func authorize() {
    viewModel.authorize()
  }
  
  @objc private func resetAll() {
    guard viewModel.isAuthorized else { return }
    viewModel.resetAll()
  }
  
  @objc private func showAbout() {
    if aboutWindowController == nil {
      let aboutVC = AboutViewController()
      let window = NSWindow(contentViewController: aboutVC)
      window.title = "About"
      window.level = .floating
      window.styleMask = [.titled, .closable, .miniaturizable]
      aboutWindowController = NSWindowController(window: window)
    }
    NSApp.activate(ignoringOtherApps: true)
    aboutWindowController?.showWindow(nil)
  }
  
  @objc private func quitApp() {
    viewModel.stopMonitoring()
    NSApplication.shared.terminate(nil)
  }
}
