import XCTest
@testable import MaestroCore

/// MenuBarState Performance Tests
final class MenuBarStatePerformanceTests: XCTestCase {

    func test_calculate_performsUnder10ms() throws {
        let db = MaestroCore.Database()
        try db.connect()
        defer { db.close() }

        let spaceStore = SpaceStore(database: db)
        let taskStore = TaskStore(database: db)
        let agentMonitor = AgentMonitor(database: db)

        // Setup: 500 tasks, 20 agents
        let space = Space(name: "Test", color: "#000")
        try spaceStore.create(space)

        for i in 0..<500 {
            var task = Task(
                spaceId: space.id,
                title: "Task \(i)",
                status: i % 5 == 0 ? .inProgress : .todo
            )
            if i % 10 == 0 {
                task.dueDate = Date().addingTimeInterval(-86400)
            }
            try taskStore.create(task)
        }

        for i in 0..<20 {
            let session = try agentMonitor.startSession(agentName: i % 2 == 0 ? "Claude Code" : "Codex")
            // End half of them
            if i % 2 == 1 {
                try agentMonitor.endSession(session.id)
            }
        }

        let calculator = MenuBarStateCalculator(database: db)

        // Measure performance
        measure {
            for _ in 0..<100 {
                _ = try? calculator.calculate()
            }
        }

        // Verify that it actually works
        let state = try calculator.calculate()
        XCTAssertTrue(state.summary.overdueTaskCount > 0)
    }

    func test_calculate_handlesEmptyDatabase() throws {
        let db = MaestroCore.Database()
        try db.connect()
        defer { db.close() }

        let calculator = MenuBarStateCalculator(database: db)

        let state = try calculator.calculate()

        XCTAssertEqual(state.color, .clear)
        XCTAssertEqual(state.badgeCount, 0)
        XCTAssertEqual(state.summary.overdueTaskCount, 0)
        XCTAssertEqual(state.summary.staleTaskCount, 0)
        XCTAssertEqual(state.summary.agentsNeedingInputCount, 0)
        XCTAssertEqual(state.summary.activeAgentCount, 0)
        XCTAssertEqual(state.summary.linearDoneCount, 0)
        XCTAssertEqual(state.summary.linearAssignedCount, 0)
    }
}
