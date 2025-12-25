import SwiftUI
import HotKey
import Combine

@main
struct Main {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var spotlightWindow: SpotlightWindow?
    var preferencesWindow: NSWindow?
    var hotKey: HotKey?
    var contextMenu: NSMenu!
    var updateCancellable: AnyCancellable?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide from Dock
        NSApp.setActivationPolicy(.accessory)
        
        // Create context menu for right-click
        setupContextMenu()
        
        // Create main menu for keyboard shortcuts
        setupMainMenu()
        
        // Create the status item in the menu bar
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "clock.arrow.2.circlepath", accessibilityDescription: "Zonely")
            button.action = #selector(handleStatusBarClick)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        
        // Create the Spotlight window
        spotlightWindow = SpotlightWindow(contentRect: NSRect(x: 0, y: 0, width: 600, height: 480))
        
        // Register global hotkey: Option + Space
        hotKey = HotKey(key: .space, modifiers: [.option])
        hotKey?.keyDownHandler = { [weak self] in
            self?.toggleSpotlight()
        }
        
        // Observe update availability to change icon
        updateCancellable = UpdateManager.shared.$isUpdateAvailable
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isAvailable in
                self?.updateMenuBarIcon(updateAvailable: isAvailable)
            }
    }
    
    private func updateMenuBarIcon(updateAvailable: Bool) {
        guard let button = statusItem?.button else { return }
        
        if updateAvailable {
            // Show update badge icon
            let config = NSImage.SymbolConfiguration(paletteColors: [.white, .systemBlue])
            button.image = NSImage(systemSymbolName: "arrow.down.circle.fill", accessibilityDescription: "Update Available")?
                .withSymbolConfiguration(config)
        } else {
            // Normal icon
            button.image = NSImage(systemSymbolName: "clock.arrow.2.circlepath", accessibilityDescription: "Zonely")
        }
    }
    
    private func setupMainMenu() {
        let mainMenu = NSMenu()
        
        // App menu
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        
        appMenu.addItem(NSMenuItem(title: "About Zonely", action: #selector(showAbout), keyEquivalent: ""))
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(NSMenuItem(title: "Preferences...", action: #selector(showPreferences), keyEquivalent: ","))
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(NSMenuItem(title: "Quit Zonely", action: #selector(quitApp), keyEquivalent: "q"))
        
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)
        
        NSApp.mainMenu = mainMenu
    }
    
    private func setupContextMenu() {
        contextMenu = NSMenu()
        contextMenu.delegate = self
    }
    
    private func rebuildContextMenu() {
        contextMenu.removeAllItems()
        
        // Update Available (if any)
        if UpdateManager.shared.isUpdateAvailable {
            let versionString = AppVersion.format(UpdateManager.shared.latestVersion)
            let updateItem = NSMenuItem(title: "⬇️ Update Available (\(versionString))", action: #selector(openUpdatePage), keyEquivalent: "")
            updateItem.target = self
            contextMenu.addItem(updateItem)
            contextMenu.addItem(NSMenuItem.separator())
        }
        
        // About Zonely
        let aboutItem = NSMenuItem(title: "About Zonely", action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        contextMenu.addItem(aboutItem)
        
        // Preferences
        let preferencesItem = NSMenuItem(title: "Preferences...", action: #selector(showPreferences), keyEquivalent: ",")
        preferencesItem.target = self
        contextMenu.addItem(preferencesItem)
        
        // Separator
        contextMenu.addItem(NSMenuItem.separator())
        
        // Quit
        let quitItem = NSMenuItem(title: "Quit Zonely", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        contextMenu.addItem(quitItem)
    }
    
    @objc func openUpdatePage() {
        UpdateManager.shared.openDownloadPage()
    }
    
    @objc func handleStatusBarClick() {
        guard let event = NSApp.currentEvent else { return }
        
        if event.type == .rightMouseUp {
            // Rebuild menu to reflect current update state
            rebuildContextMenu()
            
            // Right-click: show context menu
            if let button = statusItem?.button {
                contextMenu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.height + 5), in: button)
            }
        } else {
            // Left-click: toggle Spotlight window
            toggleSpotlight()
        }
    }
    
    @objc func toggleSpotlight() {
        if let window = spotlightWindow {
            if window.isVisible {
                window.orderOut(nil)
            } else {
                // Re-center the window before showing
                if let screen = NSScreen.main {
                    let screenFrame = screen.visibleFrame
                    let windowFrame = window.frame
                    let x = (screenFrame.width - windowFrame.width) / 2 + screenFrame.origin.x
                    let y = screenFrame.origin.y + screenFrame.height - windowFrame.height - 100
                    window.setFrameOrigin(NSPoint(x: x, y: y))
                }
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
    
    @objc func showAbout() {
        // Show Spotlight with "about" pre-filled
        if let window = spotlightWindow {
            if let screen = NSScreen.main {
                let screenFrame = screen.visibleFrame
                let windowFrame = window.frame
                let x = (screenFrame.width - windowFrame.width) / 2 + screenFrame.origin.x
                let y = screenFrame.origin.y + screenFrame.height - windowFrame.height - 100
                window.setFrameOrigin(NSPoint(x: x, y: y))
            }
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            
            // Post notification to trigger About view
            NotificationCenter.default.post(name: NSNotification.Name("ShowAboutView"), object: nil)
        }
    }
    
    @objc func showPreferences() {
        // Check if preferences window already exists and is visible
        if let window = preferencesWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        // Create new preferences window
        let preferencesView = PreferencesView()
        let hostingController = NSHostingController(rootView: preferencesView)
        
        let window = NSWindow(contentViewController: hostingController)
        window.title = "Zonely Preferences"
        window.styleMask = [.titled, .closable]
        window.setContentSize(NSSize(width: 360, height: 360))
        window.center()
        window.isReleasedWhenClosed = false
        
        preferencesWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}

// MARK: - NSMenuDelegate
extension AppDelegate: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        if menu == contextMenu {
            rebuildContextMenu()
        }
    }
}
