import Foundation
import GRDB

/// Agent Monitoring Service
/// Tracks AI agent sessions and activities
public class AgentMonitor {
    private let db: Database

    public init(database: Database) {
        self.db = database
    }

    // MARK: - Session Management

    /// Start a new agent session
    public func startSession(agentName: String, metadata: [String: String]? = nil) throws -> AgentSession {
        let session = AgentSession(
            agentName: agentName,
            metadata: metadata
        )

        try db.write { db in
            try session.insert(db)
        }

        return session
    }

    /// End an active session
    public func endSession(_ sessionId: UUID) throws {
        try db.write { db in
            if var session = try AgentSession.fetchOne(db, key: sessionId.uuidString) {
                session.endedAt = Date()
                try session.update(db)
            }
        }
    }

    /// Get an active session for an agent, or create one if none exists
    public func getOrCreateSession(agentName: String) throws -> AgentSession {
        // Try to find an active session
        if let activeSession = try getActiveSession(agentName: agentName) {
            return activeSession
        }

        // No active session, create a new one
        return try startSession(agentName: agentName)
    }

    /// Get active session for an agent
    public func getActiveSession(agentName: String) throws -> AgentSession? {
        return try db.read { db in
            try AgentSession.all()
                .filter(AgentSession.Columns.agentName == agentName)
                .filter(AgentSession.Columns.endedAt == nil)
                .order(AgentSession.Columns.startedAt.desc)
                .fetchOne(db)
        }
    }

    /// Get session by ID
    public func getSession(_ sessionId: UUID) throws -> AgentSession? {
        return try db.read { db in
            try AgentSession.fetchOne(db, key: sessionId.uuidString)
        }
    }

    /// List all sessions for an agent
    public func listSessions(
        agentName: String? = nil,
        limit: Int = 50,
        activeOnly: Bool = false
    ) throws -> [AgentSession] {
        return try db.read { db in
            var request = AgentSession.all()

            if let agentName = agentName {
                request = request.filter(AgentSession.Columns.agentName == agentName)
            }

            if activeOnly {
                request = request.filter(AgentSession.Columns.endedAt == nil)
            }

            return try request
                .order(AgentSession.Columns.startedAt.desc)
                .limit(limit)
                .fetchAll(db)
        }
    }

    // MARK: - Activity Logging

    /// Log an activity for an agent
    public func logActivity(
        sessionId: UUID,
        agentName: String,
        activityType: AgentActivity.ActivityType,
        resourceType: AgentActivity.ResourceType,
        resourceId: UUID? = nil,
        description: String? = nil,
        metadata: [String: String]? = nil
    ) throws {
        let activity = AgentActivity(
            sessionId: sessionId,
            agentName: agentName,
            activityType: activityType,
            resourceType: resourceType,
            resourceId: resourceId,
            description: description,
            metadata: metadata
        )

        try db.write { db in
            // Insert activity
            try activity.insert(db)

            // Update session counters
            if var session = try AgentSession.fetchOne(db, key: sessionId.uuidString) {
                session.totalActivities += 1

                // Update specific counters based on activity type
                switch activityType {
                case .created:
                    switch resourceType {
                    case .task:
                        session.tasksCreated += 1
                    case .space:
                        session.spacesCreated += 1
                    case .document:
                        session.documentsCreated += 1
                    default:
                        break
                    }
                case .updated:
                    if resourceType == .task {
                        session.tasksUpdated += 1
                    }
                case .completed:
                    if resourceType == .task {
                        session.tasksCompleted += 1
                    }
                default:
                    break
                }

                try session.update(db)
            }
        }
    }

    /// List activities for a session
    public func listActivities(
        sessionId: UUID? = nil,
        agentName: String? = nil,
        activityType: AgentActivity.ActivityType? = nil,
        resourceType: AgentActivity.ResourceType? = nil,
        limit: Int = 100
    ) throws -> [AgentActivity] {
        return try db.read { db in
            var request = AgentActivity.all()

            if let sessionId = sessionId {
                request = request.filter(AgentActivity.Columns.sessionId == sessionId.uuidString)
            }

            if let agentName = agentName {
                request = request.filter(AgentActivity.Columns.agentName == agentName)
            }

            if let activityType = activityType {
                request = request.filter(AgentActivity.Columns.activityType == activityType.rawValue)
            }

            if let resourceType = resourceType {
                request = request.filter(AgentActivity.Columns.resourceType == resourceType.rawValue)
            }

            return try request
                .order(AgentActivity.Columns.timestamp.desc)
                .limit(limit)
                .fetchAll(db)
        }
    }

    // MARK: - Analytics

    /// Get performance metrics for an agent
    public func getMetrics(agentName: String) throws -> AgentMetrics {
        let sessions = try listSessions(agentName: agentName, limit: 1000)

        let totalSessions = sessions.count
        let activeSessions = sessions.filter { $0.isActive }.count
        let completedSessions = sessions.filter { !$0.isActive }

        let totalDuration = completedSessions.compactMap { $0.duration }.reduce(0, +)
        let avgDuration = completedSessions.isEmpty ? 0 : totalDuration / Double(completedSessions.count)

        let totalActivities = sessions.reduce(0) { $0 + $1.totalActivities }

        return AgentMetrics(
            agentName: agentName,
            totalSessions: totalSessions,
            activeSessions: activeSessions,
            totalActivities: totalActivities,
            tasksCreated: sessions.reduce(0) { $0 + $1.tasksCreated },
            tasksUpdated: sessions.reduce(0) { $0 + $1.tasksUpdated },
            tasksCompleted: sessions.reduce(0) { $0 + $1.tasksCompleted },
            spacesCreated: sessions.reduce(0) { $0 + $1.spacesCreated },
            documentsCreated: sessions.reduce(0) { $0 + $1.documentsCreated },
            averageSessionDuration: avgDuration,
            totalWorkTime: totalDuration
        )
    }

    /// Delete old activities and sessions
    public func cleanupOldData(olderThan days: Int) throws {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let cutoffString = dateFormatter.string(from: cutoffDate)

        try db.write { db in
            // Delete old sessions (cascade will delete activities)
            try db.execute(sql: """
                DELETE FROM agent_sessions
                WHERE ended_at IS NOT NULL
                AND ended_at < ?
            """, arguments: [cutoffString])
        }
    }
}

// MARK: - Metrics Model

public struct AgentMetrics: Codable {
    public let agentName: String
    public let totalSessions: Int
    public let activeSessions: Int
    public let totalActivities: Int
    public let tasksCreated: Int
    public let tasksUpdated: Int
    public let tasksCompleted: Int
    public let spacesCreated: Int
    public let documentsCreated: Int
    public let averageSessionDuration: TimeInterval
    public let totalWorkTime: TimeInterval

    public var averageActivitiesPerSession: Double {
        totalSessions > 0 ? Double(totalActivities) / Double(totalSessions) : 0
    }

    public var tasksPerSession: Double {
        let totalTaskActions = tasksCreated + tasksUpdated + tasksCompleted
        return totalSessions > 0 ? Double(totalTaskActions) / Double(totalSessions) : 0
    }
}

// MARK: - Error Handling

public enum AgentMonitorError: Error, LocalizedError {
    case sessionNotFound
    case invalidSession

    public var errorDescription: String? {
        switch self {
        case .sessionNotFound:
            return "Agent session not found"
        case .invalidSession:
            return "Invalid agent session"
        }
    }
}
