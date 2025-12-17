import Foundation
import GRDB

/// Store for managing Space CRUD operations
public class SpaceStore {
    private let db: Database

    public enum SpaceStoreError: Error, LocalizedError {
        case spaceNotFound(UUID)
        case invalidData(String)

        public var errorDescription: String? {
            switch self {
            case .spaceNotFound(let id):
                return "Space not found: \(id)"
            case .invalidData(let msg):
                return "Invalid data: \(msg)"
            }
        }
    }

    // MARK: - Initialization

    public init(database: Database) {
        self.db = database
    }

    // MARK: - Create

    /// Create a new space
    /// - Parameter space: The space to create
    /// - Throws: Database errors
    public func create(_ space: Space) throws {
        try db.write { db in
            try space.insert(db)
        }
    }

    // MARK: - Read

    /// Get a space by ID
    /// - Parameter id: The space ID
    /// - Returns: The space, or nil if not found
    /// - Throws: Database errors
    public func get(_ id: UUID) throws -> Space? {
        return try db.read { db in
            try Space.fetchOne(db, key: id.uuidString)
        }
    }

    /// List all spaces
    /// - Parameters:
    ///   - includeArchived: Whether to include archived spaces (default: false)
    ///   - parentFilter: Filter by parent (nil = all spaces, .some(nil) = only roots, .some(id) = children of id)
    /// - Returns: Array of spaces
    /// - Throws: Database errors
    public func list(includeArchived: Bool = false, parentFilter: UUID?? = nil) throws -> [Space] {
        return try db.read { db in
            var request = Space.all()

            // Filter archived
            if !includeArchived {
                request = request.filter(Space.Columns.archived == false)
            }

            // Filter by parent (double optional to distinguish between no filter and filter by nil parent)
            if let parentFilter = parentFilter {
                if let parentId = parentFilter {
                    // Filter by specific parent
                    request = request.filter(Space.Columns.parentId == parentId.uuidString)
                } else {
                    // Filter by nil parent (root spaces only)
                    request = request.filter(Space.Columns.parentId == nil)
                }
            }
            // else: no filter, return all spaces

            return try request
                .order(Space.Columns.lastActiveAt.desc)
                .fetchAll(db)
        }
    }

    /// List root spaces (spaces with no parent)
    /// - Parameter includeArchived: Whether to include archived spaces
    /// - Returns: Array of root spaces
    /// - Throws: Database errors
    public func listRoots(includeArchived: Bool = false) throws -> [Space] {
        return try list(includeArchived: includeArchived, parentFilter: .some(nil))
    }

    /// Get children of a space
    /// - Parameters:
    ///   - parentId: The parent space ID
    ///   - includeArchived: Whether to include archived children
    /// - Returns: Array of child spaces
    /// - Throws: Database errors
    public func getChildren(of parentId: UUID, includeArchived: Bool = false) throws -> [Space] {
        return try list(includeArchived: includeArchived, parentFilter: .some(parentId))
    }

    /// Get all descendants of a space (recursive)
    /// - Parameters:
    ///   - spaceId: The space ID
    ///   - includeArchived: Whether to include archived spaces
    /// - Returns: Array of all descendant spaces
    /// - Throws: Database errors
    public func getDescendants(of spaceId: UUID, includeArchived: Bool = false) throws -> [Space] {
        return try db.read { db in
            let archivedFilter = includeArchived ? "" : "AND s.archived = 0"

            let sql = """
                WITH RECURSIVE descendants AS (
                    SELECT * FROM spaces WHERE id = ?
                    UNION ALL
                    SELECT s.* FROM spaces s
                    JOIN descendants d ON s.parent_id = d.id
                    WHERE 1=1 \(archivedFilter)
                )
                SELECT * FROM descendants WHERE id != ?
                ORDER BY created_at
            """

            return try Space.fetchAll(db, sql: sql, arguments: [spaceId.uuidString, spaceId.uuidString])
        }
    }

    /// Get all ancestors of a space (up to root)
    /// - Parameter spaceId: The space ID
    /// - Returns: Array of ancestor spaces (from parent to root)
    /// - Throws: Database errors
    public func getAncestors(of spaceId: UUID) throws -> [Space] {
        return try db.read { db in
            let sql = """
                WITH RECURSIVE ancestors AS (
                    SELECT * FROM spaces WHERE id = ?
                    UNION ALL
                    SELECT s.* FROM spaces s
                    JOIN ancestors a ON s.id = a.parent_id
                )
                SELECT * FROM ancestors WHERE id != ?
                ORDER BY created_at
            """

            return try Space.fetchAll(db, sql: sql, arguments: [spaceId.uuidString, spaceId.uuidString])
        }
    }

    /// Find spaces by tag
    /// - Parameters:
    ///   - tag: The tag to search for
    ///   - includeArchived: Whether to include archived spaces
    /// - Returns: Array of spaces with the tag
    /// - Throws: Database errors
    public func findByTag(_ tag: String, includeArchived: Bool = false) throws -> [Space] {
        return try db.read { db in
            let archivedFilter = includeArchived ? "" : "AND archived = 0"

            let sql = """
                SELECT * FROM spaces
                WHERE tags LIKE ?
                \(archivedFilter)
                ORDER BY last_active_at DESC
            """

            let pattern = "%\"\(tag)\"%"
            return try Space.fetchAll(db, sql: sql, arguments: [pattern])
        }
    }

    // MARK: - Path Matching

    /// Find spaces that match a filesystem path
    /// - Parameters:
    ///   - path: The filesystem path to match
    ///   - includeArchived: Whether to include archived spaces
    /// - Returns: Array of spaces whose path matches or is a parent of the given path
    /// - Throws: Database errors
    public func findByPath(_ path: String, includeArchived: Bool = false) throws -> [Space] {
        let normalizedPath = normalizePath(path)

        return try db.read { db in
            let archivedFilter = includeArchived ? "" : "AND archived = 0"

            let sql = """
                SELECT * FROM spaces
                WHERE path IS NOT NULL
                AND (
                    path = ?
                    OR ? LIKE path || '/%'
                )
                \(archivedFilter)
                ORDER BY length(path) DESC, last_active_at DESC
            """

            return try Space.fetchAll(db, sql: sql, arguments: [normalizedPath, normalizedPath])
        }
    }

    /// Infer which space a path belongs to
    /// Returns the space with the longest matching path (closest parent)
    /// - Parameters:
    ///   - path: The filesystem path
    ///   - includeArchived: Whether to include archived spaces
    /// - Returns: The best matching space, or nil if no match
    /// - Throws: Database errors
    public func inferSpace(forPath path: String, includeArchived: Bool = false) throws -> Space? {
        let matches = try findByPath(path, includeArchived: includeArchived)
        // findByPath already orders by path length DESC, so first match is best
        return matches.first
    }

    /// Normalize a filesystem path for consistent matching
    /// - Parameter path: The path to normalize
    /// - Returns: Normalized path (expanded, resolved symlinks, no trailing slash)
    private func normalizePath(_ path: String) -> String {
        let url = URL(fileURLWithPath: path)
        let expanded = url.standardized.path
        return expanded.hasSuffix("/") && expanded != "/"
            ? String(expanded.dropLast())
            : expanded
    }

    // MARK: - Update

    /// Update a space
    /// - Parameter space: The space with updated values
    /// - Throws: Database errors
    public func update(_ space: Space) throws {
        try db.write { db in
            try space.update(db)
        }
    }

    /// Archive a space (sets archived = true)
    /// - Parameter id: The space ID
    /// - Throws: SpaceStoreError.spaceNotFound if space doesn't exist
    public func archive(_ id: UUID) throws {
        guard var space = try get(id) else {
            throw SpaceStoreError.spaceNotFound(id)
        }

        space.archived = true
        try update(space)
    }

    /// Unarchive a space (sets archived = false)
    /// - Parameter id: The space ID
    /// - Throws: SpaceStoreError.spaceNotFound if space doesn't exist
    public func unarchive(_ id: UUID) throws {
        guard var space = try get(id) else {
            throw SpaceStoreError.spaceNotFound(id)
        }

        space.archived = false
        try update(space)
    }

    // MARK: - Delete

    /// Delete a space permanently
    /// - Parameter id: The space ID
    /// - Throws: Database errors
    public func delete(_ id: UUID) throws {
        _ = try db.write { db in
            try Space.deleteOne(db, key: id.uuidString)
        }
    }

    /// Delete all spaces (for testing)
    /// - Throws: Database errors
    public func deleteAll() throws {
        _ = try db.write { db in
            try Space.deleteAll(db)
        }
    }
}
