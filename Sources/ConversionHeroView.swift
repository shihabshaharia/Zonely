import SwiftUI
import AppKit

/// A Spotlight-style hero view that displays time format conversions
/// When user types 12hr format, shows 24hr equivalent and vice versa
struct ConversionHeroView: View {
    let inputTime: String
    let detectedDate: Date  // The exact time user typed (e.g., 3:21 for "321")
    let timeOffset: Double  // Current slider position
    let baseTimeOffset: Double  // Slider position when time was first detected
    
    @State private var showCopied = false
    
    /// The slider delta: how much the user moved the slider AFTER typing a time
    private var sliderDelta: Double {
        timeOffset - baseTimeOffset
    }
    
    /// Apply slider delta to the detected date
    /// e.g., typed "321" (3:21 AM), moved slider +2 hours → shows 5:21 AM
    private var displayedDate: Date {
        detectedDate.addingTimeInterval(sliderDelta * 3600)
    }
    
    /// Detect if the input appears to be 12-hour format
    private var inputIs12HourFormat: Bool {
        let lowercased = inputTime.lowercased()
        return lowercased.contains("am") || lowercased.contains("pm") ||
               lowercased.contains("a.m") || lowercased.contains("p.m")
    }
    
    /// Detect if the input is military time format (3-4 digits like 1800, 930)
    private var inputIsMilitaryFormat: Bool {
        let trimmed = inputTime.trimmingCharacters(in: .whitespaces)
        // Check if it's a 3-4 digit number
        return trimmed.count >= 3 && trimmed.count <= 4 && 
               trimmed.allSatisfy { $0.isNumber }
    }
    
    /// The converted time string (opposite format of input)
    /// Updates with slider movement
    private var convertedTime: String {
        let formatter = DateFormatter()
        if inputIs12HourFormat {
            // Input is 12hr, output 24hr
            formatter.dateFormat = "HH:mm"
        } else {
            // Input is 24hr or military time, output 12hr
            formatter.dateFormat = "h:mm a"
        }
        return formatter.string(from: displayedDate)
    }
    
    /// Label describing the conversion direction
    private var conversionLabel: String {
        if inputIs12HourFormat {
            return "24-hour format"
        } else {
            return "12-hour format"
        }
    }
    
    /// Copy the converted time to clipboard
    private func copyToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(convertedTime, forType: .string)
        
        // Show feedback
        withAnimation(.easeInOut(duration: 0.2)) {
            showCopied = true
        }
        
        // Reset after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.2)) {
                showCopied = false
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Left: Label
            VStack(alignment: .leading, spacing: 2) {
                Text(conversionLabel)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
            
            Spacer()
            
            // Center/Right: The converted time result
            Text(convertedTime)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            // Right: Copy button
            Button(action: copyToClipboard) {
                Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(showCopied ? .green : .secondary)
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
            .help(showCopied ? "Copied!" : "Copy to clipboard")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        // Preview with 12hr input - slider at initial position
        ConversionHeroView(
            inputTime: "2:30pm",
            detectedDate: {
                var components = DateComponents()
                components.hour = 14
                components.minute = 30
                return Calendar.current.date(from: components) ?? Date()
            }(),
            timeOffset: 0,
            baseTimeOffset: 0
        )
        
        // Preview with 24hr input - slider moved +2 hours from base
        ConversionHeroView(
            inputTime: "1430",
            detectedDate: {
                var components = DateComponents()
                components.hour = 14
                components.minute = 30
                return Calendar.current.date(from: components) ?? Date()
            }(),
            timeOffset: 4,  // Current slider position
            baseTimeOffset: 2  // Initial offset = delta of +2 hours
        )
    }
    .padding()
    .frame(width: 400)
    .background(Color.black.opacity(0.8))
    .preferredColorScheme(.dark)
}
