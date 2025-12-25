import Foundation
import AppKit

// MARK: - GitHub API Models

struct GitHubAsset: Codable {
    let name: String
    let browserDownloadUrl: String
    let size: Int
    
    enum CodingKeys: String, CodingKey {
        case name
        case browserDownloadUrl = "browser_download_url"
        case size
    }
}

struct GitHubRelease: Codable {
    let tagName: String
    let htmlUrl: String
    let name: String?
    let assets: [GitHubAsset]
    
    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case htmlUrl = "html_url"
        case name
        case assets
    }
    
    /// Get the ZIP asset URL for downloading
    var zipAssetURL: URL? {
        // Look for a ZIP file in assets
        if let zipAsset = assets.first(where: { $0.name.hasSuffix(".zip") }) {
            return URL(string: zipAsset.browserDownloadUrl)
        }
        return nil
    }
}

// MARK: - Update State

enum UpdateCheckResult {
    case upToDate
    case updateAvailable(version: String, url: URL)
    case error(String)
}

enum UpdateState: Equatable {
    case idle
    case checking
    case available(version: String)
    case downloading(progress: Double)
    case readyToInstall
    case installing
    case error(String)
}

// MARK: - Update Manager

@MainActor
class UpdateManager: NSObject, ObservableObject {
    static let shared = UpdateManager()
    
    // MARK: Published Properties
    
    @Published var state: UpdateState = .idle
    @Published var isChecking = false
    @Published var isUpdateAvailable = false
    @Published var isDownloading = false
    @Published var downloadProgress: Double = 0.0
    @Published var result: UpdateCheckResult?
    @Published var latestVersion: String?
    @Published var downloadURL: URL?
    @Published var lastCheckedAt: Date? {
        didSet {
            if let date = lastCheckedAt {
                UserDefaults.standard.set(date, forKey: "lastUpdateCheckDate")
            }
        }
    }
    
    // MARK: Private Properties
    
    private let repoURL = "https://api.github.com/repos/shihabshaharia/Zonely/releases/latest"
    private var downloadTask: URLSessionDownloadTask?
    private var downloadedAppURL: URL?
    private var zipAssetURL: URL?
    private var downloadSession: URLSession?
    private var downloadDelegate: DownloadDelegate?
    
    /// Update check interval (12 hours)
    private let checkInterval: TimeInterval = 12 * 60 * 60
    
    // MARK: Initialization
    
    private override init() {
        super.init()
        
        // Load last checked date from UserDefaults
        lastCheckedAt = UserDefaults.standard.object(forKey: "lastUpdateCheckDate") as? Date
        
        // Check for updates on app launch if needed
        Task {
            await checkForUpdatesIfNeeded()
        }
    }
    
    /// Check for updates only if 12 hours have passed since last check
    func checkForUpdatesIfNeeded() async {
        if let lastCheck = lastCheckedAt {
            let timeSinceLastCheck = Date().timeIntervalSince(lastCheck)
            if timeSinceLastCheck < checkInterval {
                // Skip check, not enough time has passed
                return
            }
        }
        await checkForUpdates()
    }
    
    // MARK: - Check for Updates
    
    func checkForUpdates() async {
        isChecking = true
        state = .checking
        result = nil
        
        defer { 
            isChecking = false
            lastCheckedAt = Date()  // Record check time
            if case .checking = state {
                state = .idle
            }
        }
        
        guard let url = URL(string: repoURL) else {
            result = .error("Invalid URL")
            state = .error("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.setValue("Zonely/\(AppVersion.current)", forHTTPHeaderField: "User-Agent")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                result = .error("Invalid response")
                state = .error("Invalid response")
                return
            }
            
            if httpResponse.statusCode == 404 {
                // No releases yet
                result = .upToDate
                isUpdateAvailable = false
                state = .idle
                return
            }
            
            guard httpResponse.statusCode == 200 else {
                result = .error("Server returned status \(httpResponse.statusCode)")
                state = .error("Server error")
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
            
            // Store ZIP asset URL for direct download
            zipAssetURL = release.zipAssetURL
            
            // Use centralized version comparison
            if AppVersion.isNewer(remoteVersion) {
                isUpdateAvailable = true
                state = .available(version: remoteVersion)
                if let url = URL(string: release.htmlUrl) {
                    result = .updateAvailable(version: remoteVersion, url: url)
                } else {
                    result = .error("Invalid download URL")
                    state = .error("Invalid download URL")
                }
            } else {
                isUpdateAvailable = false
                result = .upToDate
                state = .idle
            }
            
        } catch {
            result = .error("Could not check for updates. Please check your internet connection.")
            state = .error("Connection error")
        }
    }
    
    // MARK: - Download Update
    
    func downloadUpdate() async {
        guard let assetURL = zipAssetURL else {
            state = .error("No download URL available")
            return
        }
        
        isDownloading = true
        downloadProgress = 0.0
        state = .downloading(progress: 0.0)
        
        // Create download delegate
        downloadDelegate = DownloadDelegate { [weak self] progress in
            Task { @MainActor in
                self?.downloadProgress = progress
                self?.state = .downloading(progress: progress)
            }
        }
        
        // Create session with delegate
        let config = URLSessionConfiguration.default
        downloadSession = URLSession(configuration: config, delegate: downloadDelegate, delegateQueue: nil)
        
        guard let session = downloadSession else { return }
        
        do {
            let (tempURL, response) = try await session.download(from: assetURL)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                await MainActor.run {
                    isDownloading = false
                    state = .error("Download failed")
                }
                return
            }
            
            // Move to a safe location in temp directory
            let fileManager = FileManager.default
            let tempDir = fileManager.temporaryDirectory
            let downloadDir = tempDir.appendingPathComponent("ZonelyUpdate", isDirectory: true)
            
            // Clean up any previous download
            try? fileManager.removeItem(at: downloadDir)
            try fileManager.createDirectory(at: downloadDir, withIntermediateDirectories: true)
            
            let zipPath = downloadDir.appendingPathComponent("Zonely.zip")
            try fileManager.moveItem(at: tempURL, to: zipPath)
            
            // Extract the ZIP
            let extractedApp = try await extractUpdate(zipPath: zipPath, toDirectory: downloadDir)
            
            await MainActor.run {
                downloadedAppURL = extractedApp
                isDownloading = false
                state = .readyToInstall
            }
            
        } catch {
            await MainActor.run {
                isDownloading = false
                state = .error("Download failed: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Extract Update
    
    private func extractUpdate(zipPath: URL, toDirectory directory: URL) async throws -> URL {
        let fileManager = FileManager.default
        let extractDir = directory.appendingPathComponent("extracted", isDirectory: true)
        
        try? fileManager.removeItem(at: extractDir)
        try fileManager.createDirectory(at: extractDir, withIntermediateDirectories: true)
        
        // Use ditto to extract (preserves permissions and handles macOS apps correctly)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        process.arguments = ["-xk", zipPath.path, extractDir.path]
        
        try process.run()
        process.waitUntilExit()
        
        guard process.terminationStatus == 0 else {
            throw NSError(domain: "UpdateManager", code: 1, 
                          userInfo: [NSLocalizedDescriptionKey: "Failed to extract update"])
        }
        
        // Find the .app bundle in extracted directory
        let contents = try fileManager.contentsOfDirectory(at: extractDir, includingPropertiesForKeys: nil)
        guard let appBundle = contents.first(where: { $0.pathExtension == "app" }) else {
            throw NSError(domain: "UpdateManager", code: 2,
                          userInfo: [NSLocalizedDescriptionKey: "No app bundle found in update"])
        }
        
        return appBundle
    }
    
    // MARK: - Install Update
    
    func installUpdate() {
        guard let newAppURL = downloadedAppURL else {
            state = .error("No update downloaded")
            return
        }
        
        state = .installing
        
        // Get current app location
        guard let currentAppURL = Bundle.main.bundleURL as URL? else {
            state = .error("Could not determine app location")
            return
        }
        
        // Create an updater script that will:
        // 1. Wait for the app to quit
        // 2. Replace the old app with the new one
        // 3. Relaunch the new app
        // 4. Clean up
        
        let scriptContent = """
        #!/bin/bash
        
        # Wait for the app to quit
        sleep 1
        while pgrep -x "Zonely" > /dev/null; do
            sleep 0.5
        done
        
        # Replace the app
        rm -rf "\(currentAppURL.path)"
        cp -R "\(newAppURL.path)" "\(currentAppURL.path)"
        
        # Sign the new app (ad-hoc signature)
        codesign --force --deep --sign - "\(currentAppURL.path)" 2>/dev/null || true
        
        # Clear quarantine attribute
        xattr -dr com.apple.quarantine "\(currentAppURL.path)" 2>/dev/null || true
        
        # Relaunch
        open "\(currentAppURL.path)"
        
        # Clean up temp directory
        rm -rf "\(newAppURL.deletingLastPathComponent().path)"
        
        # Self-destruct
        rm -f "$0"
        """
        
        let fileManager = FileManager.default
        let scriptPath = fileManager.temporaryDirectory.appendingPathComponent("zonely_updater.sh")
        
        do {
            try scriptContent.write(to: scriptPath, atomically: true, encoding: .utf8)
            
            // Make executable
            try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptPath.path)
            
            // Launch the script in background
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/bash")
            process.arguments = [scriptPath.path]
            process.standardOutput = FileHandle.nullDevice
            process.standardError = FileHandle.nullDevice
            
            try process.run()
            
            // Quit the app
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NSApp.terminate(nil)
            }
            
        } catch {
            state = .error("Failed to install update: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Cancel Download
    
    func cancelDownload() {
        downloadTask?.cancel()
        downloadSession?.invalidateAndCancel()
        isDownloading = false
        downloadProgress = 0.0
        state = isUpdateAvailable ? .available(version: latestVersion ?? "") : .idle
    }
    
    // MARK: - Legacy Methods
    
    func openDownloadPage() {
        if let url = downloadURL {
            NSWorkspace.shared.open(url)
        }
    }
    
    /// Formatted latest version for display (e.g., "v1.1.0")
    var latestVersionFormatted: String {
        AppVersion.format(latestVersion)
    }
    
    /// Check if direct download is available (has ZIP asset)
    var canDownloadDirectly: Bool {
        zipAssetURL != nil
    }
}

// MARK: - Download Delegate

private class DownloadDelegate: NSObject, URLSessionDownloadDelegate {
    let progressHandler: (Double) -> Void
    
    init(progressHandler: @escaping (Double) -> Void) {
        self.progressHandler = progressHandler
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, 
                    didFinishDownloadingTo location: URL) {
        // Handled in the async download method
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64, totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        guard totalBytesExpectedToWrite > 0 else { return }
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        progressHandler(progress)
    }
}
