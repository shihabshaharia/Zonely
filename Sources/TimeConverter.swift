import Foundation

/// Handles time parsing, conversion, and math operations
struct TimeConverter {
    
    /// Result of parsing a time expression
    struct TimeResult {
        let calculatedDate: Date
        let isMathExpression: Bool
        let originalOperator: String?  // "+" or "-"
        let originalValue: String?     // e.g., "2h", "30m"
    }
    
    /// Parse time expressions with optional math operations
    /// Supports: "+ 2h", "now + 2h", "14:00 - 30m", "5pm + 1.5hrs", "+ 3d", "now + 7days"
    static func parseTimeExpression(_ text: String) -> TimeResult? {
        let trimmed = text.trimmingCharacters(in: .whitespaces).lowercased()
        
        guard !trimmed.isEmpty else { return nil }
        
        // Pattern: optional base time + operator + duration
        // Examples: "+ 2h", "now + 30m", "14:00 - 1h", "5pm + 1.5hrs", "+ 3d", "now + 7days"
        
        // Regex to match: [optional time] [+/-] [number][unit]
        let pattern = #"^(.*?)\s*([+\-])\s*(\d+(?:\.\d+)?)\s*(h|hr|hrs|hour|hours|m|min|mins|minute|minutes|d|day|days)$"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)) else {
            return nil
        }
        
        // Extract match groups
        guard let baseRange = Range(match.range(at: 1), in: trimmed),
              let operatorRange = Range(match.range(at: 2), in: trimmed),
              let valueRange = Range(match.range(at: 3), in: trimmed),
              let unitRange = Range(match.range(at: 4), in: trimmed) else {
            return nil
        }
        
        let baseTimeString = String(trimmed[baseRange]).trimmingCharacters(in: .whitespaces)
        let mathOperator = String(trimmed[operatorRange])
        let valueString = String(trimmed[valueRange])
        let unit = String(trimmed[unitRange]).lowercased()
        
        guard let value = Double(valueString) else { return nil }
        
        // Parse base time (empty or "now" means current time)
        let baseDate: Date
        if baseTimeString.isEmpty || baseTimeString == "now" {
            baseDate = Date()
        } else if let parsed = parseBaseTime(baseTimeString) {
            baseDate = parsed
        } else {
            return nil
        }
        
        // Calculate offset in seconds
        var offsetSeconds: Double
        if unit.hasPrefix("d") {
            // Days: 86400 seconds per day
            offsetSeconds = value * 86400
        } else if unit.hasPrefix("h") {
            // Hours: 3600 seconds per hour
            offsetSeconds = value * 3600
        } else {
            // Minutes: 60 seconds per minute
            offsetSeconds = value * 60
        }
        
        // Apply operator
        if mathOperator == "-" {
            offsetSeconds = -offsetSeconds
        }
        
        let calculatedDate = baseDate.addingTimeInterval(offsetSeconds)
        
        return TimeResult(
            calculatedDate: calculatedDate,
            isMathExpression: true,
            originalOperator: mathOperator,
            originalValue: "\(valueString)\(unit)"
        )
    }
    
    /// Parse base time string (e.g., "14:00", "5pm", "1800")
    private static func parseBaseTime(_ text: String) -> Date? {
        let trimmed = text.trimmingCharacters(in: .whitespaces).lowercased()
        
        // Try military time (3-4 digits)
        if let militaryDate = parseMilitaryTime(trimmed) {
            return militaryDate
        }
        
        // Try 24-hour format (HH:mm)
        let formatter24 = DateFormatter()
        formatter24.dateFormat = "HH:mm"
        if let date = formatter24.date(from: trimmed) {
            return combineDateWithToday(date)
        }
        
        // Try 12-hour format (h:mma, ha, h:mm a, h a)
        let formats12 = ["h:mma", "ha", "h:mm a", "h a", "hmma", "hma"]
        for format in formats12 {
            let formatter12 = DateFormatter()
            formatter12.dateFormat = format
            if let date = formatter12.date(from: trimmed) {
                return combineDateWithToday(date)
            }
        }
        
        // Try NSDataDetector as fallback
        if let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) {
            let range = NSRange(trimmed.startIndex..., in: trimmed)
            if let match = detector.firstMatch(in: trimmed, options: [], range: range),
               let date = match.date {
                return date
            }
        }
        
        return nil
    }
    
    /// Parse 3-4 digit military time (e.g., "1800" -> 18:00, "930" -> 9:30)
    private static func parseMilitaryTime(_ text: String) -> Date? {
        guard text.count >= 3 && text.count <= 4 && text.allSatisfy({ $0.isNumber }) else {
            return nil
        }
        
        var hour: Int
        var minute: Int
        
        if text.count == 4 {
            hour = Int(String(text.prefix(2))) ?? 0
            minute = Int(String(text.suffix(2))) ?? 0
        } else {
            hour = Int(String(text.prefix(1))) ?? 0
            minute = Int(String(text.suffix(2))) ?? 0
        }
        
        guard hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59 else {
            return nil
        }
        
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = minute
        components.second = 0
        
        return Calendar.current.date(from: components)
    }
    
    /// Combine time from parsed date with today's date
    private static func combineDateWithToday(_ time: Date) -> Date {
        let timeComponents = Calendar.current.dateComponents([.hour, .minute], from: time)
        var todayComponents = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        todayComponents.hour = timeComponents.hour
        todayComponents.minute = timeComponents.minute
        todayComponents.second = 0
        return Calendar.current.date(from: todayComponents) ?? time
    }
    
    /// Format date as 12-hour time string
    static func formatAs12Hour(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    /// Format date as 24-hour time string
    static func formatAs24Hour(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    /// Format calculated time with day context based on difference from base date
    /// - Same day: "5:00 PM"
    /// - +/- 1 day: "5:00 PM (Tomorrow)" or "5:00 PM (Yesterday)"
    /// - 2-6 days: "5:00 PM (Coming Tuesday)" or "5:00 PM (Last Monday)"
    /// - 7+ days: "5:00 PM (Jan 28)"
    static func formatWithDayContext(baseDate: Date, calculatedDate: Date) -> String {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        let timeString = timeFormatter.string(from: calculatedDate)
        
        // Get day difference
        let calendar = Calendar.current
        let dayComponents = calendar.dateComponents([.day], from: calendar.startOfDay(for: baseDate), to: calendar.startOfDay(for: calculatedDate))
        let dayDiff = dayComponents.day ?? 0
        
        // Same day - just show time
        if dayDiff == 0 {
            return timeString
        }
        
        // Tomorrow or Yesterday
        if dayDiff == 1 {
            return "\(timeString) (Tomorrow)"
        }
        if dayDiff == -1 {
            return "\(timeString) (Yesterday)"
        }
        
        // 2-6 days - show day name with "Coming" or "Last"
        if dayDiff >= 2 && dayDiff <= 6 {
            let dayFormatter = DateFormatter()
            dayFormatter.dateFormat = "EEEE"  // Full day name
            let dayName = dayFormatter.string(from: calculatedDate)
            return "\(timeString) (Coming \(dayName))"
        }
        if dayDiff >= -6 && dayDiff <= -2 {
            let dayFormatter = DateFormatter()
            dayFormatter.dateFormat = "EEEE"
            let dayName = dayFormatter.string(from: calculatedDate)
            return "\(timeString) (Last \(dayName))"
        }
        
        // 7+ days - show date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"
        let dateString = dateFormatter.string(from: calculatedDate)
        return "\(timeString) (\(dateString))"
    }
}

