import Cocoa
import MaestroCore

/// Quick View Panel - Minimal, clean design
public class QuickViewPanel: NSViewController {
    private let scrollView = NSScrollView()
    private let contentView = NSStackView()
    private weak var appDelegate: AppDelegate?
    private let db: Database
    private var calculator: MenuBarStateCalculator?

    // Minimal color palette
    private struct Colors {
        static let background = NSColor.controlBackgroundColor
        static let text = NSColor.labelColor
        static let textSecondary = NSColor.secondaryLabelColor

        // Status colors
        static let clear = NSColor.systemGreen
        static let attention = NSColor.systemYellow
        static let input = NSColor.systemOrange
        static let urgent = NSColor.systemRed
    }

    public init(database: Database, appDelegate: AppDelegate) {
        self.db = database
        self.appDelegate = appDelegate
        self.calculator = MenuBarStateCalculator(database: database)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    public override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 400))
        view.wantsLayer = true
        view.layer?.backgroundColor = Colors.background.cgColor

        setupUI()
    }

    private func setupUI() {
        contentView.orientation = .vertical
        contentView.alignment = .leading
        contentView.spacing = 0
        contentView.edgeInsets = NSEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        contentView.translatesAutoresizingMaskIntoConstraints = false

        scrollView.frame = view.bounds
        scrollView.autoresizingMask = [.width, .height]
        scrollView.hasVerticalScroller = true
        scrollView.documentView = contentView
        view.addSubview(scrollView)

        contentView.widthAnchor.constraint(equalToConstant: 268).isActive = true

        addStatusSection()
        addSpacer(height: 16)
        addSpacesSection()
        addSpacer(height: 16)
        addTasksSection()
        addSpacer(height: 16)
        addFooter()

        contentView.layoutSubtreeIfNeeded()
    }

    private func addStatusSection() {
        do {
            guard let calculator = calculator else { return }
            let state = try calculator.calculate()

            let statusRow = NSStackView()
            statusRow.orientation = .horizontal
            statusRow.spacing = 8
            statusRow.alignment = .centerY

            // Simple status dot
            let dot = NSView(frame: NSRect(x: 0, y: 0, width: 8, height: 8))
            dot.wantsLayer = true
            dot.translatesAutoresizingMaskIntoConstraints = false
            dot.widthAnchor.constraint(equalToConstant: 8).isActive = true
            dot.heightAnchor.constraint(equalToConstant: 8).isActive = true

            let statusColor: NSColor
            let statusText: String

            switch state.color {
            case .clear:
                statusColor = Colors.clear
                statusText = "All Clear"
            case .attention:
                statusColor = Colors.attention
                statusText = "Needs Attention"
            case .input:
                statusColor = Colors.input
                statusText = "Input Required"
            case .urgent:
                statusColor = Colors.urgent
                statusText = "Urgent"
            }

            dot.layer?.backgroundColor = statusColor.cgColor
            dot.layer?.cornerRadius = 4

            let label = NSTextField(labelWithString: statusText)
            label.font = NSFont.systemFont(ofSize: 13, weight: .medium)
            label.textColor = Colors.text

            statusRow.addArrangedSubview(dot)
            statusRow.addArrangedSubview(label)
            statusRow.addArrangedSubview(NSView()) // Spacer

            contentView.addArrangedSubview(statusRow)

            // Simple metrics if any
            if state.badgeCount > 0 {
                addSpacer(height: 8)
                let badge = NSTextField(labelWithString: "\(state.badgeCount) items need attention")
                badge.font = NSFont.systemFont(ofSize: 11)
                badge.textColor = Colors.textSecondary
                contentView.addArrangedSubview(badge)
            }

        } catch {
            let error = NSTextField(labelWithString: "Status unavailable")
            error.textColor = Colors.textSecondary
            error.font = NSFont.systemFont(ofSize: 13)
            contentView.addArrangedSubview(error)
        }
    }

    private func addSpacesSection() {
        let header = NSTextField(labelWithString: "Contexts")
        header.font = NSFont.systemFont(ofSize: 11, weight: .semibold)
        header.textColor = Colors.textSecondary
        contentView.addArrangedSubview(header)

        addSpacer(height: 8)

        do {
            let spaceStore = SpaceStore(database: db)
            let spaces = Array(try spaceStore.list(includeArchived: false).prefix(5))

            if spaces.isEmpty {
                let empty = NSTextField(labelWithString: "No contexts")
                empty.font = NSFont.systemFont(ofSize: 12)
                empty.textColor = Colors.textSecondary
                contentView.addArrangedSubview(empty)
            } else {
                for space in spaces {
                    let label = NSTextField(labelWithString: "• \(space.name)")
                    label.font = NSFont.systemFont(ofSize: 12)
                    label.textColor = Colors.text
                    contentView.addArrangedSubview(label)
                }
            }
        } catch {
            let error = NSTextField(labelWithString: "Error loading contexts")
            error.textColor = Colors.urgent
            error.font = NSFont.systemFont(ofSize: 12)
            contentView.addArrangedSubview(error)
        }
    }

    private func addTasksSection() {
        let header = NSTextField(labelWithString: "Tasks")
        header.font = NSFont.systemFont(ofSize: 11, weight: .semibold)
        header.textColor = Colors.textSecondary
        contentView.addArrangedSubview(header)

        addSpacer(height: 8)

        do {
            let taskStore = TaskStore(database: db)
            let tasks = try taskStore.list(spaceId: nil, status: nil)
                .filter { $0.status != .done && $0.status != .archived }
                .prefix(5)

            if tasks.isEmpty {
                let empty = NSTextField(labelWithString: "No active tasks")
                empty.font = NSFont.systemFont(ofSize: 12)
                empty.textColor = Colors.textSecondary
                contentView.addArrangedSubview(empty)
            } else {
                for task in tasks {
                    let label = NSTextField(labelWithString: "• \(task.title)")
                    label.font = NSFont.systemFont(ofSize: 12)
                    label.textColor = Colors.text
                    label.lineBreakMode = .byTruncatingTail
                    contentView.addArrangedSubview(label)
                }
            }
        } catch {
            let error = NSTextField(labelWithString: "Error loading tasks")
            error.textColor = Colors.urgent
            error.font = NSFont.systemFont(ofSize: 12)
            contentView.addArrangedSubview(error)
        }
    }

    private func addFooter() {
        let button = NSButton(title: "Open Maestro", target: self, action: #selector(openViewer))
        button.bezelStyle = .rounded
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 28).isActive = true
        contentView.addArrangedSubview(button)
    }

    private func addSpacer(height: CGFloat) {
        let spacer = NSView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        spacer.heightAnchor.constraint(equalToConstant: height).isActive = true
        contentView.addArrangedSubview(spacer)
    }

    @objc public func openViewer() {
        appDelegate?.showViewer()
    }
}
