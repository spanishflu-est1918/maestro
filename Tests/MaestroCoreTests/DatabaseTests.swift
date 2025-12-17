import XCTest
@testable import MaestroCore

/// Integration tests for Database connection management
final class DatabaseTests: XCTestCase {

    // MARK: - Connection Tests

    func testConnectInMemory() throws {
        let db = Database()
        try db.connect()

        XCTAssertTrue(db.isConnected, "Database should be connected")

        db.close()
        XCTAssertFalse(db.isConnected, "Database should be closed")
    }

    func testConnectWithPath() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let dbPath = tempDir.appendingPathComponent("test-\(UUID().uuidString).db").path

        let db = Database(path: dbPath)
        try db.connect()

        XCTAssertTrue(db.isConnected)

        // Cleanup
        db.close()
        try? FileManager.default.removeItem(atPath: dbPath)
    }

    func testReconnect() throws {
        let db = Database()
        try db.connect()
        XCTAssertTrue(db.isConnected)

        try db.reconnect()
        XCTAssertTrue(db.isConnected, "Should be connected after reconnect")
    }

    func testGetQueueThrowsWhenNotConnected() {
        let db = Database()

        XCTAssertThrowsError(try db.getQueue()) { error in
            XCTAssertTrue(error is Database.DatabaseError)
        }
    }

    // MARK: - Transaction Tests

    func testTransaction() throws {
        let db = Database()
        try db.connect()

        // Create table and insert data within transaction
        try db.transaction { grdb in
            try grdb.execute(sql: "CREATE TABLE test (id INTEGER PRIMARY KEY, name TEXT)")
            try grdb.execute(sql: "INSERT INTO test (name) VALUES ('test')")
        }

        // Verify data exists after transaction
        let count = try db.scalar("SELECT COUNT(*) FROM test")
        XCTAssertEqual(Int64.fromDatabaseValue(count ?? .null), 1)
    }

    func testTransactionRollback() throws {
        let db = Database()
        try db.connect()

        try db.execute("CREATE TABLE test (id INTEGER PRIMARY KEY, name TEXT)")

        // Transaction that throws should rollback
        do {
            try db.transaction { grdb in
                try grdb.execute(sql: "INSERT INTO test (name) VALUES ('test')")
                throw Database.DatabaseError.queryFailed("Intentional error")
            }
        } catch {
            // Expected to throw
        }

        // Verify no data was inserted (transaction rolled back)
        let count = try db.scalar("SELECT COUNT(*) FROM test")
        XCTAssertEqual(Int64.fromDatabaseValue(count ?? .null), 0, "Transaction should have rolled back")
    }

    // MARK: - Persistence Test (B004 requirement)

    func testSQLitePersistence() throws {
        // Create temporary file path
        let tempDir = FileManager.default.temporaryDirectory
        let dbPath = tempDir.appendingPathComponent("persistence-test-\(UUID().uuidString).db").path

        // Phase 1: Create database, write data, close
        do {
            let db = Database(path: dbPath)
            try db.connect()

            try db.execute("CREATE TABLE test (id INTEGER PRIMARY KEY, name TEXT)")
            try db.execute("INSERT INTO test (name) VALUES ('persisted')")

            let count = try db.scalar("SELECT COUNT(*) FROM test")
            XCTAssertEqual(Int64.fromDatabaseValue(count ?? .null), 1, "Should have 1 row before closing")

            db.close()
        }

        // Phase 2: Reopen database, verify data still exists
        do {
            let db = Database(path: dbPath)
            try db.connect()

            let count = try db.scalar("SELECT COUNT(*) FROM test")
            XCTAssertEqual(Int64.fromDatabaseValue(count ?? .null), 1, "Data should persist after reopening")

            let name = try db.scalar("SELECT name FROM test")
            XCTAssertEqual(String.fromDatabaseValue(name ?? .null), "persisted", "Data should match")

            db.close()
        }

        // Cleanup
        try? FileManager.default.removeItem(atPath: dbPath)
    }

    // MARK: - Foreign Keys Test

    func testForeignKeysEnabled() throws {
        let db = Database()
        try db.connect()

        let fkEnabled = try db.scalar("PRAGMA foreign_keys")
        XCTAssertEqual(Int64.fromDatabaseValue(fkEnabled ?? .null), 1, "Foreign keys should be enabled")
    }

    // MARK: - Error Handling Tests

    func testExecuteInvalidSQL() throws {
        let db = Database()
        try db.connect()

        XCTAssertThrowsError(try db.execute("INVALID SQL")) { error in
            XCTAssertTrue(error is Database.DatabaseError)
        }
    }
}
