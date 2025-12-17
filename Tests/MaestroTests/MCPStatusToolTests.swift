import XCTest
@testable import Maestro
@testable import MaestroCore
import MCP

/// MCP Status Tool Tests
final class MCPStatusToolTests: XCTestCase {

    func test_getStatus_returnsFullSummary() async throws {
        // Create temporary database
        let tempDir = FileManager.default.temporaryDirectory
        let dbPath = tempDir.appendingPathComponent("status-test-\(UUID().uuidString).db").path
        defer {
            try? FileManager.default.removeItem(atPath: dbPath)
        }

        let server = try MaestroMCPServer(databasePath: dbPath)

        // Setup: 1 overdue task
        let spaceStore = SpaceStore(database: server.db)
        let taskStore = TaskStore(database: server.db)

        let space = Space(name: "Test Space", color: "#FF0000")
        try spaceStore.create(space)

        let task = Task(
            spaceId: space.id,
            title: "Overdue",
            status: .todo,
            dueDate: Date().addingTimeInterval(-86400)
        )
        try taskStore.create(task)

        let result = await server.handleGetStatus(CallTool.Parameters(name: "maestro_get_status", arguments: nil))

        // Parse JSON response
        guard case .text(let jsonString) = result.content.first else {
            XCTFail("Expected text content")
            return
        }

        let data = jsonString.data(using: String.Encoding.utf8)!
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(json["color"] as? String, "urgent")
        XCTAssertEqual(json["badgeCount"] as? Int, 1)
        XCTAssertEqual(json["overdueTaskCount"] as? Int, 1)
        XCTAssertEqual(json["staleTaskCount"] as? Int, 0)
        XCTAssertEqual(json["agentsNeedingInputCount"] as? Int, 0)
        XCTAssertEqual(json["activeAgentCount"] as? Int, 0)
    }

    func test_getStatus_includesTimestamp() async throws {
        let tempDir = FileManager.default.temporaryDirectory
        let dbPath = tempDir.appendingPathComponent("status-timestamp-test-\(UUID().uuidString).db").path
        defer {
            try? FileManager.default.removeItem(atPath: dbPath)
        }

        let server = try MaestroMCPServer(databasePath: dbPath)

        let result = await server.handleGetStatus(CallTool.Parameters(name: "maestro_get_status", arguments: nil))

        guard case .text(let jsonString) = result.content.first else {
            XCTFail("Expected text content")
            return
        }

        let data = jsonString.data(using: String.Encoding.utf8)!
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertNotNil(json["updatedAt"])
    }

    func test_getStatus_includesLinearCounts() async throws {
        let tempDir = FileManager.default.temporaryDirectory
        let dbPath = tempDir.appendingPathComponent("status-linear-test-\(UUID().uuidString).db").path
        defer {
            try? FileManager.default.removeItem(atPath: dbPath)
        }

        let server = try MaestroMCPServer(databasePath: dbPath)

        // Setup Linear done issue
        let spaceStore = SpaceStore(database: server.db)
        let taskStore = TaskStore(database: server.db)
        let linearSync = LinearSync(database: server.db, apiKey: "test-key")

        let space = Space(name: "Test Space", color: "#FF0000")
        try spaceStore.create(space)

        let task = Task(spaceId: space.id, title: "Task 1", status: .todo)
        try taskStore.create(task)

        try linearSync.linkIssue(
            taskId: task.id,
            linearIssueId: "issue-1",
            linearIssueKey: "MAE-1",
            linearTeamId: "team-1",
            linearState: "Done"
        )

        let result = await server.handleGetStatus(CallTool.Parameters(name: "maestro_get_status", arguments: nil))

        guard case .text(let jsonString) = result.content.first else {
            XCTFail("Expected text content")
            return
        }

        let data = jsonString.data(using: String.Encoding.utf8)!
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(json["linearDoneCount"] as? Int, 1)
    }

    func test_getStatus_returnsValidJSON() async throws {
        let tempDir = FileManager.default.temporaryDirectory
        let dbPath = tempDir.appendingPathComponent("status-json-test-\(UUID().uuidString).db").path
        defer {
            try? FileManager.default.removeItem(atPath: dbPath)
        }

        let server = try MaestroMCPServer(databasePath: dbPath)

        // Verify the tool returns valid JSON
        let result = await server.handleGetStatus(CallTool.Parameters(name: "maestro_get_status", arguments: nil))

        guard case .text(let jsonString) = result.content.first else {
            XCTFail("Expected text content")
            return
        }

        // Should be valid JSON
        let data = jsonString.data(using: String.Encoding.utf8)!
        XCTAssertNoThrow(try JSONSerialization.jsonObject(with: data))
    }
}
