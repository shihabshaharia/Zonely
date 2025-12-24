import Foundation

struct City: Codable, Identifiable {
    let city: String
    let country: String
    let timezone: String
    let keywords: [String]
    
    var id: String { city }
    
    /// Returns the current time in this city's timezone as a formatted string
    /// - Parameters:
    ///   - hourOffset: Hours to add/subtract from current time (for time travel feature)
    ///   - is24Hour: If true, uses 24-hour format (14:00), otherwise uses 12-hour format (2:00 PM)
    func currentTime(hourOffset: Double = 0, is24Hour: Bool = true) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = is24Hour ? "HH:mm" : "h:mm a"
        formatter.timeZone = TimeZone(identifier: timezone)
        let offsetDate = Date().addingTimeInterval(hourOffset * 3600)
        return formatter.string(from: offsetDate)
    }
    
    /// Returns true if it's daytime (6am-6pm) in this city's timezone
    func isDaytime(hourOffset: Double = 0) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH"
        formatter.timeZone = TimeZone(identifier: timezone)
        let offsetDate = Date().addingTimeInterval(hourOffset * 3600)
        if let hour = Int(formatter.string(from: offsetDate)) {
            return hour >= 6 && hour < 18
        }
        return true
    }
}

