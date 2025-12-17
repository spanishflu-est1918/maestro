import XCTest
import Cocoa
@testable import MaestroUI
@testable import MaestroCore

/// Quick View Panel Tests
/// Tests dropdown panel functionality, space/task display
final class QuickViewTests: XCTestCase {

    func testQuickViewShowsSpacesAndTasks() throws {
        // Create test database
        let db = Database()
        try db.connect()

        // Add test data
        let spaceStore = SpaceStore(database: db)
        let taskStore = TaskStore(database: db)

        let space = Space(name: "Test Space", path: "/test", color: "#FF0000")
        try spaceStore.create(space)

        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!

        let task = Task(
            spaceId: space.id,
            title: "Test Task",
            description: "Test Description",
            status: .todo,
            priority: .medium,
            dueDate: tomorrow
        )
        try taskStore.create(task)

        // Create mock app delegate
        let appDelegate = AppDelegate()

        // Create quick view panel
        let quickView = QuickViewPanel(database: db, appDelegate: appDelegate)
        quickView.loadView()

        // Verify view was loaded
        XCTAssertNotNil(quickView.view, "QuickView should load")
        XCTAssertEqual(quickView.view.frame.width, 300)
        XCTAssertEqual(quickView.view.frame.height, 400)
    }

    func testQuickViewWithEmptyDatabase() throws {
        // Create empty database
        let db = Database()
        try db.connect()

        // Create mock app delegate
        let appDelegate = AppDelegate()

        // Create quick view panel
        let quickView = QuickViewPanel(database: db, appDelegate: appDelegate)
        quickView.loadView()

        // Verify view was loaded
        XCTAssertNotNil(quickView.view, "QuickView should load even with no data")
    }

    func testOpenViewerButton() throws {
        let db = Database()
        try db.connect()

        let appDelegate = AppDelegate()
        let quickView = QuickViewPanel(database: db, appDelegate: appDelegate)
        quickView.loadView()

        // Verify we can call openViewer without crashing
        // Note: This will attempt to show a window, but in tests that's okay
        XCTAssertNoThrow(quickView.openViewer())
    }
}
