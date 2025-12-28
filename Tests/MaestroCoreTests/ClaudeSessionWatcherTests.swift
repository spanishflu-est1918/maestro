import XCTest
import GRDB
@testable import MaestroCore

/// ClaudeSessionWatcher Integration Tests
/// Tests the file watching and session management functionality
final class ClaudeSessionWatcherTests: XCTestCase {

    private var database: MaestroCore.Database!
    private var tempDir: URL!

    override func setUp() {
        super.setUp()
        database = MaestroCore.Database()
        try? database.connect()

        // Create temp directory for test files
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDown() {
        database?.close()
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    // MARK: - JSONL File Parsing Tests

    func testParseFromOffset() throws {
        // Create a test JSONL file
        let testFile = tempDir.appendingPathComponent("test-session.jsonl")
        let content = """
        {"type":"user","sessionId":"test-123","uuid":"u1","timestamp":"2025-01-01T00:00:00.000Z","cwd":"/test","message":{"role":"user","content":"Hello"}}
        {"type":"assistant","sessionId":"test-123","uuid":"u2","timestamp":"2025-01-01T00:00:01.000Z","cwd":"/test","message":{"role":"assistant","content":[{"type":"text","text":"Hi there"}]}}
        """

        try content.write(to: testFile, atomically: true, encoding: .utf8)

        // Parse from beginning
        let fileHandle = try FileHandle(forReadingFrom: testFile)
        defer { try? fileHandle.close() }

        let (messages, newOffset) = ClaudeJSONLParser.parseFromOffset(fileHandle: fileHandle, offset: 0)

        XCTAssertEqual(messages.count, 2)
        XCTAssertGreaterThan(newOffset, 0)
    }

    func testIncrementalParsing() throws {
        // Create initial content
        let testFile = tempDir.appendingPathComponent("incremental.jsonl")
        let initialContent = """
        {"type":"user","sessionId":"inc-123","uuid":"u1","timestamp":"2025-01-01T00:00:00.000Z","cwd":"/test","message":{"role":"user","content":"First"}}

        """

        try initialContent.write(to: testFile, atomically: true, encoding: .utf8)

        // First read
        var fileHandle = try FileHandle(forReadingFrom: testFile)
        let (messages1, offset1) = ClaudeJSONLParser.parseFromOffset(fileHandle: fileHandle, offset: 0)
        try? fileHandle.close()

        XCTAssertEqual(messages1.count, 1)

        // Append more content
        let additionalContent = """
        {"type":"assistant","sessionId":"inc-123","uuid":"u2","timestamp":"2025-01-01T00:00:01.000Z","cwd":"/test","message":{"role":"assistant","content":[{"type":"text","text":"Reply"}]}}

        """

        let appendHandle = try FileHandle(forWritingTo: testFile)
        appendHandle.seekToEndOfFile()
        appendHandle.write(additionalContent.data(using: .utf8)!)
        try appendHandle.close()

        // Second read from offset
        fileHandle = try FileHandle(forReadingFrom: testFile)
        let (messages2, offset2) = ClaudeJSONLParser.parseFromOffset(fileHandle: fileHandle, offset: offset1)
        try? fileHandle.close()

        XCTAssertEqual(messages2.count, 1)
        XCTAssertGreaterThan(offset2, offset1)
    }

    // MARK: - Session Creation Tests

    func testSessionCreatedFromMessages() throws {
        // Create a session manually (simulating what watcher would do)
        let session = AgentSession(
            agentName: "Claude Code",
            claudeSessionId: "session-from-watcher",
            workingDirectory: "/Users/test/project"
        )

        try database.write { db in
            try session.insert(db)
        }

        // Verify session exists
        let found = try database.read { db in
            try AgentSession.all()
                .filter(AgentSession.Columns.claudeSessionId == "session-from-watcher")
                .fetchOne(db)
        }

        XCTAssertNotNil(found)
        XCTAssertEqual(found?.workingDirectory, "/Users/test/project")
    }

    // MARK: - Space Linking Tests

    func testSpaceLinkingByPath() throws {
        // Create a space with a path
        let spaceId = UUID()
        try database.write { db in
            try db.execute(sql: """
                INSERT INTO spaces (id, name, color, path, created_at, last_active_at, archived, track_focus, total_focus_time)
                VALUES (?, 'My Project', '#3B82F6', '/Users/test/my-project', datetime('now'), datetime('now'), 0, 0, 0)
            """, arguments: [spaceId.uuidString])
        }

        // Use SpaceStore to find space by path
        let spaceStore = SpaceStore(database: database)
        let inferredSpace = try spaceStore.inferSpace(forPath: "/Users/test/my-project/src/main.swift")

        XCTAssertNotNil(inferredSpace)
        XCTAssertEqual(inferredSpace?.id, spaceId)
    }

    func testSpaceLinkingNoMatch() throws {
        // Create a space with a different path
        let spaceId = UUID()
        try database.write { db in
            try db.execute(sql: """
                INSERT INTO spaces (id, name, color, path, created_at, last_active_at, archived, track_focus, total_focus_time)
                VALUES (?, 'Other Project', '#3B82F6', '/Users/test/other-project', datetime('now'), datetime('now'), 0, 0, 0)
            """, arguments: [spaceId.uuidString])
        }

        // Try to infer space from unrelated path
        let spaceStore = SpaceStore(database: database)
        let inferredSpace = try spaceStore.inferSpace(forPath: "/Users/test/different-project/file.txt")

        XCTAssertNil(inferredSpace)
    }

    // MARK: - Offset Tracking Tests

    func testOffsetPersistence() throws {
        var session = AgentSession(
            agentName: "Claude Code",
            claudeSessionId: "offset-test-session",
            lastFileOffset: 12345
        )

        try database.write { db in
            try session.insert(db)
        }

        // Update offset
        session.lastFileOffset = 54321
        try database.write { db in
            try session.update(db)
        }

        // Fetch and verify
        let fetched = try database.read { db in
            try AgentSession.all()
                .filter(AgentSession.Columns.claudeSessionId == "offset-test-session")
                .fetchOne(db)
        }

        XCTAssertEqual(fetched?.lastFileOffset, 54321)
    }

    func testOffsetZeroForNewSession() throws {
        let session = AgentSession(
            agentName: "Claude Code",
            claudeSessionId: "new-session"
        )

        try database.write { db in
            try session.insert(db)
        }

        let fetched = try database.read { db in
            try AgentSession.all()
                .filter(AgentSession.Columns.claudeSessionId == "new-session")
                .fetchOne(db)
        }

        XCTAssertEqual(fetched?.lastFileOffset, 0)
    }

    // MARK: - Tool Call Extraction Tests

    func testExtractMultipleToolCalls() throws {
        let json = """
        {"type":"assistant","sessionId":"s1","uuid":"u1","timestamp":"2025-01-01T00:00:00.000Z","message":{"role":"assistant","content":[{"type":"text","text":"Working on it..."},{"type":"tool_use","id":"t1","name":"Read","input":{"file_path":"/test.txt"}},{"type":"tool_use","id":"t2","name":"Edit","input":{"file_path":"/test.txt","old_string":"foo","new_string":"bar"}}]}}
        """

        let message = ClaudeJSONLParser.parseLine(json)
        XCTAssertNotNil(message)

        let toolCalls = message!.toolCalls
        XCTAssertEqual(toolCalls.count, 2)
        XCTAssertEqual(toolCalls[0].name, "Read")
        XCTAssertEqual(toolCalls[1].name, "Edit")
    }

    func testActivityCountFromToolCalls() throws {
        // Simulate processing multiple messages with tool calls
        let messages = [
            ClaudeJSONLParser.parseLine("""
            {"type":"assistant","sessionId":"s1","uuid":"u1","timestamp":"2025-01-01T00:00:00.000Z","message":{"role":"assistant","content":[{"type":"tool_use","id":"t1","name":"Grep","input":{}}]}}
            """),
            ClaudeJSONLParser.parseLine("""
            {"type":"assistant","sessionId":"s1","uuid":"u2","timestamp":"2025-01-01T00:00:01.000Z","message":{"role":"assistant","content":[{"type":"tool_use","id":"t2","name":"Read","input":{}},{"type":"tool_use","id":"t3","name":"Edit","input":{}}]}}
            """)
        ].compactMap { $0 }

        var totalToolCalls = 0
        for message in messages {
            totalToolCalls += message.toolCalls.count
        }

        XCTAssertEqual(totalToolCalls, 3)
    }

    // MARK: - Session Info Extraction Tests

    func testSessionInfoFromUserMessage() throws {
        let json = """
        {"type":"user","sessionId":"session-abc","uuid":"uuid-123","timestamp":"2025-12-03T05:58:05.815Z","cwd":"/Users/dev/project","gitBranch":"feature-x","message":{"role":"user","content":"Hello"}}
        """

        let message = ClaudeJSONLParser.parseLine(json)
        XCTAssertNotNil(message)

        let sessionInfo = message?.sessionInfo
        XCTAssertNotNil(sessionInfo)
        XCTAssertEqual(sessionInfo?.sessionId, "session-abc")
        XCTAssertEqual(sessionInfo?.cwd, "/Users/dev/project")
        XCTAssertEqual(sessionInfo?.gitBranch, "feature-x")
        XCTAssertEqual(sessionInfo?.timestamp, "2025-12-03T05:58:05.815Z")
    }

    func testSessionInfoFromAssistantMessage() throws {
        let json = """
        {"type":"assistant","sessionId":"session-xyz","uuid":"uuid-456","timestamp":"2025-12-03T06:00:00.000Z","cwd":"/work/repo","gitBranch":"main","message":{"role":"assistant","content":[{"type":"text","text":"Done"}]}}
        """

        let message = ClaudeJSONLParser.parseLine(json)
        XCTAssertNotNil(message)

        let sessionInfo = message?.sessionInfo
        XCTAssertNotNil(sessionInfo)
        XCTAssertEqual(sessionInfo?.sessionId, "session-xyz")
        XCTAssertEqual(sessionInfo?.cwd, "/work/repo")
    }

    // MARK: - Edge Cases

    func testEmptyFileHandling() throws {
        let testFile = tempDir.appendingPathComponent("empty.jsonl")
        try "".write(to: testFile, atomically: true, encoding: .utf8)

        let fileHandle = try FileHandle(forReadingFrom: testFile)
        defer { try? fileHandle.close() }

        let (messages, newOffset) = ClaudeJSONLParser.parseFromOffset(fileHandle: fileHandle, offset: 0)

        XCTAssertEqual(messages.count, 0)
        XCTAssertEqual(newOffset, 0)
    }

    func testMixedValidInvalidLines() throws {
        let testFile = tempDir.appendingPathComponent("mixed.jsonl")
        let content = """
        {"type":"user","sessionId":"s1","uuid":"u1","timestamp":"2025-01-01T00:00:00.000Z","message":{"role":"user","content":"Valid"}}
        {invalid json here}
        {"type":"assistant","sessionId":"s1","uuid":"u2","timestamp":"2025-01-01T00:00:01.000Z","message":{"role":"assistant","content":[{"type":"text","text":"Also valid"}]}}

        """

        try content.write(to: testFile, atomically: true, encoding: .utf8)

        let fileHandle = try FileHandle(forReadingFrom: testFile)
        defer { try? fileHandle.close() }

        let (messages, _) = ClaudeJSONLParser.parseFromOffset(fileHandle: fileHandle, offset: 0)

        // Should parse 2 valid messages, skipping the invalid one
        XCTAssertEqual(messages.count, 2)
    }

    func testSessionIdFromFilename() throws {
        // Test extracting session ID from filename pattern
        let filename = "abc123-def456-ghi789.jsonl"
        let sessionId = String(filename.dropLast(6))  // Remove ".jsonl"

        XCTAssertEqual(sessionId, "abc123-def456-ghi789")
    }
}
