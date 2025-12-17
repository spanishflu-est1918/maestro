import XCTest
@testable import MaestroCore

/// Integration tests for database migrations
final class MigrationTests: XCTestCase {

    // MARK: - Migration System Tests

    func testMigrationFromEmptyDB() throws {
        // Create temporary database file
        let tempDir = FileManager.default.temporaryDirectory
        let dbPath = tempDir.appendingPathComponent("migration-test-\(UUID().uuidString).db").path

        // Initialize database and run migrations
        let db = Database(path: dbPath)
        try db.connect()

        // At this point, migrations should have run automatically
        // Verify migration tracking table exists
        let hasMigrationsTable = try db.read { db in
            try Bool.fetchOne(db, sql: """
                SELECT EXISTS(
                    SELECT 1 FROM sqlite_master
                    WHERE type='table' AND name='grdb_migrations'
                )
            """)
        }
        XCTAssertTrue(hasMigrationsTable ?? false, "Migration tracking table should exist")

        // Cleanup
        db.close()
        try? FileManager.default.removeItem(atPath: dbPath)
    }

    func testMigrationsAreIdempotent() throws {
        // Create temporary database file
        let tempDir = FileManager.default.temporaryDirectory
        let dbPath = tempDir.appendingPathComponent("idempotent-test-\(UUID().uuidString).db").path

        // First run: create and migrate
        do {
            let db = Database(path: dbPath)
            try db.connect()
            db.close()
        }

        // Second run: reopen and verify migrations don't error
        do {
            let db = Database(path: dbPath)
            XCTAssertNoThrow(try db.connect(), "Reopening database should not fail")

            // Verify migration tracking is consistent
            let migrationCount = try db.read { db in
                try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM grdb_migrations")
            }
            XCTAssertNotNil(migrationCount, "Should be able to query migrations")

            db.close()
        }

        // Cleanup
        try? FileManager.default.removeItem(atPath: dbPath)
    }

    func testMigrationVersionTracking() throws {
        // Create temporary database file
        let tempDir = FileManager.default.temporaryDirectory
        let dbPath = tempDir.appendingPathComponent("version-test-\(UUID().uuidString).db").path

        let db = Database(path: dbPath)
        try db.connect()

        // Check that migrations have been applied
        let appliedMigrations = try db.read { db in
            try String.fetchAll(db, sql: "SELECT identifier FROM grdb_migrations ORDER BY identifier")
        }

        // Should have at least the v1 migration (we'll add this in next step)
        XCTAssertFalse(appliedMigrations.isEmpty, "Should have applied migrations")

        db.close()
        try? FileManager.default.removeItem(atPath: dbPath)
    }
}
