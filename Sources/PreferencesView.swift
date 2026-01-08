import SwiftUI
import LaunchAtLogin

struct PreferencesView: View {
    @AppStorage("is24HourMode") private var is24HourMode = true
    @AppStorage("showAltTimeOnHover") private var showAltTimeOnHover = false
    @AppStorage("customTimezone") private var customTimezone = ""
    @StateObject private var updateManager = UpdateManager.shared
    @State private var selectedTab = 0
    @State private var showTimezonePicker = false
    @State private var showInstallConfirmation = false
    @State private var showUpToDateAlert = false
    @State private var showErrorAlert = false
    @State private var timezoneSearchText = ""
    
    private var availableCities: [City] {
        DataManager.shared.loadCities().sorted { $0.city < $1.city }
    }
    
    private var filteredCities: [City] {
        if timezoneSearchText.isEmpty { return availableCities }
        let search = timezoneSearchText.lowercased()
        return availableCities.filter {
            $0.city.lowercased().contains(search) || $0.country.lowercased().contains(search)
        }
    }
    
    private var currentTimezoneDisplay: String {
        if customTimezone.isEmpty {
            let systemId = TimeZone.current.identifier
            if let city = availableCities.first(where: { $0.timezone == systemId }) {
                return "\(city.city) (Auto)"
            }
            return "Auto-detect"
        }
        return availableCities.first(where: { $0.timezone == customTimezone })?.city ?? customTimezone
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab picker (native segmented control)
            Picker("", selection: $selectedTab) {
                Text("General").tag(0)
                Text("Updates").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 60)
            .padding(.top, 16)
            
            Divider()
                .padding(.top, 12)
            
            // Content
            Group {
                if selectedTab == 0 {
                    generalContent
                } else {
                    updatesContent
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 400, height: 380)
        .sheet(isPresented: $showTimezonePicker) { timezonePicker }
        .alert("Ready to Install", isPresented: $showInstallConfirmation) {
            Button("Install & Restart") { updateManager.installUpdate() }
            Button("Later", role: .cancel) {}
        } message: { Text("Zonely will restart to complete the update.") }
        .alert("You're Up to Date", isPresented: $showUpToDateAlert) {
            Button("OK", role: .cancel) {}
        } message: { Text("\(AppVersion.fullDescription) is the latest version.") }
        .alert("Update Failed", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: { Text("Could not check for updates.") }
        .onChange(of: updateManager.state) { _, newValue in
            if case .readyToInstall = newValue { showInstallConfirmation = true }
        }
    }
    
    // MARK: - Tab Button
    private func tabButton(_ title: String, index: Int) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) { selectedTab = index }
        } label: {
            Text(title)
                .font(.system(size: 13, weight: selectedTab == index ? .semibold : .regular))
                .foregroundColor(selectedTab == index ? .primary : .secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(selectedTab == index ? Color.blue.opacity(0.15) : Color.clear)
                )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - General Content
    private var generalContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Time Format
            settingRow(icon: "clock.fill", title: "24-Hour Format", subtitle: is24HourMode ? "14:30" : "2:30 PM") {
                Toggle("", isOn: $is24HourMode).toggleStyle(.switch).labelsHidden()
            }
            
            settingRow(icon: "arrow.left.arrow.right", title: "Alt Time on Hover", subtitle: "Switch formats on hover") {
                Toggle("", isOn: $showAltTimeOnHover).toggleStyle(.switch).labelsHidden()
            }
            
            Divider().padding(.vertical, 4)
            
            // Timezone
            settingRow(icon: "globe", title: "Local Timezone", subtitle: currentTimezoneDisplay) {
                Button("Change") { showTimezonePicker = true }
                    .buttonStyle(.bordered).controlSize(.small)
            }
            
            if !customTimezone.isEmpty {
                HStack {
                    Spacer()
                    Button("Reset to Auto-detect") { customTimezone = "" }
                        .font(.caption).foregroundColor(.blue)
                    Spacer()
                }
            }
            
            Divider().padding(.vertical, 4)
            
            // Startup
            settingRow(icon: "power", title: "Launch at Login", subtitle: "Start when you log in") {
                LaunchAtLogin.Toggle("").toggleStyle(.switch).labelsHidden()
            }
            
            Spacer()
        }
        .padding(20)
    }
    
    // MARK: - Updates Content
    private var updatesContent: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // Icon
            Image(systemName: updateIconName)
                .font(.system(size: 48))
                .foregroundColor(updateIconColor)
            
            // Status
            Text(updateTitle)
                .font(.headline)
            
            if let lastChecked = updateManager.lastCheckedAt {
                Text("Last checked: \(lastCheckedFormatted(lastChecked))")
                    .font(.caption).foregroundColor(.secondary)
            }
            
            // Progress
            if updateManager.isDownloading {
                VStack(spacing: 8) {
                    ProgressView(value: updateManager.downloadProgress)
                        .frame(width: 200)
                    HStack {
                        Text("\(Int(updateManager.downloadProgress * 100))%")
                            .font(.caption).foregroundColor(.secondary)
                        Spacer()
                        Button("Cancel") { updateManager.cancelDownload() }
                            .font(.caption).foregroundColor(.red)
                    }
                    .frame(width: 200)
                }
            }
            
            // Action
            updateActionView
            
            Spacer()
            
            // Footer
            HStack {
                Text(AppVersion.fullDescription)
                    .font(.system(size: 12)).foregroundColor(.secondary)
                Spacer()
                Link("GitHub", destination: URL(string: "https://github.com/shihabshaharia/Zonely")!)
                    .font(.system(size: 12))
            }
        }
        .padding(20)
    }
    
    // MARK: - Setting Row
    private func settingRow<Content: View>(icon: String, title: String, subtitle: String, @ViewBuilder trailing: () -> Content) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 13, weight: .medium))
                Text(subtitle).font(.system(size: 11)).foregroundColor(.secondary)
            }
            
            Spacer()
            trailing()
        }
    }
    
    // MARK: - Timezone Picker
    private var timezonePicker: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Select Timezone").font(.headline)
                Spacer()
                Button("Done") { showTimezonePicker = false }.buttonStyle(.borderedProminent)
            }
            .padding()
            
            HStack {
                Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                TextField("Search...", text: $timezoneSearchText).textFieldStyle(.plain)
            }
            .padding(10)
            .background(Color(NSColor.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal)
            
            Divider().padding(.top, 12)
            
            ScrollView {
                LazyVStack(spacing: 0) {
                    Button { customTimezone = ""; showTimezonePicker = false } label: {
                        HStack {
                            Image(systemName: "location.fill").foregroundColor(.blue)
                            Text("Auto-detect").foregroundColor(.primary)
                            Spacer()
                            if customTimezone.isEmpty { Image(systemName: "checkmark").foregroundColor(.blue) }
                        }
                        .padding(.horizontal).padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)
                    
                    Divider().padding(.leading, 40)
                    
                    ForEach(filteredCities) { city in
                        Button {
                            customTimezone = city.timezone
                            showTimezonePicker = false
                        } label: {
                            HStack {
                                Image(systemName: "globe").foregroundColor(.secondary)
                                VStack(alignment: .leading) {
                                    Text(city.city).foregroundColor(.primary)
                                    Text(city.country).font(.caption).foregroundColor(.secondary)
                                }
                                Spacer()
                                if customTimezone == city.timezone {
                                    Image(systemName: "checkmark").foregroundColor(.blue)
                                }
                            }
                            .padding(.horizontal).padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .frame(width: 320, height: 380)
    }
    
    // MARK: - Helpers
    private var updateIconName: String {
        switch updateManager.state {
        case .idle, .checking: return "checkmark.circle.fill"
        case .available: return "arrow.down.circle.fill"
        case .downloading: return "arrow.down.circle"
        case .readyToInstall: return "checkmark.circle.fill"
        case .installing: return "gear"
        case .error: return "exclamationmark.triangle.fill"
        }
    }
    
    private var updateIconColor: Color {
        switch updateManager.state {
        case .idle, .checking: return .green
        case .available, .downloading: return .orange
        case .readyToInstall: return .green
        case .installing: return .blue
        case .error: return .red
        }
    }
    
    private var updateTitle: String {
        switch updateManager.state {
        case .idle, .checking: return "Zonely is up to date"
        case .available: return "Update Available"
        case .downloading: return "Downloading..."
        case .readyToInstall: return "Ready to Install"
        case .installing: return "Installing..."
        case .error: return "Update Failed"
        }
    }
    
    @ViewBuilder
    private var updateActionView: some View {
        switch updateManager.state {
        case .idle:
            Button("Check for Updates") {
                Task {
                    await updateManager.checkForUpdates()
                    if case .upToDate = updateManager.result { showUpToDateAlert = true }
                    if case .error = updateManager.result { showErrorAlert = true }
                }
            }
            .buttonStyle(.borderedProminent)
            
        case .checking:
            ProgressView().scaleEffect(0.8)
            
        case .available:
            if updateManager.canDownloadDirectly {
                Button("Download") { Task { await updateManager.downloadUpdate() } }
                    .buttonStyle(.borderedProminent)
            } else {
                Button("View Release") { updateManager.openDownloadPage() }
                    .buttonStyle(.borderedProminent)
            }
            
        case .downloading:
            EmptyView()
            
        case .readyToInstall:
            Button("Install & Restart") { showInstallConfirmation = true }
                .buttonStyle(.borderedProminent).tint(.green)
            
        case .installing:
            ProgressView().scaleEffect(0.8)
            
        case .error:
            Button("Retry") { Task { await updateManager.checkForUpdates() } }
                .buttonStyle(.bordered)
        }
    }
    
    private func lastCheckedFormatted(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 60 { return "Just now" }
        if interval < 3600 { return "\(Int(interval / 60)) min ago" }
        if interval < 86400 { return "\(Int(interval / 3600)) hours ago" }
        return DateFormatter.localizedString(from: date, dateStyle: .short, timeStyle: .none)
    }
}
