import SwiftUI
import LaunchAtLogin

struct PreferencesView: View {
    @AppStorage("is24HourMode") private var is24HourMode = true
    
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
                }
            }
            
            // General Section
            PreferencesSection(icon: "gearshape", title: "General") {
                VStack(spacing: 0) {
                    PreferencesRow(
                        icon: "power",
                        title: "Launch at Login",
                        subtitle: "Start Zonly when you log in"
                    ) {
                        LaunchAtLogin.Toggle("")
                            .toggleStyle(.switch)
                            .labelsHidden()
                    }
                }
            }
            
            Spacer()
            
            // Footer
            HStack {
                Text("Zonly 1.0.0")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Link("GitHub", destination: URL(string: "https://github.com/shihabshaharia")!)
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            .padding(.horizontal, 4)
        }
        .padding(20)
        .frame(width: 380, height: 280)
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
