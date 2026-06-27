//
//  FanControlMenuItemView.swift
//  FanControl
//
//  Created by Bexon Pak on 6/26/26.
//

import Cocoa

private let presetPercentages: [Int] = [20, 40, 50, 60, 80, 100]

class FanControlMenuItemView: NSView {
  private let slider: NSSlider
  private let nameLabel: NSTextField
  private let valueLabel: NSTextField
  private let speedLabel: NSTextField
  private let fanId: Int
  private let viewModel: MenuBarViewModel
  private var presetButtons: [NSButton] = []
  private var lastDragTime: Date = .distantPast
  private var isAutoActive = false
  private var autoBtn: NSButton!
  
  init(fanId: Int, viewModel: MenuBarViewModel) {
    self.fanId = fanId
    self.viewModel = viewModel
    
    nameLabel = NSTextField(labelWithString: "Fan \(fanId) \u{2192} Target")
    nameLabel.font = .systemFont(ofSize: 11)
    nameLabel.textColor = .secondaryLabelColor
    
    let initialSpeed: Int
    if let target = viewModel.targetSpeeds[fanId] {
      initialSpeed = target
    } else {
      initialSpeed = Int(viewModel.fanSpeeds[fanId] ?? 0)
    }
    valueLabel = NSTextField(labelWithString: "\(initialSpeed)")
    valueLabel.font = .monospacedDigitSystemFont(ofSize: 12, weight: .medium)
    valueLabel.alignment = .right
    
    speedLabel = NSTextField(labelWithString: "Actual: \(initialSpeed)")
    speedLabel.font = .monospacedDigitSystemFont(ofSize: 14, weight: .regular)
    speedLabel.textColor = .labelColor
    speedLabel.alignment = .left
    
    let maxSpeed = Int(viewModel.fanMaxSpeeds[fanId] ?? 100)
    slider = NSSlider(value: Double(initialSpeed),
                      minValue: 0,
                      maxValue: Double(maxSpeed),
                      target: nil,
                      action: nil)
    slider.isContinuous = true
    
    super.init(frame: NSRect(x: 0, y: 0, width: 280, height: 112))
    
    nameLabel.translatesAutoresizingMaskIntoConstraints = false
    valueLabel.translatesAutoresizingMaskIntoConstraints = false
    speedLabel.translatesAutoresizingMaskIntoConstraints = false
    slider.translatesAutoresizingMaskIntoConstraints = false
    addSubview(nameLabel)
    addSubview(valueLabel)
    addSubview(speedLabel)
    addSubview(slider)
    
    autoBtn = NSButton(title: "Auto", target: self, action: #selector(autoTapped))
    autoBtn.bezelStyle = .smallSquare
    autoBtn.isBordered = false
    autoBtn.font = .systemFont(ofSize: 11)
    autoBtn.wantsLayer = true
    autoBtn.layer?.cornerRadius = 4
    autoBtn.translatesAutoresizingMaskIntoConstraints = false
    autoBtn.setContentHuggingPriority(.required, for: .horizontal)
    addSubview(autoBtn)
    presetButtons.append(autoBtn)
    
    isAutoActive = viewModel.fanModes[fanId] == .automatic
    nameLabel.stringValue = isAutoActive ? "Fan \(fanId) \u{2192} Auto" : "Fan \(fanId) \u{2192} Target"
    updateAutoButtonAppearance()
    
    var previousButton: NSButton = autoBtn
    NSLayoutConstraint.activate([
      autoBtn.centerYAnchor.constraint(equalTo: slider.bottomAnchor, constant: 22),
      autoBtn.heightAnchor.constraint(equalToConstant: 22),
      autoBtn.widthAnchor.constraint(equalToConstant: 38),
      autoBtn.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
    ])
    
    for pct in presetPercentages {
      let speed = maxSpeed * pct / 100
      let btn = NSButton(title: "\(pct)%", target: self, action: #selector(presetTapped(_:)))
      btn.bezelStyle = .smallSquare
      btn.font = .systemFont(ofSize: 11)
      btn.translatesAutoresizingMaskIntoConstraints = false
      btn.tag = speed
      btn.setContentHuggingPriority(.required, for: .horizontal)
      addSubview(btn)
      presetButtons.append(btn)
      
      NSLayoutConstraint.activate([
        btn.centerYAnchor.constraint(equalTo: slider.bottomAnchor, constant: 22),
        btn.heightAnchor.constraint(equalToConstant: 22),
        btn.leadingAnchor.constraint(equalTo: previousButton.trailingAnchor, constant: 4),
      ])
      previousButton = btn
    }
    
    NSLayoutConstraint.activate([
      speedLabel.topAnchor.constraint(equalTo: topAnchor, constant: 4),
      speedLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
      
      nameLabel.topAnchor.constraint(equalTo: speedLabel.bottomAnchor, constant: 4),
      nameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
      
      valueLabel.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
      valueLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
      
      slider.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
      slider.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
      slider.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
      slider.heightAnchor.constraint(equalToConstant: 14),
      
      bottomAnchor.constraint(equalTo: slider.bottomAnchor, constant: 48),
    ])
    
    previousButton.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -12).isActive = true
    
    slider.target = self
    slider.action = #selector(sliderChanged)
  }
  
  required init?(coder: NSCoder) { nil }
  
  @objc private func sliderChanged() {
    isAutoActive = false
    nameLabel.stringValue = "Fan \(fanId) \u{2192} Target"
    lastDragTime = Date()
    let value = Int(slider.doubleValue)
    valueLabel.stringValue = "\(value)"
    viewModel.setFanSpeed(fanId, speed: value)
    updateAutoButtonAppearance()
  }
  
  @objc private func presetTapped(_ sender: NSButton) {
    isAutoActive = false
    nameLabel.stringValue = "Fan \(fanId) \u{2192} Target"
    lastDragTime = .distantPast
    let speed = sender.tag
    valueLabel.stringValue = "\(speed)"
    slider.doubleValue = Double(speed)
    viewModel.setFanSpeed(fanId, speed: speed)
    updateAutoButtonAppearance()
  }
  
  @objc private func autoTapped() {
    isAutoActive = true
    nameLabel.stringValue = "Fan \(fanId) \u{2192} Auto"
    lastDragTime = .distantPast
    viewModel.setFanToAutomatic(fanId)
    updateAutoButtonAppearance()
  }
  
  func refreshSpeed() {
    let speed = Int(viewModel.fanSpeeds[fanId] ?? 0)
    speedLabel.stringValue = "Actual: \(speed)"
    let isAuto = viewModel.fanModes[fanId] == .automatic
    if isAuto != isAutoActive {
      isAutoActive = isAuto
      nameLabel.stringValue = isAuto ? "Fan \(fanId) \u{2192} Auto" : "Fan \(fanId) \u{2192} Target"
      updateAutoButtonAppearance()
    }
  }
  
  private func updateAutoButtonAppearance() {
    autoBtn.layer?.backgroundColor = isAutoActive ? NSColor.systemBlue.cgColor : NSColor.clear.cgColor
    autoBtn.isBordered = !isAutoActive
    autoBtn.contentTintColor = isAutoActive ? NSColor.white : NSColor(named: "blackDynamic")
    valueLabel.isHidden = isAutoActive
  }
  
  func setControlsEnabled(_ enabled: Bool) {
    slider.isEnabled = enabled
    for btn in presetButtons {
      btn.isEnabled = enabled
    }
  }
  
  func resetSliderTracking() {
    slider.isHighlighted = false
    slider.cell?.isHighlighted = false
  }
}
