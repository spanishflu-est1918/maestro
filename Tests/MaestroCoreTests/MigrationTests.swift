import XCTest
import GRDB
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

        // Should have at least the v1 migration
        XCTAssertFalse(appliedMigrations.isEmpty, "Should have applied migrations")
        XCTAssertTrue(appliedMigrations.contains("v1"), "Should have v1 migration")

        db.close()
        try? FileManager.default.removeItem(atPath: dbPath)
    }

    // MARK: - Schema Verification Tests

    func testCoreSchemaExists() throws {
        // Create temporary database file
        let tempDir = FileManager.default.temporaryDirectory
        let dbPath = tempDir.appendingPathComponent("schema-test-\(UUID().uuidString).db").path

        let db = Database(path: dbPath)
        try db.connect()

        // Verify all core tables exist
        let tables = try db.read { db in
            try String.fetchAll(db, sql: """
                SELECT name FROM sqlite_master
                WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'grdb_%'
                ORDER BY name
            """)
        }

        XCTAssertEqual(tables.sorted(), ["documents", "spaces", "tasks"], "Should have spaces, documents, and tasks tables")

        db.close()
        try? FileManager.default.removeItem(atPath: dbPath)
    }

    func testSpacesTableSchema() throws {
        // Create temporary database file
        let tempDir = FileManager.default.temporaryDirectory
        let dbPath = tempDir.appendingPathComponent("spaces-schema-test-\(UUID().uuidString).db").path

        let db = Database(path: dbPath)
        try db.connect()

        // Verify spaces table has correct columns
        let columns = try db.read { db in
            try Row.fetchAll(db, sql: "PRAGMA table_info(spaces)")
        }

        let columnNames = columns.map { $0["name"] as! String }
        let requiredColumns = [
            "id", "name", "path", "color", "parent_id", "tags", "archived",
            "track_focus", "created_at", "last_active_at", "total_focus_time"
        ]

        for column in requiredColumns {
            XCTAssertTrue(columnNames.contains(column), "Spaces table should have \(column) column")
        }

        db.close()
        try? FileManager.default.removeItem(atPath: dbPath)
    }

    func testTasksTableSchema() throws {
        // Create temporary database file
        let tempDir = FileManager.default.temporaryDirectory
        let dbPath = tempDir.appendingPathComponent("tasks-schema-test-\(UUID().uuidString).db").path

        let db = Database(path: dbPath)
        try db.connect()

        // Verify tasks table has correct columns
        let columns = try db.read { db in
            try Row.fetchAll(db, sql: "PRAGMA table_info(tasks)")
        }

        let columnNames = columns.map { $0["name"] as! String }
        let requiredColumns = [
            "id", "space_id", "title", "description", "status", "priority",
            "position", "due_date", "created_at", "updated_at", "completed_at"
        ]

        for column in requiredColumns {
            XCTAssertTrue(columnNames.contains(column), "Tasks table should have \(column) column")
        }

        db.close()
        try? FileManager.default.removeItem(atPath: dbPath)
    }

    func testDocumentsTableSchema() throws {
        // Create temporary database file
        let tempDir = FileManager.default.temporaryDirectory
        let dbPath = tempDir.appendingPathComponent("documents-schema-test-\(UUID().uuidString).db").path

        let db = Database(path: dbPath)
        try db.connect()

        // Verify documents table has correct columns
        let columns = try db.read { db in
            try Row.fetchAll(db, sql: "PRAGMA table_info(documents)")
        }

        let columnNames = columns.map { $0["name"] as! String }
        let requiredColumns = [
            "id", "space_id", "title", "content", "path",
            "is_default", "is_pinned", "created_at", "updated_at"
        ]

        for column in requiredColumns {
            XCTAssertTrue(columnNames.contains(column), "Documents table should have \(column) column")
        }

        db.close()
        try? FileManager.default.removeItem(atPath: dbPath)
    }
}
