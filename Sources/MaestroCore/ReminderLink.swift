import Foundation
import GRDB

/// Link between a Maestro space and an EventKit reminder
public struct ReminderLink: Codable {
    public var id: UUID
    public var spaceId: UUID
    public var reminderId: String
    public var reminderTitle: String
    public var reminderListId: String
    public var reminderListName: String
    public var isCompleted: Bool
    public var dueDate: Date?
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        spaceId: UUID,
        reminderId: String,
        reminderTitle: String,
        reminderListId: String,
        reminderListName: String,
        isCompleted: Bool = false,
        dueDate: Date? = nil
    ) {
        self.id = id
        self.spaceId = spaceId
        self.reminderId = reminderId
        self.reminderTitle = reminderTitle
        self.reminderListId = reminderListId
        self.reminderListName = reminderListName
        self.isCompleted = isCompleted
        self.dueDate = dueDate
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

extension ReminderLink: FetchableRecord, PersistableRecord {
    public static let databaseTableName = "reminder_space_links"

    enum Columns: String, ColumnExpression {
        case id
        case spaceId = "space_id"
        case reminderId = "reminder_id"
        case reminderTitle = "reminder_title"
        case reminderListId = "reminder_list_id"
        case reminderListName = "reminder_list_name"
        case isCompleted = "is_completed"
        case dueDate = "due_date"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    public init(row: Row) throws {
        id = UUID(uuidString: row[Columns.id]) ?? UUID()
        spaceId = UUID(uuidString: row[Columns.spaceId]) ?? UUID()
        reminderId = row[Columns.reminderId]
        reminderTitle = row[Columns.reminderTitle]
        reminderListId = row[Columns.reminderListId]
        reminderListName = row[Columns.reminderListName]
        isCompleted = row[Columns.isCompleted]

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
    }

    public func encode(to container: inout PersistenceContainer) throws {
        container[Columns.id] = id.uuidString
        container[Columns.spaceId] = spaceId.uuidString
        container[Columns.reminderId] = reminderId
        container[Columns.reminderTitle] = reminderTitle
        container[Columns.reminderListId] = reminderListId
        container[Columns.reminderListName] = reminderListName
        container[Columns.isCompleted] = isCompleted
        container[Columns.dueDate] = dueDate.map { ISO8601DateFormatter().string(from: $0) }
        container[Columns.createdAt] = ISO8601DateFormatter().string(from: createdAt)
        container[Columns.updatedAt] = ISO8601DateFormatter().string(from: updatedAt)
    }
}
