import Foundation
import GRDB

/// Linear API Integration
/// Syncs Maestro tasks with Linear issues
public class LinearSync {
    private let db: Database
    private var apiKey: String?

    public init(database: Database, apiKey: String? = nil) {
        self.db = database
        self.apiKey = apiKey
    }

    /// Set Linear API key for authentication
    public func setAPIKey(_ key: String) {
        self.apiKey = key
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
            var link = try LinearLink.all()
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
    /// For now, this is a placeholder for future API integration
    public func sync() throws {
        guard let apiKey = apiKey else {
            throw LinearSyncError.noAPIKey
        }

        // TODO: Implement actual Linear API calls
        // 1. Fetch issues from Linear
        // 2. Update existing links
        // 3. Create new tasks for unlinked issues
        // 4. Push local changes to Linear

        let links = try getAllLinks()
        // Placeholder sync logic
        for link in links {
            // In a real implementation, this would call Linear API
            // to fetch the current state and update the link
            _ = link
        }
    }
}

public enum LinearSyncError: Error, LocalizedError {
    case noAPIKey

    public var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "Linear API key not configured"
        }
    }
}
