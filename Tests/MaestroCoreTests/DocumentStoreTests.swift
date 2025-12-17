import XCTest
@testable import MaestroCore

/// Integration tests for DocumentStore CRUD operations
final class DocumentStoreTests: XCTestCase {
    var db: Database!
    var documentStore: DocumentStore!
    var spaceStore: SpaceStore!
    var testSpaceId: UUID!

    override func setUp() async throws {
        try await super.setUp()

        // Create in-memory database for each test
        db = Database()
        try db.connect()
        documentStore = DocumentStore(database: db)
        spaceStore = SpaceStore(database: db)

        // Create a test space for documents
        let testSpace = Space(name: "Test Space", color: "#FF0000")
        try spaceStore.create(testSpace)
        testSpaceId = testSpace.id
    }

    override func tearDown() async throws {
        db.close()
        db = nil
        documentStore = nil
        spaceStore = nil
        testSpaceId = nil

        try await super.tearDown()
    }

    // MARK: - CRUD Flow Test

    func testDocumentCRUDFlow() throws {
        // Create
        let document = Document(
            spaceId: testSpaceId,
            title: "Test Document",
            content: "Test content",
            path: "/test"
        )
        try documentStore.create(document)

        // Get
        let retrieved = try documentStore.get(document.id)
        XCTAssertNotNil(retrieved, "Should retrieve created document")
        XCTAssertEqual(retrieved?.title, "Test Document")
        XCTAssertEqual(retrieved?.content, "Test content")
        XCTAssertEqual(retrieved?.path, "/test")

        // Update
        var updated = retrieved!
        updated.title = "Updated Document"
        updated.content = "Updated content"
        try documentStore.update(updated)

        let afterUpdate = try documentStore.get(document.id)
        XCTAssertEqual(afterUpdate?.title, "Updated Document")
        XCTAssertEqual(afterUpdate?.content, "Updated content")

        // List
        let documents = try documentStore.list()
        XCTAssertEqual(documents.count, 1)
        XCTAssertEqual(documents.first?.title, "Updated Document")

        // Delete
        try documentStore.delete(document.id)
        let afterDelete = try documentStore.get(document.id)
        XCTAssertNil(afterDelete, "Document should be deleted")
    }

    // MARK: - Space Filtering Tests

    func testListFilteredBySpace() throws {
        // Create another space
        let space2 = Space(name: "Space 2", color: "#00FF00")
        try spaceStore.create(space2)

        // Create documents in different spaces
        let doc1 = Document(spaceId: testSpaceId, title: "Space 1 Doc 1")
        let doc2 = Document(spaceId: testSpaceId, title: "Space 1 Doc 2")
        let doc3 = Document(spaceId: space2.id, title: "Space 2 Doc 1")

        try documentStore.create(doc1)
        try documentStore.create(doc2)
        try documentStore.create(doc3)

        // List all documents
        let allDocs = try documentStore.list()
        XCTAssertEqual(allDocs.count, 3)

        // List documents for space 1
        let space1Docs = try documentStore.list(spaceId: testSpaceId)
        XCTAssertEqual(space1Docs.count, 2)
        XCTAssertTrue(space1Docs.allSatisfy { $0.spaceId == testSpaceId })

        // List documents for space 2
        let space2Docs = try documentStore.list(spaceId: space2.id)
        XCTAssertEqual(space2Docs.count, 1)
        XCTAssertEqual(space2Docs.first?.title, "Space 2 Doc 1")
    }

    // MARK: - Path Tests

    func testGetByPath() throws {
        // Create documents with different paths
        let root1 = Document(spaceId: testSpaceId, title: "Root 1", path: "/")
        let root2 = Document(spaceId: testSpaceId, title: "Root 2", path: "/")
        let projects1 = Document(spaceId: testSpaceId, title: "Projects 1", path: "/projects")
        let projects2 = Document(spaceId: testSpaceId, title: "Projects 2", path: "/projects")
        let projectsWeb = Document(spaceId: testSpaceId, title: "Web Project", path: "/projects/web")

        try documentStore.create(root1)
        try documentStore.create(root2)
        try documentStore.create(projects1)
        try documentStore.create(projects2)
        try documentStore.create(projectsWeb)

        // Get documents at root path
        let rootDocs = try documentStore.getByPath("/")
        XCTAssertEqual(rootDocs.count, 2)
        XCTAssertTrue(rootDocs.allSatisfy { $0.path == "/" })

        // Get documents at /projects path
        let projectsDocs = try documentStore.getByPath("/projects")
        XCTAssertEqual(projectsDocs.count, 2)
        XCTAssertTrue(projectsDocs.allSatisfy { $0.path == "/projects" })

        // Get documents at /projects/web path
        let webDocs = try documentStore.getByPath("/projects/web")
        XCTAssertEqual(webDocs.count, 1)
        XCTAssertEqual(webDocs.first?.title, "Web Project")
    }

    func testListWithPathPrefix() throws {
        // Create documents with hierarchical paths
        let root = Document(spaceId: testSpaceId, title: "Root", path: "/")
        let projects = Document(spaceId: testSpaceId, title: "Projects", path: "/projects")
        let projectsWeb = Document(spaceId: testSpaceId, title: "Web", path: "/projects/web")
        let projectsApp = Document(spaceId: testSpaceId, title: "App", path: "/projects/app")
        let notes = Document(spaceId: testSpaceId, title: "Notes", path: "/notes")

        try documentStore.create(root)
        try documentStore.create(projects)
        try documentStore.create(projectsWeb)
        try documentStore.create(projectsApp)
        try documentStore.create(notes)

        // List all documents under /projects (prefix match)
        let projectsTree = try documentStore.list(path: "/projects")
        XCTAssertEqual(projectsTree.count, 3, "Should match /projects, /projects/web, /projects/app")

        // List all documents under /notes
        let notesTree = try documentStore.list(path: "/notes")
        XCTAssertEqual(notesTree.count, 1)

        // List all documents at root
        let allDocs = try documentStore.list(path: "/")
        XCTAssertEqual(allDocs.count, 5, "Should match all documents")
    }

    // MARK: - Default Document Tests

    func testGetDefault() throws {
        // Create multiple documents, one default
        let doc1 = Document(spaceId: testSpaceId, title: "Doc 1", isDefault: false)
        let doc2 = Document(spaceId: testSpaceId, title: "Doc 2", isDefault: true)
        let doc3 = Document(spaceId: testSpaceId, title: "Doc 3", isDefault: false)

        try documentStore.create(doc1)
        try documentStore.create(doc2)
        try documentStore.create(doc3)

        // Get default document
        let defaultDoc = try documentStore.getDefault(spaceId: testSpaceId)
        XCTAssertNotNil(defaultDoc)
        XCTAssertEqual(defaultDoc?.title, "Doc 2")
        XCTAssertTrue(defaultDoc?.isDefault ?? false)
    }

    func testSetDefault() throws {
        // Create documents
        let doc1 = Document(spaceId: testSpaceId, title: "Doc 1", isDefault: true)
        let doc2 = Document(spaceId: testSpaceId, title: "Doc 2", isDefault: false)

        try documentStore.create(doc1)
        try documentStore.create(doc2)

        // Verify doc1 is default
        var defaultDoc = try documentStore.getDefault(spaceId: testSpaceId)
        XCTAssertEqual(defaultDoc?.id, doc1.id)

        // Set doc2 as default
        try documentStore.setDefault(doc2.id)

        // Verify doc2 is now default and doc1 is not
        defaultDoc = try documentStore.getDefault(spaceId: testSpaceId)
        XCTAssertEqual(defaultDoc?.id, doc2.id)

        let updatedDoc1 = try documentStore.get(doc1.id)
        XCTAssertFalse(updatedDoc1?.isDefault ?? true, "Doc1 should no longer be default")
    }

    func testSetDefaultNonexistentDocument() {
        XCTAssertThrowsError(try documentStore.setDefault(UUID())) { error in
            XCTAssertTrue(error is DocumentStore.DocumentStoreError)
        }
    }

    // MARK: - Pinned Document Tests

    func testPinDocument() throws {
        let document = Document(spaceId: testSpaceId, title: "Test Doc", isPinned: false)
        try documentStore.create(document)

        // Pin the document
        try documentStore.pin(document.id)

        let pinned = try documentStore.get(document.id)
        XCTAssertTrue(pinned?.isPinned ?? false)
    }

    func testUnpinDocument() throws {
        let document = Document(spaceId: testSpaceId, title: "Test Doc", isPinned: true)
        try documentStore.create(document)

        // Unpin the document
        try documentStore.unpin(document.id)

        let unpinned = try documentStore.get(document.id)
        XCTAssertFalse(unpinned?.isPinned ?? true)
    }

    func testGetPinned() throws {
        // Create documents with different pinned states
        let pinned1 = Document(spaceId: testSpaceId, title: "Pinned 1", isPinned: true)
        let pinned2 = Document(spaceId: testSpaceId, title: "Pinned 2", isPinned: true)
        let notPinned = Document(spaceId: testSpaceId, title: "Not Pinned", isPinned: false)

        try documentStore.create(pinned1)
        try documentStore.create(pinned2)
        try documentStore.create(notPinned)

        // Get pinned documents
        let pinnedDocs = try documentStore.getPinned()
        XCTAssertEqual(pinnedDocs.count, 2)
        XCTAssertTrue(pinnedDocs.allSatisfy { $0.isPinned })
    }

    func testGetPinnedFilteredBySpace() throws {
        // Create another space
        let space2 = Space(name: "Space 2", color: "#00FF00")
        try spaceStore.create(space2)

        // Create pinned documents in different spaces
        let pinned1 = Document(spaceId: testSpaceId, title: "Space 1 Pinned", isPinned: true)
        let pinned2 = Document(spaceId: space2.id, title: "Space 2 Pinned", isPinned: true)
        let notPinned = Document(spaceId: testSpaceId, title: "Space 1 Not Pinned", isPinned: false)

        try documentStore.create(pinned1)
        try documentStore.create(pinned2)
        try documentStore.create(notPinned)

        // Get pinned for all spaces
        let allPinned = try documentStore.getPinned()
        XCTAssertEqual(allPinned.count, 2)

        // Get pinned for space 1 only
        let space1Pinned = try documentStore.getPinned(spaceId: testSpaceId)
        XCTAssertEqual(space1Pinned.count, 1)
        XCTAssertEqual(space1Pinned.first?.title, "Space 1 Pinned")

        // Get pinned for space 2 only
        let space2Pinned = try documentStore.getPinned(spaceId: space2.id)
        XCTAssertEqual(space2Pinned.count, 1)
        XCTAssertEqual(space2Pinned.first?.title, "Space 2 Pinned")
    }

    func testPinNonexistentDocument() {
        XCTAssertThrowsError(try documentStore.pin(UUID())) { error in
            XCTAssertTrue(error is DocumentStore.DocumentStoreError)
        }
    }

    func testUnpinNonexistentDocument() {
        XCTAssertThrowsError(try documentStore.unpin(UUID())) { error in
            XCTAssertTrue(error is DocumentStore.DocumentStoreError)
        }
    }

    // MARK: - Error Tests

    func testGetNonexistentDocument() throws {
        let result = try documentStore.get(UUID())
        XCTAssertNil(result, "Should return nil for nonexistent document")
    }

    func testDeleteNonexistentDocument() throws {
        // Should not throw (GRDB deleteOne doesn't throw for nonexistent)
        try documentStore.delete(UUID())
    }

    // MARK: - Content Tests

    func testDocumentWithEmptyContent() throws {
        let document = Document(
            spaceId: testSpaceId,
            title: "Empty Doc"
            // content defaults to ""
        )
        try documentStore.create(document)

        let retrieved = try documentStore.get(document.id)
        XCTAssertEqual(retrieved?.content, "")
    }

    func testDocumentWithLargeContent() throws {
        // Test with 1MB of content
        let largeContent = String(repeating: "a", count: 1_000_000)
        let document = Document(
            spaceId: testSpaceId,
            title: "Large Doc",
            content: largeContent
        )
        try documentStore.create(document)

        let retrieved = try documentStore.get(document.id)
        XCTAssertEqual(retrieved?.content.count, 1_000_000)
    }
}
