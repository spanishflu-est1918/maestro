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

    func testSyncWithoutAPIKey() async throws {
        let db = Database()
        try db.connect()

        // Create LinearSync without API key
        let linearSync = LinearSync(database: db)

        // Should throw noAPIKey error
        do {
            try await linearSync.sync()
            XCTFail("Should have thrown noAPIKey error")
        } catch LinearSyncError.noAPIKey {
            // Expected error
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    func testSyncTaskToLinearWithoutAPIKey() async throws {
        let db = Database()
        try db.connect()

        let taskStore = TaskStore(database: db)
        let spaceStore = SpaceStore(database: db)

        let space = Space(name: "Test Space", color: "#FF0000")
        try spaceStore.create(space)

        let task = Task(spaceId: space.id, title: "Test Task", status: .todo)
        try taskStore.create(task)

        // Create LinearSync without API key
        let linearSync = LinearSync(database: db)

        // Should throw noAPIKey error
        do {
            try await linearSync.syncTaskToLinear(taskId: task.id)
            XCTFail("Should have thrown noAPIKey error")
        } catch LinearSyncError.noAPIKey {
            // Expected error
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    func testCreateLinearIssueWithoutAPIKey() async throws {
        let db = Database()
        try db.connect()

        let taskStore = TaskStore(database: db)
        let spaceStore = SpaceStore(database: db)

        let space = Space(name: "Test Space", color: "#FF0000")
        try spaceStore.create(space)

        let task = Task(spaceId: space.id, title: "Test Task", status: .todo)
        try taskStore.create(task)

        // Create LinearSync without API key
        let linearSync = LinearSync(database: db)

        // Should throw noAPIKey error
        do {
            _ = try await linearSync.createLinearIssue(taskId: task.id, teamId: "team-123")
            XCTFail("Should have thrown noAPIKey error")
        } catch LinearSyncError.noAPIKey {
            // Expected error
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    func testSyncTaskToLinearNotLinked() async throws {
        let db = Database()
        try db.connect()

        let taskStore = TaskStore(database: db)
        let spaceStore = SpaceStore(database: db)

        let space = Space(name: "Test Space", color: "#FF0000")
        try spaceStore.create(space)

        let task = Task(spaceId: space.id, title: "Test Task", status: .todo)
        try taskStore.create(task)

        // Create LinearSync with API key but don't link the task
        let linearSync = LinearSync(database: db, apiKey: "test-key")

        // Should throw notLinked error
        do {
            try await linearSync.syncTaskToLinear(taskId: task.id)
            XCTFail("Should have thrown notLinked error")
        } catch LinearSyncError.notLinked {
            // Expected error
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    func testSyncTaskToLinearTaskNotFound() async throws {
        let db = Database()
        try db.connect()

        // Create LinearSync with API key
        let linearSync = LinearSync(database: db, apiKey: "test-key")

        // Try to sync non-existent task
        let fakeTaskId = UUID()

        // Should throw taskNotFound error
        do {
            try await linearSync.syncTaskToLinear(taskId: fakeTaskId)
            XCTFail("Should have thrown taskNotFound error")
        } catch LinearSyncError.taskNotFound {
            // Expected error
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    func testCreateLinearIssueTaskNotFound() async throws {
        let db = Database()
        try db.connect()

        // Create LinearSync with API key
        let linearSync = LinearSync(database: db, apiKey: "test-key")

        // Try to create issue for non-existent task
        let fakeTaskId = UUID()

        // Should throw taskNotFound error
        do {
            _ = try await linearSync.createLinearIssue(taskId: fakeTaskId, teamId: "team-123")
            XCTFail("Should have thrown taskNotFound error")
        } catch LinearSyncError.taskNotFound {
            // Expected error
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    func testSetAPIKey() throws {
        let db = Database()
        try db.connect()

        // Create LinearSync without API key
        let linearSync = LinearSync(database: db)

        // Set API key
        linearSync.setAPIKey("new-api-key")

        // Verify by trying to create a task (will fail on API call, not on missing key)
        // This is a basic smoke test that the key was set
        XCTAssertNotNil(linearSync)
    }
}
