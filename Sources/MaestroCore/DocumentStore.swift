import Foundation
import GRDB

/// Store for managing Document CRUD operations
public class DocumentStore {
    private let db: Database

    public enum DocumentStoreError: Error, LocalizedError {
        case documentNotFound(UUID)
        case invalidData(String)

        public var errorDescription: String? {
            switch self {
            case .documentNotFound(let id):
                return "Document not found: \(id)"
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

    /// Create a new document
    /// - Parameter document: The document to create
    /// - Throws: Database errors
    public func create(_ document: Document) throws {
        try db.write { db in
            try document.insert(db)
        }
    }

    // MARK: - Read

    /// Get a document by ID
    /// - Parameter id: The document ID
    /// - Returns: The document, or nil if not found
    /// - Throws: Database errors
    public func get(_ id: UUID) throws -> Document? {
        return try db.read { db in
            try Document.fetchOne(db, key: id.uuidString)
        }
    }

    /// List all documents
    /// - Parameters:
    ///   - spaceId: Filter by space ID (nil = all spaces)
    ///   - path: Filter by path prefix (nil = all paths)
    /// - Returns: Array of documents
    /// - Throws: Database errors
    public func list(
        spaceId: UUID? = nil,
        path: String? = nil
    ) throws -> [Document] {
        return try db.read { db in
            var request = Document.all()

            // Filter by space
            if let spaceId = spaceId {
                request = request.filter(Document.Columns.spaceId == spaceId.uuidString)
            }

            // Filter by path prefix
            if let path = path {
                request = request.filter(Document.Columns.path.like("\(path)%"))
            }

            return try request
                .order(Document.Columns.updatedAt.desc)
                .fetchAll(db)
        }
    }

    /// Get the default document for a space
    /// - Parameter spaceId: The space ID
    /// - Returns: The default document, or nil if none exists
    /// - Throws: Database errors
    public func getDefault(spaceId: UUID) throws -> Document? {
        return try db.read { db in
            try Document.filter(Document.Columns.spaceId == spaceId.uuidString)
                .filter(Document.Columns.isDefault == true)
                .fetchOne(db)
        }
    }

    /// Get pinned documents for a space
    /// - Parameter spaceId: The space ID
    /// - Returns: Array of pinned documents
    /// - Throws: Database errors
    public func getPinned(spaceId: UUID? = nil) throws -> [Document] {
        return try db.read { db in
            var request = Document.filter(Document.Columns.isPinned == true)

            if let spaceId = spaceId {
                request = request.filter(Document.Columns.spaceId == spaceId.uuidString)
            }

            return try request
                .order(Document.Columns.updatedAt.desc)
                .fetchAll(db)
        }
    }

    /// Get documents at a specific path
    /// - Parameters:
    ///   - path: The path to search
    ///   - spaceId: Optional space filter
    /// - Returns: Array of documents at the path
    /// - Throws: Database errors
    public func getByPath(_ path: String, spaceId: UUID? = nil) throws -> [Document] {
        return try db.read { db in
            var request = Document.filter(Document.Columns.path == path)

            if let spaceId = spaceId {
                request = request.filter(Document.Columns.spaceId == spaceId.uuidString)
            }

            return try request
                .order(Document.Columns.title)
                .fetchAll(db)
        }
    }

    // MARK: - Update

    /// Update a document
    /// - Parameter document: The document with updated values
    /// - Throws: Database errors
    public func update(_ document: Document) throws {
        var updatedDocument = document
        updatedDocument.updatedAt = Date()
        try db.write { db in
            try updatedDocument.update(db)
        }
    }

    /// Set a document as the default for its space
    /// - Parameter id: The document ID
    /// - Throws: DocumentStoreError.documentNotFound if document doesn't exist
    public func setDefault(_ id: UUID) throws {
        guard var document = try get(id) else {
            throw DocumentStoreError.documentNotFound(id)
        }

        try db.write { db in
            // Clear any existing defaults for this space
            try db.execute(
                sql: """
                    UPDATE documents
                    SET is_default = 0
                    WHERE space_id = ? AND is_default = 1
                """,
                arguments: [document.spaceId.uuidString]
            )

            // Set this document as default
            document.isDefault = true
            document.updatedAt = Date()
            try document.update(db)
        }
    }

    /// Pin a document
    /// - Parameter id: The document ID
    /// - Throws: DocumentStoreError.documentNotFound if document doesn't exist
    public func pin(_ id: UUID) throws {
        guard var document = try get(id) else {
            throw DocumentStoreError.documentNotFound(id)
        }

        document.isPinned = true
        try update(document)
    }

    /// Unpin a document
    /// - Parameter id: The document ID
    /// - Throws: DocumentStoreError.documentNotFound if document doesn't exist
    public func unpin(_ id: UUID) throws {
        guard var document = try get(id) else {
            throw DocumentStoreError.documentNotFound(id)
        }

        document.isPinned = false
        try update(document)
    }

    // MARK: - Delete

    /// Delete a document permanently
    /// - Parameter id: The document ID
    /// - Throws: Database errors
    public func delete(_ id: UUID) throws {
        _ = try db.write { db in
            try Document.deleteOne(db, key: id.uuidString)
        }
    }

    /// Delete all documents (for testing)
    /// - Throws: Database errors
    public func deleteAll() throws {
        _ = try db.write { db in
            try Document.deleteAll(db)
        }
    }
}
