import XCTest
@testable import MaestroCore

/// MenuBarStateCalculator Tests
final class MenuBarStateCalculatorTests: XCTestCase {

    var db: MaestroCore.Database!
    var spaceStore: SpaceStore!
    var taskStore: TaskStore!
    var spaceId: UUID!

    override func setUp() async throws {
        db = MaestroCore.Database()
        try db.connect()

        spaceStore = SpaceStore(database: db)
        taskStore = TaskStore(database: db)

        // Create test space
        let space = Space(name: "Test Space", color: "#FF0000")
        try spaceStore.create(space)
        spaceId = space.id
    }

    override func tearDown() async throws {
        db.close()
        db = nil
    }

    // MARK: - Color Logic

    func test_clearState_whenNoIssues() throws {
        let calculator = MenuBarStateCalculator(database: db)

        let state = try calculator.calculate()

        XCTAssertEqual(state.color, .clear)
        XCTAssertEqual(state.badgeCount, 0)
    }

    func test_urgentState_whenOverdueTask() throws {
        let calculator = MenuBarStateCalculator(database: db)

        // Create overdue task
        let task = Task(
            spaceId: spaceId,
            title: "Overdue task",
            status: .todo,
            dueDate: Date().addingTimeInterval(-24 * 60 * 60) // Yesterday
        )
        try taskStore.create(task)

        let state = try calculator.calculate()

        XCTAssertEqual(state.color, .urgent)
        XCTAssertEqual(state.summary.overdueTaskCount, 1)
        XCTAssertEqual(state.badgeCount, 1)
    }

    func test_urgentState_multipleOverdueTasks() throws {
        let calculator = MenuBarStateCalculator(database: db)

        try taskStore.create(Task(spaceId: spaceId, title: "Overdue 1", status: .todo, dueDate: Date().addingTimeInterval(-86400)))
        try taskStore.create(Task(spaceId: spaceId, title: "Overdue 2", status: .todo, dueDate: Date().addingTimeInterval(-86400)))
        try taskStore.create(Task(spaceId: spaceId, title: "Overdue 3", status: .inProgress, dueDate: Date().addingTimeInterval(-86400)))

        let state = try calculator.calculate()

        XCTAssertEqual(state.color, .urgent)
        XCTAssertEqual(state.summary.overdueTaskCount, 3)
        XCTAssertEqual(state.badgeCount, 3)
    }

    func test_notOverdue_whenDueDateInFuture() throws {
        let calculator = MenuBarStateCalculator(database: db)

        let task = Task(
            spaceId: spaceId,
            title: "Future task",
            status: .todo,
            dueDate: Date().addingTimeInterval(24 * 60 * 60) // Tomorrow
        )
        try taskStore.create(task)

        let state = try calculator.calculate()

        XCTAssertEqual(state.color, .clear)
        XCTAssertEqual(state.summary.overdueTaskCount, 0)
    }

    func test_notOverdue_whenTaskDone() throws {
        let calculator = MenuBarStateCalculator(database: db)

        // Overdue but completed - shouldn't count
        var task = Task(
            spaceId: spaceId,
            title: "Done task",
            status: .done,
            dueDate: Date().addingTimeInterval(-86400)
        )
        task.completedAt = Date()
        try taskStore.create(task)

        let state = try calculator.calculate()

        XCTAssertEqual(state.color, .clear)
        XCTAssertEqual(state.summary.overdueTaskCount, 0)
    }

    func test_attentionState_whenStaleTask() throws {
        let calculator = MenuBarStateCalculator(database: db)

        // Task in progress, not updated for 4 days
        var task = Task(
            spaceId: spaceId,
            title: "Stale task",
            status: .inProgress
        )
        task.createdAt = Date().addingTimeInterval(-10 * 86400)
        task.updatedAt = Date().addingTimeInterval(-4 * 86400) // 4 days ago
        try taskStore.create(task)

        let state = try calculator.calculate()

        XCTAssertEqual(state.color, .attention)
        XCTAssertEqual(state.summary.staleTaskCount, 1)
        XCTAssertEqual(state.badgeCount, 0) // Stale doesn't increment badge
    }

    func test_notStale_whenTodoStatus() throws {
        let calculator = MenuBarStateCalculator(database: db)

        // Todo tasks can sit - only inProgress goes stale
        var task = Task(
            spaceId: spaceId,
            title: "Old todo",
            status: .todo
        )
        task.createdAt = Date().addingTimeInterval(-10 * 86400)
        task.updatedAt = Date().addingTimeInterval(-10 * 86400)
        try taskStore.create(task)

        let state = try calculator.calculate()

        XCTAssertEqual(state.summary.staleTaskCount, 0)
    }

    func test_notStale_whenRecentlyUpdated() throws {
        let calculator = MenuBarStateCalculator(database: db)

        var task = Task(
            spaceId: spaceId,
            title: "Active task",
            status: .inProgress
        )
        task.createdAt = Date().addingTimeInterval(-10 * 86400)
        task.updatedAt = Date().addingTimeInterval(-1 * 86400) // 1 day ago
        try taskStore.create(task)

        let state = try calculator.calculate()

        XCTAssertEqual(state.summary.staleTaskCount, 0)
    }

    // MARK: - Priority Order (without agents for now)

    func test_attentionOverridesClear() throws {
        let calculator = MenuBarStateCalculator(database: db)

        // Only stale task, no urgent/input
        var task = Task(
            spaceId: spaceId,
            title: "Stale",
            status: .inProgress
        )
        task.updatedAt = Date().addingTimeInterval(-4 * 86400)
        try taskStore.create(task)

        let state = try calculator.calculate()

        XCTAssertEqual(state.color, .attention)
    }

    // MARK: - Badge Count

    func test_badgeCount_countsOverdue() throws {
        let calculator = MenuBarStateCalculator(database: db)

        // 2 overdue
        try taskStore.create(Task(spaceId: spaceId, title: "O1", status: .todo, dueDate: Date().addingTimeInterval(-86400)))
        try taskStore.create(Task(spaceId: spaceId, title: "O2", status: .todo, dueDate: Date().addingTimeInterval(-86400)))

        let state = try calculator.calculate()

        XCTAssertEqual(state.badgeCount, 2)
    }

    func test_badgeCount_excludesStale() throws {
        let calculator = MenuBarStateCalculator(database: db)

        // 1 stale task
        var task = Task(
            spaceId: spaceId,
            title: "Stale",
            status: .inProgress
        )
        task.updatedAt = Date().addingTimeInterval(-4 * 86400)
        try taskStore.create(task)

        let state = try calculator.calculate()

        XCTAssertEqual(state.badgeCount, 0) // Stale doesn't count
        XCTAssertEqual(state.color, .attention)
    }

    // MARK: - Configuration

    func test_staleThreshold_isConfigurable() throws {
        let calculator = MenuBarStateCalculator(database: db, staleThresholdDays: 7)

        // 5 days old - not stale with 7-day threshold
        var task = Task(
            spaceId: spaceId,
            title: "Recent-ish",
            status: .inProgress
        )
        task.updatedAt = Date().addingTimeInterval(-5 * 86400)
        try taskStore.create(task)

        let state = try calculator.calculate()

        XCTAssertEqual(state.summary.staleTaskCount, 0)
    }

    func test_staleThreshold_defaultsTo3Days() throws {
        let calculator = MenuBarStateCalculator(database: db)

        // 2 days old - not stale
        var task1 = Task(
            spaceId: spaceId,
            title: "2 days",
            status: .inProgress
        )
        task1.updatedAt = Date().addingTimeInterval(-2 * 86400)
        try taskStore.create(task1)

        // 4 days old - stale
        var task2 = Task(
            spaceId: spaceId,
            title: "4 days",
            status: .inProgress
        )
        task2.updatedAt = Date().addingTimeInterval(-4 * 86400)
        try taskStore.create(task2)

        let state = try calculator.calculate()

        XCTAssertEqual(state.summary.staleTaskCount, 1)
    }
}
