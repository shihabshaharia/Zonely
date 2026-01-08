# Zonely ⚡

A native macOS menu bar app for quickly viewing world times with a Spotlight-style interface.

![macOS](https://img.shields.io/badge/macOS-14.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/License-MIT-green)

## Features

### Core

- 🔍 **Spotlight-style Interface** — Beautiful, floating search window with glassmorphic design
- ⌨️ **Global Hotkey** — Press `Option + Space` from anywhere to toggle
- 🌍 **250+ Cities** — Comprehensive worldwide coverage across all continents
- 🔎 **Smart Search** — Filter by city name, country, or timezone keywords
- ⏰ **Time Travel** — Slider to preview times ±12 hours in the future/past
- 📍 **Local Timezone** — Your current location always shown at the top
- ☀️🌙 **Day/Night Indicators** — Sun/moon icons based on local time (6am-6pm)
- 🖥️ **Fullscreen Support** — Works above fullscreen apps like native Spotlight

### Favorites

- ⭐ **Favorite Cities** — Star cities to keep them pinned when not searching
- 💾 **Persistent Storage** — Favorites saved automatically between sessions

### Preferences

- 🕐 **24/12 Hour Format** — Toggle between 24-hour (14:30) and 12-hour (2:30 PM) display
- 🚀 **Launch at Login** — Automatically start Zonely when you log in
- ⚙️ **Right-click Menu** — Quick access to About, Preferences, and Quit

### Hidden Features

- 🥚 **About Easter Egg** — Type "about" or "version" in search to see app info
- 📤 **City Request** — Search for a missing city and request it via GitHub Issues

### Time Conversion (New in v1.0.3)

- 🔄 **Smart Time Converter** — Type any time (e.g., `1700`, `5pm`, `14:30`) to see instant format conversion
- ⏱️ **Military Time Support** — Type 3-4 digit times like `1800` (6:00 PM) or `930` (9:30 AM)
- 🎯 **Spotlight-style Hero** — Beautiful conversion display styled like macOS Calculator results
- 📋 **One-click Copy** — Copy converted time to clipboard instantly
- 🎚️ **Slider Integration** — Slide to adjust the converted time forwards or backwards

## Requirements

- macOS 14.0 (Sonoma) or later
- Xcode 15+ (for development)

## Installation

### From Source

1. Clone the repository:

   ```bash
   git clone https://github.com/shihabshaharia/Zonely.git
   cd Zonely
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

| Action           | Method                                    |
| ---------------- | ----------------------------------------- |
| Toggle Spotlight | `⌥ Option + Space` or click menu bar icon |
| Close Window     | `Escape` or click outside                 |
| Search           | Just start typing                         |
| Convert Time     | Type `1700`, `5pm`, or `14:30`            |
| Time Travel      | Drag the slider                           |
| Reset Time       | Click ↺ button                            |
| Copy Converted   | Click 📋 button in hero view              |
| Add Favorite     | Click + button on any city                |
| Remove Favorite  | Click ★ button on favorited city          |
| Open Preferences | Right-click menu bar icon → Preferences   |
| Quit App         | Right-click menu bar icon → Quit Zonely   |

## Project Structure

```
Zonely/
├── Package.swift                # Swift Package Manager manifest
├── Sources/
│   ├── ZonlyMain.swift          # App entry point & AppDelegate
│   ├── SpotlightWindow.swift    # Custom NSWindow for Spotlight UI
│   ├── SpotlightView.swift      # Main SwiftUI view with search & city list
│   ├── ConversionHeroView.swift # Time format conversion hero display
│   ├── AboutView.swift          # Hidden About section
│   ├── PreferencesView.swift    # Preferences window UI
│   ├── UpdateManager.swift      # Auto-update functionality
│   ├── AppVersion.swift         # Version management
│   ├── City.swift               # City data model
│   ├── DataManager.swift        # JSON data loading
│   ├── PersistenceManager.swift # Favorites persistence
│   └── Resources/
│       └── cities.json          # City timezone data (250+ cities)
├── .gitignore
└── README.md
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

Or simply search for a missing city in the app and click "Request" to open a GitHub issue!

## Dependencies

- [HotKey](https://github.com/soffes/HotKey) — Global keyboard shortcuts for macOS
- [LaunchAtLogin](https://github.com/sindresorhus/LaunchAtLogin-Modern) — Launch at login functionality

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

Made with ❤️ in 🇧🇩 Bangladesh by [Shihab Shaharia](https://github.com/shihabshaharia)
