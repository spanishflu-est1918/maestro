import Foundation
import GRDB

/// Agent Session Model
/// Tracks work sessions for AI agents (Claude Code, Codex, etc.)
public struct AgentSession: Codable {
    public let id: UUID
    public let agentName: String
    public let startedAt: Date
    public var endedAt: Date?
    public var totalActivities: Int
    public var tasksCreated: Int
    public var tasksUpdated: Int
    public var tasksCompleted: Int
    public var spacesCreated: Int
    public var documentsCreated: Int
    public var metadata: [String: String]?

    public init(
        id: UUID = UUID(),
        agentName: String,
        startedAt: Date = Date(),
        endedAt: Date? = nil,
        totalActivities: Int = 0,
        tasksCreated: Int = 0,
        tasksUpdated: Int = 0,
        tasksCompleted: Int = 0,
        spacesCreated: Int = 0,
        documentsCreated: Int = 0,
        metadata: [String: String]? = nil
    ) {
        self.id = id
        self.agentName = agentName
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.totalActivities = totalActivities
        self.tasksCreated = tasksCreated
        self.tasksUpdated = tasksUpdated
        self.tasksCompleted = tasksCompleted
        self.spacesCreated = spacesCreated
        self.documentsCreated = documentsCreated
        self.metadata = metadata
    }

    /// Duration of the session in seconds
    public var duration: TimeInterval? {
        guard let endedAt = endedAt else { return nil }
        return endedAt.timeIntervalSince(startedAt)
    }

    /// Whether the session is currently active
    public var isActive: Bool {
        return endedAt == nil
    }
}

// MARK: - GRDB Integration

extension AgentSession: FetchableRecord, PersistableRecord {
    public static let databaseTableName = "agent_sessions"

    enum Columns: String, ColumnExpression {
        case id
        case agentName = "agent_name"
        case startedAt = "started_at"
        case endedAt = "ended_at"
        case totalActivities = "total_activities"
        case tasksCreated = "tasks_created"
        case tasksUpdated = "tasks_updated"
        case tasksCompleted = "tasks_completed"
        case spacesCreated = "spaces_created"
        case documentsCreated = "documents_created"
        case metadata
    }

    public init(row: Row) throws {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        id = UUID(uuidString: row[Columns.id]) ?? UUID()
        agentName = row[Columns.agentName]

        if let startedAtString: String = row[Columns.startedAt] {
            startedAt = dateFormatter.date(from: startedAtString) ?? Date()
        } else {
            startedAt = Date()
        }

        if let endedAtString: String = row[Columns.endedAt] {
            endedAt = dateFormatter.date(from: endedAtString)
        } else {
            endedAt = nil
        }

        totalActivities = row[Columns.totalActivities]
        tasksCreated = row[Columns.tasksCreated]
        tasksUpdated = row[Columns.tasksUpdated]
        tasksCompleted = row[Columns.tasksCompleted]
        spacesCreated = row[Columns.spacesCreated]
        documentsCreated = row[Columns.documentsCreated]

        if let metadataString: String = row[Columns.metadata],
           let data = metadataString.data(using: .utf8),
           let dict = try? JSONDecoder().decode([String: String].self, from: data) {
            metadata = dict
        } else {
            metadata = nil
        }
    }

    public func encode(to container: inout PersistenceContainer) throws {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        container[Columns.id] = id.uuidString
        container[Columns.agentName] = agentName
        container[Columns.startedAt] = dateFormatter.string(from: startedAt)

        if let endedAt = endedAt {
            container[Columns.endedAt] = dateFormatter.string(from: endedAt)
        }

        container[Columns.totalActivities] = totalActivities
        container[Columns.tasksCreated] = tasksCreated
        container[Columns.tasksUpdated] = tasksUpdated
        container[Columns.tasksCompleted] = tasksCompleted
        container[Columns.spacesCreated] = spacesCreated
        container[Columns.documentsCreated] = documentsCreated

        if let metadata = metadata,
           let data = try? JSONEncoder().encode(metadata),
           let string = String(data: data, encoding: .utf8) {
            container[Columns.metadata] = string
        }
    }
}
