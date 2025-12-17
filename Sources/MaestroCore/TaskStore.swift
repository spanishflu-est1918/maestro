import Foundation
import GRDB

/// Store for managing Task CRUD operations
public class TaskStore {
    private let db: Database

    public enum TaskStoreError: Error, LocalizedError {
        case taskNotFound(UUID)
        case invalidData(String)

        public var errorDescription: String? {
            switch self {
            case .taskNotFound(let id):
                return "Task not found: \(id)"
            case .invalidData(let msg):
                return "Invalid data: \(msg)"
            }
        }
    }

    // MARK: - Initialization

    public init(database: Database) {
        self.db = database
    }

    // MARK: - Create

    /// Create a new task
    /// - Parameter task: The task to create
    /// - Throws: Database errors
    public func create(_ task: Task) throws {
        try db.write { db in
            try task.insert(db)
        }
    }

    // MARK: - Read

    /// Get a task by ID
    /// - Parameter id: The task ID
    /// - Returns: The task, or nil if not found
    /// - Throws: Database errors
    public func get(_ id: UUID) throws -> Task? {
        return try db.read { db in
            try Task.fetchOne(db, key: id.uuidString)
        }
    }

    /// List all tasks
    /// - Parameters:
    ///   - spaceId: Filter by space ID (nil = all spaces)
    ///   - status: Filter by status (nil = all statuses)
    ///   - includeArchived: Whether to include archived tasks
    /// - Returns: Array of tasks
    /// - Throws: Database errors
    public func list(
        spaceId: UUID? = nil,
        status: TaskStatus? = nil,
        includeArchived: Bool = false
    ) throws -> [Task] {
        return try db.read { db in
            var request = Task.all()

            // Filter by space
            if let spaceId = spaceId {
                request = request.filter(Task.Columns.spaceId == spaceId.uuidString)
            }

            // Filter by status
            if let status = status {
                request = request.filter(Task.Columns.status == status.rawValue)
            }

            // Filter archived
            if !includeArchived {
                request = request.filter(Task.Columns.status != TaskStatus.archived.rawValue)
            }

            return try request
                .order(Task.Columns.updatedAt.desc)
                .fetchAll(db)
        }
    }

    /// Get surfaced tasks (for "what should I work on?" queries)
    /// Uses surfacing algorithm: status → priority → position
    /// - Parameter spaceId: Optional space filter
    /// - Returns: Array of tasks ordered by surfacing priority
    /// - Throws: Database errors
    public func getSurfaced(spaceId: UUID? = nil, limit: Int = 10) throws -> [Task] {
        return try db.read { db in
            var sql = """
                SELECT * FROM tasks
                WHERE status IN ('inbox', 'todo', 'inProgress')
            """

            if let spaceId = spaceId {
                sql += " AND space_id = '\(spaceId.uuidString)'"
            }

            sql += """
                ORDER BY
                    CASE status
                        WHEN 'inProgress' THEN 1
                        WHEN 'todo' THEN 2
                        WHEN 'inbox' THEN 3
                    END,
                    CASE priority
                        WHEN 'urgent' THEN 1
                        WHEN 'high' THEN 2
                        WHEN 'medium' THEN 3
                        WHEN 'low' THEN 4
                        WHEN 'none' THEN 5
                    END,
                    position ASC
                LIMIT \(limit)
            """

            return try Task.fetchAll(db, sql: sql)
        }
    }

    /// Get tasks by status
    /// - Parameters:
    ///   - status: The status to filter by
    ///   - spaceId: Optional space filter
    /// - Returns: Array of tasks with the status
    /// - Throws: Database errors
    public func getByStatus(_ status: TaskStatus, spaceId: UUID? = nil) throws -> [Task] {
        return try list(spaceId: spaceId, status: status)
    }

    /// Get tasks by priority
    /// - Parameters:
    ///   - priority: The priority to filter by
    ///   - spaceId: Optional space filter
    /// - Returns: Array of tasks with the priority
    /// - Throws: Database errors
    public func getByPriority(_ priority: TaskPriority, spaceId: UUID? = nil) throws -> [Task] {
        return try db.read { db in
            var request = Task.all()
                .filter(Task.Columns.priority == priority.rawValue)
                .filter(Task.Columns.status != TaskStatus.archived.rawValue)

            if let spaceId = spaceId {
                request = request.filter(Task.Columns.spaceId == spaceId.uuidString)
            }

            return try request
                .order(Task.Columns.position)
                .fetchAll(db)
        }
    }

    // MARK: - Update

    /// Update a task
    /// - Parameter task: The task with updated values
    /// - Throws: Database errors
    public func update(_ task: Task) throws {
        var updatedTask = task
        updatedTask.updatedAt = Date()
        try db.write { db in
            try updatedTask.update(db)
        }
    }

    /// Update task status
    /// - Parameters:
    ///   - id: The task ID
    ///   - status: The new status
    /// - Throws: TaskStoreError.taskNotFound if task doesn't exist
    public func updateStatus(_ id: UUID, to status: TaskStatus) throws {
        guard var task = try get(id) else {
            throw TaskStoreError.taskNotFound(id)
        }

        task.status = status
        task.updatedAt = Date()

        // Set completedAt when marking as done
        if status == .done && task.completedAt == nil {
            task.completedAt = Date()
        }

        try update(task)
    }

    /// Archive a task
    /// - Parameter id: The task ID
    /// - Throws: TaskStoreError.taskNotFound if task doesn't exist
    public func archive(_ id: UUID) throws {
        try updateStatus(id, to: .archived)
    }

    /// Complete a task (mark as done)
    /// - Parameter id: The task ID
    /// - Throws: TaskStoreError.taskNotFound if task doesn't exist
    public func complete(_ id: UUID) throws {
        try updateStatus(id, to: .done)
    }

    // MARK: - Delete

    /// Delete a task permanently
    /// - Parameter id: The task ID
    /// - Throws: Database errors
    public func delete(_ id: UUID) throws {
        _ = try db.write { db in
            try Task.deleteOne(db, key: id.uuidString)
        }
    }

    /// Delete all tasks (for testing)
    /// - Throws: Database errors
    public func deleteAll() throws {
        _ = try db.write { db in
            try Task.deleteAll(db)
        }
    }
}
