import XCTest
import GRDB
@testable import MaestroCore

/// AgentSession Model Tests
/// Tests the AgentSession model including Claude Code file watcher fields
final class AgentSessionTests: XCTestCase {

    private var database: MaestroCore.Database!

    override func setUp() {
        super.setUp()
        // Use in-memory database like other tests
        database = MaestroCore.Database()
        try? database.connect()
    }

    override func tearDown() {
        database?.close()
        super.tearDown()
    }

    // MARK: - Basic Session Creation

    func testCreateBasicSession() throws {
        let session = AgentSession(
            agentName: "Claude Code",
            startedAt: Date()
        )

        try database.write { db in
            try session.insert(db)
        }

        let fetched = try database.read { db in
            try AgentSession.fetchOne(db, key: session.id.uuidString)
        }

        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.agentName, "Claude Code")
        XCTAssertNil(fetched?.endedAt)
        XCTAssertEqual(fetched?.isActive, true)
    }

    // MARK: - Claude Code File Watcher Fields

    func testClaudeSessionIdField() throws {
        let claudeId = "abc123-def456-ghi789"
        let session = AgentSession(
            agentName: "Claude Code",
            claudeSessionId: claudeId
        )

        try database.write { db in
            try session.insert(db)
        }

        let fetched = try database.read { db in
            try AgentSession.fetchOne(db, key: session.id.uuidString)
        }

        XCTAssertEqual(fetched?.claudeSessionId, claudeId)
    }

    func testLastFileOffsetField() throws {
        let session = AgentSession(
            agentName: "Claude Code",
            lastFileOffset: 12345
        )

        try database.write { db in
            try session.insert(db)
        }

        let fetched = try database.read { db in
            try AgentSession.fetchOne(db, key: session.id.uuidString)
        }

        XCTAssertEqual(fetched?.lastFileOffset, 12345)
    }

    func testLastFileOffsetDefaultsToZero() throws {
        let session = AgentSession(agentName: "Claude Code")

        try database.write { db in
            try session.insert(db)
        }

        let fetched = try database.read { db in
            try AgentSession.fetchOne(db, key: session.id.uuidString)
        }

        XCTAssertEqual(fetched?.lastFileOffset, 0)
    }

    func testSpaceIdField() throws {
        // First create a space to reference
        let spaceId = UUID()
        try database.write { db in
            try db.execute(sql: """
                INSERT INTO spaces (id, name, color, created_at, last_active_at, archived, track_focus, total_focus_time)
                VALUES (?, 'Test Space', '#3B82F6', datetime('now'), datetime('now'), 0, 0, 0)
            """, arguments: [spaceId.uuidString])
        }

        let session = AgentSession(
            agentName: "Claude Code",
            spaceId: spaceId
        )

        try database.write { db in
            try session.insert(db)
        }

        let fetched = try database.read { db in
            try AgentSession.fetchOne(db, key: session.id.uuidString)
        }

        XCTAssertEqual(fetched?.spaceId, spaceId)
    }

    func testWorkingDirectoryField() throws {
        let cwd = "/Users/test/projects/my-project"
        let session = AgentSession(
            agentName: "Claude Code",
            workingDirectory: cwd
        )

        try database.write { db in
            try session.insert(db)
        }

        let fetched = try database.read { db in
            try AgentSession.fetchOne(db, key: session.id.uuidString)
        }

        XCTAssertEqual(fetched?.workingDirectory, cwd)
    }

    func testAllClaudeFieldsTogether() throws {
        let claudeId = "session-uuid-12345"
        let offset: Int64 = 98765
        let spaceId = UUID()
        let cwd = "/home/user/code"

        // Create space first
        try database.write { db in
            try db.execute(sql: """
                INSERT INTO spaces (id, name, color, created_at, last_active_at, archived, track_focus, total_focus_time)
                VALUES (?, 'Dev Space', '#3B82F6', datetime('now'), datetime('now'), 0, 0, 0)
            """, arguments: [spaceId.uuidString])
        }

        let session = AgentSession(
            agentName: "Claude Code",
            claudeSessionId: claudeId,
            lastFileOffset: offset,
            spaceId: spaceId,
            workingDirectory: cwd
        )

        try database.write { db in
            try session.insert(db)
        }

        let fetched = try database.read { db in
            try AgentSession.fetchOne(db, key: session.id.uuidString)
        }

        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.claudeSessionId, claudeId)
        XCTAssertEqual(fetched?.lastFileOffset, offset)
        XCTAssertEqual(fetched?.spaceId, spaceId)
        XCTAssertEqual(fetched?.workingDirectory, cwd)
    }

    // MARK: - Update Session

    func testUpdateLastFileOffset() throws {
        var session = AgentSession(
            agentName: "Claude Code",
            claudeSessionId: "test-session",
            lastFileOffset: 0
        )

        try database.write { db in
            try session.insert(db)
        }

        // Update offset
        session.lastFileOffset = 50000
        try database.write { db in
            try session.update(db)
        }

        let fetched = try database.read { db in
            try AgentSession.fetchOne(db, key: session.id.uuidString)
        }

        XCTAssertEqual(fetched?.lastFileOffset, 50000)
    }

    func testUpdateTotalActivities() throws {
        var session = AgentSession(
            agentName: "Claude Code",
            totalActivities: 0
        )

        try database.write { db in
            try session.insert(db)
        }

        // Simulate tracking tool calls
        session.totalActivities += 10
        try database.write { db in
            try session.update(db)
        }

        let fetched = try database.read { db in
            try AgentSession.fetchOne(db, key: session.id.uuidString)
        }

        XCTAssertEqual(fetched?.totalActivities, 10)
    }

    // MARK: - Query by Claude Session ID

    func testFindByClaudeSessionId() throws {
        let claudeId = "unique-claude-session-id"
        let session = AgentSession(
            agentName: "Claude Code",
            claudeSessionId: claudeId
        )

        try database.write { db in
            try session.insert(db)
        }

        let found = try database.read { db in
            try AgentSession.all()
                .filter(AgentSession.Columns.claudeSessionId == claudeId)
                .fetchOne(db)
        }

        XCTAssertNotNil(found)
        XCTAssertEqual(found?.id, session.id)
    }

    func testClaudeSessionIdUniqueness() throws {
        let claudeId = "shared-session-id"

        let session1 = AgentSession(
            agentName: "Claude Code",
            claudeSessionId: claudeId
        )

        let session2 = AgentSession(
            agentName: "Claude Code",
            claudeSessionId: claudeId
        )

        try database.write { db in
            try session1.insert(db)
        }

        // Second insert with same claude_session_id should fail due to unique index
        do {
            try database.write { db in
                try session2.insert(db)
            }
            XCTFail("Should have thrown an error for duplicate claude_session_id")
        } catch {
            // Expected - unique constraint violation
            XCTAssertTrue(true)
        }
    }

    // MARK: - Query by Space ID

    func testQuerySessionsBySpaceId() throws {
        let spaceId = UUID()

        // Create space
        try database.write { db in
            try db.execute(sql: """
                INSERT INTO spaces (id, name, color, created_at, last_active_at, archived, track_focus, total_focus_time)
                VALUES (?, 'Project Space', '#3B82F6', datetime('now'), datetime('now'), 0, 0, 0)
            """, arguments: [spaceId.uuidString])
        }

        // Create sessions for this space in a single transaction
        try database.write { db in
            for i in 1...3 {
                let session = AgentSession(
                    agentName: "Claude Code",
                    claudeSessionId: "session-\(i)",
                    spaceId: spaceId
                )
                try session.insert(db)
            }

            // Create session without space
            let otherSession = AgentSession(
                agentName: "Claude Code",
                claudeSessionId: "session-other"
            )
            try otherSession.insert(db)
        }

        // Query by space
        let spaceSessions = try database.read { db in
            try AgentSession.all()
                .filter(AgentSession.Columns.spaceId == spaceId.uuidString)
                .fetchAll(db)
        }

        XCTAssertEqual(spaceSessions.count, 3)
    }

    // MARK: - Session Properties

    func testIsActiveProperty() throws {
        var session = AgentSession(agentName: "Claude Code")
        XCTAssertTrue(session.isActive)

        session.endedAt = Date()
        XCTAssertFalse(session.isActive)
    }

    func testDurationProperty() throws {
        let startTime = Date()
        var session = AgentSession(
            agentName: "Claude Code",
            startedAt: startTime
        )

        XCTAssertNil(session.duration)

        // End session 60 seconds later
        session.endedAt = startTime.addingTimeInterval(60)
        XCTAssertNotNil(session.duration)
        XCTAssertEqual(session.duration!, 60, accuracy: 0.001)
    }

    // MARK: - Null Handling

    func testNullClaudeSessionId() throws {
        let session = AgentSession(agentName: "Some Agent")

        try database.write { db in
            try session.insert(db)
        }

        let fetched = try database.read { db in
            try AgentSession.fetchOne(db, key: session.id.uuidString)
        }

        XCTAssertNil(fetched?.claudeSessionId)
    }

    func testNullSpaceId() throws {
        let session = AgentSession(agentName: "Claude Code")

        try database.write { db in
            try session.insert(db)
        }

        let fetched = try database.read { db in
            try AgentSession.fetchOne(db, key: session.id.uuidString)
        }

        XCTAssertNil(fetched?.spaceId)
    }

    func testNullWorkingDirectory() throws {
        let session = AgentSession(agentName: "Claude Code")

        try database.write { db in
            try session.insert(db)
        }

        let fetched = try database.read { db in
            try AgentSession.fetchOne(db, key: session.id.uuidString)
        }

        XCTAssertNil(fetched?.workingDirectory)
    }
}
