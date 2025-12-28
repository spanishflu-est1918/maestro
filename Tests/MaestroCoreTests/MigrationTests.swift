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

        XCTAssertEqual(tables.sorted(), ["agent_activity", "agent_sessions", "documents", "linear_sync", "reminder_space_links", "spaces", "tasks"], "Should have all core tables including agent monitoring")

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

    // MARK: - v5 Migration Tests (Claude Code File Watcher)

    func testV5MigrationApplied() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let dbPath = tempDir.appendingPathComponent("v5-test-\(UUID().uuidString).db").path

        let db = Database(path: dbPath)
        try db.connect()

        let appliedMigrations = try db.read { db in
            try String.fetchAll(db, sql: "SELECT identifier FROM grdb_migrations ORDER BY identifier")
        }

        XCTAssertTrue(appliedMigrations.contains("v5"), "Should have v5 migration applied")

        db.close()
        try? FileManager.default.removeItem(atPath: dbPath)
    }

    func testV5AgentSessionsHasClaudeSessionId() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let dbPath = tempDir.appendingPathComponent("v5-columns-test-\(UUID().uuidString).db").path

        let db = Database(path: dbPath)
        try db.connect()

        let columns = try db.read { db in
            try Row.fetchAll(db, sql: "PRAGMA table_info(agent_sessions)")
        }

        let columnNames = columns.map { $0["name"] as! String }

        XCTAssertTrue(columnNames.contains("claude_session_id"), "Should have claude_session_id column")
        XCTAssertTrue(columnNames.contains("last_file_offset"), "Should have last_file_offset column")
        XCTAssertTrue(columnNames.contains("space_id"), "Should have space_id column")
        XCTAssertTrue(columnNames.contains("working_directory"), "Should have working_directory column")

        db.close()
        try? FileManager.default.removeItem(atPath: dbPath)
    }

    func testV5ClaudeSessionIdIndex() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let dbPath = tempDir.appendingPathComponent("v5-index-test-\(UUID().uuidString).db").path

        let db = Database(path: dbPath)
        try db.connect()

        let indexes = try db.read { db in
            try Row.fetchAll(db, sql: """
                SELECT name FROM sqlite_master
                WHERE type='index' AND tbl_name='agent_sessions'
            """)
        }

        let indexNames = indexes.map { $0["name"] as! String }

        XCTAssertTrue(indexNames.contains("idx_agent_sessions_claude_id"), "Should have claude_session_id unique index")
        XCTAssertTrue(indexNames.contains("idx_agent_sessions_space_id"), "Should have space_id index")

        db.close()
        try? FileManager.default.removeItem(atPath: dbPath)
    }

    func testV5LastFileOffsetDefaultValue() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let dbPath = tempDir.appendingPathComponent("v5-default-test-\(UUID().uuidString).db").path

        let db = Database(path: dbPath)
        try db.connect()

        // Insert a session without specifying last_file_offset
        try db.write { db in
            try db.execute(sql: """
                INSERT INTO agent_sessions (id, agent_name, started_at, total_activities, tasks_created, tasks_updated, tasks_completed, spaces_created, documents_created)
                VALUES ('test-id', 'Test Agent', datetime('now'), 0, 0, 0, 0, 0, 0)
            """)
        }

        let offset = try db.read { db in
            try Int64.fetchOne(db, sql: "SELECT last_file_offset FROM agent_sessions WHERE id = 'test-id'")
        }

        XCTAssertEqual(offset, 0, "last_file_offset should default to 0")

        db.close()
        try? FileManager.default.removeItem(atPath: dbPath)
    }

    func testV5SpaceIdForeignKey() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let dbPath = tempDir.appendingPathComponent("v5-fk-test-\(UUID().uuidString).db").path

        let db = Database(path: dbPath)
        try db.connect()

        // Create a space
        let spaceId = UUID().uuidString
        try db.write { db in
            try db.execute(sql: """
                INSERT INTO spaces (id, name, color, created_at, last_active_at, archived, track_focus, total_focus_time)
                VALUES (?, 'Test Space', '#3B82F6', datetime('now'), datetime('now'), 0, 0, 0)
            """, arguments: [spaceId])
        }

        // Create session linked to space
        try db.write { db in
            try db.execute(sql: """
                INSERT INTO agent_sessions (id, agent_name, started_at, total_activities, tasks_created, tasks_updated, tasks_completed, spaces_created, documents_created, space_id)
                VALUES ('session-1', 'Claude Code', datetime('now'), 0, 0, 0, 0, 0, 0, ?)
            """, arguments: [spaceId])
        }

        // Verify the link exists
        let linkedSpaceId = try db.read { db in
            try String.fetchOne(db, sql: "SELECT space_id FROM agent_sessions WHERE id = 'session-1'")
        }

        XCTAssertEqual(linkedSpaceId, spaceId)

        db.close()
        try? FileManager.default.removeItem(atPath: dbPath)
    }
}
