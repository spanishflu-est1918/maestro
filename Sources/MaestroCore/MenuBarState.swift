import Foundation

/// Menu bar color state
public enum MenuBarColor: String, Codable {
    case clear = "clear"         // 🟢 Nothing actionable
    case attention = "attention" // 🟡 Stale tasks, idle agents
    case input = "input"         // 🟠 Agent needs input
    case urgent = "urgent"       // 🔴 Overdue task
}

/// Status summary for menu bar
public struct StatusSummary: Codable {
    public let overdueTaskCount: Int
    public let staleTaskCount: Int
    public let agentsNeedingInputCount: Int
    public let activeAgentCount: Int
    public let linearDoneCount: Int      // Issues moved to Done in last 24h
    public let linearAssignedCount: Int  // New issues assigned

    public init(
        overdueTaskCount: Int,
        staleTaskCount: Int,
        agentsNeedingInputCount: Int,
        activeAgentCount: Int,
        linearDoneCount: Int,
        linearAssignedCount: Int
    ) {
        self.overdueTaskCount = overdueTaskCount
        self.staleTaskCount = staleTaskCount
        self.agentsNeedingInputCount = agentsNeedingInputCount
        self.activeAgentCount = activeAgentCount
        self.linearDoneCount = linearDoneCount
        self.linearAssignedCount = linearAssignedCount
    }
}

/// Menu bar state
public struct MenuBarState: Codable {
    public let color: MenuBarColor
    public let badgeCount: Int
    public let summary: StatusSummary
    public let updatedAt: Date

    public init(
        color: MenuBarColor,
        badgeCount: Int,
        summary: StatusSummary,
        updatedAt: Date
    ) {
        self.color = color
        self.badgeCount = badgeCount
        self.summary = summary
        self.updatedAt = updatedAt
    }
}
