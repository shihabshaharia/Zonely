import AppKit
import SwiftUI

class SpotlightWindow: NSWindow {
    
    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        // Make it appear above fullscreen apps (like native Spotlight)
        self.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.maximumWindow)))
        
        // Transparent background
        self.isOpaque = false
        self.backgroundColor = .clear
        
        // Window behavior - appear on all spaces including fullscreen
        self.isMovableByWindowBackground = false
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        
        // Center horizontally, position near top of screen
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let windowWidth = contentRect.width
            let windowHeight = contentRect.height
            let x = (screenFrame.width - windowWidth) / 2 + screenFrame.origin.x
            let y = screenFrame.origin.y + screenFrame.height - windowHeight - 100
            self.setFrameOrigin(NSPoint(x: x, y: y))
        }
        
        // Set the SwiftUI content
        self.contentView = NSHostingView(rootView: SpotlightView(window: self))
        
        // Close when clicking outside (window loses focus)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidResignKey),
            name: NSWindow.didResignKeyNotification,
            object: self
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func windowDidResignKey(_ notification: Notification) {
        self.orderOut(nil)
    }
    
    // Allow the window to become key window for keyboard input
    override var canBecomeKey: Bool {
        return true
    }
    
    override var canBecomeMain: Bool {
        return true
    }
    
    // Close on Escape key
    override func cancelOperation(_ sender: Any?) {
        self.orderOut(nil)
    }
    
    // Handle key events
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Escape key
            self.orderOut(nil)
        } else {
            super.keyDown(with: event)
        }
    }
}
