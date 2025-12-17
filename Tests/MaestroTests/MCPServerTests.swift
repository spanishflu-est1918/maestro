import XCTest
import MCP
@testable import Maestro
@testable import MaestroCore

/// MCP Server Contract Tests
/// Tests the MCP interface layer to ensure tools work correctly
final class MCPServerTests: XCTestCase {
    var server: MaestroMCPServer!

    /// Helper to extract text from CallTool.Result
    private func extractText(from result: CallTool.Result) -> String? {
        guard case .text(let text) = result.content.first else {
            return nil
        }
        return text
    }

    override func setUp() async throws {
        try await super.setUp()
        server = try MaestroMCPServer()

        // Clean up any existing test data
        try server.db.write { db in
            try db.execute(sql: "DELETE FROM documents")
            try db.execute(sql: "DELETE FROM tasks")
            try db.execute(sql: "DELETE FROM spaces")
        }
    }

    override func tearDown() async throws {
        // Clean up test data
        try server.db.write { db in
            try db.execute(sql: "DELETE FROM documents")
            try db.execute(sql: "DELETE FROM tasks")
            try db.execute(sql: "DELETE FROM spaces")
        }
        try await super.tearDown()
    }

    // MARK: - Space Tests

    func testCreateSpace() async throws {
        let params = CallTool.Parameters(
            name: "maestro_create_space",
            arguments: [
                "name": .string("Test Space"),
                "color": .string("#FF0000")
            ]
        )

        let result = await server.handleCreateSpace(params)
        XCTAssertEqual(result.isError, false)

        let text = extractText(from: result)
        XCTAssertNotNil(text)

        let jsonData = text!.data(using: .utf8)!
        let space = try JSONDecoder().decode(Space.self, from: jsonData)
        XCTAssertEqual(space.name, "Test Space")
        XCTAssertEqual(space.color, "#FF0000")
    }

    func testListSpaces() async throws {
        // Create test spaces
        let space1 = Space(name: "Space 1", color: "#FF0000")
        let space2 = Space(name: "Space 2", color: "#00FF00")
        try server.spaceStore.create(space1)
        try server.spaceStore.create(space2)

        let params = CallTool.Parameters(
            name: "maestro_list_spaces",
            arguments: nil
        )

        let result = await server.handleListSpaces(params)
        XCTAssertEqual(result.isError, false)

        let text = extractText(from: result)!
        let jsonData = text.data(using: .utf8)!
        let spaces = try JSONDecoder().decode([Space].self, from: jsonData)
        XCTAssertEqual(spaces.count, 2)
    }

    func testGetSpace() async throws {
        let space = Space(name: "Test Space", color: "#FF0000")
        try server.spaceStore.create(space)

        let params = CallTool.Parameters(
            name: "maestro_get_space",
            arguments: ["id": .string(space.id.uuidString)]
        )

        let result = await server.handleGetSpace(params)
        XCTAssertEqual(result.isError, false)

        let text = extractText(from: result)!
        let jsonData = text.data(using: .utf8)!
        let retrievedSpace = try JSONDecoder().decode(Space.self, from: jsonData)
        XCTAssertEqual(retrievedSpace.id, space.id)
        XCTAssertEqual(retrievedSpace.name, "Test Space")
    }

    func testUpdateSpace() async throws {
        let space = Space(name: "Original Name", color: "#FF0000")
        try server.spaceStore.create(space)

        let params = CallTool.Parameters(
            name: "maestro_update_space",
            arguments: [
                "id": .string(space.id.uuidString),
                "name": .string("Updated Name"),
                "color": .string("#00FF00")
            ]
        )

        let result = await server.handleUpdateSpace(params)
        XCTAssertEqual(result.isError, false)

        let text = extractText(from: result)!
        let jsonData = text.data(using: .utf8)!
        let updatedSpace = try JSONDecoder().decode(Space.self, from: jsonData)
        XCTAssertEqual(updatedSpace.name, "Updated Name")
        XCTAssertEqual(updatedSpace.color, "#00FF00")
    }

    func testArchiveSpace() async throws {
        let space = Space(name: "Test Space", color: "#FF0000")
        try server.spaceStore.create(space)

        let params = CallTool.Parameters(
            name: "maestro_archive_space",
            arguments: ["id": .string(space.id.uuidString)]
        )

        let result = await server.handleArchiveSpace(params)
        XCTAssertEqual(result.isError, false)

        let archivedSpace = try server.spaceStore.get(space.id)
        XCTAssertTrue(archivedSpace?.archived ?? false)
    }

    func testDeleteSpace() async throws {
        let space = Space(name: "Test Space", color: "#FF0000")
        try server.spaceStore.create(space)

        let params = CallTool.Parameters(
            name: "maestro_delete_space",
            arguments: ["id": .string(space.id.uuidString)]
        )

        let result = await server.handleDeleteSpace(params)
        XCTAssertEqual(result.isError, false)

        let deletedSpace = try server.spaceStore.get(space.id)
        XCTAssertNil(deletedSpace)
    }

    // MARK: - Task Tests

    func testCreateTask() async throws {
        let space = Space(name: "Test Space", color: "#FF0000")
        try server.spaceStore.create(space)

        let params = CallTool.Parameters(
            name: "maestro_create_task",
            arguments: [
                "spaceId": .string(space.id.uuidString),
                "title": .string("Test Task"),
                "status": .string("inbox"),
                "priority": .string("high")
            ]
        )

        let result = await server.handleCreateTask(params)
        XCTAssertEqual(result.isError, false)

        let text = extractText(from: result)!
        let jsonData = text.data(using: .utf8)!
        let task = try JSONDecoder().decode(MaestroCore.Task.self, from: jsonData)
        XCTAssertEqual(task.title, "Test Task")
        XCTAssertEqual(task.status, .inbox)
        XCTAssertEqual(task.priority, .high)
    }

    func testListTasks() async throws {
        let space = Space(name: "Test Space", color: "#FF0000")
        try server.spaceStore.create(space)

        let task1 = MaestroCore.Task(spaceId: space.id, title: "Task 1")
        let task2 = MaestroCore.Task(spaceId: space.id, title: "Task 2")
        try server.taskStore.create(task1)
        try server.taskStore.create(task2)

        let params = CallTool.Parameters(
            name: "maestro_list_tasks",
            arguments: ["spaceId": .string(space.id.uuidString)]
        )

        let result = await server.handleListTasks(params)
        XCTAssertEqual(result.isError, false)

        let text = extractText(from: result)!
        let jsonData = text.data(using: .utf8)!
        let tasks = try JSONDecoder().decode([MaestroCore.Task].self, from: jsonData)
        XCTAssertEqual(tasks.count, 2)
    }

    func testGetTask() async throws {
        let space = Space(name: "Test Space", color: "#FF0000")
        try server.spaceStore.create(space)

        let task = MaestroCore.Task(spaceId: space.id, title: "Test Task")
        try server.taskStore.create(task)

        let params = CallTool.Parameters(
            name: "maestro_get_task",
            arguments: ["id": .string(task.id.uuidString)]
        )

        let result = await server.handleGetTask(params)
        XCTAssertEqual(result.isError, false)

        let text = extractText(from: result)!
        let jsonData = text.data(using: .utf8)!
        let retrievedTask = try JSONDecoder().decode(MaestroCore.Task.self, from: jsonData)
        XCTAssertEqual(retrievedTask.id, task.id)
        XCTAssertEqual(retrievedTask.title, "Test Task")
    }

    func testUpdateTask() async throws {
        let space = Space(name: "Test Space", color: "#FF0000")
        try server.spaceStore.create(space)

        let task = MaestroCore.Task(spaceId: space.id, title: "Original Title")
        try server.taskStore.create(task)

        let params = CallTool.Parameters(
            name: "maestro_update_task",
            arguments: [
                "id": .string(task.id.uuidString),
                "title": .string("Updated Title"),
                "status": .string("inProgress")
            ]
        )

        let result = await server.handleUpdateTask(params)
        XCTAssertEqual(result.isError, false)

        let text = extractText(from: result)!
        let jsonData = text.data(using: .utf8)!
        let updatedTask = try JSONDecoder().decode(MaestroCore.Task.self, from: jsonData)
        XCTAssertEqual(updatedTask.title, "Updated Title")
        XCTAssertEqual(updatedTask.status, .inProgress)
    }

    func testCompleteTask() async throws {
        let space = Space(name: "Test Space", color: "#FF0000")
        try server.spaceStore.create(space)

        let task = MaestroCore.Task(spaceId: space.id, title: "Test Task")
        try server.taskStore.create(task)

        let params = CallTool.Parameters(
            name: "maestro_complete_task",
            arguments: ["id": .string(task.id.uuidString)]
        )

        let result = await server.handleCompleteTask(params)
        XCTAssertEqual(result.isError, false)

        let completedTask = try server.taskStore.get(task.id)
        XCTAssertEqual(completedTask?.status, .done)
        XCTAssertNotNil(completedTask?.completedAt)
    }

    func testGetSurfacedTasks() async throws {
        let space = Space(name: "Test Space", color: "#FF0000")
        try server.spaceStore.create(space)

        // Create tasks with different priorities and statuses
        let task1 = MaestroCore.Task(spaceId: space.id, title: "Urgent InProgress", status: .inProgress, priority: .urgent, position: 1)
        let task2 = MaestroCore.Task(spaceId: space.id, title: "High Todo", status: .todo, priority: .high, position: 1)
        let task3 = MaestroCore.Task(spaceId: space.id, title: "Done Task", status: .done, priority: .high, position: 1)

        try server.taskStore.create(task1)
        try server.taskStore.create(task2)
        try server.taskStore.create(task3)

        let params = CallTool.Parameters(
            name: "maestro_get_surfaced_tasks",
            arguments: [
                "spaceId": .string(space.id.uuidString),
                "limit": .int(10)
            ]
        )

        let result = await server.handleGetSurfacedTasks(params)
        XCTAssertEqual(result.isError, false)

        let text = extractText(from: result)!
        let jsonData = text.data(using: .utf8)!
        let tasks = try JSONDecoder().decode([MaestroCore.Task].self, from: jsonData)

        // Should only get active tasks (not done)
        XCTAssertEqual(tasks.count, 2)
        // InProgress with urgent should be first
        XCTAssertEqual(tasks[0].title, "Urgent InProgress")
    }

    // MARK: - Document Tests

    func testCreateDocument() async throws {
        let space = Space(name: "Test Space", color: "#FF0000")
        try server.spaceStore.create(space)

        let params = CallTool.Parameters(
            name: "maestro_create_document",
            arguments: [
                "spaceId": .string(space.id.uuidString),
                "title": .string("Test Doc"),
                "content": .string("Test content")
            ]
        )

        let result = await server.handleCreateDocument(params)
        XCTAssertEqual(result.isError, false)

        let text = extractText(from: result)!
        let jsonData = text.data(using: .utf8)!
        let document = try JSONDecoder().decode(Document.self, from: jsonData)
        XCTAssertEqual(document.title, "Test Doc")
        XCTAssertEqual(document.content, "Test content")
    }

    func testListDocuments() async throws {
        let space = Space(name: "Test Space", color: "#FF0000")
        try server.spaceStore.create(space)

        let doc1 = Document(spaceId: space.id, title: "Doc 1", content: "Content 1")
        let doc2 = Document(spaceId: space.id, title: "Doc 2", content: "Content 2")
        try server.documentStore.create(doc1)
        try server.documentStore.create(doc2)

        let params = CallTool.Parameters(
            name: "maestro_list_documents",
            arguments: ["spaceId": .string(space.id.uuidString)]
        )

        let result = await server.handleListDocuments(params)
        XCTAssertEqual(result.isError, false)

        let text = extractText(from: result)!
        let jsonData = text.data(using: .utf8)!
        let documents = try JSONDecoder().decode([Document].self, from: jsonData)
        XCTAssertEqual(documents.count, 2)
    }

    func testPinDocument() async throws {
        let space = Space(name: "Test Space", color: "#FF0000")
        try server.spaceStore.create(space)

        let document = Document(spaceId: space.id, title: "Test Doc", content: "Content")
        try server.documentStore.create(document)

        let params = CallTool.Parameters(
            name: "maestro_pin_document",
            arguments: ["id": .string(document.id.uuidString)]
        )

        let result = await server.handlePinDocument(params)
        XCTAssertEqual(result.isError, false)

        let pinnedDoc = try server.documentStore.get(document.id)
        XCTAssertTrue(pinnedDoc?.isPinned ?? false)
    }

    func testSetDefaultDocument() async throws {
        let space = Space(name: "Test Space", color: "#FF0000")
        try server.spaceStore.create(space)

        let doc1 = Document(spaceId: space.id, title: "Doc 1", content: "Content 1", isDefault: true)
        let doc2 = Document(spaceId: space.id, title: "Doc 2", content: "Content 2")
        try server.documentStore.create(doc1)
        try server.documentStore.create(doc2)

        let params = CallTool.Parameters(
            name: "maestro_set_default_document",
            arguments: ["id": .string(doc2.id.uuidString)]
        )

        let result = await server.handleSetDefaultDocument(params)
        XCTAssertEqual(result.isError, false)

        let defaultDoc = try server.documentStore.getDefault(spaceId: space.id)
        XCTAssertEqual(defaultDoc?.id, doc2.id)
    }

    func testGetDefaultDocument() async throws {
        let space = Space(name: "Test Space", color: "#FF0000")
        try server.spaceStore.create(space)

        let document = Document(spaceId: space.id, title: "Default Doc", content: "Content", isDefault: true)
        try server.documentStore.create(document)

        let params = CallTool.Parameters(
            name: "maestro_get_default_document",
            arguments: ["spaceId": .string(space.id.uuidString)]
        )

        let result = await server.handleGetDefaultDocument(params)
        XCTAssertEqual(result.isError, false)

        let text = extractText(from: result)!
        let jsonData = text.data(using: .utf8)!
        let defaultDoc = try JSONDecoder().decode(Document.self, from: jsonData)
        XCTAssertEqual(defaultDoc.id, document.id)
        XCTAssertTrue(defaultDoc.isDefault)
    }

    // MARK: - Error Handling Tests

    func testCreateSpaceMissingParameters() async throws {
        let params = CallTool.Parameters(
            name: "maestro_create_space",
            arguments: ["name": .string("Test Space")]
            // Missing required 'color' parameter
        )

        let result = await server.handleCreateSpace(params)
        XCTAssertEqual(result.isError, true)

        let text = extractText(from: result)!
        XCTAssertTrue(text.contains("Missing required parameters"))
    }

    func testGetSpaceInvalidUUID() async throws {
        let params = CallTool.Parameters(
            name: "maestro_get_space",
            arguments: ["id": .string("invalid-uuid")]
        )

        let result = await server.handleGetSpace(params)
        XCTAssertEqual(result.isError, true)

        let text = extractText(from: result)!
        XCTAssertTrue(text.contains("Invalid or missing id"))
    }

    func testGetSpaceNotFound() async throws {
        let nonExistentId = UUID().uuidString
        let params = CallTool.Parameters(
            name: "maestro_get_space",
            arguments: ["id": .string(nonExistentId)]
        )

        let result = await server.handleGetSpace(params)
        XCTAssertEqual(result.isError, true)

        let text = extractText(from: result)!
        XCTAssertTrue(text.contains("not found"))
    }

    func testCreateTaskMissingParameters() async throws {
        let params = CallTool.Parameters(
            name: "maestro_create_task",
            arguments: ["title": .string("Test Task")]
            // Missing required 'spaceId' parameter
        )

        let result = await server.handleCreateTask(params)
        XCTAssertEqual(result.isError, true)

        let text = extractText(from: result)!
        XCTAssertTrue(text.contains("Missing required parameters"))
    }
}
