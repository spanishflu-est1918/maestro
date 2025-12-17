import Foundation
import GRDB

/// Database connection manager using GRDB
/// Handles SQLite connection lifecycle, transactions, and error handling
public class Database {
    private var dbQueue: DatabaseQueue?
    private let path: String

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
    }

    /// Initialize with in-memory database
    public convenience init() {
        self.init(path: ":memory:")
    }

    // MARK: - Connection Management

    /// Open database connection
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

            // Enable foreign keys
            try dbQueue?.write { db in
                try db.execute(sql: "PRAGMA foreign_keys = ON")
            }

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
