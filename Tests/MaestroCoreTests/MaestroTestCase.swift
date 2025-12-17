import XCTest
import SQLite
@testable import MaestroCore

/// Base test case class for all Maestro tests
/// Provides in-memory SQLite database for each test
class MaestroTestCase: XCTestCase {
    var db: Connection!
    var dbPath: String!

    override func setUp() async throws {
        try await super.setUp()

        // Create in-memory database for each test
        // This ensures tests are isolated and fast
        db = try Connection(.inMemory)
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
        try db.execute(sql)
    }

    /// Verify a table exists in the database
    func assertTableExists(_ tableName: String, file: StaticString = #file, line: UInt = #line) throws {
        let query = """
        SELECT name FROM sqlite_master
        WHERE type='table' AND name=?
        """
        let stmt = try db.prepare(query)
        let exists = try stmt.scalar(tableName) != nil
        XCTAssertTrue(exists, "Table '\(tableName)' should exist", file: file, line: line)
    }

    /// Get row count from a table
    func rowCount(in tableName: String) throws -> Int {
        let query = "SELECT COUNT(*) FROM \(tableName)"
        let stmt = try db.prepare(query)
        guard let row = try stmt.scalar() else { return 0 }
        return row as? Int64 as? Int ?? 0
    }
}
