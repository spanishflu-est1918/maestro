import Cocoa
import MaestroCore

/// Quick View Panel - Dropdown panel from menu bar
/// Shows status summary, recent spaces, and due tasks
public class QuickViewPanel: NSViewController {
    private let scrollView = NSScrollView()
    private let contentView = NSStackView()
    private weak var appDelegate: AppDelegate?
    private let db: Database
    private var calculator: MenuBarStateCalculator?

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
        setupUI()
    }

    private func setupUI() {
        // Setup scroll view
        scrollView.frame = view.bounds
        scrollView.autoresizingMask = [.width, .height]
        scrollView.hasVerticalScroller = true
        scrollView.documentView = contentView
        view.addSubview(scrollView)

        // Setup content stack
        contentView.orientation = .vertical
        contentView.alignment = .leading
        contentView.spacing = 12
        contentView.edgeInsets = NSEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)

        // Add sections
        addStatusSummary()
        addSpacesSection()
        addTasksSection()
        addViewerButton()
    }

    private func addStatusSummary() {
        let header = NSTextField(labelWithString: "Status")
        header.font = NSFont.boldSystemFont(ofSize: 13)
        contentView.addArrangedSubview(header)

        do {
            guard let calculator = calculator else { return }
            let state = try calculator.calculate()
            
            // Create summary text
            var summaryParts: [String] = []
            
            if state.summary.overdueTaskCount > 0 {
                summaryParts.append("\(state.summary.overdueTaskCount) overdue")
            }
            
            if state.summary.staleTaskCount > 0 {
                summaryParts.append("\(state.summary.staleTaskCount) stale")
            }
            
            if state.summary.agentsNeedingInputCount > 0 {
                summaryParts.append("\(state.summary.agentsNeedingInputCount) agent waiting")
            }
            
            if state.summary.activeAgentCount > 0 {
                summaryParts.append("\(state.summary.activeAgentCount) active agents")
            }
            
            if state.summary.linearDoneCount > 0 {
                summaryParts.append("Linear: \(state.summary.linearDoneCount) done")
            }
            
            let summaryText = summaryParts.isEmpty ? "All clear ✓" : summaryParts.joined(separator: " • ")
            
            let summary = NSTextField(labelWithString: summaryText)
            summary.font = NSFont.systemFont(ofSize: 11)
            
            // Color based on state
            switch state.color {
            case .clear:
                summary.textColor = .systemGreen
            case .attention:
                summary.textColor = .systemYellow
            case .input:
                summary.textColor = .systemOrange
            case .urgent:
                summary.textColor = .systemRed
            }
            
            contentView.addArrangedSubview(summary)
        } catch {
            let errorLabel = NSTextField(labelWithString: "Error loading status")
            errorLabel.textColor = .systemRed
            errorLabel.font = NSFont.systemFont(ofSize: 11)
            contentView.addArrangedSubview(errorLabel)
        }
    }

    private func addSpacesSection() {
        let header = NSTextField(labelWithString: "Recent Spaces")
        header.font = NSFont.boldSystemFont(ofSize: 13)
        contentView.addArrangedSubview(header)

        // Fetch recent spaces
        do {
            let spaceStore = SpaceStore(database: db)
            let spaces = Array(try spaceStore.list(includeArchived: false).prefix(5))

            if spaces.isEmpty {
                let empty = NSTextField(labelWithString: "No spaces")
                empty.font = NSFont.systemFont(ofSize: 11)
                empty.textColor = .secondaryLabelColor
                contentView.addArrangedSubview(empty)
            } else {
                for space in spaces {
                    let button = NSButton(title: space.name, target: self, action: #selector(spaceClicked(_:)))
                    button.bezelStyle = .recessed
                    button.tag = spaces.firstIndex(where: { $0.id == space.id }) ?? 0
                    contentView.addArrangedSubview(button)
                }
            }
        } catch {
            let error = NSTextField(labelWithString: "Error loading spaces")
            error.textColor = .systemRed
            contentView.addArrangedSubview(error)
        }
    }

    private func addTasksSection() {
        let header = NSTextField(labelWithString: "Due Tasks")
        header.font = NSFont.boldSystemFont(ofSize: 13)
        contentView.addArrangedSubview(header)

        // Fetch tasks with due dates
        do {
            let taskStore = TaskStore(database: db)
            let tasks = try taskStore.list(spaceId: nil, status: nil)
                .filter { $0.dueDate != nil }
                .sorted { task1, task2 in
                    guard let date1 = task1.dueDate, let date2 = task2.dueDate else {
                        return false
                    }
                    return date1 < date2
                }

            if tasks.isEmpty {
                let empty = NSTextField(labelWithString: "No tasks due")
                empty.font = NSFont.systemFont(ofSize: 11)
                empty.textColor = .secondaryLabelColor
                contentView.addArrangedSubview(empty)
            } else {
                for task in Array(tasks.prefix(5)) {
                    let taskLabel = NSTextField(labelWithString: "• \(task.title)")
                    taskLabel.font = NSFont.systemFont(ofSize: 11)
                    contentView.addArrangedSubview(taskLabel)
                }
            }
        } catch {
            let error = NSTextField(labelWithString: "Error loading tasks")
            error.textColor = .systemRed
            contentView.addArrangedSubview(error)
        }
    }

    private func addViewerButton() {
        let separator = NSBox()
        separator.boxType = .separator
        contentView.addArrangedSubview(separator)

        let button = NSButton(title: "Open Viewer", target: self, action: #selector(openViewer))
        button.bezelStyle = .rounded
        contentView.addArrangedSubview(button)
    }

    @objc private func spaceClicked(_ sender: NSButton) {
        NSLog("Space clicked: \(sender.title)")
        openViewer()
    }

    @objc public func openViewer() {
        appDelegate?.showViewer()
    }
}
