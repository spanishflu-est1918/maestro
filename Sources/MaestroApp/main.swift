import Cocoa
import MaestroUI

/// Maestro Menu Bar App Entry Point
/// Creates and launches the menu bar application

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate

// Don't show in Dock (menu bar app only)
app.setActivationPolicy(.accessory)

// Run the app
app.run()
