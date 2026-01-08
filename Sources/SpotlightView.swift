import SwiftUI

struct SearchResult {
    var citySearchText: String
    var detectedDate: Date?
    var timeOffset: Double?
}

struct SpotlightView: View {
    weak var window: NSWindow?
    
    @State private var searchText = ""
    @State private var allCities: [City] = []
    @State private var favoriteCityIds: Set<String> = []
    @State private var currentDate = Date()
    @State private var timeOffset: Double = 0
    @State private var baseTimeOffset: Double = 0  // The offset when time was first detected (for slider delta)
    @State private var detectedTimeLabel: String? = nil
    @State private var detectedDate: Date? = nil
    @State private var showConversion = false
    @State private var showAboutView = false
    @AppStorage("is24HourMode") private var is24HourMode = true
    @StateObject private var updateManager = UpdateManager.shared
    @FocusState private var isSearchFocused: Bool
    
    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    /// Parse search query for dates/times using NSDataDetector
    func parseSearchQuery(text: String) -> SearchResult {
        var result = SearchResult(citySearchText: text, detectedDate: nil, timeOffset: nil)
        
        guard !text.isEmpty else { return result }
        
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        
        // First, try to parse math expressions (e.g., "+ 2h", "now + 30m", "14:00 - 1h")
        if let timeResult = TimeConverter.parseTimeExpression(trimmed) {
            result.detectedDate = timeResult.calculatedDate
            
            // Calculate offset from now
            let exactSecondsFromNow = timeResult.calculatedDate.timeIntervalSince(Date())
            let exactHoursFromNow = exactSecondsFromNow / 3600
            let clampedOffset = max(-12, min(12, exactHoursFromNow))
            result.timeOffset = clampedOffset
            result.citySearchText = ""  // Math expressions don't filter cities
            return result
        }
        
        // Try to parse 4-digit military time format (e.g., 1800 -> 18:00)
        if let militaryTime = parseMilitaryTime(trimmed) {
            result.detectedDate = militaryTime.date
            
            // Calculate EXACT offset in hours (including fractional hours for minutes)
            // This preserves minute precision - e.g., typing "321" at 3:41 gives offset of -0.333... hours
            let exactSecondsFromNow = militaryTime.date.timeIntervalSince(Date())
            let exactHoursFromNow = exactSecondsFromNow / 3600
            let clampedOffset = max(-12, min(12, exactHoursFromNow))
            result.timeOffset = clampedOffset  // Don't round! Keep exact fractional hours
            
            // Remove the time portion from search text
            result.citySearchText = trimmed.replacingOccurrences(of: militaryTime.matchedText, with: "").trimmingCharacters(in: .whitespaces)
            return result
        }
        
        // Try to detect dates using NSDataDetector
        do {
            let detector = try NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
            let range = NSRange(text.startIndex..., in: text)
            
            if let match = detector.firstMatch(in: text, options: [], range: range) {
                if let detectedDate = match.date {
                    result.detectedDate = detectedDate
                    
                    // Calculate exact hours from now (don't round - preserve minute precision)
                    let hoursFromNow = detectedDate.timeIntervalSince(Date()) / 3600
                    
                    // Clamp to -12 to +12 range
                    let clampedOffset = max(-12, min(12, hoursFromNow))
                    result.timeOffset = clampedOffset  // No rounding!
                    
                    // Remove the date portion from search text for city filtering
                    let matchRange = Range(match.range, in: text)!
                    result.citySearchText = text.replacingCharacters(in: matchRange, with: "").trimmingCharacters(in: .whitespaces)
                }
            }
        } catch {
            // If detection fails, just use the text as-is
        }
        
        return result
    }
    
    /// Parse 4-digit military time format (e.g., "1800" -> 18:00, "0930" -> 09:30)
    private func parseMilitaryTime(_ text: String) -> (date: Date, matchedText: String)? {
        // Match 3-4 digit patterns that look like military time
        let pattern = #"^(\d{3,4})$"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) != nil else {
            return nil
        }
        
        let timeString = text
        var hour: Int
        var minute: Int
        
        if timeString.count == 4 {
            // Format: HHMM (e.g., 1800)
            hour = Int(String(timeString.prefix(2))) ?? 0
            minute = Int(String(timeString.suffix(2))) ?? 0
        } else if timeString.count == 3 {
            // Format: HMM (e.g., 930 -> 9:30)
            hour = Int(String(timeString.prefix(1))) ?? 0
            minute = Int(String(timeString.suffix(2))) ?? 0
        } else {
            return nil
        }
        
        // Validate hour and minute
        guard hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59 else {
            return nil
        }
        
        // Create date with today's date and the parsed time
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = minute
        components.second = 0
        
        guard let date = Calendar.current.date(from: components) else {
            return nil
        }
        
        return (date, timeString)
    }
    
    /// Get the user's local timezone identifier (uses custom preference if set)
    @AppStorage("customTimezone") private var customTimezone = ""
    
    private var localTimezoneId: String {
        if !customTimezone.isEmpty {
            return customTimezone
        }
        return TimeZone.current.identifier
    }
    
    /// Check if the search results contain a city matching local timezone
    var searchResultsContainLocalCity: Bool {
        let parsed = parseSearchQuery(text: searchText)
        let searchString = parsed.citySearchText
        
        guard !searchString.isEmpty else { return false }
        
        let lowercasedSearch = searchString.lowercased()
        return allCities.contains { city in
            city.timezone == localTimezoneId &&
            (city.city.lowercased().contains(lowercasedSearch) ||
             city.country.lowercased().contains(lowercasedSearch) ||
             city.keywords.contains { $0.lowercased().contains(lowercasedSearch) })
        }
    }
    
    /// Cities to display based on search or favorites
    var displayCities: [City] {
        let parsed = parseSearchQuery(text: searchText)
        let searchString = parsed.citySearchText
        
        if searchString.isEmpty {
            // Show favorites when not searching (exclude local timezone city since LocalTimeRow handles it)
            return allCities.filter { 
                favoriteCityIds.contains($0.id) && $0.timezone != localTimezoneId
            }
        }
        
        // When searching, show all matching cities (including local timezone)
        let lowercasedSearch = searchString.lowercased()
        return allCities.filter { city in
            city.city.lowercased().contains(lowercasedSearch) ||
            city.country.lowercased().contains(lowercasedSearch) ||
            city.keywords.contains { $0.lowercased().contains(lowercasedSearch) }
        }
    }
    
    /// Check if a city is in favorites
    func isFavorite(_ city: City) -> Bool {
        favoriteCityIds.contains(city.id)
    }
    
    /// Toggle favorite status for a city
    func toggleFavorite(_ city: City) {
        if favoriteCityIds.contains(city.id) {
            favoriteCityIds.remove(city.id)
            PersistenceManager.shared.removeFavorite(cityId: city.id)
        } else {
            favoriteCityIds.insert(city.id)
            PersistenceManager.shared.addFavorite(cityId: city.id)
        }
    }
    
    var offsetLabel: String {
        // Always show the normal offset format (+X hrs)
        let offset = Int(timeOffset.rounded())
        if offset == 0 {
            return "Now"
        } else if offset > 0 {
            return "+\(offset) hrs"
        } else {
            return "\(offset) hrs"
        }
    }
    
    /// Whether to show the update banner
    private var shouldShowUpdateBanner: Bool {
        switch updateManager.state {
        case .available, .downloading, .readyToInstall, .installing:
            return true
        default:
            return false
        }
    }
    
    /// Update banner view based on current state
    @ViewBuilder
    private var updateBannerView: some View {
        switch updateManager.state {
        case .available(let version):
            // Available - show download button
            Button(action: {
                Task { await updateManager.downloadUpdate() }
            }) {
                HStack {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 14))
                    Text("New version \(AppVersion.format(version)) available")
                        .font(.system(size: 12, weight: .medium))
                    Spacer()
                    Text("Download")
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Capsule())
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            }
            .buttonStyle(.plain)
            
        case .downloading(let progress):
            // Downloading - show progress
            VStack(spacing: 6) {
                HStack {
                    Image(systemName: "arrow.down.circle")
                        .font(.system(size: 14))
                    Text("Downloading update...")
                        .font(.system(size: 12, weight: .medium))
                    Spacer()
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    Button("Cancel") {
                        updateManager.cancelDownload()
                    }
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                }
                
                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                    .tint(.white)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                LinearGradient(
                    colors: [.orange, .red],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            
        case .readyToInstall:
            // Ready - show install button
            Button(action: {
                updateManager.installUpdate()
            }) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                    Text("Update downloaded! Click to install & restart")
                        .font(.system(size: 12, weight: .medium))
                    Spacer()
                    Text("Install")
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Capsule())
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    LinearGradient(
                        colors: [.green, .mint],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            }
            .buttonStyle(.plain)
            
        case .installing:
            // Installing - show spinner
            HStack {
                ProgressView()
                    .scaleEffect(0.7)
                    .colorInvert()
                Text("Installing update... App will restart shortly")
                    .font(.system(size: 12, weight: .medium))
                Spacer()
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                LinearGradient(
                    colors: [.green, .mint],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            
        default:
            EmptyView()
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Field
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.secondary)
                
                TextField("Search cities, times (e.g. '5pm', 'tomorrow')...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 22, weight: .light))
                    .foregroundColor(.primary)
                    .focused($isSearchFocused)
                    .onChange(of: searchText) { _, newValue in
                        // Check for hidden About trigger
                        let lowercased = newValue.lowercased().trimmingCharacters(in: .whitespaces)
                        showAboutView = (lowercased == "about" || lowercased == "version")
                        
                        let parsed = parseSearchQuery(text: newValue)
                        if let offset = parsed.timeOffset, let date = parsed.detectedDate {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                timeOffset = offset
                                baseTimeOffset = offset  // Store initial offset for slider delta calculation
                                detectedDate = date
                                showConversion = true
                            }
                            // Format the detected time
                            let formatter = DateFormatter()
                            formatter.dateFormat = "HH:mm"
                            detectedTimeLabel = formatter.string(from: date)
                        } else {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showConversion = false
                            }
                            detectedTimeLabel = nil
                            detectedDate = nil
                            baseTimeOffset = 0
                        }
                    }
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            // Time Travel Slider
            HStack(spacing: 12) {
                Image(systemName: "clock.arrow.2.circlepath")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                Slider(value: $timeOffset, in: -12...12, step: 1)
                    .tint(.blue)
                
                Text(offsetLabel)
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundColor(timeOffset == 0 ? .secondary : .blue)
                    .frame(width: 60, alignment: .trailing)
                
                Button(action: { timeOffset = 0 }) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .opacity(timeOffset != 0 ? 1 : 0)
                .disabled(timeOffset == 0)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
            
            // Time Conversion Hero View (Spotlight-style result)
            if showConversion, let date = detectedDate {
                ConversionHeroView(inputTime: searchText, detectedDate: date, timeOffset: timeOffset, baseTimeOffset: baseTimeOffset)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            Divider()
                .padding(.horizontal, 12)
            
            // Cities List or About View
            if showAboutView {
                AboutView()
            } else if displayCities.isEmpty && !searchText.isEmpty && !showAboutView {
                EmptySearchStateView(searchText: searchText)
            } else if displayCities.isEmpty && searchText.isEmpty {
                // No favorites yet - but still show local time
                ScrollView {
                    VStack(spacing: 0) {
                        LocalTimeRow(timeOffset: timeOffset, is24HourMode: is24HourMode)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                        
                        Divider()
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 12) {
                            Image(systemName: "star")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary.opacity(0.5))
                            Text("No favorite cities yet")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                            Text("Search for a city and tap + to add")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary.opacity(0.7))
                        }
                        .padding(.vertical, 40)
                    }
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        // User's Local Time (hide when search results contain local city to avoid duplicate)
                        if !searchResultsContainLocalCity {
                            LocalTimeRow(timeOffset: timeOffset, is24HourMode: is24HourMode)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                            
                            Divider()
                                .padding(.horizontal, 20)
                        }
                        
                        ForEach(displayCities) { city in
                            CityRowWithFavorite(
                                city: city,
                                timeOffset: timeOffset,
                                isFavorite: isFavorite(city),
                                isSearching: !searchText.isEmpty,
                                is24HourMode: is24HourMode,
                                isLocalTimezone: city.timezone == localTimezoneId,
                                onToggleFavorite: { toggleFavorite(city) }
                            )
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            
                            if city.id != displayCities.last?.id {
                                Divider()
                                    .padding(.horizontal, 20)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            
            // Update Banner
            updateBannerView
        }
        .frame(width: 600, height: shouldShowUpdateBanner ? 520 : 480)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .onAppear {
            allCities = DataManager.shared.loadCities()
            favoriteCityIds = Set(PersistenceManager.shared.favoriteCityIds)
            // Focus the search field after a brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isSearchFocused = true
            }
        }
        .onReceive(timer) { _ in
            currentDate = Date()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowAboutView"))) { _ in
            searchText = "about"
        }
        .preferredColorScheme(.dark)
    }
}

struct CityRowWithFavorite: View {
    let city: City
    let timeOffset: Double
    let isFavorite: Bool
    let isSearching: Bool
    let is24HourMode: Bool
    let isLocalTimezone: Bool  // Hide favorite button for local timezone
    let onToggleFavorite: () -> Void
    
    @AppStorage("showAltTimeOnHover") private var showAltTimeOnHover = false
    @State private var isHovering = false
    
    /// Current display time - switches format on hover if preference enabled
    private var displayTime: String {
        if showAltTimeOnHover && isHovering {
            // Show alternate format when hovering
            return city.currentTime(hourOffset: timeOffset, is24Hour: !is24HourMode)
        }
        return city.currentTime(hourOffset: timeOffset, is24Hour: is24HourMode)
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(city.city)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                Text(city.country)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                // Favorite toggle button (hide for local timezone - always pinned at top)
                if !isLocalTimezone {
                    Button(action: onToggleFavorite) {
                        Image(systemName: isFavorite ? "star.fill" : "plus.circle")
                            .font(.system(size: 16))
                            .foregroundColor(isFavorite ? .yellow : .blue)
                    }
                    .buttonStyle(.plain)
                }
                
                Image(systemName: city.isDaytime(hourOffset: timeOffset) ? "sun.max.fill" : "moon.fill")
                    .font(.system(size: 14))
                    .foregroundColor(city.isDaytime(hourOffset: timeOffset) ? .yellow : .indigo)
                
                Text(displayTime)
                    .font(.system(size: 24, weight: .semibold, design: .monospaced))
                    .foregroundColor(timeOffset == 0 ? .primary : .blue)
                    .frame(minWidth: showAltTimeOnHover ? 120 : nil, alignment: .trailing)
                    .onHover { hovering in
                        if showAltTimeOnHover {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                isHovering = hovering
                            }
                        }
                    }
            }
        }
        .contentShape(Rectangle())
    }
}

struct CityRow: View {
    let city: City
    let timeOffset: Double
    let is24HourMode: Bool
    
    @AppStorage("showAltTimeOnHover") private var showAltTimeOnHover = false
    @State private var isHovering = false
    
    private var displayTime: String {
        if showAltTimeOnHover && isHovering {
            return city.currentTime(hourOffset: timeOffset, is24Hour: !is24HourMode)
        }
        return city.currentTime(hourOffset: timeOffset, is24Hour: is24HourMode)
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(city.city)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                Text(city.country)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Image(systemName: city.isDaytime(hourOffset: timeOffset) ? "sun.max.fill" : "moon.fill")
                    .font(.system(size: 14))
                    .foregroundColor(city.isDaytime(hourOffset: timeOffset) ? .yellow : .indigo)
                
                Text(displayTime)
                    .font(.system(size: 24, weight: .semibold, design: .monospaced))
                    .foregroundColor(timeOffset == 0 ? .primary : .blue)
                    .frame(minWidth: showAltTimeOnHover ? 120 : nil, alignment: .trailing)
                    .onHover { hovering in
                        if showAltTimeOnHover {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                isHovering = hovering
                            }
                        }
                    }
            }
        }
        .contentShape(Rectangle())
    }
}

struct LocalTimeRow: View {
    let timeOffset: Double
    let is24HourMode: Bool
    
    @AppStorage("showAltTimeOnHover") private var showAltTimeOnHover = false
    @State private var isHovering = false
    
    private var localTimezone: String {
        TimeZone.current.identifier
    }
    
    private var localCity: String {
        // Extract city name from timezone identifier (e.g., "Asia/Dhaka" -> "Dhaka")
        let components = TimeZone.current.identifier.split(separator: "/")
        if let city = components.last {
            return String(city).replacingOccurrences(of: "_", with: " ")
        }
        return "Local"
    }
    
    private var isLocalDaytime: Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH"
        let offsetDate = Date().addingTimeInterval(timeOffset * 3600)
        if let hour = Int(formatter.string(from: offsetDate)) {
            return hour >= 6 && hour < 18
        }
        return true
    }
    
    /// Display time - switches format on hover if preference enabled
    private var displayTime: String {
        let formatter = DateFormatter()
        if showAltTimeOnHover && isHovering {
            formatter.dateFormat = is24HourMode ? "h:mm a" : "HH:mm"
        } else {
            formatter.dateFormat = is24HourMode ? "HH:mm" : "h:mm a"
        }
        let offsetDate = Date().addingTimeInterval(timeOffset * 3600)
        return formatter.string(from: offsetDate)
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.blue)
                    Text(localCity)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                }
                Text("Your timezone")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Image(systemName: isLocalDaytime ? "sun.max.fill" : "moon.fill")
                    .font(.system(size: 14))
                    .foregroundColor(isLocalDaytime ? .yellow : .indigo)
                
                Text(displayTime)
                    .font(.system(size: 24, weight: .semibold, design: .monospaced))
                    .foregroundColor(timeOffset == 0 ? .primary : .blue)
                    .frame(minWidth: showAltTimeOnHover ? 120 : nil, alignment: .trailing)
                    .onHover { hovering in
                        if showAltTimeOnHover {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                isHovering = hovering
                            }
                        }
                    }
            }
        }
        .contentShape(Rectangle())
    }
}

// MARK: - Empty Search State
struct EmptySearchStateView: View {
    let searchText: String
    
    private var cleanSearchText: String {
        searchText.trimmingCharacters(in: .whitespaces)
    }
    
    private var requestURL: URL? {
        let encodedCity = cleanSearchText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let title = "Add city: \(cleanSearchText)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "https://github.com/shihabshaharia/Zonely/issues/new?title=\(title)&body=Please%20add%20the%20city%20\(encodedCity)%20to%20Zonely.")
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.secondary.opacity(0.4))
            
            VStack(spacing: 6) {
                Text("No cities found for")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                Text("'\(cleanSearchText)'")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
            }
            
            if let url = requestURL {
                Link(destination: url) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 12))
                        Text("Request '\(cleanSearchText)'")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 40)
    }
}

#Preview {
    SpotlightView(window: nil)
        .frame(width: 600, height: 480)
}

