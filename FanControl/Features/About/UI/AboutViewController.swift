//
//  AboutViewController.swift
//  FanControl
//
//  Created by Bexon Pak on 6/26/26.
//

import Cocoa

@MainActor
class AboutViewController: NSViewController {
  private let viewModel = AboutViewModel()
  private let iconView = NSImageView()
  private let nameLabel = NSTextField(labelWithString: "FanControl")
  private let versionLabel = NSTextField(labelWithString: "")
  private let updateButton = NSButton(title: "Check for Updates", target: nil, action: nil)
  private let spinner = NSProgressIndicator()
  private let copyrightLabel = NSTextField(labelWithString: "Copyright © 2026 Bexon Pak")
  private let openSourceButton = NSButton(title: "", target: nil, action: nil)
  
  override func loadView() {
    view = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 240))
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    versionLabel.stringValue = viewModel.versionString
  }
  
  private func setupUI() {
    iconView.image = NSApp.applicationIconImage
    iconView.frame = NSRect(x: 130, y: 175, width: 40, height: 40)
    iconView.imageScaling = .scaleProportionallyUpOrDown
    
    nameLabel.font = .systemFont(ofSize: 14, weight: .semibold)
    nameLabel.alignment = .center
    nameLabel.frame = NSRect(x: 0, y: 145, width: 300, height: 20)
    
    versionLabel.font = .systemFont(ofSize: 11)
    versionLabel.textColor = .secondaryLabelColor
    versionLabel.alignment = .center
    versionLabel.frame = NSRect(x: 0, y: 123, width: 300, height: 18)
    
    copyrightLabel.font = .systemFont(ofSize: 10)
    copyrightLabel.textColor = .secondaryLabelColor
    copyrightLabel.alignment = .center
    copyrightLabel.frame = NSRect(x: 0, y: 95, width: 300, height: 16)
    
    let linkAttr: [NSAttributedString.Key: Any] = [
      .foregroundColor: NSColor.linkColor,
      .underlineStyle: NSUnderlineStyle.single.rawValue,
      .font: NSFont.systemFont(ofSize: 10),
    ]
    openSourceButton.attributedTitle = NSAttributedString(string: "https://github.com/bexonpak/FanControl", attributes: linkAttr)
    openSourceButton.isBordered = false
    openSourceButton.frame = NSRect(x: 0, y: 72, width: 300, height: 16)
    openSourceButton.target = self
    openSourceButton.action = #selector(openGitHub)
    
    updateButton.bezelStyle = .rounded
    updateButton.font = .systemFont(ofSize: 12)
    updateButton.frame = NSRect(x: 80, y: 25, width: 140, height: 28)
    updateButton.target = self
    updateButton.action = #selector(checkForUpdatesTapped)
    
    spinner.style = .spinning
    spinner.controlSize = .small
    spinner.frame = NSRect(x: 228, y: 29, width: 16, height: 16)
    spinner.isDisplayedWhenStopped = false
    
    view.addSubview(iconView)
    view.addSubview(nameLabel)
    view.addSubview(versionLabel)
    view.addSubview(copyrightLabel)
    view.addSubview(openSourceButton)
    view.addSubview(updateButton)
    view.addSubview(spinner)
  }
  
  @objc private func checkForUpdatesTapped() {
    updateButton.isEnabled = false
    spinner.startAnimation(nil)
    
    Task {
      let result = await viewModel.checkForUpdates()
      let alert = NSAlert()
      alert.alertStyle = .informational
      
      switch result {
      case .upToDate:
        alert.messageText = "FanControl is up to date"
        alert.informativeText = "You are running the latest version (\(viewModel.version))."
        
      case .available(let version, let url):
        alert.messageText = "Update Available"
        alert.informativeText = "Version \(version) is available. Download it from GitHub."
        alert.addButton(withTitle: "Download")
        alert.addButton(withTitle: "Cancel")
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
          NSWorkspace.shared.open(URL(string: url)!)
        }
        updateButton.isEnabled = true
        spinner.stopAnimation(nil)
        return
        
      case .error(let msg):
        alert.messageText = "Check for Updates Failed"
        alert.informativeText = msg
      }
      
      alert.addButton(withTitle: "OK")
      alert.runModal()
      updateButton.isEnabled = true
      spinner.stopAnimation(nil)
    }
  }
  
  @objc private func openGitHub() {
    NSWorkspace.shared.open(URL(string: "https://github.com/bexonpak/FanControl")!)
  }
}
