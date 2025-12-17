import Foundation
import MCP
import MaestroCore

// MARK: - Task Tool Handlers

extension MaestroMCPServer {
    func handleListTasks(_ params: CallTool.Parameters) async -> CallTool.Result {
        do {
            var spaceId: UUID? = nil
            if let spaceIdStr = params.arguments?["spaceId"]?.stringValue {
                spaceId = UUID(uuidString: spaceIdStr)
            }

            var status: TaskStatus? = nil
            if let statusStr = params.arguments?["status"]?.stringValue {
                status = TaskStatus(rawValue: statusStr)
            }

            let includeArchived = params.arguments?["includeArchived"]?.boolValue ?? false

            let tasks = try taskStore.list(spaceId: spaceId, status: status, includeArchived: includeArchived)
            let json = try JSONEncoder().encode(tasks)
            let jsonString = String(data: json, encoding: .utf8) ?? "[]"

            return .init(content: [.text(jsonString)], isError: false)
        } catch {
            return .init(content: [.text("Error: \(error.localizedDescription)")], isError: true)
        }
    }

    func handleGetTask(_ params: CallTool.Parameters) async -> CallTool.Result {
        guard let idStr = params.arguments?["id"]?.stringValue,
              let id = UUID(uuidString: idStr) else {
            return .init(content: [.text("Error: Invalid or missing id parameter")], isError: true)
        }

        do {
            guard let task = try taskStore.get(id) else {
                return .init(content: [.text("Error: Task not found")], isError: true)
            }

            let json = try JSONEncoder().encode(task)
            let jsonString = String(data: json, encoding: .utf8) ?? "{}"

            return .init(content: [.text(jsonString)], isError: false)
        } catch {
            return .init(content: [.text("Error: \(error.localizedDescription)")], isError: true)
        }
    }

    func handleCreateTask(_ params: CallTool.Parameters) async -> CallTool.Result {
        guard let spaceIdStr = params.arguments?["spaceId"]?.stringValue,
              let spaceId = UUID(uuidString: spaceIdStr),
              let title = params.arguments?["title"]?.stringValue else {
            return .init(content: [.text("Error: Missing required parameters (spaceId, title)")], isError: true)
        }

        do {
            let description = params.arguments?["description"]?.stringValue

            var status: TaskStatus = .inbox
            if let statusStr = params.arguments?["status"]?.stringValue,
               let parsedStatus = TaskStatus(rawValue: statusStr) {
                status = parsedStatus
            }

            var priority: TaskPriority = .none
            if let priorityStr = params.arguments?["priority"]?.stringValue,
               let parsedPriority = TaskPriority(rawValue: priorityStr) {
                priority = parsedPriority
            }

            let task = Task(
                spaceId: spaceId,
                title: title,
                description: description,
                status: status,
                priority: priority
            )

            try taskStore.create(task)

            let json = try JSONEncoder().encode(task)
            let jsonString = String(data: json, encoding: .utf8) ?? "{}"

            return .init(content: [.text(jsonString)], isError: false)
        } catch {
            return .init(content: [.text("Error: \(error.localizedDescription)")], isError: true)
        }
    }

    func handleUpdateTask(_ params: CallTool.Parameters) async -> CallTool.Result {
        guard let idStr = params.arguments?["id"]?.stringValue,
              let id = UUID(uuidString: idStr) else {
            return .init(content: [.text("Error: Invalid or missing id parameter")], isError: true)
        }

        do {
            guard var task = try taskStore.get(id) else {
                return .init(content: [.text("Error: Task not found")], isError: true)
            }

            if let title = params.arguments?["title"]?.stringValue {
                task.title = title
            }

            if let description = params.arguments?["description"]?.stringValue {
                task.description = description
            }

            if let statusStr = params.arguments?["status"]?.stringValue,
               let status = TaskStatus(rawValue: statusStr) {
                task.status = status
            }

            if let priorityStr = params.arguments?["priority"]?.stringValue,
               let priority = TaskPriority(rawValue: priorityStr) {
                task.priority = priority
            }

            try taskStore.update(task)

            let json = try JSONEncoder().encode(task)
            let jsonString = String(data: json, encoding: .utf8) ?? "{}"

            return .init(content: [.text(jsonString)], isError: false)
        } catch {
            return .init(content: [.text("Error: \(error.localizedDescription)")], isError: true)
        }
    }

    func handleCompleteTask(_ params: CallTool.Parameters) async -> CallTool.Result {
        guard let idStr = params.arguments?["id"]?.stringValue,
              let id = UUID(uuidString: idStr) else {
            return .init(content: [.text("Error: Invalid or missing id parameter")], isError: true)
        }

        do {
            try taskStore.complete(id)
            return .init(content: [.text("{\"success\": true}")], isError: false)
        } catch {
            return .init(content: [.text("Error: \(error.localizedDescription)")], isError: true)
        }
    }

    func handleArchiveTask(_ params: CallTool.Parameters) async -> CallTool.Result {
        guard let idStr = params.arguments?["id"]?.stringValue,
              let id = UUID(uuidString: idStr) else {
            return .init(content: [.text("Error: Invalid or missing id parameter")], isError: true)
        }

        do {
            try taskStore.archive(id)
            return .init(content: [.text("{\"success\": true}")], isError: false)
        } catch {
            return .init(content: [.text("Error: \(error.localizedDescription)")], isError: true)
        }
    }

    func handleDeleteTask(_ params: CallTool.Parameters) async -> CallTool.Result {
        guard let idStr = params.arguments?["id"]?.stringValue,
              let id = UUID(uuidString: idStr) else {
            return .init(content: [.text("Error: Invalid or missing id parameter")], isError: true)
        }

        do {
            try taskStore.delete(id)
            return .init(content: [.text("{\"success\": true}")], isError: false)
        } catch {
            return .init(content: [.text("Error: \(error.localizedDescription)")], isError: true)
        }
    }

    func handleGetSurfacedTasks(_ params: CallTool.Parameters) async -> CallTool.Result {
        do {
            var spaceId: UUID? = nil
            if let spaceIdStr = params.arguments?["spaceId"]?.stringValue {
                spaceId = UUID(uuidString: spaceIdStr)
            }

            let limit = params.arguments?["limit"]?.intValue ?? 10

            let tasks = try taskStore.getSurfaced(spaceId: spaceId, limit: limit)
            let json = try JSONEncoder().encode(tasks)
            let jsonString = String(data: json, encoding: .utf8) ?? "[]"

            return .init(content: [.text(jsonString)], isError: false)
        } catch {
            return .init(content: [.text("Error: \(error.localizedDescription)")], isError: true)
        }
    }
}

