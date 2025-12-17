import XCTest
@testable import MaestroCore

/// Tests for space path matching and inference
final class SpacePathMatchingTests: XCTestCase {
    var db: Database!
    var store: SpaceStore!

    override func setUpWithError() throws {
        db = Database()
        try db.connect()
        store = SpaceStore(database: db)
    }

    override func tearDownWithError() throws {
        try store.deleteAll()
        db.close()
    }

    func testSpacePathMatching() throws {
        // Create spaces with paths
        let rootSpace = Space(name: "Root", path: "/Users/test/projects", color: "#FF0000")
        let subSpace = Space(name: "Sub", path: "/Users/test/projects/subproject", color: "#00FF00", parentId: rootSpace.id)

        try store.create(rootSpace)
        try store.create(subSpace)

        // Test exact match
        let exactMatches = try store.findByPath("/Users/test/projects")
        XCTAssertEqual(exactMatches.count, 1)
        XCTAssertEqual(exactMatches.first?.id, rootSpace.id)

        // Test subdirectory match (should return both)
        let subdirMatches = try store.findByPath("/Users/test/projects/subproject/file.txt")
        XCTAssertEqual(subdirMatches.count, 2)
        // Should be ordered by path length DESC (subSpace first, rootSpace second)
        XCTAssertEqual(subdirMatches[0].id, subSpace.id)
        XCTAssertEqual(subdirMatches[1].id, rootSpace.id)

        // Test non-matching path
        let noMatches = try store.findByPath("/Users/other/path")
        XCTAssertEqual(noMatches.count, 0)
    }

    func testSpaceInference() throws {
        // Create nested space hierarchy
        let root = Space(name: "Projects", path: "/Users/test/projects", color: "#FF0000")
        let work = Space(name: "Work", path: "/Users/test/projects/work", color: "#00FF00", parentId: root.id)
        let personal = Space(name: "Personal", path: "/Users/test/projects/personal", color: "#0000FF", parentId: root.id)

        try store.create(root)
        try store.create(work)
        try store.create(personal)

        // Infer space for work subdirectory - should return work space (closest match)
        let workMatch = try store.inferSpace(forPath: "/Users/test/projects/work/project1/src/main.swift")
        XCTAssertEqual(workMatch?.id, work.id)

        // Infer space for personal subdirectory - should return personal space
        let personalMatch = try store.inferSpace(forPath: "/Users/test/projects/personal/notes.md")
        XCTAssertEqual(personalMatch?.id, personal.id)

        // Infer space for direct child of root - should return root space
        let rootMatch = try store.inferSpace(forPath: "/Users/test/projects/readme.md")
        XCTAssertEqual(rootMatch?.id, root.id)

        // No match for completely different path
        let noMatch = try store.inferSpace(forPath: "/Users/other/file.txt")
        XCTAssertNil(noMatch)
    }

    func testPathNormalization() throws {
        // Create space with normalized path
        let space = Space(name: "Test", path: "/Users/test/projects", color: "#FF0000")
        try store.create(space)

        // Test with trailing slash
        let match1 = try store.findByPath("/Users/test/projects/")
        XCTAssertEqual(match1.count, 1)
        XCTAssertEqual(match1.first?.id, space.id)

        // Test with relative path components
        let match2 = try store.findByPath("/Users/test/./projects")
        XCTAssertEqual(match2.count, 1)
        XCTAssertEqual(match2.first?.id, space.id)
    }

    func testPathMatchingWithArchivedSpaces() throws {
        let activeSpace = Space(name: "Active", path: "/Users/test/active", color: "#FF0000")
        var archivedSpace = Space(name: "Archived", path: "/Users/test/archived", color: "#00FF00")
        archivedSpace.archived = true

        try store.create(activeSpace)
        try store.create(archivedSpace)

        // By default, should not include archived
        let defaultMatches = try store.findByPath("/Users/test/archived")
        XCTAssertEqual(defaultMatches.count, 0)

        // With includeArchived, should find it
        let allMatches = try store.findByPath("/Users/test/archived", includeArchived: true)
        XCTAssertEqual(allMatches.count, 1)
        XCTAssertEqual(allMatches.first?.id, archivedSpace.id)
    }

    func testSpaceInferenceWithNoPath() throws {
        // Create space without path
        let spaceWithoutPath = Space(name: "No Path", color: "#FF0000")
        try store.create(spaceWithoutPath)

        // Should not match any paths
        let noMatch = try store.findByPath("/any/path")
        XCTAssertEqual(noMatch.count, 0)
    }
}
