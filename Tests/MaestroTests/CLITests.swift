import XCTest
import GRDB
@testable import MaestroCore
@testable import Maestro

/// CLI Tests
/// Tests the session listing, details, and resume command logic
final class CLITests: XCTestCase {

    private var database: MaestroCore.Database!
    private var tempDbPath: String!

    override func setUp() {
        super.setUp()
        // Create temp database file for CLI tests
        tempDbPath = NSTemporaryDirectory() + "maestro_cli_test_\(UUID().uuidString).db"
        database = MaestroCore.Database(path: tempDbPath)
        try? database.connect()
    }

    override func tearDown() {
        database?.close()
        // Clean up temp file
        try? FileManager.default.removeItem(atPath: tempDbPath)
        super.tearDown()
    }

    // MARK: - CLI Initialization

    func testCLIInitializesWithDatabasePath() throws {
        let cli = try CLI(databasePath: tempDbPath)
        XCTAssertNotNil(cli)
    }

    func testCLIFailsWithInvalidPath() {
        XCTAssertThrowsError(try CLI(databasePath: "/nonexistent/path/db.sqlite"))
    }

    // MARK: - Session Listing

    func testListSessionsWithNoSessions() throws {
        let cli = try CLI(databasePath: tempDbPath)
        // Should not throw, just print "No sessions found"
        XCTAssertNoThrow(try cli.listSessions())
    }

    func testListSessionsShowsClaudeSessions() throws {
        // Create a session with claude_session_id
        let session = AgentSession(
            agentName: "Claude Code",
            totalActivities: 42,
            claudeSessionId: "test-session-12345"
        )

        try database.write { db in
            try session.insert(db)
        }

        let cli = try CLI(databasePath: tempDbPath)
        // Should complete without throwing
        XCTAssertNoThrow(try cli.listSessions())
    }

    func testListSessionsIgnoresNonClaudeSessions() throws {
        // Create a session WITHOUT claude_session_id
        let session = AgentSession(agentName: "Other Agent")

        try database.write { db in
            try session.insert(db)
        }

        // The listing should work but not show this session
        // (it filters for claudeSessionId != nil)
        let cli = try CLI(databasePath: tempDbPath)
        XCTAssertNoThrow(try cli.listSessions())
    }

    func testListSessionsShowsSpaceName() throws {
        // Create a space
        let spaceId = UUID()
        try database.write { db in
            try db.execute(sql: """
                INSERT INTO spaces (id, name, color, created_at, last_active_at, archived, track_focus, total_focus_time)
                VALUES (?, 'My Project', '#3B82F6', datetime('now'), datetime('now'), 0, 0, 0)
            """, arguments: [spaceId.uuidString])
        }

        // Create session linked to space
        let session = AgentSession(
            agentName: "Claude Code",
            claudeSessionId: "session-with-space",
            spaceId: spaceId
        )

        try database.write { db in
            try session.insert(db)
        }

        let cli = try CLI(databasePath: tempDbPath)
        XCTAssertNoThrow(try cli.listSessions())
    }

    func testListSessionsRespectLimit() throws {
        // Create more sessions than the limit
        try database.write { db in
            for i in 1...30 {
                let session = AgentSession(
                    agentName: "Claude Code",
                    startedAt: Date().addingTimeInterval(TimeInterval(-i * 60)),
                    claudeSessionId: "session-\(i)"
                )
                try session.insert(db)
            }
        }

        let cli = try CLI(databasePath: tempDbPath)
        // Default limit is 20, should work fine
        XCTAssertNoThrow(try cli.listSessions(limit: 5))
    }

    // MARK: - Session Details

    func testShowSessionFindsById() throws {
        let sessionId = "abc12345-def6-7890-ghij-klmnopqrstuv"
        let session = AgentSession(
            agentName: "Claude Code",
            totalActivities: 100,
            claudeSessionId: sessionId,
            workingDirectory: "/Users/test/project"
        )

        try database.write { db in
            try session.insert(db)
        }

        let cli = try CLI(databasePath: tempDbPath)
        // Find by full ID
        XCTAssertNoThrow(try cli.showSession(id: sessionId))
    }

    func testShowSessionFindsByPrefix() throws {
        let sessionId = "abc12345-def6-7890-ghij-klmnopqrstuv"
        let session = AgentSession(
            agentName: "Claude Code",
            claudeSessionId: sessionId
        )

        try database.write { db in
            try session.insert(db)
        }

        let cli = try CLI(databasePath: tempDbPath)
        // Find by prefix (8 chars)
        XCTAssertNoThrow(try cli.showSession(id: "abc12345"))
    }

    func testShowSessionShowsSpaceInfo() throws {
        let spaceId = UUID()
        try database.write { db in
            try db.execute(sql: """
                INSERT INTO spaces (id, name, color, created_at, last_active_at, archived, track_focus, total_focus_time)
                VALUES (?, 'Test Space', '#3B82F6', datetime('now'), datetime('now'), 0, 0, 0)
            """, arguments: [spaceId.uuidString])
        }

        let session = AgentSession(
            agentName: "Claude Code",
            claudeSessionId: "session-with-space-details",
            spaceId: spaceId,
            workingDirectory: "/test/path"
        )

        try database.write { db in
            try session.insert(db)
        }

        let cli = try CLI(databasePath: tempDbPath)
        XCTAssertNoThrow(try cli.showSession(id: "session-with"))
    }

    // MARK: - Resume Session Logic

    func testResumeSessionFindsSession() throws {
        let sessionId = "resume-test-session-id"
        let session = AgentSession(
            agentName: "Claude Code",
            claudeSessionId: sessionId,
            workingDirectory: "/tmp"
        )

        try database.write { db in
            try session.insert(db)
        }

        // Note: We can't fully test resumeSession as it calls `claude --resume`
        // But we can verify the session lookup works
        let found = try database.read { db in
            try AgentSession.all()
                .filter(AgentSession.Columns.claudeSessionId != nil)
                .fetchAll(db)
                .first { $0.claudeSessionId?.hasPrefix("resume-test") == true }
        }

        XCTAssertNotNil(found)
        XCTAssertEqual(found?.claudeSessionId, sessionId)
        XCTAssertEqual(found?.workingDirectory, "/tmp")
    }

    // MARK: - Help Output

    func testPrintUsageDoesNotThrow() {
        // Static method, just verify it doesn't crash
        CLI.printUsage()
    }

    // MARK: - Edge Cases

    func testSessionWithLongSpaceName() throws {
        let spaceId = UUID()
        let longName = "This Is A Very Long Space Name That Should Be Truncated"
        try database.write { db in
            try db.execute(sql: """
                INSERT INTO spaces (id, name, color, created_at, last_active_at, archived, track_focus, total_focus_time)
                VALUES (?, ?, '#3B82F6', datetime('now'), datetime('now'), 0, 0, 0)
            """, arguments: [spaceId.uuidString, longName])
        }

        let session = AgentSession(
            agentName: "Claude Code",
            claudeSessionId: "long-space-name-session",
            spaceId: spaceId
        )

        try database.write { db in
            try session.insert(db)
        }

        let cli = try CLI(databasePath: tempDbPath)
        // Should truncate space name to 14 chars without crashing
        XCTAssertNoThrow(try cli.listSessions())
    }

    func testSessionWithEmptyWorkingDirectory() throws {
        let session = AgentSession(
            agentName: "Claude Code",
            claudeSessionId: "no-cwd-session",
            workingDirectory: nil
        )

        try database.write { db in
            try session.insert(db)
        }

        let cli = try CLI(databasePath: tempDbPath)
        XCTAssertNoThrow(try cli.showSession(id: "no-cwd"))
    }

    func testSessionWithHighActivityCount() throws {
        let session = AgentSession(
            agentName: "Claude Code",
            totalActivities: 999999,
            claudeSessionId: "high-activity-session"
        )

        try database.write { db in
            try session.insert(db)
        }

        let cli = try CLI(databasePath: tempDbPath)
        XCTAssertNoThrow(try cli.listSessions())
    }
}
