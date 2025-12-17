import Foundation
import GRDB

/// Linear API Integration
/// Syncs Maestro tasks with Linear issues
public class LinearSync {
    private let db: Database
    private var apiClient: LinearAPIClient?

    public init(database: Database, apiKey: String? = nil) {
        self.db = database
        if let apiKey = apiKey {
            self.apiClient = LinearAPIClient(apiKey: apiKey)
        }
    }

    /// Set Linear API key for authentication
    public func setAPIKey(_ key: String) {
        self.apiClient = LinearAPIClient(apiKey: key)
    }

    /// Link a Linear issue to a Maestro task
    public func linkIssue(taskId: UUID, linearIssueId: String, linearIssueKey: String, linearTeamId: String, linearState: String) throws {
        let link = LinearLink(
            taskId: taskId,
            linearIssueId: linearIssueId,
            linearIssueKey: linearIssueKey,
            linearTeamId: linearTeamId,
            linearState: linearState
        )

        try db.write { db in
            try link.insert(db)
        }
    }

    /// Get linked Linear issue for a task
    public func getLinkedIssue(forTask taskId: UUID) throws -> LinearLink? {
        return try db.read { db in
            try LinearLink.all()
                .filter(LinearLink.Columns.taskId == taskId.uuidString)
                .fetchOne(db)
        }
    }

    /// Get all Linear links
    public func getAllLinks() throws -> [LinearLink] {
        return try db.read { db in
            try LinearLink.fetchAll(db)
        }
    }

    /// Update the state of a linked issue
    public func updateIssueState(linearIssueId: String, newState: String) throws {
        try db.write { db in
            let link = try LinearLink.all()
                .filter(LinearLink.Columns.linearIssueId == linearIssueId)
                .fetchOne(db)

            if var link = link {
                link.linearState = newState
                link.updatedAt = Date()
                try link.update(db)
            }
        }
    }

    /// Sync: Fetch issues from Linear API and update local state
    public func sync() async throws {
        guard let client = apiClient else {
            throw LinearSyncError.noAPIKey
        }

        // 1. Fetch all assigned issues from Linear
        let issues = try await client.fetchMyIssues()

        // 2. Get all existing links
        let existingLinks = try getAllLinks()
        let linkedIssueIds = Set(existingLinks.map { $0.linearIssueId })

        // 3. Update existing links with current state from Linear
        for issue in issues where linkedIssueIds.contains(issue.id) {
            try updateIssueState(
                linearIssueId: issue.id,
                newState: issue.state.name
            )
        }

        // 4. Return summary
        print("✓ Synced \(issues.count) Linear issues")
        print("  - Updated \(existingLinks.count) existing links")
        print("  - Found \(issues.count - existingLinks.count) unlinked issues")
    }

    /// Sync a specific task to Linear
    /// Creates or updates the Linear issue based on task state
    public func syncTaskToLinear(taskId: UUID) async throws {
        guard let client = apiClient else {
            throw LinearSyncError.noAPIKey
        }

        // Get task
        let taskStore = TaskStore(database: db)
        guard let task = try taskStore.get(taskId) else {
            throw LinearSyncError.taskNotFound
        }

        // Check if already linked
        if let link = try getLinkedIssue(forTask: taskId) {
            // Update existing Linear issue
            let priorityMap = mapTaskPriorityToLinearPriority(task.priority)

            _ = try await client.updateIssue(
                id: link.linearIssueId,
                title: task.title,
                description: task.description,
                priority: priorityMap
            )

            print("✓ Updated Linear issue \(link.linearIssueKey)")
        } else {
            throw LinearSyncError.notLinked
        }
    }

    /// Create a new Linear issue from a Maestro task
    public func createLinearIssue(
        taskId: UUID,
        teamId: String
    ) async throws -> LinearLink {
        guard let client = apiClient else {
            throw LinearSyncError.noAPIKey
        }

        let taskStore = TaskStore(database: db)
        guard let task = try taskStore.get(taskId) else {
            throw LinearSyncError.taskNotFound
        }

        // Map Maestro task to Linear issue
        let priorityMap = mapTaskPriorityToLinearPriority(task.priority)

        let issue = try await client.createIssue(
            teamId: teamId,
            title: task.title,
            description: task.description,
            priority: priorityMap
        )

        // Create link
        try linkIssue(
            taskId: taskId,
            linearIssueId: issue.id,
            linearIssueKey: issue.identifier,
            linearTeamId: issue.team.id,
            linearState: issue.state.name
        )

        print("✓ Created Linear issue \(issue.identifier)")

        return try getLinkedIssue(forTask: taskId)!
    }

    // MARK: - Mapping Functions

    private func mapTaskStatusToLinearState(_ status: TaskStatus) -> String {
        switch status {
        case .inbox: return "Backlog"
        case .todo: return "Todo"
        case .inProgress: return "In Progress"
        case .done: return "Done"
        case .archived: return "Canceled"
        }
    }

    private func mapTaskPriorityToLinearPriority(_ priority: TaskPriority) -> Int {
        switch priority {
        case .urgent: return 1  // Urgent
        case .high: return 2    // High
        case .medium: return 3  // Medium
        case .low: return 4     // Low
        case .none: return 0    // No priority
        }
    }

    private func mapLinearPriorityToTaskPriority(_ priority: Int?) -> TaskPriority {
        guard let priority = priority else { return .none }
        switch priority {
        case 1: return .urgent
        case 2: return .high
        case 3: return .medium
        case 4: return .low
        default: return .none
        }
    }

    private func mapLinearStateToTaskStatus(_ state: String) -> TaskStatus {
        let lowercased = state.lowercased()
        if lowercased.contains("progress") {
            return .inProgress
        } else if lowercased.contains("done") || lowercased.contains("completed") {
            return .done
        } else if lowercased.contains("canceled") || lowercased.contains("archived") {
            return .archived
        } else if lowercased.contains("backlog") {
            return .inbox
        } else {
            return .todo
        }
    }
}

public enum LinearSyncError: Error, LocalizedError {
    case noAPIKey
    case taskNotFound
    case notLinked

    public var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "Linear API key not configured"
        case .taskNotFound:
            return "Task not found in database"
        case .notLinked:
            return "Task is not linked to a Linear issue"
        }
    }
}
