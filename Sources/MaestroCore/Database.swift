import Foundation
import GRDB

/// Database connection manager using GRDB
/// Handles SQLite connection lifecycle, transactions, migrations, and error handling
public class Database {
    private var dbQueue: DatabaseQueue?
    private let path: String
    private var migrator = DatabaseMigrator()

    public enum DatabaseError: Error, LocalizedError {
        case notConnected
        case connectionFailed(String)
        case transactionFailed(String)
        case queryFailed(String)

        public var errorDescription: String? {
            switch self {
            case .notConnected:
                return "Database is not connected"
            case .connectionFailed(let msg):
                return "Failed to connect to database: \(msg)"
            case .transactionFailed(let msg):
                return "Transaction failed: \(msg)"
            case .queryFailed(let msg):
                return "Query failed: \(msg)"
            }
        }
    }

    // MARK: - Initialization

    /// Initialize database with file path
    /// - Parameter path: Path to SQLite database file (use ":memory:" for in-memory)
    public init(path: String) {
        // Expand tilde in path
        self.path = path == ":memory:" ? path : (path as NSString).expandingTildeInPath
        setupMigrations()
    }

    /// Initialize with in-memory database
    public convenience init() {
        self.init(path: ":memory:")
    }

    // MARK: - Migrations

    /// Register all database migrations
    /// Migrations are applied in order and tracked automatically by GRDB
    private func setupMigrations() {
        // v1: Initial schema - spaces, tasks, documents
        migrator.registerMigration("v1") { db in
            // Spaces table
            try db.execute(sql: """
                CREATE TABLE spaces (
                    id TEXT PRIMARY KEY NOT NULL,
                    name TEXT NOT NULL,
                    path TEXT,
                    color TEXT NOT NULL,
                    parent_id TEXT,
                    tags TEXT NOT NULL DEFAULT '[]',
                    archived INTEGER NOT NULL DEFAULT 0,
                    track_focus INTEGER NOT NULL DEFAULT 0,
                    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
                    last_active_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
                    total_focus_time INTEGER NOT NULL DEFAULT 0,
                    FOREIGN KEY (parent_id) REFERENCES spaces(id) ON DELETE CASCADE
                )
            """)

            // Create index on path for space inference
            try db.execute(sql: """
                CREATE INDEX idx_spaces_path ON spaces(path) WHERE path IS NOT NULL
            """)

            // Create index on parent_id for hierarchy queries
            try db.execute(sql: """
                CREATE INDEX idx_spaces_parent_id ON spaces(parent_id) WHERE parent_id IS NOT NULL
            """)

            // Documents table
            try db.execute(sql: """
                CREATE TABLE documents (
                    id TEXT PRIMARY KEY NOT NULL,
                    space_id TEXT NOT NULL,
                    title TEXT NOT NULL,
                    content TEXT NOT NULL DEFAULT '',
                    path TEXT NOT NULL DEFAULT '/',
                    is_default INTEGER NOT NULL DEFAULT 0,
                    is_pinned INTEGER NOT NULL DEFAULT 0,
                    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
                    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (space_id) REFERENCES spaces(id) ON DELETE CASCADE
                )
            """)

            // Create index on space_id for document queries
            try db.execute(sql: """
                CREATE INDEX idx_documents_space_id ON documents(space_id)
            """)

            // Tasks table
            try db.execute(sql: """
                CREATE TABLE tasks (
                    id TEXT PRIMARY KEY NOT NULL,
                    space_id TEXT NOT NULL,
                    title TEXT NOT NULL,
                    description TEXT,
                    status TEXT NOT NULL DEFAULT 'inbox',
                    priority TEXT NOT NULL DEFAULT 'none',
                    position INTEGER NOT NULL DEFAULT 0,
                    due_date TEXT,
                    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
                    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
                    completed_at TEXT,
                    FOREIGN KEY (space_id) REFERENCES spaces(id) ON DELETE CASCADE,
                    CHECK (status IN ('inbox', 'todo', 'inProgress', 'done', 'archived')),
                    CHECK (priority IN ('none', 'low', 'medium', 'high', 'urgent'))
                )
            """)

            // Create index on space_id for task queries
            try db.execute(sql: """
                CREATE INDEX idx_tasks_space_id ON tasks(space_id)
            """)

            // Create index on status for filtering
            try db.execute(sql: """
                CREATE INDEX idx_tasks_status ON tasks(status)
            """)

            // Create composite index for surfacing algorithm (status + priority + position)
            try db.execute(sql: """
                CREATE INDEX idx_tasks_surfacing ON tasks(status, priority, position)
            """)
        }

        // v2: EventKit integration - reminder_space_links table
        migrator.registerMigration("v2") { db in
            try db.execute(sql: """
                CREATE TABLE reminder_space_links (
                    id TEXT PRIMARY KEY NOT NULL,
                    space_id TEXT NOT NULL,
                    reminder_id TEXT NOT NULL,
                    reminder_title TEXT NOT NULL,
                    reminder_list_id TEXT NOT NULL,
                    reminder_list_name TEXT NOT NULL,
                    is_completed INTEGER NOT NULL DEFAULT 0,
                    due_date TEXT,
                    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
                    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (space_id) REFERENCES spaces(id) ON DELETE CASCADE,
                    UNIQUE(reminder_id)
                )
            """)

            // Create index on space_id for quick lookup
            try db.execute(sql: """
                CREATE INDEX idx_reminder_links_space_id ON reminder_space_links(space_id)
            """)

            // Create index on reminder_id for reverse lookup
            try db.execute(sql: """
                CREATE INDEX idx_reminder_links_reminder_id ON reminder_space_links(reminder_id)
            """)
        }

        // v3: Linear integration - linear_sync table
        migrator.registerMigration("v3") { db in
            try db.execute(sql: """
                CREATE TABLE linear_sync (
                    id TEXT PRIMARY KEY NOT NULL,
                    task_id TEXT NOT NULL,
                    linear_issue_id TEXT NOT NULL,
                    linear_issue_key TEXT NOT NULL,
                    linear_team_id TEXT NOT NULL,
                    linear_state TEXT NOT NULL,
                    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
                    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE,
                    UNIQUE(linear_issue_id)
                )
            """)

            // Create index on task_id for quick lookup
            try db.execute(sql: """
                CREATE INDEX idx_linear_sync_task_id ON linear_sync(task_id)
            """)

            // Create index on linear_issue_id for reverse lookup
            try db.execute(sql: """
                CREATE INDEX idx_linear_sync_linear_issue_id ON linear_sync(linear_issue_id)
            """)
        }

        // v4: Agent monitoring - agent activity and sessions
        migrator.registerMigration("v4") { db in
            // Agent sessions table - tracks agent work sessions
            try db.execute(sql: """
                CREATE TABLE agent_sessions (
                    id TEXT PRIMARY KEY NOT NULL,
                    agent_name TEXT NOT NULL,
                    started_at TEXT NOT NULL,
                    ended_at TEXT,
                    total_activities INTEGER NOT NULL DEFAULT 0,
                    tasks_created INTEGER NOT NULL DEFAULT 0,
                    tasks_updated INTEGER NOT NULL DEFAULT 0,
                    tasks_completed INTEGER NOT NULL DEFAULT 0,
                    spaces_created INTEGER NOT NULL DEFAULT 0,
                    documents_created INTEGER NOT NULL DEFAULT 0,
                    metadata TEXT
                )
            """)

            // Agent activity table - detailed activity log
            try db.execute(sql: """
                CREATE TABLE agent_activity (
                    id TEXT PRIMARY KEY NOT NULL,
                    session_id TEXT NOT NULL,
                    agent_name TEXT NOT NULL,
                    activity_type TEXT NOT NULL,
                    resource_type TEXT NOT NULL,
                    resource_id TEXT,
                    description TEXT,
                    metadata TEXT,
                    timestamp TEXT NOT NULL,
                    FOREIGN KEY (session_id) REFERENCES agent_sessions(id) ON DELETE CASCADE
                )
            """)

            // Create indexes for efficient queries
            try db.execute(sql: """
                CREATE INDEX idx_agent_sessions_agent_name ON agent_sessions(agent_name)
            """)

            try db.execute(sql: """
                CREATE INDEX idx_agent_sessions_started_at ON agent_sessions(started_at)
            """)

            try db.execute(sql: """
                CREATE INDEX idx_agent_activity_session_id ON agent_activity(session_id)
            """)

            try db.execute(sql: """
                CREATE INDEX idx_agent_activity_agent_name ON agent_activity(agent_name)
            """)

            try db.execute(sql: """
                CREATE INDEX idx_agent_activity_resource ON agent_activity(resource_type, resource_id)
            """)

            try db.execute(sql: """
                CREATE INDEX idx_agent_activity_timestamp ON agent_activity(timestamp)
            """)
        }
    }

    // MARK: - Connection Management

    /// Open database connection and run migrations
    /// - Throws: DatabaseError.connectionFailed if connection fails
    public func connect() throws {
        do {
            if path == ":memory:" {
                dbQueue = try DatabaseQueue()
            } else {
                // Ensure parent directory exists
                let url = URL(fileURLWithPath: path)
                let directory = url.deletingLastPathComponent()
                try FileManager.default.createDirectory(
                    at: directory,
                    withIntermediateDirectories: true
                )

                dbQueue = try DatabaseQueue(path: path)
            }

            guard let queue = dbQueue else {
                throw DatabaseError.connectionFailed("Failed to create database queue")
            }

            // Enable foreign keys
            try queue.write { db in
                try db.execute(sql: "PRAGMA foreign_keys = ON")
            }

            // Run migrations
            try migrator.migrate(queue)

            print("✓ Database connected: \(path)")
        } catch {
            throw DatabaseError.connectionFailed(error.localizedDescription)
        }
    }

    /// Close database connection
    public func close() {
        dbQueue = nil
        print("✓ Database closed")
    }

    /// Reconnect to database
    public func reconnect() throws {
        close()
        try connect()
    }

    /// Get current database queue
    /// - Throws: DatabaseError.notConnected if not connected
    public func getQueue() throws -> DatabaseQueue {
        guard let queue = dbQueue else {
            throw DatabaseError.notConnected
        }
        return queue
    }

    /// Check if database is connected
    public var isConnected: Bool {
        return dbQueue != nil
    }

    // MARK: - Transactions

    /// Execute a block of code within a transaction
    /// - Parameter block: Code to execute within transaction (receives GRDB.Database)
    /// - Throws: DatabaseError.transactionFailed or errors from block
    public func transaction(_ block: @escaping (GRDB.Database) throws -> Void) throws {
        let queue = try getQueue()

        do {
            // queue.write already starts a transaction
            try queue.write { db in
                try block(db)
            }
        } catch {
            throw DatabaseError.transactionFailed(error.localizedDescription)
        }
    }

    // MARK: - Query Execution

    /// Execute raw SQL (for migrations, schema changes)
    /// - Parameter sql: SQL statement to execute
    /// - Throws: DatabaseError.queryFailed if execution fails
    public func execute(_ sql: String) throws {
        let queue = try getQueue()

        do {
            try queue.write { db in
                try db.execute(sql: sql)
            }
        } catch {
            throw DatabaseError.queryFailed(error.localizedDescription)
        }
    }

    /// Execute a read query and return a single scalar value
    /// - Parameter sql: SQL query that returns a single value
    /// - Returns: The scalar value, or nil if no result
    public func scalar(_ sql: String) throws -> DatabaseValue? {
        let queue = try getQueue()

        do {
            return try queue.read { db in
                try DatabaseValue.fetchOne(db, sql: sql)
            }
        } catch {
            throw DatabaseError.queryFailed(error.localizedDescription)
        }
    }

    /// Execute a write operation with direct database access
    /// - Parameter block: Code to execute with database access
    public func write<T>(_ block: @escaping (GRDB.Database) throws -> T) throws -> T {
        let queue = try getQueue()
        return try queue.write(block)
    }

    /// Execute a read operation with direct database access
    /// - Parameter block: Code to execute with database access
    public func read<T>(_ block: @escaping (GRDB.Database) throws -> T) throws -> T {
        let queue = try getQueue()
        return try queue.read(block)
    }
}
