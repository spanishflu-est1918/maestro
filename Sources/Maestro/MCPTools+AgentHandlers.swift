import Foundation
import MCP
import MaestroCore

// MARK: - Agent Monitoring Tool Handlers

extension MaestroMCPServer {
    func handleStartAgentSession(_ params: CallTool.Parameters) async -> CallTool.Result {
        do {
            guard let agentName = params.arguments?["agentName"]?.stringValue else {
                return .init(content: [.text("Missing agent name")], isError: true)
            }

            // TODO: Handle metadata when MCP SDK supports it
            let metadata: [String: String]? = nil

            let agentMonitor = AgentMonitor(database: db)
            let session = try agentMonitor.startSession(agentName: agentName, metadata: metadata)

            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(session)
            let json = String(data: data, encoding: .utf8) ?? "{}"

            return .init(content: [.text(json)])
        } catch {
            return .init(content: [.text("Error: \(error.localizedDescription)")], isError: true)
        }
    }

    func handleEndAgentSession(_ params: CallTool.Parameters) async -> CallTool.Result {
        do {
            guard let sessionIdString = params.arguments?["sessionId"]?.stringValue,
                  let sessionId = UUID(uuidString: sessionIdString) else {
                return .init(content: [.text("Invalid session ID")], isError: true)
            }

            let agentMonitor = AgentMonitor(database: db)
            try agentMonitor.endSession(sessionId)

            return .init(content: [.text("{\"success\": true}")])
        } catch {
            return .init(content: [.text("Error: \(error.localizedDescription)")], isError: true)
        }
    }

    func handleLogAgentActivity(_ params: CallTool.Parameters) async -> CallTool.Result {
        do {
            guard let sessionIdString = params.arguments?["sessionId"]?.stringValue,
                  let sessionId = UUID(uuidString: sessionIdString),
                  let agentName = params.arguments?["agentName"]?.stringValue,
                  let activityTypeString = params.arguments?["activityType"]?.stringValue,
                  let activityType = AgentActivity.ActivityType(rawValue: activityTypeString),
                  let resourceTypeString = params.arguments?["resourceType"]?.stringValue,
                  let resourceType = AgentActivity.ResourceType(rawValue: resourceTypeString) else {
                return .init(content: [.text("Missing or invalid required parameters")], isError: true)
            }

            var resourceId: UUID?
            if let resourceIdString = params.arguments?["resourceId"]?.stringValue {
                resourceId = UUID(uuidString: resourceIdString)
            }

            let description = params.arguments?["description"]?.stringValue

            let agentMonitor = AgentMonitor(database: db)
            try agentMonitor.logActivity(
                sessionId: sessionId,
                agentName: agentName,
                activityType: activityType,
                resourceType: resourceType,
                resourceId: resourceId,
                description: description
            )

            return .init(content: [.text("{\"success\": true}")])
        } catch {
            return .init(content: [.text("Error: \(error.localizedDescription)")], isError: true)
        }
    }

    func handleGetAgentSession(_ params: CallTool.Parameters) async -> CallTool.Result {
        do {
            guard let sessionIdString = params.arguments?["sessionId"]?.stringValue,
                  let sessionId = UUID(uuidString: sessionIdString) else {
                return .init(content: [.text("Invalid session ID")], isError: true)
            }

            let agentMonitor = AgentMonitor(database: db)
            guard let session = try agentMonitor.getSession(sessionId) else {
                return .init(content: [.text("Session not found")], isError: true)
            }

            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(session)
            let json = String(data: data, encoding: .utf8) ?? "{}"

            return .init(content: [.text(json)])
        } catch {
            return .init(content: [.text("Error: \(error.localizedDescription)")], isError: true)
        }
    }

    func handleListAgentSessions(_ params: CallTool.Parameters) async -> CallTool.Result {
        do {
            let agentName = params.arguments?["agentName"]?.stringValue
            let limit = params.arguments?["limit"]?.intValue ?? 50
            let activeOnly = params.arguments?["activeOnly"]?.boolValue ?? false

            let agentMonitor = AgentMonitor(database: db)
            let sessions = try agentMonitor.listSessions(
                agentName: agentName,
                limit: limit,
                activeOnly: activeOnly
            )

            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(sessions)
            let json = String(data: data, encoding: .utf8) ?? "[]"

            return .init(content: [.text(json)])
        } catch {
            return .init(content: [.text("Error: \(error.localizedDescription)")], isError: true)
        }
    }

    func handleListAgentActivities(_ params: CallTool.Parameters) async -> CallTool.Result {
        do {
            var sessionId: UUID?
            if let sessionIdString = params.arguments?["sessionId"]?.stringValue {
                sessionId = UUID(uuidString: sessionIdString)
            }

            let agentName = params.arguments?["agentName"]?.stringValue

            var activityType: AgentActivity.ActivityType?
            if let activityTypeString = params.arguments?["activityType"]?.stringValue {
                activityType = AgentActivity.ActivityType(rawValue: activityTypeString)
            }

            var resourceType: AgentActivity.ResourceType?
            if let resourceTypeString = params.arguments?["resourceType"]?.stringValue {
                resourceType = AgentActivity.ResourceType(rawValue: resourceTypeString)
            }

            let limit = params.arguments?["limit"]?.intValue ?? 100

            let agentMonitor = AgentMonitor(database: db)
            let activities = try agentMonitor.listActivities(
                sessionId: sessionId,
                agentName: agentName,
                activityType: activityType,
                resourceType: resourceType,
                limit: limit
            )

            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(activities)
            let json = String(data: data, encoding: .utf8) ?? "[]"

            return .init(content: [.text(json)])
        } catch {
            return .init(content: [.text("Error: \(error.localizedDescription)")], isError: true)
        }
    }

    func handleGetAgentMetrics(_ params: CallTool.Parameters) async -> CallTool.Result {
        do {
            guard let agentName = params.arguments?["agentName"]?.stringValue else {
                return .init(content: [.text("Missing agent name")], isError: true)
            }

            let agentMonitor = AgentMonitor(database: db)
            let metrics = try agentMonitor.getMetrics(agentName: agentName)

            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(metrics)
            let json = String(data: data, encoding: .utf8) ?? "{}"

            return .init(content: [.text(json)])
        } catch {
            return .init(content: [.text("Error: \(error.localizedDescription)")], isError: true)
        }
    }
}
