import XCTest
import GRDB
@testable import MaestroCore

/// Linear Integration Tests
/// Tests Linear issue linking and sync
final class LinearSyncTests: XCTestCase {

    func testLinearIntegrationFlow() throws {
        // Create test database
        let db = Database()
        try db.connect()

        // Verify migration created linear_sync table
        let tables = try db.read { db in
            try String.fetchAll(db, sql: """
                SELECT name FROM sqlite_master
                WHERE type='table' AND name = 'linear_sync'
            """)
        }

        XCTAssertTrue(tables.contains("linear_sync"), "Should have linear_sync table")
    }

    func testLinearSyncFlow() throws {
        // Create test database
        let db = Database()
        try db.connect()

        // Create test task
        let taskStore = TaskStore(database: db)
        let spaceStore = SpaceStore(database: db)

        let space = Space(name: "Test Space", color: "#FF0000")
        try spaceStore.create(space)

        let task = Task(spaceId: space.id, title: "Test Task", status: .todo)
        try taskStore.create(task)

        // Link to Linear issue
        let linearSync = LinearSync(database: db, apiKey: "test-api-key")
        try linearSync.linkIssue(
            taskId: task.id,
            linearIssueId: "linear-issue-123",
            linearIssueKey: "PROJ-123",
            linearTeamId: "team-456",
            linearState: "In Progress"
        )

        // Verify link was created
        let link = try linearSync.getLinkedIssue(forTask: task.id)
        XCTAssertNotNil(link)
        XCTAssertEqual(link?.linearIssueKey, "PROJ-123")
        XCTAssertEqual(link?.linearState, "In Progress")
    }

    func testLinearSyncInit() throws {
        let db = Database()
        try db.connect()

        // Verify LinearSync can be initialized
        let sync = LinearSync(database: db)
        XCTAssertNotNil(sync)
    }

    func testGetAllLinks() throws {
        let db = Database()
        try db.connect()

        let taskStore = TaskStore(database: db)
        let spaceStore = SpaceStore(database: db)

        let space = Space(name: "Test Space", color: "#FF0000")
        try spaceStore.create(space)

        // Add multiple task-issue links
        let linearSync = LinearSync(database: db)
        for i in 1...3 {
            let task = Task(spaceId: space.id, title: "Task \(i)", status: .todo)
            try taskStore.create(task)

            try linearSync.linkIssue(
                taskId: task.id,
                linearIssueId: "issue-\(i)",
                linearIssueKey: "PROJ-\(i)",
                linearTeamId: "team-1",
                linearState: "Open"
            )
        }

        // Get all links
        let links = try linearSync.getAllLinks()
        XCTAssertEqual(links.count, 3)
    }

    func testUpdateIssueState() throws {
        let db = Database()
        try db.connect()

        let taskStore = TaskStore(database: db)
        let spaceStore = SpaceStore(database: db)

        let space = Space(name: "Test Space", color: "#FF0000")
        try spaceStore.create(space)

        let task = Task(spaceId: space.id, title: "Test Task", status: .todo)
        try taskStore.create(task)

        // Link issue
        let linearSync = LinearSync(database: db, apiKey: "test-key")
        try linearSync.linkIssue(
            taskId: task.id,
            linearIssueId: "issue-123",
            linearIssueKey: "PROJ-123",
            linearTeamId: "team-1",
            linearState: "Open"
        )

        // Update state
        try linearSync.updateIssueState(linearIssueId: "issue-123", newState: "In Progress")

        // Verify state was updated
        let link = try linearSync.getLinkedIssue(forTask: task.id)
        XCTAssertEqual(link?.linearState, "In Progress")
    }
}
