import Foundation
import MCP
import MaestroCore

// MARK: - Space Tool Handlers

extension MaestroMCPServer {
    func handleListSpaces(_ params: CallTool.Parameters) async -> CallTool.Result {
        do {
            let includeArchived = params.arguments?["includeArchived"]?.boolValue ?? false
            var parentFilter: UUID?? = nil

            if let parentIdStr = params.arguments?["parentId"]?.stringValue,
               let parentId = UUID(uuidString: parentIdStr) {
                parentFilter = .some(parentId)
            }

            let spaces = try spaceStore.list(includeArchived: includeArchived, parentFilter: parentFilter)
            let json = try JSONEncoder().encode(spaces)
            let jsonString = String(data: json, encoding: .utf8) ?? "[]"

            return .init(content: [.text(jsonString)], isError: false)
        } catch {
            return .init(content: [.text("Error: \(error.localizedDescription)")], isError: true)
        }
    }

    func handleGetSpace(_ params: CallTool.Parameters) async -> CallTool.Result {
        guard let idStr = params.arguments?["id"]?.stringValue,
              let id = UUID(uuidString: idStr) else {
            return .init(content: [.text("Error: Invalid or missing id parameter")], isError: true)
        }

        do {
            guard let space = try spaceStore.get(id) else {
                return .init(content: [.text("Error: Space not found")], isError: true)
            }

            let json = try JSONEncoder().encode(space)
            let jsonString = String(data: json, encoding: .utf8) ?? "{}"

            return .init(content: [.text(jsonString)], isError: false)
        } catch {
            return .init(content: [.text("Error: \(error.localizedDescription)")], isError: true)
        }
    }

    func handleCreateSpace(_ params: CallTool.Parameters) async -> CallTool.Result {
        guard let name = params.arguments?["name"]?.stringValue,
              let color = params.arguments?["color"]?.stringValue else {
            return .init(content: [.text("Error: Missing required parameters (name, color)")], isError: true)
        }

        do {
            var parentId: UUID? = nil
            if let parentIdStr = params.arguments?["parentId"]?.stringValue {
                parentId = UUID(uuidString: parentIdStr)
            }

            var tags: [String] = []
            if let tagsArray = params.arguments?["tags"]?.arrayValue {
                tags = tagsArray.compactMap { $0.stringValue }
            }

            let path = params.arguments?["path"]?.stringValue

            let space = Space(
                name: name,
                path: path,
                color: color,
                parentId: parentId,
                tags: tags
            )

            try spaceStore.create(space)

            let json = try JSONEncoder().encode(space)
            let jsonString = String(data: json, encoding: .utf8) ?? "{}"

            return .init(content: [.text(jsonString)], isError: false)
        } catch {
            return .init(content: [.text("Error: \(error.localizedDescription)")], isError: true)
        }
    }

    func handleUpdateSpace(_ params: CallTool.Parameters) async -> CallTool.Result {
        guard let idStr = params.arguments?["id"]?.stringValue,
              let id = UUID(uuidString: idStr) else {
            return .init(content: [.text("Error: Invalid or missing id parameter")], isError: true)
        }

        do {
            guard var space = try spaceStore.get(id) else {
                return .init(content: [.text("Error: Space not found")], isError: true)
            }

            if let name = params.arguments?["name"]?.stringValue {
                space.name = name
            }

            if let color = params.arguments?["color"]?.stringValue {
                space.color = color
            }

            if let tagsArray = params.arguments?["tags"]?.arrayValue {
                space.tags = tagsArray.compactMap { $0.stringValue }
            }

            try spaceStore.update(space)

            let json = try JSONEncoder().encode(space)
            let jsonString = String(data: json, encoding: .utf8) ?? "{}"

            return .init(content: [.text(jsonString)], isError: false)
        } catch {
            return .init(content: [.text("Error: \(error.localizedDescription)")], isError: true)
        }
    }

    func handleArchiveSpace(_ params: CallTool.Parameters) async -> CallTool.Result {
        guard let idStr = params.arguments?["id"]?.stringValue,
              let id = UUID(uuidString: idStr) else {
            return .init(content: [.text("Error: Invalid or missing id parameter")], isError: true)
        }

        do {
            try spaceStore.archive(id)
            return .init(content: [.text("{\"success\": true}")], isError: false)
        } catch {
            return .init(content: [.text("Error: \(error.localizedDescription)")], isError: true)
        }
    }

    func handleDeleteSpace(_ params: CallTool.Parameters) async -> CallTool.Result {
        guard let idStr = params.arguments?["id"]?.stringValue,
              let id = UUID(uuidString: idStr) else {
            return .init(content: [.text("Error: Invalid or missing id parameter")], isError: true)
        }

        do {
            try spaceStore.delete(id)
            return .init(content: [.text("{\"success\": true}")], isError: false)
        } catch {
            return .init(content: [.text("Error: \(error.localizedDescription)")], isError: true)
        }
    }
}
