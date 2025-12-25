import Foundation

/// Central app version configuration
/// Update this single value when releasing new versions
enum AppVersion {
    /// The current app version - SINGLE SOURCE OF TRUTH
    static let current = "1.0.1"
    
    /// App display name
    static let displayName = "Zonely"
    
    /// Version with "v" prefix (e.g., "v1.0.0")
    static var formatted: String {
        "v\(current)"
    }
    
    /// Full app description (e.g., "Zonely v1.0.0")
    static var fullDescription: String {
        "\(displayName) \(formatted)"
    }
    
    /// Format any version string with "v" prefix
    static func format(_ version: String?) -> String {
        guard let version = version, !version.isEmpty else {
            return formatted // Fallback to current version
        }
        return version.hasPrefix("v") ? version : "v\(version)"
    }
    
    /// Compare two version strings, returns true if remote > current
    static func isNewer(_ remoteVersion: String) -> Bool {
        let remote = remoteVersion.hasPrefix("v") 
            ? String(remoteVersion.dropFirst()) 
            : remoteVersion
        
        let remoteComponents = remote.split(separator: ".").compactMap { Int($0) }
        let currentComponents = current.split(separator: ".").compactMap { Int($0) }
        
        let maxLength = max(remoteComponents.count, currentComponents.count)
        var remotePadded = remoteComponents
        var currentPadded = currentComponents
        
        while remotePadded.count < maxLength { remotePadded.append(0) }
        while currentPadded.count < maxLength { currentPadded.append(0) }
        
        for i in 0..<maxLength {
            if remotePadded[i] > currentPadded[i] {
                return true
            } else if remotePadded[i] < currentPadded[i] {
                return false
            }
        }
        
        return false
    }
}
