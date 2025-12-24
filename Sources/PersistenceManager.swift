import Foundation

class PersistenceManager {
    static let shared = PersistenceManager()
    
    private let favoritesKey = "favoriteCityIds"
    private let defaults = UserDefaults.standard
    
    private init() {}
    
    /// Get the list of favorite city IDs
    var favoriteCityIds: [String] {
        get {
            defaults.stringArray(forKey: favoritesKey) ?? []
        }
        set {
            defaults.set(newValue, forKey: favoritesKey)
        }
    }
    
    /// Add a city to favorites
    func addFavorite(cityId: String) {
        var favorites = favoriteCityIds
        if !favorites.contains(cityId) {
            favorites.append(cityId)
            favoriteCityIds = favorites
        }
    }
    
    /// Remove a city from favorites
    func removeFavorite(cityId: String) {
        var favorites = favoriteCityIds
        favorites.removeAll { $0 == cityId }
        favoriteCityIds = favorites
    }
    
    /// Check if a city is a favorite
    func isFavorite(cityId: String) -> Bool {
        favoriteCityIds.contains(cityId)
    }
    
    /// Get favorite cities from the full city list
    func getFavoriteCities(from allCities: [City]) -> [City] {
        let favoriteIds = favoriteCityIds
        return allCities.filter { favoriteIds.contains($0.id) }
    }
}
