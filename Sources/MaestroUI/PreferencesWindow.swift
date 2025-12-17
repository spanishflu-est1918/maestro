import Cocoa

/// Preferences window for Maestro app configuration
public class PreferencesWindow: NSWindowController {

    private let databasePathField: NSTextField
    private let autoLaunchCheckbox: NSButton
    private let refreshIntervalField: NSTextField

    public init() {
        // Create text fields
        databasePathField = NSTextField(frame: .zero)
        autoLaunchCheckbox = NSButton(checkboxWithTitle: "Launch at login", target: nil, action: nil)
        refreshIntervalField = NSTextField(frame: .zero)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 300),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )

        window.title = "Maestro Preferences"
        window.center()

        super.init(window: window)

        setupUI()
        loadPreferences()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    private func setupUI() {
        guard let contentView = window?.contentView else { return }

        let stackView = NSStackView()
        stackView.orientation = .vertical
        stackView.spacing = 20
        stackView.alignment = .leading
        stackView.translatesAutoresizingMaskIntoConstraints = false

        // Database path section
        let dbLabel = NSTextField(labelWithString: "Database Path:")
        dbLabel.font = .boldSystemFont(ofSize: 13)

        databasePathField.placeholderString = "~/Library/Application Support/Maestro/maestro.db"
        databasePathField.translatesAutoresizingMaskIntoConstraints = false

        let dbBrowseButton = NSButton(title: "Browse...", target: self, action: #selector(browseDatabasePath))

        let dbStack = NSStackView(views: [databasePathField, dbBrowseButton])
        dbStack.orientation = .horizontal
        dbStack.spacing = 8

        // Auto-launch section
        autoLaunchCheckbox.target = self
        autoLaunchCheckbox.action = #selector(toggleAutoLaunch)

        // Refresh interval section
        let refreshLabel = NSTextField(labelWithString: "Refresh Interval (seconds):")
        refreshLabel.font = .boldSystemFont(ofSize: 13)

        refreshIntervalField.placeholderString = "300"
        refreshIntervalField.translatesAutoresizingMaskIntoConstraints = false

        // Save button
        let saveButton = NSButton(title: "Save", target: self, action: #selector(savePreferences))
        saveButton.keyEquivalent = "\r"

        let cancelButton = NSButton(title: "Cancel", target: self, action: #selector(cancel))
        cancelButton.keyEquivalent = "\u{1b}" // Escape key

        let buttonStack = NSStackView(views: [cancelButton, saveButton])
        buttonStack.orientation = .horizontal
        buttonStack.spacing = 8

        // Add all sections to main stack
        stackView.addArrangedSubview(dbLabel)
        stackView.addArrangedSubview(dbStack)
        stackView.addArrangedSubview(autoLaunchCheckbox)
        stackView.addArrangedSubview(refreshLabel)
        stackView.addArrangedSubview(refreshIntervalField)
        stackView.addArrangedSubview(NSView()) // Spacer
        stackView.addArrangedSubview(buttonStack)

        contentView.addSubview(stackView)

        // Layout constraints
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),

            databasePathField.widthAnchor.constraint(equalToConstant: 350),
            refreshIntervalField.widthAnchor.constraint(equalToConstant: 100)
        ])
    }

    private func loadPreferences() {
        let defaults = UserDefaults.standard

        if let dbPath = defaults.string(forKey: "MaestroDatabasePath") {
            databasePathField.stringValue = dbPath
        }

        autoLaunchCheckbox.state = defaults.bool(forKey: "MaestroAutoLaunch") ? .on : .off

        let refreshInterval = defaults.integer(forKey: "MaestroRefreshInterval")
        if refreshInterval > 0 {
            refreshIntervalField.stringValue = "\(refreshInterval)"
        }
    }

    @objc private func browseDatabasePath() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = []
        panel.allowsOtherFileTypes = true

        if panel.runModal() == .OK, let url = panel.url {
            databasePathField.stringValue = url.path
        }
    }

    @objc private func toggleAutoLaunch() {
        // Auto-launch functionality would require LaunchServices integration
        // For now, just save the preference
    }

    @objc private func savePreferences() {
        let defaults = UserDefaults.standard

        // Save database path
        let dbPath = databasePathField.stringValue.isEmpty ?
            "~/Library/Application Support/Maestro/maestro.db" :
            databasePathField.stringValue
        defaults.set(dbPath, forKey: "MaestroDatabasePath")

        // Save auto-launch preference
        defaults.set(autoLaunchCheckbox.state == .on, forKey: "MaestroAutoLaunch")

        // Save refresh interval
        if let interval = Int(refreshIntervalField.stringValue), interval > 0 {
            defaults.set(interval, forKey: "MaestroRefreshInterval")
        }

        defaults.synchronize()

        // Notify that preferences changed
        NotificationCenter.default.post(name: NSNotification.Name("MaestroPreferencesChanged"), object: nil)

        window?.close()
    }

    @objc private func cancel() {
        window?.close()
    }
}
