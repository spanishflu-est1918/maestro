import Cocoa
import MaestroCore

/// Native viewer window with minimal data visualization
public class ViewerWindow: NSWindowController {
    private static let windowFrameKey = "MaestroViewerWindowFrame"
    private let db: Database

    public init() {
        // Initialize database
        let dbPath = (("~/Library/Application Support/Maestro/maestro.db" as NSString).expandingTildeInPath)
        self.db = Database(path: dbPath)

        // Create window
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 700),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        window.title = "Maestro"
        window.center()

        // Restore saved frame if available
        if let frameString = UserDefaults.standard.string(forKey: Self.windowFrameKey) {
            window.setFrame(from: frameString)
        }

        super.init(window: window)

        // Save frame when window moves or resizes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidMove),
            name: NSWindow.didMoveNotification,
            object: window
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidResize),
            name: NSWindow.didResizeNotification,
            object: window
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    /// Load the viewer
    public func loadViewer() {
        do {
            try db.connect()
            let viewController = ViewerViewController(database: db)
            window?.contentViewController = viewController
        } catch {
            NSLog("Failed to initialize viewer: \(error)")
        }
    }

    @objc private func windowDidMove() {
        saveWindowFrame()
    }

    @objc private func windowDidResize() {
        saveWindowFrame()
    }

    private func saveWindowFrame() {
        guard let window = window else { return }
        let frameDescriptor = window.frameDescriptor
        UserDefaults.standard.set(frameDescriptor, forKey: Self.windowFrameKey)
    }
}

/// Main viewer view controller with data visualization
class ViewerViewController: NSViewController {
    private let db: Database
    private let scrollView = NSScrollView()
    private let contentView = NSStackView()

    init(database: Database) {
        self.db = database
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 900, height: 700))
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor

        setupUI()
    }

    private func setupUI() {
        contentView.orientation = .vertical
        contentView.alignment = .leading
        contentView.spacing = 24
        contentView.edgeInsets = NSEdgeInsets(top: 40, left: 40, bottom: 40, right: 40)
        contentView.translatesAutoresizingMaskIntoConstraints = false

        scrollView.frame = view.bounds
        scrollView.autoresizingMask = [.width, .height]
        scrollView.hasVerticalScroller = true
        scrollView.documentView = contentView
        view.addSubview(scrollView)

        contentView.widthAnchor.constraint(equalToConstant: 820).isActive = true

        addHeader()
        addOverview()
        addSpacesSection()
        addTasksSection()

        contentView.layoutSubtreeIfNeeded()
    }

    private func addHeader() {
        let title = NSTextField(labelWithString: "Maestro")
        title.font = NSFont.systemFont(ofSize: 32, weight: .bold)
        title.textColor = NSColor.labelColor
        contentView.addArrangedSubview(title)
    }

    private func addOverview() {
        let calculator = MenuBarStateCalculator(database: db)

        do {
            let state = try calculator.calculate()

            let grid = NSStackView()
            grid.orientation = .horizontal
            grid.spacing = 16
            grid.distribution = .fillEqually

            // Status card
            grid.addArrangedSubview(createMetricCard(
                title: "Status",
                value: statusText(for: state.color),
                color: statusColor(for: state.color)
            ))

            // Overdue tasks
            if state.summary.overdueTaskCount > 0 {
                grid.addArrangedSubview(createMetricCard(
                    title: "Overdue",
                    value: "\(state.summary.overdueTaskCount)",
                    color: .systemRed
                ))
            }

            // Stale tasks
            if state.summary.staleTaskCount > 0 {
                grid.addArrangedSubview(createMetricCard(
                    title: "Stale",
                    value: "\(state.summary.staleTaskCount)",
                    color: .systemYellow
                ))
            }

            // Active agents
            if state.summary.activeAgentCount > 0 {
                grid.addArrangedSubview(createMetricCard(
                    title: "Active Agents",
                    value: "\(state.summary.activeAgentCount)",
                    color: .systemBlue
                ))
            }

            contentView.addArrangedSubview(grid)
        } catch {
            let error = NSTextField(labelWithString: "Unable to load overview")
            error.textColor = .secondaryLabelColor
            contentView.addArrangedSubview(error)
        }
    }

    private func createMetricCard(title: String, value: String, color: NSColor) -> NSView {
        let card = NSView()
        card.wantsLayer = true
        card.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        card.layer?.cornerRadius = 8
        card.translatesAutoresizingMaskIntoConstraints = false
        card.heightAnchor.constraint(equalToConstant: 100).isActive = true

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.spacing = 8
        stack.edgeInsets = NSEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        stack.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        titleLabel.textColor = .secondaryLabelColor

        let valueLabel = NSTextField(labelWithString: value)
        valueLabel.font = NSFont.systemFont(ofSize: 28, weight: .semibold)
        valueLabel.textColor = color

        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(valueLabel)
        stack.addArrangedSubview(NSView()) // Spacer

        card.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])

        return card
    }

    private func addSpacesSection() {
        let header = NSTextField(labelWithString: "Contexts")
        header.font = NSFont.systemFont(ofSize: 18, weight: .semibold)
        header.textColor = .labelColor
        contentView.addArrangedSubview(header)

        do {
            let spaceStore = SpaceStore(database: db)
            let taskStore = TaskStore(database: db)
            let spaces = try spaceStore.list(includeArchived: false)

            for space in spaces.prefix(10) {
                let taskCount = try taskStore.list(spaceId: space.id, status: nil)
                    .filter { $0.status != .done && $0.status != .archived }
                    .count

                let row = NSStackView()
                row.orientation = .horizontal
                row.spacing = 12

                let name = NSTextField(labelWithString: space.name)
                name.font = NSFont.systemFont(ofSize: 14)
                name.textColor = .labelColor
                name.setContentHuggingPriority(.defaultLow, for: .horizontal)

                let count = NSTextField(labelWithString: "\(taskCount) tasks")
                count.font = NSFont.systemFont(ofSize: 13)
                count.textColor = .secondaryLabelColor
                count.alignment = .right

                row.addArrangedSubview(name)
                row.addArrangedSubview(count)

                contentView.addArrangedSubview(row)
            }
        } catch {
            let error = NSTextField(labelWithString: "Unable to load contexts")
            error.textColor = .secondaryLabelColor
            contentView.addArrangedSubview(error)
        }
    }

    private func addTasksSection() {
        let header = NSTextField(labelWithString: "Recent Tasks")
        header.font = NSFont.systemFont(ofSize: 18, weight: .semibold)
        header.textColor = .labelColor
        contentView.addArrangedSubview(header)

        do {
            let taskStore = TaskStore(database: db)
            let tasks = try taskStore.list(spaceId: nil, status: nil)
                .filter { $0.status != .done && $0.status != .archived }
                .prefix(15)

            for task in tasks {
                let row = NSStackView()
                row.orientation = .horizontal
                row.spacing = 12

                // Priority dot
                let dot = NSView(frame: NSRect(x: 0, y: 0, width: 6, height: 6))
                dot.wantsLayer = true
                dot.translatesAutoresizingMaskIntoConstraints = false
                dot.widthAnchor.constraint(equalToConstant: 6).isActive = true
                dot.heightAnchor.constraint(equalToConstant: 6).isActive = true
                dot.layer?.cornerRadius = 3

                switch task.priority {
                case .urgent:
                    dot.layer?.backgroundColor = NSColor.systemRed.cgColor
                case .high:
                    dot.layer?.backgroundColor = NSColor.systemOrange.cgColor
                default:
                    dot.layer?.backgroundColor = NSColor.tertiaryLabelColor.cgColor
                }

                let title = NSTextField(labelWithString: task.title)
                title.font = NSFont.systemFont(ofSize: 13)
                title.textColor = .labelColor
                title.lineBreakMode = .byTruncatingTail
                title.setContentHuggingPriority(.defaultLow, for: .horizontal)

                let status = NSTextField(labelWithString: task.status.rawValue)
                status.font = NSFont.systemFont(ofSize: 12)
                status.textColor = .tertiaryLabelColor
                status.alignment = .right

                row.addArrangedSubview(dot)
                row.addArrangedSubview(title)
                row.addArrangedSubview(status)

                contentView.addArrangedSubview(row)
            }
        } catch {
            let error = NSTextField(labelWithString: "Unable to load tasks")
            error.textColor = .secondaryLabelColor
            contentView.addArrangedSubview(error)
        }
    }

    private func statusText(for color: MenuBarColor) -> String {
        switch color {
        case .clear: return "Clear"
        case .attention: return "Attention"
        case .input: return "Input"
        case .urgent: return "Urgent"
        }
    }

    private func statusColor(for color: MenuBarColor) -> NSColor {
        switch color {
        case .clear: return .systemGreen
        case .attention: return .systemYellow
        case .input: return .systemOrange
        case .urgent: return .systemRed
        }
    }
}
