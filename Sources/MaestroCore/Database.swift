import Foundation
import SQLite

/// Database connection manager
/// Handles SQLite connection lifecycle, transactions, and error handling
public class Database {
    private var connection: Connection?
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
                connection = try Connection(.inMemory)
            } else {
                // Ensure parent directory exists
                let url = URL(fileURLWithPath: path)
                let directory = url.deletingLastPathComponent()
                try FileManager.default.createDirectory(
                    at: directory,
                    withIntermediateDirectories: true
                )

                connection = try Connection(path)
            }

            // Enable foreign keys
            try connection?.execute("PRAGMA foreign_keys = ON")

            print("✓ Database connected: \(path)")
        } catch {
            throw DatabaseError.connectionFailed(error.localizedDescription)
        }
    }

    /// Close database connection
    public func close() {
        connection = nil
        print("✓ Database closed")
    }

    /// Reconnect to database
    public func reconnect() throws {
        close()
        try connect()
    }

    /// Get current connection
    /// - Throws: DatabaseError.notConnected if not connected
    public func getConnection() throws -> Connection {
        guard let conn = connection else {
            throw DatabaseError.notConnected
        }
        return conn
    }

    /// Check if database is connected
    public var isConnected: Bool {
        return connection != nil
    }

    // MARK: - Transactions

    /// Execute a block of code within a transaction
    /// - Parameter block: Code to execute within transaction
    /// - Throws: DatabaseError.transactionFailed or errors from block
    public func transaction(_ block: () throws -> Void) throws {
        let conn = try getConnection()

        do {
            try conn.transaction {
                try block()
            }
        } catch {
            throw DatabaseError.transactionFailed(error.localizedDescription)
        }
    }

    /// Execute a block with a savepoint (nested transaction)
    /// - Parameters:
    ///   - name: Savepoint name
    ///   - block: Code to execute within savepoint
    public func savepoint(_ name: String, _ block: () throws -> Void) throws {
        let conn = try getConnection()

        try conn.savepoint(name) {
            try block()
        }
    }

    // MARK: - Query Execution

    /// Execute raw SQL (for migrations, schema changes)
    /// - Parameter sql: SQL statement to execute
    /// - Throws: DatabaseError.queryFailed if execution fails
    public func execute(_ sql: String) throws {
        let conn = try getConnection()

        do {
            try conn.execute(sql)
        } catch {
            throw DatabaseError.queryFailed(error.localizedDescription)
        }
    }

    /// Prepare a SQL statement
    /// - Parameter query: SQL query
    /// - Returns: Prepared statement
    public func prepare(_ query: String) throws -> Statement {
        let conn = try getConnection()
        return try conn.prepare(query)
    }
}
