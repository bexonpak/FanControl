//
//  AboutViewModel.swift
//  FanControl
//
//  Created by Bexon Pak on 6/26/26.
//

import Foundation

@MainActor
class AboutViewModel {
  let version: String
  let build: String
  
  init() {
    let info = Bundle.main.infoDictionary
    version = info?["CFBundleShortVersionString"] as? String ?? "?"
    build = info?["CFBundleVersion"] as? String ?? "?"
  }
  
  var versionString: String {
    "Version \(version) (\(build))"
  }
  
  func checkForUpdates() async -> UpdateCheckResult {
    let url = URL(string: "https://api.github.com/repos/bexonpak/FanControl/releases/latest")!
    do {
      let (data, _) = try await URLSession.shared.data(from: url)
      guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let tagName = json["tag_name"] as? String else {
        return .error("Invalid response from server")
      }
      let latestVersion = tagName.trimmingCharacters(in: CharacterSet(charactersIn: "v"))
      let comparison = latestVersion.compare(version, options: .numeric)
      if comparison == .orderedDescending {
        let htmlUrl = json["html_url"] as? String ?? url.absoluteString
        return .available(version: latestVersion, url: htmlUrl)
      } else {
        return .upToDate
      }
    } catch {
      return .error(error.localizedDescription)
    }
  }
}

enum UpdateCheckResult {
  case upToDate
  case available(version: String, url: String)
  case error(String)
}
