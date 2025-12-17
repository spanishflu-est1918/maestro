import XCTest
@testable import MaestroCore

/// Integration tests for TaskStore CRUD operations
final class TaskStoreTests: XCTestCase {
    var db: Database!
    var taskStore: TaskStore!
    var spaceStore: SpaceStore!
    var testSpaceId: UUID!

    override func setUp() async throws {
        try await super.setUp()

        // Create in-memory database for each test
        db = Database()
        try db.connect()
        taskStore = TaskStore(database: db)
        spaceStore = SpaceStore(database: db)

        // Create a test space for tasks
        let testSpace = Space(name: "Test Space", color: "#FF0000")
        try spaceStore.create(testSpace)
        testSpaceId = testSpace.id
    }

    override func tearDown() async throws {
        db.close()
        db = nil
        taskStore = nil
        spaceStore = nil
        testSpaceId = nil

        try await super.tearDown()
    }

    // MARK: - CRUD Flow Test

    func testTaskCRUDFlow() throws {
        // Create
        let task = Task(
            spaceId: testSpaceId,
            title: "Test Task",
            description: "A test task",
            status: .inbox,
            priority: .medium
        )
        try taskStore.create(task)

        // Get
        let retrieved = try taskStore.get(task.id)
        XCTAssertNotNil(retrieved, "Should retrieve created task")
        XCTAssertEqual(retrieved?.title, "Test Task")
        XCTAssertEqual(retrieved?.description, "A test task")
        XCTAssertEqual(retrieved?.status, .inbox)
        XCTAssertEqual(retrieved?.priority, .medium)

        // Update
        var updated = retrieved!
        updated.title = "Updated Task"
        updated.status = .todo
        updated.priority = .high
        try taskStore.update(updated)

        let afterUpdate = try taskStore.get(task.id)
        XCTAssertEqual(afterUpdate?.title, "Updated Task")
        XCTAssertEqual(afterUpdate?.status, .todo)
        XCTAssertEqual(afterUpdate?.priority, .high)

        // List
        let tasks = try taskStore.list()
        XCTAssertEqual(tasks.count, 1)
        XCTAssertEqual(tasks.first?.title, "Updated Task")

        // Delete
        try taskStore.delete(task.id)
        let afterDelete = try taskStore.get(task.id)
        XCTAssertNil(afterDelete, "Task should be deleted")
    }

    // MARK: - Status Tests

    func testStatusTransitions() throws {
        let task = Task(
            spaceId: testSpaceId,
            title: "Status Test",
            status: .inbox
        )
        try taskStore.create(task)

        // inbox → todo
        try taskStore.updateStatus(task.id, to: .todo)
        var retrieved = try taskStore.get(task.id)
        XCTAssertEqual(retrieved?.status, .todo)

        // todo → inProgress
        try taskStore.updateStatus(task.id, to: .inProgress)
        retrieved = try taskStore.get(task.id)
        XCTAssertEqual(retrieved?.status, .inProgress)

        // inProgress → done (should set completedAt)
        try taskStore.updateStatus(task.id, to: .done)
        retrieved = try taskStore.get(task.id)
        XCTAssertEqual(retrieved?.status, .done)
        XCTAssertNotNil(retrieved?.completedAt, "completedAt should be set when marking as done")
    }

    func testCompleteTask() throws {
        let task = Task(
            spaceId: testSpaceId,
            title: "Complete Test",
            status: .inProgress
        )
        try taskStore.create(task)

        try taskStore.complete(task.id)
        let completed = try taskStore.get(task.id)
        XCTAssertEqual(completed?.status, .done)
        XCTAssertNotNil(completed?.completedAt)
    }

    func testArchiveTask() throws {
        let task = Task(
            spaceId: testSpaceId,
            title: "Archive Test"
        )
        try taskStore.create(task)

        try taskStore.archive(task.id)
        let archived = try taskStore.get(task.id)
        XCTAssertEqual(archived?.status, .archived)

        // Archived tasks should not appear in default list
        let nonArchivedList = try taskStore.list(includeArchived: false)
        XCTAssertEqual(nonArchivedList.count, 0)

        let archivedList = try taskStore.list(includeArchived: true)
        XCTAssertEqual(archivedList.count, 1)
    }

    func testGetByStatus() throws {
        // Create tasks with different statuses
        let inbox1 = Task(spaceId: testSpaceId, title: "Inbox 1", status: .inbox)
        let inbox2 = Task(spaceId: testSpaceId, title: "Inbox 2", status: .inbox)
        let todo1 = Task(spaceId: testSpaceId, title: "Todo 1", status: .todo)
        let inProgress1 = Task(spaceId: testSpaceId, title: "In Progress 1", status: .inProgress)
        let done1 = Task(spaceId: testSpaceId, title: "Done 1", status: .done)

        try taskStore.create(inbox1)
        try taskStore.create(inbox2)
        try taskStore.create(todo1)
        try taskStore.create(inProgress1)
        try taskStore.create(done1)

        // Test getByStatus
        let inboxTasks = try taskStore.getByStatus(.inbox)
        XCTAssertEqual(inboxTasks.count, 2)
        XCTAssertTrue(inboxTasks.allSatisfy { $0.status == .inbox })

        let todoTasks = try taskStore.getByStatus(.todo)
        XCTAssertEqual(todoTasks.count, 1)
        XCTAssertEqual(todoTasks.first?.title, "Todo 1")

        let inProgressTasks = try taskStore.getByStatus(.inProgress)
        XCTAssertEqual(inProgressTasks.count, 1)
        XCTAssertEqual(inProgressTasks.first?.title, "In Progress 1")

        let doneTasks = try taskStore.getByStatus(.done)
        XCTAssertEqual(doneTasks.count, 1)
        XCTAssertEqual(doneTasks.first?.title, "Done 1")
    }

    // MARK: - Priority Tests

    func testGetByPriority() throws {
        // Create tasks with different priorities
        let urgent1 = Task(spaceId: testSpaceId, title: "Urgent 1", priority: .urgent)
        let urgent2 = Task(spaceId: testSpaceId, title: "Urgent 2", priority: .urgent)
        let high1 = Task(spaceId: testSpaceId, title: "High 1", priority: .high)
        let medium1 = Task(spaceId: testSpaceId, title: "Medium 1", priority: .medium)
        let low1 = Task(spaceId: testSpaceId, title: "Low 1", priority: .low)

        try taskStore.create(urgent1)
        try taskStore.create(urgent2)
        try taskStore.create(high1)
        try taskStore.create(medium1)
        try taskStore.create(low1)

        // Test getByPriority
        let urgentTasks = try taskStore.getByPriority(.urgent)
        XCTAssertEqual(urgentTasks.count, 2)
        XCTAssertTrue(urgentTasks.allSatisfy { $0.priority == .urgent })

        let highTasks = try taskStore.getByPriority(.high)
        XCTAssertEqual(highTasks.count, 1)
        XCTAssertEqual(highTasks.first?.title, "High 1")

        let mediumTasks = try taskStore.getByPriority(.medium)
        XCTAssertEqual(mediumTasks.count, 1)

        let lowTasks = try taskStore.getByPriority(.low)
        XCTAssertEqual(lowTasks.count, 1)
    }

    // MARK: - Surfacing Algorithm Tests

    func testGetSurfaced() throws {
        // Create tasks with different status/priority combinations
        // Status priority: inProgress > todo > inbox
        // Priority: urgent > high > medium > low > none

        let task1 = Task(spaceId: testSpaceId, title: "InProgress Urgent", status: .inProgress, priority: .urgent, position: 1)
        let task2 = Task(spaceId: testSpaceId, title: "InProgress Low", status: .inProgress, priority: .low, position: 2)
        let task3 = Task(spaceId: testSpaceId, title: "Todo Urgent", status: .todo, priority: .urgent, position: 1)
        let task4 = Task(spaceId: testSpaceId, title: "Todo High", status: .todo, priority: .high, position: 2)
        let task5 = Task(spaceId: testSpaceId, title: "Inbox Urgent", status: .inbox, priority: .urgent, position: 1)
        let task6 = Task(spaceId: testSpaceId, title: "Done Urgent", status: .done, priority: .urgent, position: 1)

        try taskStore.create(task1)
        try taskStore.create(task2)
        try taskStore.create(task3)
        try taskStore.create(task4)
        try taskStore.create(task5)
        try taskStore.create(task6)

        // Get surfaced tasks
        let surfaced = try taskStore.getSurfaced()

        // Should only include inbox, todo, inProgress (not done)
        XCTAssertEqual(surfaced.count, 5)
        XCTAssertFalse(surfaced.contains { $0.status == .done })

        // Order should be:
        // 1. InProgress Urgent (status=1, priority=1)
        // 2. InProgress Low (status=1, priority=4)
        // 3. Todo Urgent (status=2, priority=1)
        // 4. Todo High (status=2, priority=2)
        // 5. Inbox Urgent (status=3, priority=1)

        XCTAssertEqual(surfaced[0].title, "InProgress Urgent")
        XCTAssertEqual(surfaced[1].title, "InProgress Low")
        XCTAssertEqual(surfaced[2].title, "Todo Urgent")
        XCTAssertEqual(surfaced[3].title, "Todo High")
        XCTAssertEqual(surfaced[4].title, "Inbox Urgent")
    }

    func testGetSurfacedWithLimit() throws {
        // Create 15 tasks
        for i in 1...15 {
            let task = Task(
                spaceId: testSpaceId,
                title: "Task \(i)",
                status: .todo,
                priority: .medium,
                position: i
            )
            try taskStore.create(task)
        }

        // Get with default limit (10)
        let surfaced10 = try taskStore.getSurfaced()
        XCTAssertEqual(surfaced10.count, 10)

        // Get with custom limit (5)
        let surfaced5 = try taskStore.getSurfaced(limit: 5)
        XCTAssertEqual(surfaced5.count, 5)
    }

    func testGetSurfacedFilteredBySpace() throws {
        // Create another space
        let space2 = Space(name: "Space 2", color: "#00FF00")
        try spaceStore.create(space2)

        // Create tasks in different spaces
        let task1 = Task(spaceId: testSpaceId, title: "Space 1 Task", status: .todo)
        let task2 = Task(spaceId: space2.id, title: "Space 2 Task", status: .todo)

        try taskStore.create(task1)
        try taskStore.create(task2)

        // Get surfaced for space 1 only
        let space1Surfaced = try taskStore.getSurfaced(spaceId: testSpaceId)
        XCTAssertEqual(space1Surfaced.count, 1)
        XCTAssertEqual(space1Surfaced.first?.title, "Space 1 Task")

        // Get surfaced for space 2 only
        let space2Surfaced = try taskStore.getSurfaced(spaceId: space2.id)
        XCTAssertEqual(space2Surfaced.count, 1)
        XCTAssertEqual(space2Surfaced.first?.title, "Space 2 Task")

        // Get surfaced for all spaces
        let allSurfaced = try taskStore.getSurfaced()
        XCTAssertEqual(allSurfaced.count, 2)
    }

    // MARK: - Space Filtering Tests

    func testListFilteredBySpace() throws {
        // Create another space
        let space2 = Space(name: "Space 2", color: "#00FF00")
        try spaceStore.create(space2)

        // Create tasks in different spaces
        let task1 = Task(spaceId: testSpaceId, title: "Space 1 Task 1")
        let task2 = Task(spaceId: testSpaceId, title: "Space 1 Task 2")
        let task3 = Task(spaceId: space2.id, title: "Space 2 Task 1")

        try taskStore.create(task1)
        try taskStore.create(task2)
        try taskStore.create(task3)

        // List all tasks
        let allTasks = try taskStore.list()
        XCTAssertEqual(allTasks.count, 3)

        // List tasks for space 1
        let space1Tasks = try taskStore.list(spaceId: testSpaceId)
        XCTAssertEqual(space1Tasks.count, 2)
        XCTAssertTrue(space1Tasks.allSatisfy { $0.spaceId == testSpaceId })

        // List tasks for space 2
        let space2Tasks = try taskStore.list(spaceId: space2.id)
        XCTAssertEqual(space2Tasks.count, 1)
        XCTAssertEqual(space2Tasks.first?.title, "Space 2 Task 1")
    }

    // MARK: - Error Tests

    func testGetNonexistentTask() throws {
        let result = try taskStore.get(UUID())
        XCTAssertNil(result, "Should return nil for nonexistent task")
    }

    func testUpdateStatusNonexistentTask() {
        XCTAssertThrowsError(try taskStore.updateStatus(UUID(), to: .done)) { error in
            XCTAssertTrue(error is TaskStore.TaskStoreError)
        }
    }

    func testCompleteNonexistentTask() {
        XCTAssertThrowsError(try taskStore.complete(UUID())) { error in
            XCTAssertTrue(error is TaskStore.TaskStoreError)
        }
    }

    func testArchiveNonexistentTask() {
        XCTAssertThrowsError(try taskStore.archive(UUID())) { error in
            XCTAssertTrue(error is TaskStore.TaskStoreError)
        }
    }

    func testDeleteNonexistentTask() throws {
        // Should not throw (GRDB deleteOne doesn't throw for nonexistent)
        try taskStore.delete(UUID())
    }

    // MARK: - Due Date Tests

    func testTaskWithDueDate() throws {
        let dueDate = ISO8601DateFormatter().date(from: "2025-12-31T23:59:59Z")!
        let task = Task(
            spaceId: testSpaceId,
            title: "Task with Due Date",
            dueDate: dueDate
        )
        try taskStore.create(task)

        let retrieved = try taskStore.get(task.id)
        XCTAssertNotNil(retrieved?.dueDate)
        // Compare timestamps (allow small difference due to encoding)
        let timeDiff = abs(retrieved!.dueDate!.timeIntervalSince(dueDate))
        XCTAssertLessThan(timeDiff, 1.0, "Due dates should match within 1 second")
    }
}
