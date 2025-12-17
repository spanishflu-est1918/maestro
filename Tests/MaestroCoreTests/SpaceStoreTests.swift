import XCTest
@testable import MaestroCore

/// Integration tests for SpaceStore CRUD operations
final class SpaceStoreTests: XCTestCase {
    var db: Database!
    var store: SpaceStore!

    override func setUp() async throws {
        try await super.setUp()

        // Create in-memory database for each test
        db = Database()
        try db.connect()
        store = SpaceStore(database: db)
    }

    override func tearDown() async throws {
        db.close()
        db = nil
        store = nil

        try await super.tearDown()
    }

    // MARK: - CRUD Flow Test

    func testSpaceCRUDFlow() throws {
        // Create
        let space = Space(
            name: "Test Space",
            color: "#FF0000",
            tags: ["test", "active"]
        )
        try store.create(space)

        // Get
        let retrieved = try store.get(space.id)
        XCTAssertNotNil(retrieved, "Should retrieve created space")
        XCTAssertEqual(retrieved?.name, "Test Space")
        XCTAssertEqual(retrieved?.color, "#FF0000")
        XCTAssertEqual(retrieved?.tags, ["test", "active"])

        // Update
        var updated = retrieved!
        updated.name = "Updated Space"
        updated.tags = ["test", "active", "updated"]
        try store.update(updated)

        let afterUpdate = try store.get(space.id)
        XCTAssertEqual(afterUpdate?.name, "Updated Space")
        XCTAssertEqual(afterUpdate?.tags, ["test", "active", "updated"])

        // List
        let spaces = try store.list()
        XCTAssertEqual(spaces.count, 1)
        XCTAssertEqual(spaces.first?.name, "Updated Space")

        // Archive
        try store.archive(space.id)
        let afterArchive = try store.get(space.id)
        XCTAssertTrue(afterArchive?.archived ?? false, "Should be archived")

        let nonArchivedList = try store.list(includeArchived: false)
        XCTAssertEqual(nonArchivedList.count, 0, "Archived spaces should not appear in default list")

        let archivedList = try store.list(includeArchived: true)
        XCTAssertEqual(archivedList.count, 1, "Archived spaces should appear when includeArchived=true")

        // Delete
        try store.delete(space.id)
        let afterDelete = try store.get(space.id)
        XCTAssertNil(afterDelete, "Space should be deleted")
    }

    // MARK: - Hierarchy Tests

    func testSpaceHierarchy() throws {
        // Create parent
        let music = Space(name: "Music", color: "#FF0000")
        try store.create(music)

        // Create children
        let band = Space(name: "Band Music", color: "#00FF00", parentId: music.id)
        let solo = Space(name: "Solo Music", color: "#0000FF", parentId: music.id)
        try store.create(band)
        try store.create(solo)

        // Create grandchildren
        let marketing = Space(name: "Marketing", color: "#FFFF00", parentId: band.id)
        let production = Space(name: "Production", color: "#FF00FF", parentId: band.id)
        try store.create(marketing)
        try store.create(production)

        // Test getChildren
        let musicChildren = try store.getChildren(of: music.id)
        XCTAssertEqual(musicChildren.count, 2)
        XCTAssertTrue(musicChildren.contains { $0.name == "Band Music" })
        XCTAssertTrue(musicChildren.contains { $0.name == "Solo Music" })

        let bandChildren = try store.getChildren(of: band.id)
        XCTAssertEqual(bandChildren.count, 2)
        XCTAssertTrue(bandChildren.contains { $0.name == "Marketing" })
        XCTAssertTrue(bandChildren.contains { $0.name == "Production" })

        // Test getDescendants (recursive)
        let musicDescendants = try store.getDescendants(of: music.id)
        XCTAssertEqual(musicDescendants.count, 4, "Should have 2 children + 2 grandchildren")

        let bandDescendants = try store.getDescendants(of: band.id)
        XCTAssertEqual(bandDescendants.count, 2, "Should have 2 children")

        // Test getAncestors
        let marketingAncestors = try store.getAncestors(of: marketing.id)
        XCTAssertEqual(marketingAncestors.count, 2, "Should have parent + grandparent")
        XCTAssertTrue(marketingAncestors.contains { $0.name == "Band Music" })
        XCTAssertTrue(marketingAncestors.contains { $0.name == "Music" })

        // Test root spaces (parentFilter = .some(nil))
        let rootSpaces = try store.listRoots()
        XCTAssertEqual(rootSpaces.count, 1)
        XCTAssertEqual(rootSpaces.first?.name, "Music")
    }

    func testDeepHierarchy() throws {
        // Test unlimited depth: 5 levels
        let level0 = Space(name: "Level 0", color: "#000000")
        try store.create(level0)

        let level1 = Space(name: "Level 1", color: "#111111", parentId: level0.id)
        try store.create(level1)

        let level2 = Space(name: "Level 2", color: "#222222", parentId: level1.id)
        try store.create(level2)

        let level3 = Space(name: "Level 3", color: "#333333", parentId: level2.id)
        try store.create(level3)

        let level4 = Space(name: "Level 4", color: "#444444", parentId: level3.id)
        try store.create(level4)

        // Get all descendants from root
        let descendants = try store.getDescendants(of: level0.id)
        XCTAssertEqual(descendants.count, 4, "Should have 4 descendants")

        // Get all ancestors from leaf
        let ancestors = try store.getAncestors(of: level4.id)
        XCTAssertEqual(ancestors.count, 4, "Should have 4 ancestors")
    }

    // MARK: - Tags Tests

    func testFindByTag() throws {
        // Create spaces with different tags
        let space1 = Space(name: "Space 1", color: "#FF0000", tags: ["active", "creative"])
        let space2 = Space(name: "Space 2", color: "#00FF00", tags: ["active", "revenue"])
        let space3 = Space(name: "Space 3", color: "#0000FF", tags: ["creative", "experimental"])
        let space4 = Space(name: "Space 4", color: "#FFFF00", tags: ["archived"])

        try store.create(space1)
        try store.create(space2)
        try store.create(space3)
        try store.create(space4)

        // Find by "active" tag
        let activeSpaces = try store.findByTag("active")
        XCTAssertEqual(activeSpaces.count, 2)
        XCTAssertTrue(activeSpaces.contains { $0.name == "Space 1" })
        XCTAssertTrue(activeSpaces.contains { $0.name == "Space 2" })

        // Find by "creative" tag
        let creativeSpaces = try store.findByTag("creative")
        XCTAssertEqual(creativeSpaces.count, 2)
        XCTAssertTrue(creativeSpaces.contains { $0.name == "Space 1" })
        XCTAssertTrue(creativeSpaces.contains { $0.name == "Space 3" })

        // Find by "revenue" tag
        let revenueSpaces = try store.findByTag("revenue")
        XCTAssertEqual(revenueSpaces.count, 1)
        XCTAssertEqual(revenueSpaces.first?.name, "Space 2")

        // Find non-existent tag
        let noneSpaces = try store.findByTag("nonexistent")
        XCTAssertEqual(noneSpaces.count, 0)
    }

    func testTagsWithHierarchy() throws {
        // Create hierarchy with tags
        let music = Space(name: "Music", color: "#FF0000", tags: ["creative"])
        let band = Space(name: "Band Music", color: "#00FF00", parentId: music.id, tags: ["active", "revenue"])
        let marketing = Space(name: "Marketing", color: "#0000FF", parentId: band.id, tags: ["active", "urgent"])

        try store.create(music)
        try store.create(band)
        try store.create(marketing)

        // Find all "active" spaces (should get 2)
        let activeSpaces = try store.findByTag("active")
        XCTAssertEqual(activeSpaces.count, 2)

        // Find all "creative" spaces (should get 1)
        let creativeSpaces = try store.findByTag("creative")
        XCTAssertEqual(creativeSpaces.count, 1)
        XCTAssertEqual(creativeSpaces.first?.name, "Music")
    }

    // MARK: - Archive Tests

    func testArchiveWithChildren() throws {
        // Create parent with children
        let parent = Space(name: "Parent", color: "#FF0000")
        let child1 = Space(name: "Child 1", color: "#00FF00", parentId: parent.id)
        let child2 = Space(name: "Child 2", color: "#0000FF", parentId: parent.id)

        try store.create(parent)
        try store.create(child1)
        try store.create(child2)

        // Archive parent
        try store.archive(parent.id)

        // Children should still be accessible
        let children = try store.getChildren(of: parent.id, includeArchived: false)
        XCTAssertEqual(children.count, 2, "Children should still be visible")

        // Parent should not appear in default list
        let spaces = try store.list(includeArchived: false)
        XCTAssertEqual(spaces.count, 2, "Only non-archived spaces")
        XCTAssertFalse(spaces.contains { $0.id == parent.id })
    }

    func testUnarchive() throws {
        let space = Space(name: "Test", color: "#FF0000")
        try store.create(space)

        // Archive
        try store.archive(space.id)
        let archived = try store.get(space.id)
        XCTAssertTrue(archived?.archived ?? false)

        // Unarchive
        try store.unarchive(space.id)
        let unarchived = try store.get(space.id)
        XCTAssertFalse(unarchived?.archived ?? true)
    }

    // MARK: - Error Tests

    func testGetNonexistentSpace() throws {
        let result = try store.get(UUID())
        XCTAssertNil(result, "Should return nil for nonexistent space")
    }

    func testArchiveNonexistentSpace() {
        XCTAssertThrowsError(try store.archive(UUID())) { error in
            XCTAssertTrue(error is SpaceStore.SpaceStoreError)
        }
    }

    func testDeleteNonexistentSpace() throws {
        // Should not throw (GRDB deleteOne doesn't throw for nonexistent)
        try store.delete(UUID())
    }
}
