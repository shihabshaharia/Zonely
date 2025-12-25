import Foundation
import AppKit

struct GitHubRelease: Codable {
    let tagName: String
    let htmlUrl: String
    let name: String?
    
    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case htmlUrl = "html_url"
        case name
    }
}

enum UpdateCheckResult {
    case upToDate
    case updateAvailable(version: String, url: URL)
    case error(String)
}

@MainActor
class UpdateManager: ObservableObject {
    static let shared = UpdateManager()
    
    @Published var isChecking = false
    @Published var isUpdateAvailable = false
    @Published var result: UpdateCheckResult?
    @Published var latestVersion: String?
    @Published var downloadURL: URL?
    
    private let repoURL = "https://api.github.com/repos/shihabshaharia/Zonely/releases/latest"
    
    private init() {
        // Check for updates on app launch
        Task {
            await checkForUpdates()
        }
    }
    
    func checkForUpdates() async {
        isChecking = true
        result = nil
        
        defer { isChecking = false }
        
        guard let url = URL(string: repoURL) else {
            result = .error("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.setValue("Zonely/\(AppVersion.current)", forHTTPHeaderField: "User-Agent")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                result = .error("Invalid response")
                return
            }
            
            if httpResponse.statusCode == 404 {
                // No releases yet
                result = .upToDate
                isUpdateAvailable = false
                return
            }
            
            guard httpResponse.statusCode == 200 else {
                result = .error("Server returned status \(httpResponse.statusCode)")
                return
            }
            
            let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
            
            // Store raw version (without "v" prefix for consistency)
            let remoteVersion = release.tagName.hasPrefix("v") 
                ? String(release.tagName.dropFirst()) 
                : release.tagName
            
            latestVersion = remoteVersion
            
            if let url = URL(string: release.htmlUrl) {
                downloadURL = url
            }
            
            // Use centralized version comparison
            if AppVersion.isNewer(remoteVersion) {
                isUpdateAvailable = true
                if let url = URL(string: release.htmlUrl) {
                    result = .updateAvailable(version: remoteVersion, url: url)
                } else {
                    result = .error("Invalid download URL")
                }
            } else {
                isUpdateAvailable = false
                result = .upToDate
            }
            
        } catch {
            result = .error("Could not check for updates. Please check your internet connection.")
        }
    }
    
    func openDownloadPage() {
        if let url = downloadURL {
            NSWorkspace.shared.open(url)
        }
    }
    
    /// Formatted latest version for display (e.g., "v1.1.0")
    var latestVersionFormatted: String {
        AppVersion.format(latestVersion)
    }
}
