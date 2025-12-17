import XCTest
import GRDB
@testable import MaestroCore

/// EventKit Reminders Integration Tests
/// Tests reminder sync and space linking
final class ReminderSyncTests: XCTestCase {

    func testEventKitIntegrationFlow() throws {
        // Create test database
        let db = Database()
        try db.connect()

        // Verify migration created reminder_space_links table
        let tables = try db.read { db in
            try String.fetchAll(db, sql: """
                SELECT name FROM sqlite_master
                WHERE type='table' AND name = 'reminder_space_links'
            """)
        }

        XCTAssertTrue(tables.contains("reminder_space_links"), "Should have reminder_space_links table")
    }

    func testReminderSyncFlow() throws {
        // Create test database
        let db = Database()
        try db.connect()

        // Create test space
        let spaceStore = SpaceStore(database: db)
        let space = Space(name: "Test Space", color: "#FF0000")
        try spaceStore.create(space)

        // Create mock reminder link
        let link = ReminderLink(
            spaceId: space.id,
            reminderId: "test-reminder-id",
            reminderTitle: "Test Reminder",
            reminderListId: "test-list-id",
            reminderListName: "Test List"
        )

        try db.write { db in
            try link.insert(db)
        }

        // Verify link was created
        let links = try db.read { db in
            try ReminderLink.all()
                .filter(ReminderLink.Columns.spaceId == space.id.uuidString)
                .fetchAll(db)
        }

        XCTAssertEqual(links.count, 1)
        XCTAssertEqual(links.first?.reminderTitle, "Test Reminder")
    }

    func testReminderSyncInit() throws {
        let db = Database()
        try db.connect()

        // Verify ReminderSync can be initialized
        let sync = ReminderSync(database: db)
        XCTAssertNotNil(sync)
    }

    func testGetLinkedReminders() throws {
        let db = Database()
        try db.connect()

        let spaceStore = SpaceStore(database: db)
        let space = Space(name: "Test Space", color: "#FF0000")
        try spaceStore.create(space)

        // Add multiple reminder links
        for i in 1...3 {
            let link = ReminderLink(
                spaceId: space.id,
                reminderId: "reminder-\(i)",
                reminderTitle: "Reminder \(i)",
                reminderListId: "list-1",
                reminderListName: "My List"
            )
            try db.write { db in
                try link.insert(db)
            }
        }

        // Get linked reminders
        let sync = ReminderSync(database: db)
        let links = try sync.getLinkedReminders(forSpace: space.id)

        XCTAssertEqual(links.count, 3)
    }
}
