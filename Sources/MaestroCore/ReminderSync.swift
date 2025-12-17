import Foundation
import EventKit
import GRDB

/// EventKit Reminders Integration
/// Fetches reminders and links them to Maestro spaces
public class ReminderSync {
    private let eventStore = EKEventStore()
    private let db: Database

    public init(database: Database) {
        self.db = database
    }

    /// Request permission to access reminders
    public func requestPermission() async throws -> Bool {
        if #available(macOS 14.0, *) {
            return try await eventStore.requestFullAccessToReminders()
        } else {
            return try await withCheckedThrowingContinuation { continuation in
                eventStore.requestAccess(to: .reminder) { granted, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: granted)
                    }
                }
            }
        }
    }

    /// Fetch all reminders from Reminders.app
    public func fetchReminders() throws -> [EKReminder] {
        let predicate = eventStore.predicateForReminders(in: nil)
        var reminders: [EKReminder] = []

        let semaphore = DispatchSemaphore(value: 0)

        eventStore.fetchReminders(matching: predicate) { fetchedReminders in
            if let fetchedReminders = fetchedReminders {
                reminders = fetchedReminders
            }
            semaphore.signal()
        }

        semaphore.wait()
        return reminders
    }

    /// Link a reminder to a space
    public func linkReminder(_ reminder: EKReminder, toSpace spaceId: UUID) throws {
        let link = ReminderLink(
            spaceId: spaceId,
            reminderId: reminder.calendarItemIdentifier,
            reminderTitle: reminder.title ?? "Untitled",
            reminderListId: reminder.calendar.calendarIdentifier,
            reminderListName: reminder.calendar.title,
            isCompleted: reminder.isCompleted,
            dueDate: reminder.dueDateComponents?.date
        )

        try db.write { db in
            try link.insert(db)
        }
    }

    /// Get linked reminders for a space
    public func getLinkedReminders(forSpace spaceId: UUID) throws -> [ReminderLink] {
        return try db.read { db in
            try ReminderLink.all()
                .filter(ReminderLink.Columns.spaceId == spaceId.uuidString)
                .fetchAll(db)
        }
    }

    /// Sync reminders: fetch from EventKit and update existing links
    public func sync() throws {
        let reminders = try fetchReminders()
        let reminderMap = Dictionary(uniqueKeysWithValues: reminders.map { ($0.calendarItemIdentifier, $0) })

        // Get all existing links
        let links = try db.read { db in
            try ReminderLink.fetchAll(db)
        }

        // Update existing links
        try db.write { db in
            for var link in links {
                if let reminder = reminderMap[link.reminderId] {
                    link.reminderTitle = reminder.title ?? "Untitled"
                    link.isCompleted = reminder.isCompleted
                    link.dueDate = reminder.dueDateComponents?.date
                    link.updatedAt = Date()
                    try link.update(db)
                }
            }
        }
    }
}
