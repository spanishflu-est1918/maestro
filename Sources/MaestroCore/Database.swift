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
        self.path = path
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
