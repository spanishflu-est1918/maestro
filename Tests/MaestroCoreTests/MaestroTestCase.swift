import XCTest
import GRDB
@testable import MaestroCore

/// Base test case class for all Maestro tests
/// Provides in-memory SQLite database for each test
class MaestroTestCase: XCTestCase {
    var db: DatabaseQueue!
    var dbPath: String!

    override func setUp() async throws {
        try await super.setUp()

        // Create in-memory database for each test
        // This ensures tests are isolated and fast
        db = try DatabaseQueue()
        dbPath = ":memory:"

        print("✓ Test database initialized (in-memory)")
    }

    override func tearDown() async throws {
        // Close database connection
        db = nil
        dbPath = nil

        try await super.tearDown()
    }

    // MARK: - Helper Methods

    /// Execute raw SQL for test setup
    func executeSQL(_ sql: String) throws {
        try db.write { db in
            try db.execute(sql: sql)
        }
    }

    /// Verify a table exists in the database
    func assertTableExists(_ tableName: String, file: StaticString = #file, line: UInt = #line) throws {
        let exists = try db.read { db in
            try Bool.fetchOne(db, sql: """
                SELECT EXISTS(
                    SELECT 1 FROM sqlite_master
                    WHERE type='table' AND name=?
                )
                """, arguments: [tableName])
        }
        XCTAssertTrue(exists ?? false, "Table '\(tableName)' should exist", file: file, line: line)
    }

    /// Get row count from a table
    func rowCount(in tableName: String) throws -> Int {
        let count = try db.read { db in
            try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM \(tableName)")
        }
        return count ?? 0
    }

    /// Execute a scalar query
    func scalar(_ sql: String) throws -> DatabaseValue? {
        return try db.read { db in
            try DatabaseValue.fetchOne(db, sql: sql)
        }
    }
}
