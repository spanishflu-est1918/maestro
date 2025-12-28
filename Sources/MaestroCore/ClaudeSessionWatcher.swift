import Foundation
import CoreServices
import GRDB

/// Watches Claude Code session files in ~/.claude/projects/ and updates Maestro's agent monitoring
/// Uses FSEvents for efficient file system monitoring
public class ClaudeSessionWatcher {
    private let claudeDir: String
    private let projectsDir: String
    private var eventStream: FSEventStreamRef?
    private let database: Database
    private let spaceStore: SpaceStore
    private var agentMonitor: AgentMonitor?

    // Track file offsets for incremental reading
    private var fileOffsets: [String: Int64] = [:]
    private let offsetQueue = DispatchQueue(label: "com.maestro.claude-watcher.offsets")

    // Callback context for FSEvents
    private var callbackContext: UnsafeMutableRawPointer?

    public init(database: Database) {
        self.database = database
        self.spaceStore = SpaceStore(database: database)
        self.claudeDir = (NSHomeDirectory() as NSString).appendingPathComponent(".claude")
        self.projectsDir = (claudeDir as NSString).appendingPathComponent("projects")
    }

    /// Start watching for Claude Code session file changes
    public func start() {
        // Initialize agent monitor
        agentMonitor = AgentMonitor(database: database)

        // Load existing offsets from database
        loadOffsetsFromDatabase()

        // Create FSEvents stream
        guard FileManager.default.fileExists(atPath: projectsDir) else {
            print("⚠️ Claude projects directory not found: \(projectsDir)")
            return
        }

        var context = FSEventStreamContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )

        let pathsToWatch = [projectsDir] as CFArray

        eventStream = FSEventStreamCreate(
            nil,
            fsEventCallback,
            &context,
            pathsToWatch,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            1.0,  // Latency in seconds (batch events)
            FSEventStreamCreateFlags(kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagUseCFTypes)
        )

        guard let stream = eventStream else {
            print("❌ Failed to create FSEvents stream")
            return
        }

        // Use dispatch queue instead of deprecated run loop method
        let queue = DispatchQueue(label: "com.maestro.claude-watcher.events", qos: .utility)
        FSEventStreamSetDispatchQueue(stream, queue)

        FSEventStreamStart(stream)
        print("✓ Claude session watcher started: \(projectsDir)")

        // Do initial scan of existing files
        scanExistingFiles()
    }

    /// Stop watching
    public func stop() {
        guard let stream = eventStream else { return }

        FSEventStreamStop(stream)
        FSEventStreamInvalidate(stream)
        FSEventStreamRelease(stream)
        eventStream = nil

        print("✓ Claude session watcher stopped")
    }

    // MARK: - FSEvents Callback

    private let fsEventCallback: FSEventStreamCallback = { (
        streamRef,
        clientCallbackInfo,
        numEvents,
        eventPaths,
        eventFlags,
        eventIds
    ) in
        guard let info = clientCallbackInfo else { return }
        let watcher = Unmanaged<ClaudeSessionWatcher>.fromOpaque(info).takeUnretainedValue()

        guard let paths = unsafeBitCast(eventPaths, to: NSArray.self) as? [String] else { return }

        for path in paths {
            if path.hasSuffix(".jsonl") {
                watcher.handleFileChange(path)
            }
        }
    }

    // MARK: - File Handling

    private func handleFileChange(_ path: String) {
        // Extract session ID from filename (e.g., "abc123-def456.jsonl" -> "abc123-def456")
        let filename = (path as NSString).lastPathComponent
        guard filename.hasSuffix(".jsonl") else { return }

        let sessionId = String(filename.dropLast(6))  // Remove ".jsonl"

        // Skip non-session files (agent-* files, etc.)
        // Regular sessions are UUIDs, skip files with prefixes
        guard sessionId.contains("-") && !sessionId.hasPrefix("agent-") else { return }

        // Get current offset for this file
        let currentOffset = offsetQueue.sync { fileOffsets[path] ?? 0 }

        // Parse new content from offset
        guard let fileHandle = FileHandle(forReadingAtPath: path) else { return }
        defer { try? fileHandle.close() }

        let (messages, newOffset) = ClaudeJSONLParser.parseFromOffset(
            fileHandle: fileHandle,
            offset: currentOffset
        )

        guard !messages.isEmpty else { return }

        // Update offset
        offsetQueue.sync { fileOffsets[path] = newOffset }

        // Process messages
        processMessages(messages, sessionId: sessionId, filePath: path, newOffset: newOffset)
    }

    private func processMessages(_ messages: [ClaudeMessage], sessionId: String, filePath: String, newOffset: Int64) {
        // Extract session info from first message with session info
        guard let firstSessionInfo = messages.compactMap({ $0.sessionInfo }).first else { return }

        do {
            // Get or create agent session
            var session = try getOrCreateSession(
                claudeSessionId: sessionId,
                cwd: firstSessionInfo.cwd,
                timestamp: firstSessionInfo.timestamp
            )

            // Count activities
            var toolCallCount = 0
            var userMessageCount = 0

            for message in messages {
                switch message {
                case .user:
                    userMessageCount += 1
                case .assistant:
                    toolCallCount += message.toolCalls.count
                default:
                    break
                }
            }

            // Update session stats
            session.totalActivities += toolCallCount + userMessageCount
            session.lastFileOffset = newOffset

            // Log individual tool calls as activities
            for message in messages {
                for tool in message.toolCalls {
                    try agentMonitor?.logActivity(
                        sessionId: session.id,
                        agentName: "Claude Code",
                        activityType: .other,
                        resourceType: .other,
                        resourceId: nil,
                        description: "Tool: \(tool.name)",
                        metadata: nil
                    )
                }
            }

            // Save updated session
            try database.write { db in
                try session.update(db)
            }

        } catch {
            print("❌ Error processing Claude messages: \(error)")
        }
    }

    // MARK: - Session Management

    private func getOrCreateSession(claudeSessionId: String, cwd: String?, timestamp: String) throws -> AgentSession {
        // Try to find existing session
        if let existing = try findSessionByClaudeId(claudeSessionId) {
            return existing
        }

        // Create new session
        var session = AgentSession(
            agentName: "Claude Code",
            startedAt: parseTimestamp(timestamp) ?? Date(),
            claudeSessionId: claudeSessionId,
            workingDirectory: cwd
        )

        // Link to space if possible
        if let cwd = cwd {
            if let space = try spaceStore.inferSpace(forPath: cwd) {
                session.spaceId = space.id
            }
        }

        // Save to database
        try database.write { db in
            try session.insert(db)
        }

        print("✓ New Claude session detected: \(claudeSessionId)")
        if let spaceId = session.spaceId {
            print("  → Linked to space: \(spaceId)")
        }

        return session
    }

    private func findSessionByClaudeId(_ claudeSessionId: String) throws -> AgentSession? {
        return try database.read { db in
            try AgentSession.all()
                .filter(AgentSession.Columns.claudeSessionId == claudeSessionId)
                .fetchOne(db)
        }
    }

    // MARK: - Initialization Helpers

    private func loadOffsetsFromDatabase() {
        do {
            let sessions: [AgentSession] = try database.read { db in
                try AgentSession.all()
                    .filter(AgentSession.Columns.claudeSessionId != nil)
                    .filter(AgentSession.Columns.lastFileOffset > 0)
                    .fetchAll(db)
            }

            for session in sessions {
                if let claudeId = session.claudeSessionId {
                    // Reconstruct file path from claude session ID
                    let possiblePath = findFileForSession(claudeId)
                    if let path = possiblePath {
                        offsetQueue.sync {
                            fileOffsets[path] = session.lastFileOffset
                        }
                    }
                }
            }

            print("✓ Loaded \(sessions.count) session offsets from database")
        } catch {
            print("⚠️ Failed to load session offsets: \(error)")
        }
    }

    private func findFileForSession(_ sessionId: String) -> String? {
        let filename = "\(sessionId).jsonl"

        // Search in projects directory
        let enumerator = FileManager.default.enumerator(
            at: URL(fileURLWithPath: projectsDir),
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )

        while let url = enumerator?.nextObject() as? URL {
            if url.lastPathComponent == filename {
                return url.path
            }
        }

        return nil
    }

    private func scanExistingFiles() {
        let enumerator = FileManager.default.enumerator(
            at: URL(fileURLWithPath: projectsDir),
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        )

        var recentFiles: [(URL, Date)] = []

        while let url = enumerator?.nextObject() as? URL {
            guard url.pathExtension == "jsonl" else { continue }

            // Get modification date
            if let resourceValues = try? url.resourceValues(forKeys: [.contentModificationDateKey]),
               let modDate = resourceValues.contentModificationDate {
                recentFiles.append((url, modDate))
            }
        }

        // Process files modified in the last hour (likely active sessions)
        let oneHourAgo = Date().addingTimeInterval(-3600)
        let activeFiles = recentFiles.filter { $0.1 > oneHourAgo }

        for (url, _) in activeFiles {
            handleFileChange(url.path)
        }

        print("✓ Scanned \(activeFiles.count) recently active session files")
    }

    // MARK: - Helpers

    private func parseTimestamp(_ timestamp: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: timestamp)
    }
}
