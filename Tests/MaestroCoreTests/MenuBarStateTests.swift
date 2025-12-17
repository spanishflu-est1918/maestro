import XCTest
@testable import MaestroCore

/// MenuBarState Model Tests
final class MenuBarStateTests: XCTestCase {

    func testMenuBarColor_rawValues() {
        XCTAssertEqual(MenuBarColor.clear.rawValue, "clear")
        XCTAssertEqual(MenuBarColor.attention.rawValue, "attention")
        XCTAssertEqual(MenuBarColor.input.rawValue, "input")
        XCTAssertEqual(MenuBarColor.urgent.rawValue, "urgent")
    }

    func testMenuBarColor_codable() throws {
        let color = MenuBarColor.urgent

        let encoder = JSONEncoder()
        let data = try encoder.encode(color)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(MenuBarColor.self, from: data)

        XCTAssertEqual(decoded, color)
    }

    func testStatusSummary_initialization() {
        let summary = StatusSummary(
            overdueTaskCount: 2,
            staleTaskCount: 1,
            agentsNeedingInputCount: 1,
            activeAgentCount: 3,
            linearDoneCount: 5,
            linearAssignedCount: 2
        )

        XCTAssertEqual(summary.overdueTaskCount, 2)
        XCTAssertEqual(summary.staleTaskCount, 1)
        XCTAssertEqual(summary.agentsNeedingInputCount, 1)
        XCTAssertEqual(summary.activeAgentCount, 3)
        XCTAssertEqual(summary.linearDoneCount, 5)
        XCTAssertEqual(summary.linearAssignedCount, 2)
    }

    func testStatusSummary_codable() throws {
        let summary = StatusSummary(
            overdueTaskCount: 2,
            staleTaskCount: 1,
            agentsNeedingInputCount: 1,
            activeAgentCount: 3,
            linearDoneCount: 5,
            linearAssignedCount: 2
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(summary)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(StatusSummary.self, from: data)

        XCTAssertEqual(decoded.overdueTaskCount, summary.overdueTaskCount)
        XCTAssertEqual(decoded.staleTaskCount, summary.staleTaskCount)
        XCTAssertEqual(decoded.agentsNeedingInputCount, summary.agentsNeedingInputCount)
        XCTAssertEqual(decoded.activeAgentCount, summary.activeAgentCount)
        XCTAssertEqual(decoded.linearDoneCount, summary.linearDoneCount)
        XCTAssertEqual(decoded.linearAssignedCount, summary.linearAssignedCount)
    }

    func testMenuBarState_initialization() {
        let summary = StatusSummary(
            overdueTaskCount: 1,
            staleTaskCount: 0,
            agentsNeedingInputCount: 0,
            activeAgentCount: 0,
            linearDoneCount: 0,
            linearAssignedCount: 0
        )

        let state = MenuBarState(
            color: .urgent,
            badgeCount: 1,
            summary: summary,
            updatedAt: Date()
        )

        XCTAssertEqual(state.color, .urgent)
        XCTAssertEqual(state.badgeCount, 1)
        XCTAssertEqual(state.summary.overdueTaskCount, 1)
    }

    func testMenuBarState_codable() throws {
        let summary = StatusSummary(
            overdueTaskCount: 2,
            staleTaskCount: 1,
            agentsNeedingInputCount: 1,
            activeAgentCount: 3,
            linearDoneCount: 5,
            linearAssignedCount: 2
        )

        let updatedAt = Date()
        let state = MenuBarState(
            color: .urgent,
            badgeCount: 3,
            summary: summary,
            updatedAt: updatedAt
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(state)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(MenuBarState.self, from: data)

        XCTAssertEqual(decoded.color, state.color)
        XCTAssertEqual(decoded.badgeCount, state.badgeCount)
        XCTAssertEqual(decoded.summary.overdueTaskCount, state.summary.overdueTaskCount)
        // Date comparison with tolerance for encoding precision
        XCTAssertEqual(decoded.updatedAt.timeIntervalSince1970, updatedAt.timeIntervalSince1970, accuracy: 1.0)
    }
}
