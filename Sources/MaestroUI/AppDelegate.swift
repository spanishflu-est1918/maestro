import Cocoa
import MaestroCore

/// Maestro Menu Bar Application
/// Provides quick access to tasks and spaces via system menu bar
public class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var quickView: QuickViewPanel?
    private var db: Database?
    private var viewerWindow: ViewerWindow?

    public override init() {
        super.init()
    }

    public func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize database
        do {
            db = Database(path: "~/Library/Application Support/Maestro/maestro.db")
            try db?.connect()
        } catch {
            NSLog("Failed to initialize database: \(error)")
        }

        // Create status item in menu bar
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        guard let button = statusItem?.button else {
            NSLog("Failed to create status item button")
            return
        }

        // Set icon - using system symbol for now
        if let image = NSImage(systemSymbolName: "checklist", accessibilityDescription: "Maestro") {
            image.isTemplate = true
            button.image = image
        }

        // Set button action to toggle popover
        button.action = #selector(togglePopover)
        button.target = self

        NSLog("Maestro menu bar app started")
    }

    @objc func togglePopover() {
        guard let button = statusItem?.button else { return }

        if let popover = popover, popover.isShown {
            popover.performClose(nil)
        } else {
            showPopover(relativeTo: button)
        }
    }

    private func showPopover(relativeTo view: NSView) {
        guard let db = db else { return }

        // Create popover if needed
        if popover == nil {
            popover = NSPopover()
            popover?.contentSize = NSSize(width: 300, height: 400)
            popover?.behavior = .transient

            quickView = QuickViewPanel(database: db, appDelegate: self)
            popover?.contentViewController = quickView
        }

        popover?.show(relativeTo: view.bounds, of: view, preferredEdge: .minY)
    }

    public func showViewer() {
        if viewerWindow == nil {
            viewerWindow = ViewerWindow()
            viewerWindow?.loadViewer()
        }
        viewerWindow?.showWindow(self)
        
        // Hide popover when showing viewer
        popover?.performClose(nil)
    }

    @objc func openMaestro() {
        NSLog("Open Maestro clicked")
        showViewer()
    }

    @objc func openPreferences() {
        NSLog("Preferences clicked")
        let preferences = PreferencesWindow()
        preferences.showWindow(self)
    }

    @objc func quit() {
        NSApplication.shared.terminate(nil)
    }
}
