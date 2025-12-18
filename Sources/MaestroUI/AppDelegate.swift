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
    private var updateTimer: Timer?
    private var calculator: MenuBarStateCalculator?

    public override init() {
        super.init()
    }
    
    // MARK: - First Run Setup
    
    private func isFirstLaunch() -> Bool {
        let hasLaunchedBefore = UserDefaults.standard.bool(forKey: "HasLaunchedBefore")
        return !hasLaunchedBefore
    }
    
    private func markFirstLaunchComplete() {
        UserDefaults.standard.set(true, forKey: "HasLaunchedBefore")
    }
    
    private func performFirstRunSetup() {
        NSLog("First run detected, starting setup...")
        
        // Show welcome wizard
        showWelcomeWizard { [weak self] success in
            if success {
                self?.configureMCPServer()
                self?.installMaestroSkill()
                self?.markFirstLaunchComplete()
                self?.showSetupComplete()
            }
        }
    }
    
    private func showWelcomeWizard(completion: @escaping (Bool) -> Void) {
        let alert = NSAlert()
        alert.messageText = "Welcome to Maestro!"
        alert.informativeText = """
        Maestro helps you manage tasks, spaces, and documents with intelligent surfacing and AI agent monitoring.
        
        Setup will:
        • Configure Claude Code integration
        • Install Maestro Skill
        • Set up menu bar intelligence
        
        This takes about 30 seconds.
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Continue")
        alert.addButton(withTitle: "Skip Setup")
        
        let response = alert.runModal()
        completion(response == .alertFirstButtonReturn)
    }
    
    private func configureMCPServer() {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        let mcpConfigPath = homeDir.appendingPathComponent(".mcp.json")
        
        // Get path to Maestro binary
        guard let maestroPath = Bundle.main.executablePath else {
            NSLog("Could not find Maestro executable path")
            return
        }
        
        do {
            var config: [String: Any] = [:]
            
            // Read existing config if it exists
            if FileManager.default.fileExists(atPath: mcpConfigPath.path) {
                let data = try Data(contentsOf: mcpConfigPath)
                if let existingConfig = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    config = existingConfig
                }
            }
            
            // Add/update maestro server
            var mcpServers = config["mcpServers"] as? [String: Any] ?? [:]
            mcpServers["maestro"] = [
                "command": maestroPath,
                "args": ["--mcp"],
                "env": [:]
            ]
            config["mcpServers"] = mcpServers
            
            // Write back to file
            let jsonData = try JSONSerialization.data(withJSONObject: config, options: .prettyPrinted)
            try jsonData.write(to: mcpConfigPath)
            
            NSLog("✅ MCP server configured at \(mcpConfigPath.path)")
        } catch {
            NSLog("❌ Failed to configure MCP server: \(error)")
        }
    }
    
    private func installMaestroSkill() {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        let skillDestination = homeDir.appendingPathComponent(".claude/skills/maestro")
        
        // Get skill source from bundle
        guard let skillSource = Bundle.main.resourceURL?.appendingPathComponent("skills/maestro") else {
            NSLog("❌ Could not find Maestro skill in bundle")
            return
        }
        
        do {
            // Create .claude/skills directory if needed
            let skillsDir = homeDir.appendingPathComponent(".claude/skills")
            try FileManager.default.createDirectory(at: skillsDir, withIntermediateDirectories: true)
            
            // Remove existing skill if present
            if FileManager.default.fileExists(atPath: skillDestination.path) {
                try FileManager.default.removeItem(at: skillDestination)
            }
            
            // Copy skill to destination
            try FileManager.default.copyItem(at: skillSource, to: skillDestination)
            
            NSLog("✅ Maestro Skill installed at \(skillDestination.path)")
        } catch {
            NSLog("❌ Failed to install Maestro Skill: \(error)")
        }
    }
    
    private func showSetupComplete() {
        let alert = NSAlert()
        alert.messageText = "Setup Complete!"
        alert.informativeText = """
        Maestro is ready to use!
        
        ✅ MCP server configured
        ✅ Maestro Skill installed
        ✅ Menu bar active
        
        Next steps:
        1. Restart Claude Code
        2. Try: "How do I use Maestro?"
        3. Create your first space and tasks
        
        The menu bar icon shows your task status:
        🟢 Green = All clear
        🟡 Yellow = Stale tasks
        🟠 Orange = Agent needs input
        🔴 Red = Overdue tasks
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Get Started")
        alert.runModal()
    }

    public func applicationDidFinishLaunching(_ notification: Notification) {
        // Check for first launch
        if isFirstLaunch() {
            performFirstRunSetup()
        }
        
        // Initialize database
        do {
            let dbPath = ("~/Library/Application Support/Maestro/maestro.db" as NSString).expandingTildeInPath
            db = Database(path: dbPath)
            try db?.connect()
            
            // Initialize calculator
            if let db = db {
                calculator = MenuBarStateCalculator(database: db)
            }
        } catch {
            NSLog("Failed to initialize database: \(error)")
        }

        // Create status item in menu bar
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        guard let button = statusItem?.button else {
            NSLog("Failed to create status item button")
            return
        }

        // Load custom menu bar icon
        if let iconURL = Bundle.module.url(forResource: "maestro-menubar-template@2x", withExtension: "png") ??
                         Bundle.module.url(forResource: "maestro-menubar-template", withExtension: "png"),
           let image = NSImage(contentsOf: iconURL) {
            image.isTemplate = true
            button.image = image
        } else {
            // Fallback to SF Symbol if custom icon not found
            if let image = NSImage(systemSymbolName: "checklist", accessibilityDescription: "Maestro") {
                image.isTemplate = true
                button.image = image
            }
        }

        // Set button action to toggle popover
        button.action = #selector(togglePopover)
        button.target = self
        
        // Update menu bar state immediately
        updateMenuBarState()
        
        // Start timer to update state every 30 seconds
        updateTimer = Timer.scheduledTimer(
            timeInterval: 30,
            target: self,
            selector: #selector(updateMenuBarState),
            userInfo: nil,
            repeats: true
        )

        NSLog("Maestro menu bar app started")
    }
    
    @objc private func updateMenuBarState() {
        guard let calculator = calculator else { return }
        
        do {
            let state = try calculator.calculate()
            
            // Update icon color based on state
            updateIconColor(state.color)
            
            // Update badge count
            if state.badgeCount > 0 {
                statusItem?.button?.title = "\(state.badgeCount)"
            } else {
                statusItem?.button?.title = ""
            }
            
            NSLog("Menu bar state updated: \(state.color.rawValue), badge: \(state.badgeCount)")
        } catch {
            NSLog("Failed to update menu bar state: \(error)")
        }
    }
    
    private func updateIconColor(_ color: MenuBarColor) {
        guard let button = statusItem?.button else { return }
        
        // Create colored icon based on state
        let symbolName: String
        switch color {
        case .clear:
            symbolName = "checklist"
            button.contentTintColor = .systemGreen
        case .attention:
            symbolName = "exclamationmark.circle"
            button.contentTintColor = .systemYellow
        case .input:
            symbolName = "hand.raised"
            button.contentTintColor = .systemOrange
        case .urgent:
            symbolName = "exclamationmark.triangle"
            button.contentTintColor = .systemRed
        }
        
        if let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Maestro") {
            image.isTemplate = true
            button.image = image
        }
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
