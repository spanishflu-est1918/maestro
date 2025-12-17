import Foundation
import MCP
import MaestroCore

extension MaestroMCPServer {
    /// Handle get status request
    func handleGetStatus(_ params: CallTool.Parameters) async -> CallTool.Result {
        do {
            let calculator = MenuBarStateCalculator(database: db)
            let state = try calculator.calculate()

            // Convert to JSON response
            let response: [String: Any] = [
                "color": state.color.rawValue,
                "badgeCount": state.badgeCount,
                "overdueTaskCount": state.summary.overdueTaskCount,
                "staleTaskCount": state.summary.staleTaskCount,
                "agentsNeedingInputCount": state.summary.agentsNeedingInputCount,
                "activeAgentCount": state.summary.activeAgentCount,
                "linearDoneCount": state.summary.linearDoneCount,
                "linearAssignedCount": state.summary.linearAssignedCount,
                "updatedAt": ISO8601DateFormatter().string(from: state.updatedAt)
            ]

            let data = try JSONSerialization.data(withJSONObject: response)
            let json = String(data: data, encoding: .utf8) ?? "{}"

            return .init(content: [.text(json)])
        } catch {
            return .init(content: [.text("Error: \(error.localizedDescription)")], isError: true)
        }
    }
}
