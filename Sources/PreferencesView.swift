import SwiftUI
import LaunchAtLogin

struct PreferencesView: View {
    @AppStorage("is24HourMode") private var is24HourMode = true
    @AppStorage("showAltTimeOnHover") private var showAltTimeOnHover = false
    @StateObject private var updateManager = UpdateManager.shared
    @State private var showUpdateAlert = false
    @State private var showErrorAlert = false
    @State private var showUpToDateAlert = false
    @State private var showInstallConfirmation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Time Display Section
            PreferencesSection(icon: "clock", title: "Time Display") {
                VStack(spacing: 0) {
                    PreferencesRow(
                        icon: "clock.fill",
                        title: "24-Hour Format",
                        subtitle: is24HourMode ? "14:30" : "2:30 PM"
                    ) {
                        Toggle("", isOn: $is24HourMode)
                            .toggleStyle(.switch)
                            .labelsHidden()
                    }
                    
                    Divider()
                        .padding(.horizontal, 14)
                    
                    PreferencesRow(
                        icon: "arrow.left.arrow.right",
                        title: "Show Alt Time on Hover",
                        subtitle: "Switch to 12h/24h when hovering"
                    ) {
                        Toggle("", isOn: $showAltTimeOnHover)
                            .toggleStyle(.switch)
                            .labelsHidden()
                    }
                }
            }
            
            // General Section
            PreferencesSection(icon: "gearshape", title: "General") {
                VStack(spacing: 0) {
                    PreferencesRow(
                        icon: "power",
                        title: "Launch at Login",
                        subtitle: "Start Zonely when you log in"
                    ) {
                        LaunchAtLogin.Toggle("")
                            .toggleStyle(.switch)
                            .labelsHidden()
                    }
                }
            }
            
            // Updates Section
            PreferencesSection(icon: "arrow.triangle.2.circlepath", title: "Updates") {
                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        Image(systemName: updateIconName)
                            .font(.system(size: 14))
                            .foregroundColor(updateIconColor)
                            .frame(width: 20)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(updateTitle)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.primary)
                            
                            // Last checked time
                            if let lastChecked = updateManager.lastCheckedAt {
                                Text("Checked \(lastCheckedFormatted(lastChecked))")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            } else {
                                Text("Never checked")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        updateActionView
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    
                    // Download Progress Bar
                    if updateManager.isDownloading {
                        VStack(spacing: 6) {
                            ProgressView(value: updateManager.downloadProgress)
                                .progressViewStyle(.linear)
                            
                            HStack {
                                Text("\(Int(updateManager.downloadProgress * 100))%")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Button("Cancel") {
                                    updateManager.cancelDownload()
                                }
                                .buttonStyle(.plain)
                                .font(.system(size: 10))
                                .foregroundColor(.red)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.bottom, 12)
                    }
                }
            }
            
            Spacer()
            
            // Footer
            HStack {
                Text(AppVersion.fullDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Link("GitHub", destination: URL(string: "https://github.com/shihabshaharia/Zonely")!)
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            .padding(.horizontal, 4)
        }
        .padding(20)
        .frame(width: 380, height: 450)
        .alert("Update Available", isPresented: $showUpdateAlert) {
            if updateManager.canDownloadDirectly {
                Button("Download Now") {
                    Task {
                        await updateManager.downloadUpdate()
                    }
                }
                Button("View on GitHub") {
                    updateManager.openDownloadPage()
                }
                Button("Later", role: .cancel) {}
            } else {
                Button("Download") {
                    updateManager.openDownloadPage()
                }
                Button("Cancel", role: .cancel) {}
            }
        } message: {
            Text("\(updateManager.latestVersionFormatted) is available. Would you like to download it?")
        }
        .alert("Ready to Install", isPresented: $showInstallConfirmation) {
            Button("Install & Restart") {
                updateManager.installUpdate()
            }
            Button("Later", role: .cancel) {}
        } message: {
            Text("The update has been downloaded. Zonely will quit, update, and relaunch automatically.")
        }
        .alert("You're Up to Date", isPresented: $showUpToDateAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("\(AppVersion.fullDescription) is the latest version.")
        }
        .alert("Update Check Failed", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            if case .error(let message) = updateManager.result {
                Text(message)
            } else {
                Text("Could not check for updates.")
            }
        }
        .onChange(of: updateManager.state) { oldValue, newValue in
            handleStateChange(newValue)
        }
    }
    
    // MARK: - Computed Properties
    
    private var updateIconName: String {
        switch updateManager.state {
        case .idle, .checking:
            return "app.badge"
        case .available:
            return "arrow.down.circle"
        case .downloading:
            return "arrow.down.circle.fill"
        case .readyToInstall:
            return "checkmark.circle.fill"
        case .installing:
            return "gear"
        case .error:
            return "exclamationmark.triangle"
        }
    }
    
    private var updateIconColor: Color {
        switch updateManager.state {
        case .idle, .checking:
            return .blue
        case .available, .downloading:
            return .orange
        case .readyToInstall:
            return .green
        case .installing:
            return .blue
        case .error:
            return .red
        }
    }
    
    private var updateTitle: String {
        switch updateManager.state {
        case .idle, .checking:
            return "Current Version"
        case .available(_):
            return "Update Available"
        case .downloading:
            return "Downloading Update..."
        case .readyToInstall:
            return "Ready to Install"
        case .installing:
            return "Installing..."
        case .error:
            return "Update Error"
        }
    }
    
    private var updateSubtitle: String {
        switch updateManager.state {
        case .idle, .checking:
            return AppVersion.formatted
        case .available(let version):
            return "\(AppVersion.format(version)) is available"
        case .downloading:
            return "Please wait..."
        case .readyToInstall:
            return "\(updateManager.latestVersionFormatted) downloaded"
        case .installing:
            return "Restarting..."
        case .error(let message):
            return message
        }
    }
    
    @ViewBuilder
    private var updateActionView: some View {
        switch updateManager.state {
        case .idle:
            Button("Check for Updates") {
                Task {
                    await updateManager.checkForUpdates()
                    handleUpdateResult()
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            
        case .checking:
            ProgressView()
                .scaleEffect(0.7)
            
        case .available:
            if updateManager.canDownloadDirectly {
                Button("Download") {
                    Task {
                        await updateManager.downloadUpdate()
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            } else {
                Button("View Release") {
                    updateManager.openDownloadPage()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            
        case .downloading:
            EmptyView() // Progress shown below
            
        case .readyToInstall:
            Button("Install & Restart") {
                showInstallConfirmation = true
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .controlSize(.small)
            
        case .installing:
            ProgressView()
                .scaleEffect(0.7)
            
        case .error:
            Button("Retry") {
                Task {
                    await updateManager.checkForUpdates()
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
    }
    
    // MARK: - Helpers
    
    private func handleUpdateResult() {
        guard let result = updateManager.result else { return }
        
        switch result {
        case .updateAvailable:
            // Don't show alert, state change handles UI
            break
        case .upToDate:
            showUpToDateAlert = true
        case .error:
            showErrorAlert = true
        }
    }
    
    private func handleStateChange(_ newState: UpdateState) {
        if case .readyToInstall = newState {
            // Optionally auto-show install confirmation
            showInstallConfirmation = true
        }
    }
    
    private func lastCheckedFormatted(_ date: Date) -> String {
        let now = Date()
        let interval = now.timeIntervalSince(date)
        
        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes) minute\(minutes == 1 ? "" : "s") ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours) hour\(hours == 1 ? "" : "s") ago"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    }
}

// MARK: - Section Header
struct PreferencesSection<Content: View>: View {
    let icon: String
    let title: String
    let content: Content
    
    init(icon: String, title: String, @ViewBuilder content: () -> Content) {
        self.icon = icon
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Section Header
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            
            // Section Content
            content
                .background(Color(NSColor.controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

// MARK: - Preference Row
struct PreferencesRow<Trailing: View>: View {
    let icon: String
    let title: String
    let subtitle: String?
    let trailing: Trailing
    
    init(icon: String, title: String, subtitle: String? = nil, @ViewBuilder trailing: () -> Trailing) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing()
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.blue)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            trailing
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}
