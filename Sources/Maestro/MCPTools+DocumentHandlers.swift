import Foundation
import MCP
import MaestroCore

// MARK: - Document Tool Handlers

extension MaestroMCPServer {
    func handleListDocuments(_ params: CallTool.Parameters) async -> CallTool.Result {
        do {
            var spaceId: UUID? = nil
            if let spaceIdStr = params.arguments?["spaceId"]?.stringValue {
                spaceId = UUID(uuidString: spaceIdStr)
            }

            let path = params.arguments?["path"]?.stringValue

            let documents = try documentStore.list(spaceId: spaceId, path: path)
            let json = try JSONEncoder().encode(documents)
            let jsonString = String(data: json, encoding: .utf8) ?? "[]"

            return .init(content: [.text(jsonString)], isError: false)
        } catch {
            return .init(content: [.text("Error: \(error.localizedDescription)")], isError: true)
        }
    }

    func handleGetDocument(_ params: CallTool.Parameters) async -> CallTool.Result {
        guard let idStr = params.arguments?["id"]?.stringValue,
              let id = UUID(uuidString: idStr) else {
            return .init(content: [.text("Error: Invalid or missing id parameter")], isError: true)
        }

        do {
            guard let document = try documentStore.get(id) else {
                return .init(content: [.text("Error: Document not found")], isError: true)
            }

            let json = try JSONEncoder().encode(document)
            let jsonString = String(data: json, encoding: .utf8) ?? "{}"

            return .init(content: [.text(jsonString)], isError: false)
        } catch {
            return .init(content: [.text("Error: \(error.localizedDescription)")], isError: true)
        }
    }

    func handleCreateDocument(_ params: CallTool.Parameters) async -> CallTool.Result {
        guard let spaceIdStr = params.arguments?["spaceId"]?.stringValue,
              let spaceId = UUID(uuidString: spaceIdStr),
              let title = params.arguments?["title"]?.stringValue else {
            return .init(content: [.text("Error: Missing required parameters (spaceId, title)")], isError: true)
        }

        do {
            let content = params.arguments?["content"]?.stringValue ?? ""
            let path = params.arguments?["path"]?.stringValue ?? "/"

            let document = Document(
                spaceId: spaceId,
                title: title,
                content: content,
                path: path
            )

            try documentStore.create(document)

            let json = try JSONEncoder().encode(document)
            let jsonString = String(data: json, encoding: .utf8) ?? "{}"

            return .init(content: [.text(jsonString)], isError: false)
        } catch {
            return .init(content: [.text("Error: \(error.localizedDescription)")], isError: true)
        }
    }

    func handleUpdateDocument(_ params: CallTool.Parameters) async -> CallTool.Result {
        guard let idStr = params.arguments?["id"]?.stringValue,
              let id = UUID(uuidString: idStr) else {
            return .init(content: [.text("Error: Invalid or missing id parameter")], isError: true)
        }

        do {
            guard var document = try documentStore.get(id) else {
                return .init(content: [.text("Error: Document not found")], isError: true)
            }

            if let title = params.arguments?["title"]?.stringValue {
                document.title = title
            }

            if let content = params.arguments?["content"]?.stringValue {
                document.content = content
            }

            try documentStore.update(document)

            let json = try JSONEncoder().encode(document)
            let jsonString = String(data: json, encoding: .utf8) ?? "{}"

            return .init(content: [.text(jsonString)], isError: false)
        } catch {
            return .init(content: [.text("Error: \(error.localizedDescription)")], isError: true)
        }
    }

    func handlePinDocument(_ params: CallTool.Parameters) async -> CallTool.Result {
        guard let idStr = params.arguments?["id"]?.stringValue,
              let id = UUID(uuidString: idStr) else {
            return .init(content: [.text("Error: Invalid or missing id parameter")], isError: true)
        }

        do {
            try documentStore.pin(id)
            return .init(content: [.text("{\"success\": true}")], isError: false)
        } catch {
            return .init(content: [.text("Error: \(error.localizedDescription)")], isError: true)
        }
    }

    func handleUnpinDocument(_ params: CallTool.Parameters) async -> CallTool.Result {
        guard let idStr = params.arguments?["id"]?.stringValue,
              let id = UUID(uuidString: idStr) else {
            return .init(content: [.text("Error: Invalid or missing id parameter")], isError: true)
        }

        do {
            try documentStore.unpin(id)
            return .init(content: [.text("{\"success\": true}")], isError: false)
        } catch {
            return .init(content: [.text("Error: \(error.localizedDescription)")], isError: true)
        }
    }

    func handleDeleteDocument(_ params: CallTool.Parameters) async -> CallTool.Result {
        guard let idStr = params.arguments?["id"]?.stringValue,
              let id = UUID(uuidString: idStr) else {
            return .init(content: [.text("Error: Invalid or missing id parameter")], isError: true)
        }

        do {
            try documentStore.delete(id)
            return .init(content: [.text("{\"success\": true}")], isError: false)
        } catch {
            return .init(content: [.text("Error: \(error.localizedDescription)")], isError: true)
        }
    }

    func handleGetDefaultDocument(_ params: CallTool.Parameters) async -> CallTool.Result {
        guard let spaceIdStr = params.arguments?["spaceId"]?.stringValue,
              let spaceId = UUID(uuidString: spaceIdStr) else {
            return .init(content: [.text("Error: Invalid or missing spaceId parameter")], isError: true)
        }

        do {
            guard let document = try documentStore.getDefault(spaceId: spaceId) else {
                return .init(content: [.text("Error: No default document found")], isError: true)
            }

            let json = try JSONEncoder().encode(document)
            let jsonString = String(data: json, encoding: .utf8) ?? "{}"

            return .init(content: [.text(jsonString)], isError: false)
        } catch {
            return .init(content: [.text("Error: \(error.localizedDescription)")], isError: true)
        }
    }

    func handleSetDefaultDocument(_ params: CallTool.Parameters) async -> CallTool.Result {
        guard let idStr = params.arguments?["id"]?.stringValue,
              let id = UUID(uuidString: idStr) else {
            return .init(content: [.text("Error: Invalid or missing id parameter")], isError: true)
        }

        do {
            try documentStore.setDefault(id)
            return .init(content: [.text("{\"success\": true}")], isError: false)
        } catch {
            return .init(content: [.text("Error: \(error.localizedDescription)")], isError: true)
        }
    }
}
