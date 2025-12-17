import Foundation
import MCP
import MaestroCore

/// Maestro MCP Server
public final class MaestroMCPServer {
    private let server: Server
    let db: Database
    let spaceStore: SpaceStore
    let taskStore: TaskStore
    let documentStore: DocumentStore

    public init() throws {
        // Initialize database
        db = Database()
        try db.connect()

        // Initialize stores
        spaceStore = SpaceStore(database: db)
        taskStore = TaskStore(database: db)
        documentStore = DocumentStore(database: db)

        // Create server with capabilities
        server = Server(
            name: "maestro",
            version: "0.1.0",
            capabilities: .init(
                tools: .init(listChanged: true)
            )
        )
    }

    public func start() async throws {
        // Register tool handlers
        await registerListTools()
        await registerSpaceTools()
        await registerTaskTools()
        await registerDocumentTools()

        // Start server with stdio transport
        let transport = StdioTransport()
        try await server.start(transport: transport)
    }

    // MARK: - Tool Registration

    private func registerListTools() async {
        await server.withMethodHandler(ListTools.self) { [weak self] _ in
            guard let self = self else {
                return .init(tools: [])
            }

            var tools: [Tool] = []

            // Spaces tools
            tools.append(contentsOf: [
                self.makeListSpacesTool(),
                self.makeGetSpaceTool(),
                self.makeCreateSpaceTool(),
                self.makeUpdateSpaceTool(),
                self.makeArchiveSpaceTool(),
                self.makeDeleteSpaceTool()
            ])

            // Tasks tools
            tools.append(contentsOf: [
                self.makeListTasksTool(),
                self.makeGetTaskTool(),
                self.makeCreateTaskTool(),
                self.makeUpdateTaskTool(),
                self.makeCompleteTaskTool(),
                self.makeArchiveTaskTool(),
                self.makeDeleteTaskTool(),
                self.makeGetSurfacedTasksTool()
            ])

            // Documents tools
            tools.append(contentsOf: [
                self.makeListDocumentsTool(),
                self.makeGetDocumentTool(),
                self.makeCreateDocumentTool(),
                self.makeUpdateDocumentTool(),
                self.makePinDocumentTool(),
                self.makeUnpinDocumentTool(),
                self.makeDeleteDocumentTool(),
                self.makeGetDefaultDocumentTool(),
                self.makeSetDefaultDocumentTool()
            ])

            return .init(tools: tools)
        }
    }

    private func registerSpaceTools() async {
        await server.withMethodHandler(CallTool.self) { [weak self] params in
            guard let self = self else {
                return .init(content: [.text("Server not available")], isError: true)
            }

            switch params.name {
            case "maestro_list_spaces":
                return await self.handleListSpaces(params)
            case "maestro_get_space":
                return await self.handleGetSpace(params)
            case "maestro_create_space":
                return await self.handleCreateSpace(params)
            case "maestro_update_space":
                return await self.handleUpdateSpace(params)
            case "maestro_archive_space":
                return await self.handleArchiveSpace(params)
            case "maestro_delete_space":
                return await self.handleDeleteSpace(params)

            case "maestro_list_tasks":
                return await self.handleListTasks(params)
            case "maestro_get_task":
                return await self.handleGetTask(params)
            case "maestro_create_task":
                return await self.handleCreateTask(params)
            case "maestro_update_task":
                return await self.handleUpdateTask(params)
            case "maestro_complete_task":
                return await self.handleCompleteTask(params)
            case "maestro_archive_task":
                return await self.handleArchiveTask(params)
            case "maestro_delete_task":
                return await self.handleDeleteTask(params)
            case "maestro_get_surfaced_tasks":
                return await self.handleGetSurfacedTasks(params)

            case "maestro_list_documents":
                return await self.handleListDocuments(params)
            case "maestro_get_document":
                return await self.handleGetDocument(params)
            case "maestro_create_document":
                return await self.handleCreateDocument(params)
            case "maestro_update_document":
                return await self.handleUpdateDocument(params)
            case "maestro_pin_document":
                return await self.handlePinDocument(params)
            case "maestro_unpin_document":
                return await self.handleUnpinDocument(params)
            case "maestro_delete_document":
                return await self.handleDeleteDocument(params)
            case "maestro_get_default_document":
                return await self.handleGetDefaultDocument(params)
            case "maestro_set_default_document":
                return await self.handleSetDefaultDocument(params)

            default:
                return .init(content: [.text("Unknown tool: \(params.name)")], isError: true)
            }
        }
    }

    private func registerTaskTools() async {
        // Task tools are handled in registerSpaceTools (all tools in one handler)
    }

    private func registerDocumentTools() async {
        // Document tools are handled in registerSpaceTools (all tools in one handler)
    }
}

// MARK: - Tool Definitions (continued in next file for readability)
