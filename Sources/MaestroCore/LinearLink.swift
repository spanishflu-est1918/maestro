import Foundation
import GRDB

/// Link between a Maestro task and a Linear issue
public struct LinearLink: Codable {
    public var id: UUID
    public var taskId: UUID
    public var linearIssueId: String
    public var linearIssueKey: String
    public var linearTeamId: String
    public var linearState: String
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        taskId: UUID,
        linearIssueId: String,
        linearIssueKey: String,
        linearTeamId: String,
        linearState: String
    ) {
        self.id = id
        self.taskId = taskId
        self.linearIssueId = linearIssueId
        self.linearIssueKey = linearIssueKey
        self.linearTeamId = linearTeamId
        self.linearState = linearState
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

extension LinearLink: FetchableRecord, PersistableRecord {
    public static let databaseTableName = "linear_sync"

    enum Columns: String, ColumnExpression {
        case id
        case taskId = "task_id"
        case linearIssueId = "linear_issue_id"
        case linearIssueKey = "linear_issue_key"
        case linearTeamId = "linear_team_id"
        case linearState = "linear_state"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    public init(row: Row) throws {
        id = UUID(uuidString: row[Columns.id]) ?? UUID()
        taskId = UUID(uuidString: row[Columns.taskId]) ?? UUID()
        linearIssueId = row[Columns.linearIssueId]
        linearIssueKey = row[Columns.linearIssueKey]
        linearTeamId = row[Columns.linearTeamId]
        linearState = row[Columns.linearState]

        if let createdAtString: String = row[Columns.createdAt],
           let date = ISO8601DateFormatter().date(from: createdAtString) {
            createdAt = date
        } else {
            createdAt = Date()
        }

        if let updatedAtString: String = row[Columns.updatedAt],
           let date = ISO8601DateFormatter().date(from: updatedAtString) {
            updatedAt = date
        } else {
            updatedAt = Date()
        }
    }

    public func encode(to container: inout PersistenceContainer) throws {
        container[Columns.id] = id.uuidString
        container[Columns.taskId] = taskId.uuidString
        container[Columns.linearIssueId] = linearIssueId
        container[Columns.linearIssueKey] = linearIssueKey
        container[Columns.linearTeamId] = linearTeamId
        container[Columns.linearState] = linearState
        container[Columns.createdAt] = ISO8601DateFormatter().string(from: createdAt)
        container[Columns.updatedAt] = ISO8601DateFormatter().string(from: updatedAt)
    }
}
