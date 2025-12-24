import Foundation

class DataManager {
    static let shared = DataManager()
    
    private init() {}
    
    /// Loads cities from the bundled JSON file
    func loadCities() -> [City] {
        // Try Bundle.module first (Swift Package Manager), then fall back to Bundle.main
        let bundle = Bundle.module
        
        guard let url = bundle.url(forResource: "cities", withExtension: "json") else {
            print("Error: Could not find cities.json in bundle")
            return []
        }
        
        do {
            let data = try Data(contentsOf: url)
            let cities = try JSONDecoder().decode([City].self, from: data)
            return cities
        } catch {
            print("Error loading cities: \(error)")
            return []
        }
    }
}

