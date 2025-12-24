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
    @State private var detectedTimeLabel: String? = nil
    @State private var showAboutView = false
    @AppStorage("is24HourMode") private var is24HourMode = true
    @FocusState private var isSearchFocused: Bool
    
    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    /// Parse search query for dates/times using NSDataDetector
    func parseSearchQuery(text: String) -> SearchResult {
        var result = SearchResult(citySearchText: text, detectedDate: nil, timeOffset: nil)
        
        guard !text.isEmpty else { return result }
        
        // Try to detect dates using NSDataDetector
        do {
            let detector = try NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
            let range = NSRange(text.startIndex..., in: text)
            
            if let match = detector.firstMatch(in: text, options: [], range: range) {
                if let detectedDate = match.date {
                    result.detectedDate = detectedDate
                    
                    // Calculate hours from now
                    let hoursFromNow = detectedDate.timeIntervalSince(Date()) / 3600
                    
                    // Clamp to -12 to +12 range
                    let clampedOffset = max(-12, min(12, hoursFromNow))
                    result.timeOffset = clampedOffset.rounded()
                    
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
    
    /// Get the user's local timezone identifier
    private var localTimezoneId: String {
        TimeZone.current.identifier
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
        if let label = detectedTimeLabel {
            return label
        }
        if timeOffset == 0 {
            return "Now"
        } else if timeOffset > 0 {
            return "+\(Int(timeOffset)) hrs"
        } else {
            return "\(Int(timeOffset)) hrs"
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
                        if let offset = parsed.timeOffset {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                timeOffset = offset
                            }
                            // Format the detected time
                            if let date = parsed.detectedDate {
                                let formatter = DateFormatter()
                                formatter.dateFormat = "HH:mm"
                                detectedTimeLabel = formatter.string(from: date)
                            }
                        } else {
                            detectedTimeLabel = nil
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
        }
        .frame(width: 600, height: 480)
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
    let onToggleFavorite: () -> Void
    
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
                // Favorite toggle button (show when searching or hovering)
                Button(action: onToggleFavorite) {
                    Image(systemName: isFavorite ? "star.fill" : "plus.circle")
                        .font(.system(size: 16))
                        .foregroundColor(isFavorite ? .yellow : .blue)
                }
                .buttonStyle(.plain)
                
                Image(systemName: city.isDaytime(hourOffset: timeOffset) ? "sun.max.fill" : "moon.fill")
                    .font(.system(size: 14))
                    .foregroundColor(city.isDaytime(hourOffset: timeOffset) ? .yellow : .indigo)
                
                Text(city.currentTime(hourOffset: timeOffset, is24Hour: is24HourMode))
                    .font(.system(size: 24, weight: .semibold, design: .monospaced))
                    .foregroundColor(timeOffset == 0 ? .primary : .blue)
            }
        }
        .contentShape(Rectangle())
    }
}

struct CityRow: View {
    let city: City
    let timeOffset: Double
    let is24HourMode: Bool
    
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
                
                Text(city.currentTime(hourOffset: timeOffset, is24Hour: is24HourMode))
                    .font(.system(size: 24, weight: .semibold, design: .monospaced))
                    .foregroundColor(timeOffset == 0 ? .primary : .blue)
            }
        }
        .contentShape(Rectangle())
    }
}

struct LocalTimeRow: View {
    let timeOffset: Double
    let is24HourMode: Bool
    
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
    
    private var localTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = is24HourMode ? "HH:mm" : "h:mm a"
        let offsetDate = Date().addingTimeInterval(timeOffset * 3600)
        return formatter.string(from: offsetDate)
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
                
                Text(localTime)
                    .font(.system(size: 24, weight: .semibold, design: .monospaced))
                    .foregroundColor(timeOffset == 0 ? .primary : .blue)
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
        return URL(string: "https://github.com/shihabshaharia/Zonly/issues/new?title=\(title)&body=Please%20add%20the%20city%20\(encodedCity)%20to%20Zonly.")
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

