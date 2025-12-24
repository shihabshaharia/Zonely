# Zonly ⚡

A native macOS menu bar app for quickly viewing world times with a Spotlight-style interface.

![macOS](https://img.shields.io/badge/macOS-14.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/License-MIT-green)

## Features

- 🔍 **Spotlight-style Interface** — Beautiful, floating search window with glassmorphic design
- ⌨️ **Global Hotkey** — Press `Option + Space` from anywhere to toggle
- 🌍 **60+ Cities** — Comprehensive coverage of Asian cities and major world cities
- 🔎 **Smart Search** — Filter by city name, country, or timezone keywords
- ⏰ **Time Travel** — Slider to preview times ±12 hours in the future/past
- 📍 **Local Timezone** — Your current location shown at the top
- ☀️🌙 **Day/Night Indicators** — Sun/moon icons based on local time (6am-6pm)
- 🖥️ **Fullscreen Support** — Works above fullscreen apps like native Spotlight

## Requirements

- macOS 14.0 (Sonoma) or later
- Xcode 15+ (for development)

## Installation

### From Source

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/Zonly.git
   cd Zonly
   ```

2. Build the project:
   ```bash
   swift build
   ```

3. Run the app:
   ```bash
   swift run Zonly
   ```

### Build Release

To create a release build:
```bash
swift build -c release
```

The binary will be located at `.build/release/Zonly`

## Usage

| Action | Shortcut |
|--------|----------|
| Toggle Spotlight | `⌥ Option + Space` |
| Close Window | `Escape` or click outside |
| Search | Just start typing |
| Time Travel | Drag the slider |
| Reset Time | Click ↺ button |

## Project Structure

```
Zonly/
├── Package.swift           # Swift Package Manager manifest
├── Sources/
│   ├── ZonlyMain.swift     # App entry point & AppDelegate
│   ├── SpotlightWindow.swift   # Custom NSWindow for Spotlight UI
│   ├── SpotlightView.swift     # Main SwiftUI view
│   ├── MenuBarView.swift       # Legacy menu bar view
│   ├── City.swift              # City data model
│   ├── DataManager.swift       # JSON data loading
│   └── Resources/
│       └── cities.json         # City timezone data
└── .gitignore
```

## Adding Cities

Edit `Sources/Resources/cities.json` to add or modify cities:

```json
{
  "city": "City Name",
  "country": "Country",
  "timezone": "Region/City",
  "keywords": ["keyword1", "keyword2"]
}
```

Timezone identifiers must be valid [IANA timezone names](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones).

## Dependencies

- [HotKey](https://github.com/soffes/HotKey) — Global keyboard shortcuts for macOS

## Permissions

The app may request **Accessibility permissions** to register global hotkeys. Grant permission in:

**System Settings → Privacy & Security → Accessibility**

## License

MIT License - feel free to use and modify.

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

Made with ❤️ using Swift & SwiftUI
