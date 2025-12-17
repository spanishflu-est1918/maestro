import Foundation
import GRDB

/// Task status enum
public enum TaskStatus: String, Codable, DatabaseValueConvertible {
    case inbox
    case todo
    case inProgress
    case done
    case archived
}

/// Task priority enum
public enum TaskPriority: String, Codable, DatabaseValueConvertible {
    case none
    case low
    case medium
    case high
    case urgent
}

/// A task within a space
public struct Task: Codable {
    public let id: UUID
    public var spaceId: UUID
    public var title: String
    public var description: String?
    public var status: TaskStatus
    public var priority: TaskPriority
    public var position: Int
    public var dueDate: Date?
    public var createdAt: Date
    public var updatedAt: Date
    public var completedAt: Date?

    // MARK: - Initialization

    public init(
        id: UUID = UUID(),
        spaceId: UUID,
        title: String,
        description: String? = nil,
        status: TaskStatus = .inbox,
        priority: TaskPriority = .none,
        position: Int = 0,
        dueDate: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        completedAt: Date? = nil
    ) {
        self.id = id
        self.spaceId = spaceId
        self.title = title
        self.description = description
        self.status = status
        self.priority = priority
        self.position = position
        self.dueDate = dueDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.completedAt = completedAt
    }
}

// MARK: - GRDB Conformance

extension Task: FetchableRecord, PersistableRecord {
    public static let databaseTableName = "tasks"

    enum Columns: String, ColumnExpression {
        case id
        case spaceId = "space_id"
        case title
        case description
        case status
        case priority
        case position
        case dueDate = "due_date"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case completedAt = "completed_at"
    }

    public init(row: Row) throws {
        id = UUID(uuidString: row[Columns.id]) ?? UUID()
        spaceId = UUID(uuidString: row[Columns.spaceId]) ?? UUID()
        title = row[Columns.title]
        description = row[Columns.description]
        status = TaskStatus(rawValue: row[Columns.status]) ?? .inbox
        priority = TaskPriority(rawValue: row[Columns.priority]) ?? .none
        position = row[Columns.position]

        // Parse dates
        if let dueDateString: String = row[Columns.dueDate],
           let date = ISO8601DateFormatter().date(from: dueDateString) {
            dueDate = date
        } else {
            dueDate = nil
        }

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

        if let completedAtString: String = row[Columns.completedAt],
           let date = ISO8601DateFormatter().date(from: completedAtString) {
            completedAt = date
        } else {
            completedAt = nil
        }
    }

    public func encode(to container: inout PersistenceContainer) throws {
        container[Columns.id] = id.uuidString
        container[Columns.spaceId] = spaceId.uuidString
        container[Columns.title] = title
        container[Columns.description] = description
        container[Columns.status] = status.rawValue
        container[Columns.priority] = priority.rawValue
        container[Columns.position] = position

        if let dueDate = dueDate {
            container[Columns.dueDate] = ISO8601DateFormatter().string(from: dueDate)
        } else {
            container[Columns.dueDate] = nil
        }

        container[Columns.createdAt] = ISO8601DateFormatter().string(from: createdAt)
        container[Columns.updatedAt] = ISO8601DateFormatter().string(from: updatedAt)

        if let completedAt = completedAt {
            container[Columns.completedAt] = ISO8601DateFormatter().string(from: completedAt)
        } else {
            container[Columns.completedAt] = nil
        }
    }
}

// MARK: - Identifiable

extension Task: Identifiable {}

// MARK: - Equatable

extension Task: Equatable {
    public static func == (lhs: Task, rhs: Task) -> Bool {
        return lhs.id == rhs.id
    }
}
