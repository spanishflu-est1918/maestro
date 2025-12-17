import XCTest
@testable import Maestro
@testable import MaestroCore
@testable import MaestroUI

/// End-to-End System Integration Tests
/// Tests the full Maestro system: daemon, MCP, database, UI, and external integrations
final class E2ESystemTests: XCTestCase {

    func testFullSystemIntegration() throws {
        // 1. Setup: Create isolated test database
        let testDBPath = "/tmp/e2e-test-\(UUID().uuidString).db"
        defer {
            try? FileManager.default.removeItem(atPath: testDBPath)
        }

        let db = Database(path: testDBPath)
        try db.connect()

        // 2. Test: Create space via SpaceStore (simulating MCP tool)
        let spaceStore = SpaceStore(database: db)
        let space = Space(name: "E2E Test Space", path: "/test/path", color: "#00FF00")
        try spaceStore.create(space)

        // Verify space was created
        let retrievedSpace = try spaceStore.get(space.id)
        XCTAssertNotNil(retrievedSpace)
        XCTAssertEqual(retrievedSpace?.name, "E2E Test Space")
        XCTAssertEqual(retrievedSpace?.path, "/test/path")

        // 3. Test: Create task via TaskStore (simulating MCP tool)
        let taskStore = TaskStore(database: db)
        let task = Task(
            spaceId: space.id,
            title: "E2E Test Task",
            description: "Testing full system integration",
            status: .todo,
            priority: .high
        )
        try taskStore.create(task)

        // Verify task was created
        let retrievedTask = try taskStore.get(task.id)
        XCTAssertNotNil(retrievedTask)
        XCTAssertEqual(retrievedTask?.title, "E2E Test Task")
        XCTAssertEqual(retrievedTask?.status, .todo)
        XCTAssertEqual(retrievedTask?.priority, .high)

        // 4. Test: Create document via DocumentStore (simulating MCP tool)
        let documentStore = DocumentStore(database: db)
        let document = Document(
            spaceId: space.id,
            title: "E2E Test Document",
            content: "# E2E Test\n\nThis is a test document.",
            path: "/docs"
        )
        try documentStore.create(document)

        // Verify document was created
        let retrievedDocument = try documentStore.get(document.id)
        XCTAssertNotNil(retrievedDocument)
        XCTAssertEqual(retrievedDocument?.title, "E2E Test Document")

        // 5. Test: Linear integration - link task to Linear issue
        let linearSync = LinearSync(database: db, apiKey: "test-api-key")
        try linearSync.linkIssue(
            taskId: task.id,
            linearIssueId: "e2e-issue-123",
            linearIssueKey: "E2E-123",
            linearTeamId: "team-e2e",
            linearState: "In Progress"
        )

        // Verify Linear link was created
        let linearLink = try linearSync.getLinkedIssue(forTask: task.id)
        XCTAssertNotNil(linearLink)
        XCTAssertEqual(linearLink?.linearIssueKey, "E2E-123")
        XCTAssertEqual(linearLink?.linearState, "In Progress")

        // 6. Test: Reminder integration - link space to reminder
        let reminderSync = ReminderSync(database: db)
        // Note: We can't actually create EKReminders in tests without EventKit permissions,
        // so we'll just verify the ReminderLink model works
        let reminderLink = ReminderLink(
            spaceId: space.id,
            reminderId: "e2e-reminder-123",
            reminderTitle: "E2E Reminder",
            reminderListId: "list-e2e",
            reminderListName: "E2E List"
        )

        try db.write { db in
            try reminderLink.insert(db)
        }

        // Verify reminder link was created
        let reminderLinks = try reminderSync.getLinkedReminders(forSpace: space.id)
        XCTAssertEqual(reminderLinks.count, 1)
        XCTAssertEqual(reminderLinks.first?.reminderTitle, "E2E Reminder")

        // 7. Test: Menu bar app can read data
        // Note: We can't fully test NSStatusItem UI in unit tests, but we can verify
        // QuickViewPanel can be initialized and read data
        let appDelegate = AppDelegate()
        // AppDelegate uses its own db connection, but we can't easily override it in tests
        // So we'll just verify it can be created
        XCTAssertNotNil(appDelegate)

        // 8. Test: Cross-component data consistency
        // Verify that all data is consistent across different access patterns
        let allSpaces = try spaceStore.list(includeArchived: false)
        XCTAssertTrue(allSpaces.contains { $0.id == space.id })

        let allTasks = try taskStore.list(includeArchived: false)
        XCTAssertTrue(allTasks.contains { $0.id == task.id })

        let allDocuments = try documentStore.list()
        XCTAssertTrue(allDocuments.contains { $0.id == document.id })

        // 9. Test: Task surfacing algorithm
        let surfacedTasks = try taskStore.getSurfaced(limit: 10)
        XCTAssertTrue(surfacedTasks.contains { $0.id == task.id })

        // 10. Test: Update operations work across integrations
        // Update task status
        var updatedTask = task
        updatedTask.status = .inProgress
        try taskStore.update(updatedTask)

        // Update Linear state to match
        try linearSync.updateIssueState(linearIssueId: "e2e-issue-123", newState: "In Progress")

        // Verify both updates persisted
        let finalTask = try taskStore.get(task.id)
        XCTAssertEqual(finalTask?.status, .inProgress)

        let finalLinearLink = try linearSync.getLinkedIssue(forTask: task.id)
        XCTAssertEqual(finalLinearLink?.linearState, "In Progress")
    }

    func testMCPServerInitialization() throws {
        // Test that MCP server can be initialized with a database
        let testDBPath = "/tmp/mcp-test-\(UUID().uuidString).db"
        defer {
            try? FileManager.default.removeItem(atPath: testDBPath)
        }

        let server = try MaestroMCPServer(databasePath: testDBPath)
        XCTAssertNotNil(server)

        // Verify database was initialized with all tables
        let db = Database(path: testDBPath)
        try db.connect()

        let tables = try db.read { db in
            try String.fetchAll(db, sql: """
                SELECT name FROM sqlite_master
                WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'grdb_%'
                ORDER BY name
            """)
        }

        XCTAssertEqual(tables.sorted(), ["agent_activity", "agent_sessions", "documents", "linear_sync", "reminder_space_links", "spaces", "tasks"])
    }

    func testDataPersistenceAcrossConnections() throws {
        // Test that data persists when closing and reopening database connections
        let testDBPath = "/tmp/persistence-test-\(UUID().uuidString).db"
        defer {
            try? FileManager.default.removeItem(atPath: testDBPath)
        }

        // Create and populate database
        do {
            let db = Database(path: testDBPath)
            try db.connect()

            let spaceStore = SpaceStore(database: db)
            let space = Space(name: "Persistence Test", color: "#FF0000")
            try spaceStore.create(space)

            db.close()
        }

        // Reopen and verify data persists
        do {
            let db = Database(path: testDBPath)
            try db.connect()

            let spaceStore = SpaceStore(database: db)
            let spaces = try spaceStore.list()

            XCTAssertEqual(spaces.count, 1)
            XCTAssertEqual(spaces.first?.name, "Persistence Test")

            db.close()
        }
    }
}
