import XCTest
import GRDB
@testable import MaestroCore

/// Agent Monitoring Tests
/// Tests agent session and activity tracking
final class AgentMonitorTests: XCTestCase {

    func testStartSession() throws {
        let db = Database()
        try db.connect()

        let monitor = AgentMonitor(database: db)
        let session = try monitor.startSession(agentName: "Claude Code")

        XCTAssertEqual(session.agentName, "Claude Code")
        XCTAssertTrue(session.isActive)
        XCTAssertEqual(session.totalActivities, 0)
        XCTAssertEqual(session.tasksCreated, 0)
    }

    func testEndSession() throws {
        let db = Database()
        try db.connect()

        let monitor = AgentMonitor(database: db)
        let session = try monitor.startSession(agentName: "Claude Code")

        XCTAssertTrue(session.isActive)

        try monitor.endSession(session.id)

        let updated = try monitor.getSession(session.id)
        XCTAssertNotNil(updated)
        XCTAssertFalse(updated!.isActive)
        XCTAssertNotNil(updated!.endedAt)
    }

    func testGetOrCreateSession() throws {
        let db = Database()
        try db.connect()

        let monitor = AgentMonitor(database: db)

        // First call creates new session
        let session1 = try monitor.getOrCreateSession(agentName: "Claude Code")
        XCTAssertEqual(session1.agentName, "Claude Code")

        // Second call returns same active session
        let session2 = try monitor.getOrCreateSession(agentName: "Claude Code")
        XCTAssertEqual(session1.id, session2.id)

        // End session
        try monitor.endSession(session1.id)

        // Third call creates new session since previous is ended
        let session3 = try monitor.getOrCreateSession(agentName: "Claude Code")
        XCTAssertNotEqual(session1.id, session3.id)
    }

    func testLogActivity() throws {
        let db = Database()
        try db.connect()

        let monitor = AgentMonitor(database: db)
        let session = try monitor.startSession(agentName: "Claude Code")

        try monitor.logActivity(
            sessionId: session.id,
            agentName: "Claude Code",
            activityType: .created,
            resourceType: .task,
            resourceId: UUID(),
            description: "Created a new task"
        )

        // Verify session counters updated
        let updated = try monitor.getSession(session.id)
        XCTAssertEqual(updated?.totalActivities, 1)
        XCTAssertEqual(updated?.tasksCreated, 1)
    }

    func testLogMultipleActivities() throws {
        let db = Database()
        try db.connect()

        let monitor = AgentMonitor(database: db)
        let session = try monitor.startSession(agentName: "Claude Code")

        // Create task
        try monitor.logActivity(
            sessionId: session.id,
            agentName: "Claude Code",
            activityType: .created,
            resourceType: .task
        )

        // Update task
        try monitor.logActivity(
            sessionId: session.id,
            agentName: "Claude Code",
            activityType: .updated,
            resourceType: .task
        )

        // Complete task
        try monitor.logActivity(
            sessionId: session.id,
            agentName: "Claude Code",
            activityType: .completed,
            resourceType: .task
        )

        // Create space
        try monitor.logActivity(
            sessionId: session.id,
            agentName: "Claude Code",
            activityType: .created,
            resourceType: .space
        )

        let updated = try monitor.getSession(session.id)
        XCTAssertEqual(updated?.totalActivities, 4)
        XCTAssertEqual(updated?.tasksCreated, 1)
        XCTAssertEqual(updated?.tasksUpdated, 1)
        XCTAssertEqual(updated?.tasksCompleted, 1)
        XCTAssertEqual(updated?.spacesCreated, 1)
    }

    func testListSessions() throws {
        let db = Database()
        try db.connect()

        let monitor = AgentMonitor(database: db)

        // Create sessions for different agents
        _ = try monitor.startSession(agentName: "Claude Code")
        _ = try monitor.startSession(agentName: "Codex")
        _ = try monitor.startSession(agentName: "Claude Code")

        // List all sessions
        let allSessions = try monitor.listSessions()
        XCTAssertEqual(allSessions.count, 3)

        // List Claude Code sessions only
        let claudeSessions = try monitor.listSessions(agentName: "Claude Code")
        XCTAssertEqual(claudeSessions.count, 2)

        // List Codex sessions only
        let codexSessions = try monitor.listSessions(agentName: "Codex")
        XCTAssertEqual(codexSessions.count, 1)
    }

    func testListActiveSessionsOnly() throws {
        let db = Database()
        try db.connect()

        let monitor = AgentMonitor(database: db)

        let session1 = try monitor.startSession(agentName: "Claude Code")
        let session2 = try monitor.startSession(agentName: "Claude Code")

        // End first session
        try monitor.endSession(session1.id)

        // List all sessions
        let allSessions = try monitor.listSessions(agentName: "Claude Code")
        XCTAssertEqual(allSessions.count, 2)

        // List only active sessions
        let activeSessions = try monitor.listSessions(agentName: "Claude Code", activeOnly: true)
        XCTAssertEqual(activeSessions.count, 1)
        XCTAssertEqual(activeSessions[0].id, session2.id)
    }

    func testListActivities() throws {
        let db = Database()
        try db.connect()

        let monitor = AgentMonitor(database: db)
        let session = try monitor.startSession(agentName: "Claude Code")

        // Log various activities
        try monitor.logActivity(
            sessionId: session.id,
            agentName: "Claude Code",
            activityType: .created,
            resourceType: .task
        )

        try monitor.logActivity(
            sessionId: session.id,
            agentName: "Claude Code",
            activityType: .viewed,
            resourceType: .space
        )

        // List all activities
        let allActivities = try monitor.listActivities(sessionId: session.id)
        XCTAssertEqual(allActivities.count, 2)

        // List only 'created' activities
        let createdActivities = try monitor.listActivities(
            sessionId: session.id,
            activityType: .created
        )
        XCTAssertEqual(createdActivities.count, 1)

        // List only task activities
        let taskActivities = try monitor.listActivities(
            sessionId: session.id,
            resourceType: .task
        )
        XCTAssertEqual(taskActivities.count, 1)
    }

    func testGetMetrics() throws {
        let db = Database()
        try db.connect()

        let monitor = AgentMonitor(database: db)
        let session = try monitor.startSession(agentName: "Claude Code")

        // Log activities
        try monitor.logActivity(
            sessionId: session.id,
            agentName: "Claude Code",
            activityType: .created,
            resourceType: .task
        )

        try monitor.logActivity(
            sessionId: session.id,
            agentName: "Claude Code",
            activityType: .updated,
            resourceType: .task
        )

        // End session
        try monitor.endSession(session.id)

        // Get metrics
        let metrics = try monitor.getMetrics(agentName: "Claude Code")

        XCTAssertEqual(metrics.agentName, "Claude Code")
        XCTAssertEqual(metrics.totalSessions, 1)
        XCTAssertEqual(metrics.activeSessions, 0)
        XCTAssertEqual(metrics.totalActivities, 2)
        XCTAssertEqual(metrics.tasksCreated, 1)
        XCTAssertEqual(metrics.tasksUpdated, 1)
        XCTAssertGreaterThan(metrics.averageSessionDuration, 0)
    }

    func testSessionDuration() throws {
        let db = Database()
        try db.connect()

        let monitor = AgentMonitor(database: db)
        let session = try monitor.startSession(agentName: "Claude Code")

        // Active session has no duration
        XCTAssertNil(session.duration)

        // End session
        try monitor.endSession(session.id)

        let ended = try monitor.getSession(session.id)
        XCTAssertNotNil(ended?.duration)
        // Duration might be 0 if ended very quickly, just verify it's not nil
        XCTAssertGreaterThanOrEqual(ended!.duration!, 0)
    }

    func testCleanupOldData() throws {
        let db = Database()
        try db.connect()

        let monitor = AgentMonitor(database: db)

        // Create and end a session
        let session = try monitor.startSession(agentName: "Claude Code")
        try monitor.endSession(session.id)

        // Verify session exists
        var sessions = try monitor.listSessions()
        XCTAssertEqual(sessions.count, 1)

        // Cleanup old data (0 days = all ended sessions)
        try monitor.cleanupOldData(olderThan: 0)

        // Verify session was deleted
        sessions = try monitor.listSessions()
        XCTAssertEqual(sessions.count, 0)
    }

    func testMetricsMultipleSessions() throws {
        let db = Database()
        try db.connect()

        let monitor = AgentMonitor(database: db)

        // Create multiple sessions with activities
        for i in 0..<3 {
            let session = try monitor.startSession(agentName: "Claude Code")

            for _ in 0..<(i + 1) {
                try monitor.logActivity(
                    sessionId: session.id,
                    agentName: "Claude Code",
                    activityType: .created,
                    resourceType: .task
                )
            }

            try monitor.endSession(session.id)
        }

        let metrics = try monitor.getMetrics(agentName: "Claude Code")

        XCTAssertEqual(metrics.totalSessions, 3)
        XCTAssertEqual(metrics.activeSessions, 0)
        XCTAssertEqual(metrics.tasksCreated, 6) // 1 + 2 + 3
        XCTAssertEqual(metrics.averageActivitiesPerSession, 2.0) // 6 / 3
    }

    func testActivityWithMetadata() throws {
        let db = Database()
        try db.connect()

        let monitor = AgentMonitor(database: db)
        let session = try monitor.startSession(agentName: "Claude Code")

        let taskId = UUID()
        let metadata = ["taskTitle": "Test Task", "priority": "high"]

        try monitor.logActivity(
            sessionId: session.id,
            agentName: "Claude Code",
            activityType: .created,
            resourceType: .task,
            resourceId: taskId,
            description: "Created a high-priority task",
            metadata: metadata
        )

        let activities = try monitor.listActivities(sessionId: session.id)
        XCTAssertEqual(activities.count, 1)

        let activity = activities[0]
        XCTAssertEqual(activity.resourceId, taskId)
        XCTAssertEqual(activity.description, "Created a high-priority task")
        XCTAssertEqual(activity.metadata?["taskTitle"], "Test Task")
        XCTAssertEqual(activity.metadata?["priority"], "high")
    }
}
