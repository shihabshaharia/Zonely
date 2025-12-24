import SwiftUI

struct MenuBarView: View {
    @State private var cities: [City] = []
    @State private var currentDate = Date()
    
    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("World Clocks")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)
            
            Divider()
            
            List(cities) { city in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(city.city)
                            .font(.system(size: 14, weight: .medium))
                        Text(city.country)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text(city.currentTime())
                        .font(.system(size: 18, weight: .semibold, design: .monospaced))
                        .foregroundColor(.primary)
                }
                .padding(.vertical, 4)
            }
            .listStyle(.plain)
        }
        .frame(width: 300, height: 400)
        .onAppear {
            cities = DataManager.shared.loadCities()
        }
        .onReceive(timer) { _ in
            currentDate = Date()
        }
    }
}

#Preview {
    MenuBarView()
}
