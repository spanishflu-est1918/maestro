import XCTest
@testable import MaestroCore

/// MenuBarState Linear Integration Tests
final class MenuBarStateLinearTests: XCTestCase {

    var db: MaestroCore.Database!
    var spaceStore: SpaceStore!
    var taskStore: TaskStore!
    var linearSync: LinearSync!
    var spaceId: UUID!
    var taskId: UUID!
    var taskId2: UUID!

    override func setUp() async throws {
        db = MaestroCore.Database()
        try db.connect()

        spaceStore = SpaceStore(database: db)
        taskStore = TaskStore(database: db)
        linearSync = LinearSync(database: db, apiKey: "test-key")

        // Create test space
        let space = Space(name: "Test Space", color: "#FF0000")
        try spaceStore.create(space)
        spaceId = space.id

        // Create test tasks
        let task1 = Task(spaceId: spaceId, title: "Task 1", status: .todo)
        try taskStore.create(task1)
        taskId = task1.id

        let task2 = Task(spaceId: spaceId, title: "Task 2", status: .todo)
        try taskStore.create(task2)
        taskId2 = task2.id
    }

    override func tearDown() async throws {
        db.close()
        db = nil
    }

    func test_linearDoneCount_countsLast24Hours() throws {
        let calculator = MenuBarStateCalculator(database: db)

        // Issue marked done 12 hours ago
        try linearSync.linkIssue(
            taskId: taskId,
            linearIssueId: "issue-1",
            linearIssueKey: "MAE-1",
            linearTeamId: "team-1",
            linearState: "Done"
        )

        // Update the link's updatedAt to 12 hours ago
        try db.write { db in
            try db.execute(
                sql: """
                    UPDATE linear_sync
                    SET updated_at = datetime('now', '-12 hours')
                    WHERE linear_issue_id = 'issue-1'
                    """
            )
        }

        // Issue marked done 36 hours ago - shouldn't count
        try linearSync.linkIssue(
            taskId: taskId2,
            linearIssueId: "issue-2",
            linearIssueKey: "MAE-2",
            linearTeamId: "team-1",
            linearState: "Done"
        )

        // Update the link's updatedAt to 36 hours ago
        try db.write { db in
            try db.execute(
                sql: """
                    UPDATE linear_sync
                    SET updated_at = datetime('now', '-36 hours')
                    WHERE linear_issue_id = 'issue-2'
                    """
            )
        }

        let state = try calculator.calculate()

        XCTAssertEqual(state.summary.linearDoneCount, 1)
    }

    func test_linearDoneCount_onlyCountsDoneState() throws {
        let calculator = MenuBarStateCalculator(database: db)

        // In Progress - shouldn't count
        try linearSync.linkIssue(
            taskId: taskId,
            linearIssueId: "issue-1",
            linearIssueKey: "MAE-1",
            linearTeamId: "team-1",
            linearState: "In Progress"
        )

        let state = try calculator.calculate()

        XCTAssertEqual(state.summary.linearDoneCount, 0)
    }
}
