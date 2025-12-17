import Foundation
import GRDB

/// A document within a space
public struct Document: Codable {
    public let id: UUID
    public var spaceId: UUID
    public var title: String
    public var content: String
    public var path: String
    public var isDefault: Bool
    public var isPinned: Bool
    public var createdAt: Date
    public var updatedAt: Date

    // MARK: - Initialization

    public init(
        id: UUID = UUID(),
        spaceId: UUID,
        title: String,
        content: String = "",
        path: String = "/",
        isDefault: Bool = false,
        isPinned: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.spaceId = spaceId
        self.title = title
        self.content = content
        self.path = path
        self.isDefault = isDefault
        self.isPinned = isPinned
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - GRDB Conformance

extension Document: FetchableRecord, PersistableRecord {
    public static let databaseTableName = "documents"

    enum Columns: String, ColumnExpression {
        case id
        case spaceId = "space_id"
        case title
        case content
        case path
        case isDefault = "is_default"
        case isPinned = "is_pinned"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    public init(row: Row) throws {
        id = UUID(uuidString: row[Columns.id]) ?? UUID()
        spaceId = UUID(uuidString: row[Columns.spaceId]) ?? UUID()
        title = row[Columns.title]
        content = row[Columns.content]
        path = row[Columns.path]
        isDefault = row[Columns.isDefault]
        isPinned = row[Columns.isPinned]

        // Parse ISO8601 dates
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
        container[Columns.title] = title
        container[Columns.content] = content
        container[Columns.path] = path
        container[Columns.isDefault] = isDefault
        container[Columns.isPinned] = isPinned

        // Format dates as ISO8601
        container[Columns.createdAt] = ISO8601DateFormatter().string(from: createdAt)
        container[Columns.updatedAt] = ISO8601DateFormatter().string(from: updatedAt)
    }
}

// MARK: - Identifiable

extension Document: Identifiable {}

// MARK: - Equatable

extension Document: Equatable {
    public static func == (lhs: Document, rhs: Document) -> Bool {
        return lhs.id == rhs.id
    }
}
