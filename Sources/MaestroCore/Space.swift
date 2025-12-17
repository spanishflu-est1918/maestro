import Foundation
import GRDB

/// A work context or project space with hierarchical organization
public struct Space: Codable {
    public let id: UUID
    public var name: String
    public var path: String?
    public var color: String
    public var parentId: UUID?
    public var tags: [String]
    public var archived: Bool
    public var trackFocus: Bool
    public var createdAt: Date
    public var lastActiveAt: Date
    public var totalFocusTime: Int  // Seconds

    // MARK: - Initialization

    public init(
        id: UUID = UUID(),
        name: String,
        path: String? = nil,
        color: String,
        parentId: UUID? = nil,
        tags: [String] = [],
        archived: Bool = false,
        trackFocus: Bool = false,
        createdAt: Date = Date(),
        lastActiveAt: Date = Date(),
        totalFocusTime: Int = 0
    ) {
        self.id = id
        self.name = name
        self.path = path
        self.color = color
        self.parentId = parentId
        self.tags = tags
        self.archived = archived
        self.trackFocus = trackFocus
        self.createdAt = createdAt
        self.lastActiveAt = lastActiveAt
        self.totalFocusTime = totalFocusTime
    }
}

// MARK: - GRDB Conformance

extension Space: FetchableRecord, PersistableRecord {
    public static let databaseTableName = "spaces"

    // Custom column mapping for snake_case database columns
    enum Columns: String, ColumnExpression {
        case id
        case name
        case path
        case color
        case parentId = "parent_id"
        case tags
        case archived
        case trackFocus = "track_focus"
        case createdAt = "created_at"
        case lastActiveAt = "last_active_at"
        case totalFocusTime = "total_focus_time"
    }

    // Decode from database row
    public init(row: Row) throws {
        id = UUID(uuidString: row[Columns.id]) ?? UUID()
        name = row[Columns.name]
        path = row[Columns.path]
        color = row[Columns.color]

        if let parentIdString: String = row[Columns.parentId] {
            parentId = UUID(uuidString: parentIdString)
        } else {
            parentId = nil
        }

        // Decode tags from JSON string
        let tagsJSON: String = row[Columns.tags]
        if let tagsData = tagsJSON.data(using: .utf8),
           let decodedTags = try? JSONDecoder().decode([String].self, from: tagsData) {
            tags = decodedTags
        } else {
            tags = []
        }

        archived = row[Columns.archived]
        trackFocus = row[Columns.trackFocus]

        // Parse ISO8601 dates
        if let createdAtString: String = row[Columns.createdAt],
           let date = ISO8601DateFormatter().date(from: createdAtString) {
            createdAt = date
        } else {
            createdAt = Date()
        }

        if let lastActiveAtString: String = row[Columns.lastActiveAt],
           let date = ISO8601DateFormatter().date(from: lastActiveAtString) {
            lastActiveAt = date
        } else {
            lastActiveAt = Date()
        }

        totalFocusTime = row[Columns.totalFocusTime]
    }

    // Encode to database row
    public func encode(to container: inout PersistenceContainer) throws {
        container[Columns.id] = id.uuidString
        container[Columns.name] = name
        container[Columns.path] = path
        container[Columns.color] = color
        container[Columns.parentId] = parentId?.uuidString

        // Encode tags to JSON string
        let tagsData = try JSONEncoder().encode(tags)
        container[Columns.tags] = String(data: tagsData, encoding: .utf8) ?? "[]"

        container[Columns.archived] = archived
        container[Columns.trackFocus] = trackFocus

        // Format dates as ISO8601
        container[Columns.createdAt] = ISO8601DateFormatter().string(from: createdAt)
        container[Columns.lastActiveAt] = ISO8601DateFormatter().string(from: lastActiveAt)

        container[Columns.totalFocusTime] = totalFocusTime
    }
}

// MARK: - Identifiable

extension Space: Identifiable {}

// MARK: - Equatable

extension Space: Equatable {
    public static func == (lhs: Space, rhs: Space) -> Bool {
        return lhs.id == rhs.id
    }
}
