# Maintenance Guide for Zonely

## How to Release

1. **Bump Version**
   Edit `Sources/AppVersion.swift`:

   ```swift
   static let current = "1.0.1"  // Update this
   ```

2. **Build Release**
   The project uses `dmgbuild` (Python) for professional DMG creation. Ensure dependencies are met:
   `pip install dmgbuild`

   ```bash
   ./scripts/release.sh
   ```

3. **Create GitHub Release**

   - Go to [GitHub Releases](https://github.com/shihabshaharia/Zonely/releases)
   - Click "Draft a new release"

4. **Tag the Release**

   - Create tag: `v1.0.1` (must match version)
   - Title: `Zonely v1.0.1`

5. **Upload Artifacts**
   - Attach `dist/Zonely_v1.0.1.dmg`
   - Attach `dist/Zonely_v1.0.1.zip`
   - Publish release

---

## Auto-Update System

The app automatically checks for updates on launch:

1. Fetches `https://api.github.com/repos/shihabshaharia/Zonely/releases/latest`
2. Compares GitHub `tag_name` (e.g., `v1.0.1`) with `AppVersion.current`
3. If newer version exists → shows update badge in:
   - Menu bar icon
   - Right-click context menu
   - Spotlight window banner

**Key File:** `Sources/UpdateManager.swift`

---

## Project Map

| File                            | Purpose                                     |
| ------------------------------- | ------------------------------------------- |
| `Sources/AppVersion.swift`      | **Version number** (single source of truth) |
| `Sources/UpdateManager.swift`   | GitHub API update checks                    |
| `Sources/ZonlyMain.swift`       | App entry point, menus                      |
| `Sources/SpotlightView.swift`   | Main search UI                              |
| `Sources/City.swift`            | City model                                  |
| `Sources/Resources/cities.json` | **City database** (250+ cities)             |
| `art/background.png`            | **DMG Background** (600x400)                |
| `scripts/release.sh`            | Build automation script                     |
| `scripts/dmg_settings.py`       | **DMG Layout settings** (dmgbuild)          |

---

## DMG Customization

We use `dmgbuild` (Industry Standard) to bypass macOS caching and security issues that plague AppleScript-based tools.

- **Retina Support**: `dmg_settings.py` has `retina = True` enabled. The background image should ideally be high-resolution.
- **Coordinates**: Icon positions are defined in `dmg_settings.py` (relative to the 600x400 window).
- **Background**: The script looks for `art/background.png`.
