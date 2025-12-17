import XCTest
@testable import MaestroCore

/// MenuBarState Agent Integration Tests
final class MenuBarStateAgentTests: XCTestCase {

    var db: MaestroCore.Database!
    var agentMonitor: AgentMonitor!

    override func setUp() async throws {
        db = MaestroCore.Database()
        try db.connect()
        agentMonitor = AgentMonitor(database: db)
    }

    override func tearDown() async throws {
        db.close()
        db = nil
    }

    func test_activeAgentCount_excludesEnded() throws {
        let calculator = MenuBarStateCalculator(database: db)

        // Start 3 sessions
        let session1 = try agentMonitor.startSession(agentName: "Claude Code")
        let session2 = try agentMonitor.startSession(agentName: "Codex")
        let session3 = try agentMonitor.startSession(agentName: "Claude Code")

        // End one session
        try agentMonitor.endSession(session3.id)

        let state = try calculator.calculate()

        XCTAssertEqual(state.summary.activeAgentCount, 2) // Only active sessions
    }

    func test_noAgentMetrics_whenNoSessions() throws {
        let calculator = MenuBarStateCalculator(database: db)

        let state = try calculator.calculate()

        XCTAssertEqual(state.summary.activeAgentCount, 0)
        XCTAssertEqual(state.summary.agentsNeedingInputCount, 0)
    }

    func test_activeAgentCount_countsActiveSessions() throws {
        let calculator = MenuBarStateCalculator(database: db)

        // Start 5 active sessions
        try agentMonitor.startSession(agentName: "Claude Code")
        try agentMonitor.startSession(agentName: "Codex")
        try agentMonitor.startSession(agentName: "Claude Code")
        try agentMonitor.startSession(agentName: "Codex")
        try agentMonitor.startSession(agentName: "Claude Code")

        let state = try calculator.calculate()

        XCTAssertEqual(state.summary.activeAgentCount, 5)
    }
}
