import Foundation
import GRDB

/// Calculates menu bar state from current system status
public class MenuBarStateCalculator {
    private let db: Database
    private let staleThresholdDays: Int

    public init(database: Database, staleThresholdDays: Int = 3) {
        self.db = database
        self.staleThresholdDays = staleThresholdDays
    }

    public func calculate() throws -> MenuBarState {
        let summary = try calculateSummary()
        let color = determineColor(from: summary)
        let badge = calculateBadge(from: summary)

        return MenuBarState(
            color: color,
            badgeCount: badge,
            summary: summary,
            updatedAt: Date()
        )
    }

    private func calculateSummary() throws -> StatusSummary {
        // Query each metric
        let overdueCount = try countOverdueTasks()
        let staleCount = try countStaleTasks()
        let needsInputCount = try countAgentsNeedingInput()
        let activeCount = try countActiveAgents()
        let linearDone = try countLinearDone()
        let linearAssigned = try countLinearAssigned()

        return StatusSummary(
            overdueTaskCount: overdueCount,
            staleTaskCount: staleCount,
            agentsNeedingInputCount: needsInputCount,
            activeAgentCount: activeCount,
            linearDoneCount: linearDone,
            linearAssignedCount: linearAssigned
        )
    }

    private func determineColor(from summary: StatusSummary) -> MenuBarColor {
        if summary.overdueTaskCount > 0 {
            return .urgent
        }
        if summary.agentsNeedingInputCount > 0 {
            return .input
        }
        if summary.staleTaskCount > 0 {
            return .attention
        }
        return .clear
    }

    private func calculateBadge(from summary: StatusSummary) -> Int {
        // Only overdue + needs_input count for badge
        return summary.overdueTaskCount + summary.agentsNeedingInputCount
    }

    // MARK: - Query Methods

    private func countOverdueTasks() throws -> Int {
        return try db.read { db in
            try Int.fetchOne(
                db,
                sql: """
                    SELECT COUNT(*) FROM tasks
                    WHERE due_date < datetime('now')
                      AND status NOT IN ('done', 'archived')
                    """
            ) ?? 0
        }
    }

    private func countStaleTasks() throws -> Int {
        return try db.read { [self] db in
            try Int.fetchOne(
                db,
                sql: """
                    SELECT COUNT(*) FROM tasks
                    WHERE status = 'inProgress'
                      AND updated_at < datetime('now', ?)
                    """,
                arguments: ["-\(self.staleThresholdDays) days"]
            ) ?? 0
        }
    }

    private func countAgentsNeedingInput() throws -> Int {
        // TODO: Implement when agent status tracking is added
        return 0
    }

    private func countActiveAgents() throws -> Int {
        return try db.read { db in
            try Int.fetchOne(
                db,
                sql: """
                    SELECT COUNT(*) FROM agent_sessions
                    WHERE ended_at IS NULL
                    """
            ) ?? 0
        }
    }

    private func countLinearDone() throws -> Int {
        return try db.read { db in
            try Int.fetchOne(
                db,
                sql: """
                    SELECT COUNT(*) FROM linear_sync
                    WHERE linear_state = 'Done'
                      AND updated_at > datetime('now', '-1 day')
                    """
            ) ?? 0
        }
    }

    private func countLinearAssigned() throws -> Int {
        // TODO: Implement when needed
        return 0
    }
}
