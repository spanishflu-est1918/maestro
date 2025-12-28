import Foundation
import MaestroCore

/// CLI command handlers for Maestro
struct CLI {
    private let database: Database

    init(databasePath: String) throws {
        self.database = Database(path: databasePath)
        try database.connect()
    }

    // MARK: - Sessions List

    func listSessions(limit: Int = 20) throws {
        let sessions = try database.read { db in
            try AgentSession.all()
                .filter(AgentSession.Columns.claudeSessionId != nil)
                .order(AgentSession.Columns.startedAt.desc)
                .limit(limit)
                .fetchAll(db)
        }

        if sessions.isEmpty {
            print("No Claude Code sessions found.")
            return
        }

        // Get spaces for linking
        let spaces = try database.read { db in
            try Space.fetchAll(db)
        }
        let spaceMap = Dictionary(uniqueKeysWithValues: spaces.map { ($0.id, $0.name) })

        // Header
        print("")
        print("Claude Code Sessions")
        print(String(repeating: "─", count: 80))
        print("\("Session ID".padding(toLength: 38, withPad: " ", startingAt: 0))\("Space".padding(toLength: 15, withPad: " ", startingAt: 0))\("Activities".padding(toLength: 12, withPad: " ", startingAt: 0))Last Active")
        print(String(repeating: "─", count: 80))

        let dateFormatter = RelativeDateTimeFormatter()
        dateFormatter.unitsStyle = .abbreviated

        for session in sessions {
            let sessionId = session.claudeSessionId ?? "unknown"
            let shortId = String(sessionId.prefix(36)).padding(toLength: 38, withPad: " ", startingAt: 0)
            let spaceName = String((session.spaceId.flatMap { spaceMap[$0] } ?? "-").prefix(14)).padding(toLength: 15, withPad: " ", startingAt: 0)
            let activities = "\(session.totalActivities)".padding(toLength: 12, withPad: " ", startingAt: 0)
            let lastActive = dateFormatter.localizedString(for: session.startedAt, relativeTo: Date())

            print("\(shortId)\(spaceName)\(activities)\(lastActive)")
        }
        print("")
    }

    // MARK: - Session Details

    func showSession(id: String) throws {
        // Find session by prefix match
        let session = try database.read { db -> AgentSession? in
            try AgentSession.all()
                .filter(AgentSession.Columns.claudeSessionId != nil)
                .fetchAll(db)
                .first { $0.claudeSessionId?.hasPrefix(id) == true }
        }

        guard let session = session else {
            print("Session not found: \(id)")
            print("Use 'maestro sessions' to list available sessions.")
            exit(1)
        }

        // Get linked space
        var spaceName: String? = nil
        if let spaceId = session.spaceId {
            spaceName = try database.read { db in
                try Space.fetchOne(db, key: spaceId.uuidString)?.name
            }
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short

        print("")
        print("Session Details")
        print(String(repeating: "─", count: 60))
        print("ID:          \(session.claudeSessionId ?? "unknown")")
        print("Space:       \(spaceName ?? "-")")
        print("Directory:   \(session.workingDirectory ?? "-")")
        print("Started:     \(dateFormatter.string(from: session.startedAt))")
        if let endedAt = session.endedAt {
            print("Ended:       \(dateFormatter.string(from: endedAt))")
        }
        print("Activities:  \(session.totalActivities) tool calls")
        print("Status:      \(session.isActive ? "Active" : "Ended")")
        print(String(repeating: "─", count: 60))
        print("")
        print("Resume command:")
        print("  claude --resume \(session.claudeSessionId ?? "")")
        print("")
    }

    // MARK: - Resume Session

    func resumeSession(id: String) throws {
        // Find session by prefix match
        let session = try database.read { db -> AgentSession? in
            try AgentSession.all()
                .filter(AgentSession.Columns.claudeSessionId != nil)
                .fetchAll(db)
                .first { $0.claudeSessionId?.hasPrefix(id) == true }
        }

        guard let session = session, let sessionId = session.claudeSessionId else {
            print("Session not found: \(id)")
            print("Use 'maestro sessions' to list available sessions.")
            exit(1)
        }

        // Change to working directory if available
        if let cwd = session.workingDirectory {
            FileManager.default.changeCurrentDirectoryPath(cwd)
        }

        print("Resuming session: \(sessionId)")
        print("Directory: \(session.workingDirectory ?? FileManager.default.currentDirectoryPath)")
        print("")

        // Execute claude --resume
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["claude", "--resume", sessionId]
        process.standardInput = FileHandle.standardInput
        process.standardOutput = FileHandle.standardOutput
        process.standardError = FileHandle.standardError

        try process.run()
        process.waitUntilExit()

        exit(process.terminationStatus)
    }

    // MARK: - Help

    static func printUsage() {
        print("""
        Maestro - AI Work Orchestration

        Usage: maestrod <command> [options]

        Commands:
          daemon              Start the Maestro daemon (default)
          sessions            List Claude Code sessions
          session <id>        Show session details
          resume <id>         Resume a Claude Code session
          help                Show this help message

        Examples:
          maestrod                         Start daemon
          maestrod sessions                List all sessions
          maestrod session 0b8be45d        Show session details
          maestrod resume 0b8be45d         Resume session in Claude Code

        Session IDs can be abbreviated - first 8 characters is usually enough.
        """)
    }
}
