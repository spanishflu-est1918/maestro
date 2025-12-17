import Foundation
import GRDB

/// Agent Activity Model
/// Records individual actions performed by AI agents
public struct AgentActivity: Codable {
    public let id: UUID
    public let sessionId: UUID
    public let agentName: String
    public let activityType: ActivityType
    public let resourceType: ResourceType
    public let resourceId: UUID?
    public let description: String?
    public let metadata: [String: String]?
    public let timestamp: Date

    public init(
        id: UUID = UUID(),
        sessionId: UUID,
        agentName: String,
        activityType: ActivityType,
        resourceType: ResourceType,
        resourceId: UUID? = nil,
        description: String? = nil,
        metadata: [String: String]? = nil,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.sessionId = sessionId
        self.agentName = agentName
        self.activityType = activityType
        self.resourceType = resourceType
        self.resourceId = resourceId
        self.description = description
        self.metadata = metadata
        self.timestamp = timestamp
    }
}

// MARK: - Enums

public extension AgentActivity {
    enum ActivityType: String, Codable {
        case created
        case updated
        case completed
        case archived
        case deleted
        case viewed
        case searched
        case synced
        case other
    }

    enum ResourceType: String, Codable {
        case task
        case space
        case document
        case reminder
        case linearIssue = "linear_issue"
        case session
        case other
    }
}

// MARK: - GRDB Integration

extension AgentActivity: FetchableRecord, PersistableRecord {
    public static let databaseTableName = "agent_activity"

    enum Columns: String, ColumnExpression {
        case id
        case sessionId = "session_id"
        case agentName = "agent_name"
        case activityType = "activity_type"
        case resourceType = "resource_type"
        case resourceId = "resource_id"
        case description
        case metadata
        case timestamp
    }

    public init(row: Row) throws {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        id = UUID(uuidString: row[Columns.id]) ?? UUID()
        sessionId = UUID(uuidString: row[Columns.sessionId]) ?? UUID()
        agentName = row[Columns.agentName]

        if let activityTypeString: String = row[Columns.activityType] {
            activityType = ActivityType(rawValue: activityTypeString) ?? .other
        } else {
            activityType = .other
        }

        if let resourceTypeString: String = row[Columns.resourceType] {
            resourceType = ResourceType(rawValue: resourceTypeString) ?? .other
        } else {
            resourceType = .other
        }

        if let resourceIdString: String = row[Columns.resourceId] {
            resourceId = UUID(uuidString: resourceIdString)
        } else {
            resourceId = nil
        }

        description = row[Columns.description]

        if let metadataString: String = row[Columns.metadata],
           let data = metadataString.data(using: .utf8),
           let dict = try? JSONDecoder().decode([String: String].self, from: data) {
            metadata = dict
        } else {
            metadata = nil
        }

        if let timestampString: String = row[Columns.timestamp] {
            timestamp = dateFormatter.date(from: timestampString) ?? Date()
        } else {
            timestamp = Date()
        }
    }

    public func encode(to container: inout PersistenceContainer) throws {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        container[Columns.id] = id.uuidString
        container[Columns.sessionId] = sessionId.uuidString
        container[Columns.agentName] = agentName
        container[Columns.activityType] = activityType.rawValue
        container[Columns.resourceType] = resourceType.rawValue

        if let resourceId = resourceId {
            container[Columns.resourceId] = resourceId.uuidString
        }

        container[Columns.description] = description
        container[Columns.timestamp] = dateFormatter.string(from: timestamp)

        if let metadata = metadata,
           let data = try? JSONEncoder().encode(metadata),
           let string = String(data: data, encoding: .utf8) {
            container[Columns.metadata] = string
        }
    }
}
