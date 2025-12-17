import XCTest
@testable import MaestroCore

/// Basic smoke tests for Maestro core functionality
final class MaestroTests: MaestroTestCase {

    // MARK: - Smoke Tests

    func testMaestroVersion() {
        // Verify version string is set
        XCTAssertEqual(Maestro.version, "0.1.0")
    }

    func testMaestroHello() {
        // Verify hello() returns correct message
        let maestro = Maestro()
        let message = maestro.hello()
        XCTAssertEqual(message, "Maestro v0.1.0")
    }

    // MARK: - Database Tests

    func testInMemoryDatabaseConnection() async throws {
        // Verify in-memory database connection works
        XCTAssertNotNil(db, "Database connection should be initialized")
        XCTAssertEqual(dbPath, ":memory:", "Should use in-memory database for tests")
    }

    func testExecuteSQL() async throws {
        // Verify we can execute raw SQL
        try executeSQL("""
            CREATE TABLE test_table (
                id INTEGER PRIMARY KEY,
                name TEXT NOT NULL
            )
        """)

        // Verify table was created
        try assertTableExists("test_table")
    }

    func testRowCount() async throws {
        // Create test table and insert data
        try executeSQL("CREATE TABLE test_table (id INTEGER PRIMARY KEY, name TEXT)")
        try executeSQL("INSERT INTO test_table (name) VALUES ('test1')")
        try executeSQL("INSERT INTO test_table (name) VALUES ('test2')")
        try executeSQL("INSERT INTO test_table (name) VALUES ('test3')")

        // Verify row count helper works
        let count = try rowCount(in: "test_table")
        XCTAssertEqual(count, 3, "Should have 3 rows")
    }

    func testDatabaseIsolation() async throws {
        // Each test should get a fresh database
        // This test verifies no tables exist from previous tests
        let tableCount = try scalar("SELECT COUNT(*) FROM sqlite_master WHERE type='table'")

        // In-memory DB should be empty at start of each test
        XCTAssertEqual(Int64.fromDatabaseValue(tableCount ?? .null), 0, "Fresh test should have no tables")
    }
}
