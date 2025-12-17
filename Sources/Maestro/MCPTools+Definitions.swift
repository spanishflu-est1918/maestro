import Foundation
import MCP
import MaestroCore

// MARK: - Tool Definitions

extension MaestroMCPServer {
    // MARK: - Spaces Tool Definitions

    func makeListSpacesTool() -> Tool {
        Tool(
            name: "maestro_list_spaces",
            description: "List all spaces with optional filters",
            inputSchema: .object([
                "type": "object",
                "properties": .object([
                    "includeArchived": .object([
                        "type": "boolean",
                        "description": "Include archived spaces (default: false)"
                    ]),
                    "parentId": .object([
                        "type": "string",
                        "description": "Filter by parent ID (optional)"
                    ])
                ]),
                "additionalProperties": false
            ])
        )
    }

    func makeGetSpaceTool() -> Tool {
        Tool(
            name: "maestro_get_space",
            description: "Get a space by ID",
            inputSchema: .object([
                "type": "object",
                "properties": .object([
                    "id": .object([
                        "type": "string",
                        "description": "Space ID (UUID)"
                    ])
                ]),
                "required": .array(["id"]),
                "additionalProperties": false
            ])
        )
    }

    func makeCreateSpaceTool() -> Tool {
        Tool(
            name: "maestro_create_space",
            description: "Create a new space",
            inputSchema: .object([
                "type": "object",
                "properties": .object([
                    "name": .object([
                        "type": "string",
                        "description": "Space name"
                    ]),
                    "color": .object([
                        "type": "string",
                        "description": "Space color (hex code, e.g. #FF0000)"
                    ]),
                    "parentId": .object([
                        "type": "string",
                        "description": "Parent space ID (optional)"
                    ]),
                    "tags": .object([
                        "type": "array",
                        "items": .object(["type": "string"]),
                        "description": "Tags for the space"
                    ]),
                    "path": .object([
                        "type": "string",
                        "description": "File system path (optional)"
                    ])
                ]),
                "required": .array(["name", "color"]),
                "additionalProperties": false
            ])
        )
    }

    func makeUpdateSpaceTool() -> Tool {
        Tool(
            name: "maestro_update_space",
            description: "Update a space",
            inputSchema: .object([
                "type": "object",
                "properties": .object([
                    "id": .object([
                        "type": "string",
                        "description": "Space ID (UUID)"
                    ]),
                    "name": .object([
                        "type": "string",
                        "description": "New name (optional)"
                    ]),
                    "color": .object([
                        "type": "string",
                        "description": "New color (optional)"
                    ]),
                    "tags": .object([
                        "type": "array",
                        "items": .object(["type": "string"]),
                        "description": "New tags (optional)"
                    ])
                ]),
                "required": .array(["id"]),
                "additionalProperties": false
            ])
        )
    }

    func makeArchiveSpaceTool() -> Tool {
        Tool(
            name: "maestro_archive_space",
            description: "Archive a space",
            inputSchema: .object([
                "type": "object",
                "properties": .object([
                    "id": .object([
                        "type": "string",
                        "description": "Space ID (UUID)"
                    ])
                ]),
                "required": .array(["id"]),
                "additionalProperties": false
            ])
        )
    }

    func makeDeleteSpaceTool() -> Tool {
        Tool(
            name: "maestro_delete_space",
            description: "Delete a space permanently",
            inputSchema: .object([
                "type": "object",
                "properties": .object([
                    "id": .object([
                        "type": "string",
                        "description": "Space ID (UUID)"
                    ])
                ]),
                "required": .array(["id"]),
                "additionalProperties": false
            ])
        )
    }

    // MARK: - Tasks Tool Definitions

    func makeListTasksTool() -> Tool {
        Tool(
            name: "maestro_list_tasks",
            description: "List tasks with optional filters",
            inputSchema: .object([
                "type": "object",
                "properties": .object([
                    "spaceId": .object([
                        "type": "string",
                        "description": "Filter by space ID (optional)"
                    ]),
                    "status": .object([
                        "type": "string",
                        "enum": .array(["inbox", "todo", "inProgress", "done", "archived"]),
                        "description": "Filter by status (optional)"
                    ]),
                    "includeArchived": .object([
                        "type": "boolean",
                        "description": "Include archived tasks (default: false)"
                    ])
                ]),
                "additionalProperties": false
            ])
        )
    }

    func makeGetTaskTool() -> Tool {
        Tool(
            name: "maestro_get_task",
            description: "Get a task by ID",
            inputSchema: .object([
                "type": "object",
                "properties": .object([
                    "id": .object([
                        "type": "string",
                        "description": "Task ID (UUID)"
                    ])
                ]),
                "required": .array(["id"]),
                "additionalProperties": false
            ])
        )
    }

    func makeCreateTaskTool() -> Tool {
        Tool(
            name: "maestro_create_task",
            description: "Create a new task",
            inputSchema: .object([
                "type": "object",
                "properties": .object([
                    "spaceId": .object([
                        "type": "string",
                        "description": "Space ID (UUID)"
                    ]),
                    "title": .object([
                        "type": "string",
                        "description": "Task title"
                    ]),
                    "description": .object([
                        "type": "string",
                        "description": "Task description (optional)"
                    ]),
                    "status": .object([
                        "type": "string",
                        "enum": .array(["inbox", "todo", "inProgress", "done"]),
                        "description": "Task status (default: inbox)"
                    ]),
                    "priority": .object([
                        "type": "string",
                        "enum": .array(["none", "low", "medium", "high", "urgent"]),
                        "description": "Task priority (default: none)"
                    ])
                ]),
                "required": .array(["spaceId", "title"]),
                "additionalProperties": false
            ])
        )
    }

    func makeUpdateTaskTool() -> Tool {
        Tool(
            name: "maestro_update_task",
            description: "Update a task",
            inputSchema: .object([
                "type": "object",
                "properties": .object([
                    "id": .object([
                        "type": "string",
                        "description": "Task ID (UUID)"
                    ]),
                    "title": .object([
                        "type": "string",
                        "description": "New title (optional)"
                    ]),
                    "description": .object([
                        "type": "string",
                        "description": "New description (optional)"
                    ]),
                    "status": .object([
                        "type": "string",
                        "enum": .array(["inbox", "todo", "inProgress", "done"]),
                        "description": "New status (optional)"
                    ]),
                    "priority": .object([
                        "type": "string",
                        "enum": .array(["none", "low", "medium", "high", "urgent"]),
                        "description": "New priority (optional)"
                    ])
                ]),
                "required": .array(["id"]),
                "additionalProperties": false
            ])
        )
    }

    func makeCompleteTaskTool() -> Tool {
        Tool(
            name: "maestro_complete_task",
            description: "Mark a task as complete",
            inputSchema: .object([
                "type": "object",
                "properties": .object([
                    "id": .object([
                        "type": "string",
                        "description": "Task ID (UUID)"
                    ])
                ]),
                "required": .array(["id"]),
                "additionalProperties": false
            ])
        )
    }

    func makeArchiveTaskTool() -> Tool {
        Tool(
            name: "maestro_archive_task",
            description: "Archive a task",
            inputSchema: .object([
                "type": "object",
                "properties": .object([
                    "id": .object([
                        "type": "string",
                        "description": "Task ID (UUID)"
                    ])
                ]),
                "required": .array(["id"]),
                "additionalProperties": false
            ])
        )
    }

    func makeDeleteTaskTool() -> Tool {
        Tool(
            name: "maestro_delete_task",
            description: "Delete a task permanently",
            inputSchema: .object([
                "type": "object",
                "properties": .object([
                    "id": .object([
                        "type": "string",
                        "description": "Task ID (UUID)"
                    ])
                ]),
                "required": .array(["id"]),
                "additionalProperties": false
            ])
        )
    }

    func makeGetSurfacedTasksTool() -> Tool {
        Tool(
            name: "maestro_get_surfaced_tasks",
            description: "Get surfaced tasks using priority algorithm",
            inputSchema: .object([
                "type": "object",
                "properties": .object([
                    "spaceId": .object([
                        "type": "string",
                        "description": "Filter by space ID (optional)"
                    ]),
                    "limit": .object([
                        "type": "integer",
                        "description": "Maximum number of tasks (default: 10)"
                    ])
                ]),
                "additionalProperties": false
            ])
        )
    }

    // MARK: - Documents Tool Definitions

    func makeListDocumentsTool() -> Tool {
        Tool(
            name: "maestro_list_documents",
            description: "List documents with optional filters",
            inputSchema: .object([
                "type": "object",
                "properties": .object([
                    "spaceId": .object([
                        "type": "string",
                        "description": "Filter by space ID (optional)"
                    ]),
                    "path": .object([
                        "type": "string",
                        "description": "Filter by path prefix (optional)"
                    ])
                ]),
                "additionalProperties": false
            ])
        )
    }

    func makeGetDocumentTool() -> Tool {
        Tool(
            name: "maestro_get_document",
            description: "Get a document by ID",
            inputSchema: .object([
                "type": "object",
                "properties": .object([
                    "id": .object([
                        "type": "string",
                        "description": "Document ID (UUID)"
                    ])
                ]),
                "required": .array(["id"]),
                "additionalProperties": false
            ])
        )
    }

    func makeCreateDocumentTool() -> Tool {
        Tool(
            name: "maestro_create_document",
            description: "Create a new document",
            inputSchema: .object([
                "type": "object",
                "properties": .object([
                    "spaceId": .object([
                        "type": "string",
                        "description": "Space ID (UUID)"
                    ]),
                    "title": .object([
                        "type": "string",
                        "description": "Document title"
                    ]),
                    "content": .object([
                        "type": "string",
                        "description": "Document content (optional)"
                    ]),
                    "path": .object([
                        "type": "string",
                        "description": "Document path (default: /)"
                    ])
                ]),
                "required": .array(["spaceId", "title"]),
                "additionalProperties": false
            ])
        )
    }

    func makeUpdateDocumentTool() -> Tool {
        Tool(
            name: "maestro_update_document",
            description: "Update a document",
            inputSchema: .object([
                "type": "object",
                "properties": .object([
                    "id": .object([
                        "type": "string",
                        "description": "Document ID (UUID)"
                    ]),
                    "title": .object([
                        "type": "string",
                        "description": "New title (optional)"
                    ]),
                    "content": .object([
                        "type": "string",
                        "description": "New content (optional)"
                    ])
                ]),
                "required": .array(["id"]),
                "additionalProperties": false
            ])
        )
    }

    func makePinDocumentTool() -> Tool {
        Tool(
            name: "maestro_pin_document",
            description: "Pin a document",
            inputSchema: .object([
                "type": "object",
                "properties": .object([
                    "id": .object([
                        "type": "string",
                        "description": "Document ID (UUID)"
                    ])
                ]),
                "required": .array(["id"]),
                "additionalProperties": false
            ])
        )
    }

    func makeUnpinDocumentTool() -> Tool {
        Tool(
            name: "maestro_unpin_document",
            description: "Unpin a document",
            inputSchema: .object([
                "type": "object",
                "properties": .object([
                    "id": .object([
                        "type": "string",
                        "description": "Document ID (UUID)"
                    ])
                ]),
                "required": .array(["id"]),
                "additionalProperties": false
            ])
        )
    }

    func makeDeleteDocumentTool() -> Tool {
        Tool(
            name: "maestro_delete_document",
            description: "Delete a document permanently",
            inputSchema: .object([
                "type": "object",
                "properties": .object([
                    "id": .object([
                        "type": "string",
                        "description": "Document ID (UUID)"
                    ])
                ]),
                "required": .array(["id"]),
                "additionalProperties": false
            ])
        )
    }

    func makeGetDefaultDocumentTool() -> Tool {
        Tool(
            name: "maestro_get_default_document",
            description: "Get the default document for a space",
            inputSchema: .object([
                "type": "object",
                "properties": .object([
                    "spaceId": .object([
                        "type": "string",
                        "description": "Space ID (UUID)"
                    ])
                ]),
                "required": .array(["spaceId"]),
                "additionalProperties": false
            ])
        )
    }

    func makeSetDefaultDocumentTool() -> Tool {
        Tool(
            name: "maestro_set_default_document",
            description: "Set a document as the default for its space",
            inputSchema: .object([
                "type": "object",
                "properties": .object([
                    "id": .object([
                        "type": "string",
                        "description": "Document ID (UUID)"
                    ])
                ]),
                "required": .array(["id"]),
                "additionalProperties": false
            ])
        )
    }

    // MARK: - Agent Monitoring Tools

    func makeStartAgentSessionTool() -> Tool {
        Tool(
            name: "maestro_start_agent_session",
            description: "Start a new agent work session for tracking",
            inputSchema: .object([
                "type": "object",
                "properties": .object([
                    "agentName": .object([
                        "type": "string",
                        "description": "Agent name (e.g., 'Claude Code', 'Codex')"
                    ]),
                    "metadata": .object([
                        "type": "object",
                        "description": "Optional metadata (key-value pairs)",
                        "additionalProperties": .object(["type": "string"])
                    ])
                ]),
                "required": .array(["agentName"]),
                "additionalProperties": false
            ])
        )
    }

    func makeEndAgentSessionTool() -> Tool {
        Tool(
            name: "maestro_end_agent_session",
            description: "End an active agent session",
            inputSchema: .object([
                "type": "object",
                "properties": .object([
                    "sessionId": .object([
                        "type": "string",
                        "description": "Session ID (UUID)"
                    ])
                ]),
                "required": .array(["sessionId"]),
                "additionalProperties": false
            ])
        )
    }

    func makeLogAgentActivityTool() -> Tool {
        Tool(
            name: "maestro_log_agent_activity",
            description: "Log an activity performed by an agent",
            inputSchema: .object([
                "type": "object",
                "properties": .object([
                    "sessionId": .object([
                        "type": "string",
                        "description": "Session ID (UUID)"
                    ]),
                    "agentName": .object([
                        "type": "string",
                        "description": "Agent name"
                    ]),
                    "activityType": .object([
                        "type": "string",
                        "description": "Activity type",
                        "enum": .array(["created", "updated", "completed", "archived", "deleted", "viewed", "searched", "synced", "other"])
                    ]),
                    "resourceType": .object([
                        "type": "string",
                        "description": "Resource type",
                        "enum": .array(["task", "space", "document", "reminder", "linear_issue", "session", "other"])
                    ]),
                    "resourceId": .object([
                        "type": "string",
                        "description": "Resource ID (UUID, optional)"
                    ]),
                    "description": .object([
                        "type": "string",
                        "description": "Activity description (optional)"
                    ])
                ]),
                "required": .array(["sessionId", "agentName", "activityType", "resourceType"]),
                "additionalProperties": false
            ])
        )
    }

    func makeGetAgentSessionTool() -> Tool {
        Tool(
            name: "maestro_get_agent_session",
            description: "Get agent session details",
            inputSchema: .object([
                "type": "object",
                "properties": .object([
                    "sessionId": .object([
                        "type": "string",
                        "description": "Session ID (UUID)"
                    ])
                ]),
                "required": .array(["sessionId"]),
                "additionalProperties": false
            ])
        )
    }

    func makeListAgentSessionsTool() -> Tool {
        Tool(
            name: "maestro_list_agent_sessions",
            description: "List agent sessions with optional filters",
            inputSchema: .object([
                "type": "object",
                "properties": .object([
                    "agentName": .object([
                        "type": "string",
                        "description": "Filter by agent name (optional)"
                    ]),
                    "limit": .object([
                        "type": "integer",
                        "description": "Maximum number of sessions (default: 50)",
                        "default": 50
                    ]),
                    "activeOnly": .object([
                        "type": "boolean",
                        "description": "Only return active sessions (default: false)",
                        "default": false
                    ])
                ]),
                "additionalProperties": false
            ])
        )
    }

    func makeListAgentActivitiesTool() -> Tool {
        Tool(
            name: "maestro_list_agent_activities",
            description: "List agent activities with optional filters",
            inputSchema: .object([
                "type": "object",
                "properties": .object([
                    "sessionId": .object([
                        "type": "string",
                        "description": "Filter by session ID (optional)"
                    ]),
                    "agentName": .object([
                        "type": "string",
                        "description": "Filter by agent name (optional)"
                    ]),
                    "activityType": .object([
                        "type": "string",
                        "description": "Filter by activity type (optional)",
                        "enum": .array(["created", "updated", "completed", "archived", "deleted", "viewed", "searched", "synced", "other"])
                    ]),
                    "resourceType": .object([
                        "type": "string",
                        "description": "Filter by resource type (optional)",
                        "enum": .array(["task", "space", "document", "reminder", "linear_issue", "session", "other"])
                    ]),
                    "limit": .object([
                        "type": "integer",
                        "description": "Maximum number of activities (default: 100)",
                        "default": 100
                    ])
                ]),
                "additionalProperties": false
            ])
        )
    }

    func makeGetAgentMetricsTool() -> Tool {
        Tool(
            name: "maestro_get_agent_metrics",
            description: "Get performance metrics for an agent",
            inputSchema: .object([
                "type": "object",
                "properties": .object([
                    "agentName": .object([
                        "type": "string",
                        "description": "Agent name"
                    ])
                ]),
                "required": .array(["agentName"]),
                "additionalProperties": false
            ])
        )
    }

    // MARK: - Status Tool

    func makeGetStatusTool() -> Tool {
        Tool(
            name: "maestro_get_status",
            description: """
                Get current status summary for menu bar.
                Returns: color (clear/attention/input/urgent), badgeCount,
                and counts for overdue tasks, stale tasks, agents needing input,
                active agents, and recent Linear activity.
                """,
            inputSchema: .object([
                "type": "object",
                "properties": .object([:]),
                "additionalProperties": false
            ])
        )
    }
}
