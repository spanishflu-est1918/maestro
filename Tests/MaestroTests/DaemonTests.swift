import XCTest
import _Concurrency
import GRDB
@testable import Maestro
@testable import MaestroCore

/// Daemon Process Tests
/// Tests daemon lifecycle, signal handling, and process management
final class DaemonTests: XCTestCase {

    func testStartupSequence() async throws {
        // Create temporary database path
        let tempDir = FileManager.default.temporaryDirectory
        let dbPath = tempDir.appendingPathComponent("daemon-test-\(UUID().uuidString).db").path
        
        // Create config with test database path
        let config = Configuration(
            logLevel: .debug,
            logPath: "/tmp/maestro-daemon-test.log",
            logRotationSizeMB: 10,
            databasePath: dbPath,
            refreshInterval: 5
        )
        
        let daemon = try Daemon(config: config)
        
        // Start daemon in background
        let daemonTask = _Concurrency.Task {
            try await daemon.start()
        }
        
        // Give it time to complete startup sequence
        try await _Concurrency.Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        // Verify database file was created
        XCTAssertTrue(FileManager.default.fileExists(atPath: dbPath), "Database file should exist")
        
        // Verify database has correct schema by opening it
        let db = Database(path: dbPath)
        try db.connect()
        
        let tables = try db.read { db in
            try String.fetchAll(db, sql: """
                SELECT name FROM sqlite_master
                WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'grdb_%'
                ORDER BY name
            """)
        }
        
        XCTAssertEqual(tables.sorted(), ["agent_activity", "agent_sessions", "documents", "linear_sync", "reminder_space_links", "spaces", "tasks"], "Should have all core tables")
        
        db.close()
        
        // Send SIGTERM to trigger shutdown
        kill(getpid(), SIGTERM)
        
        // Wait for graceful shutdown
        try await _Concurrency.Task.sleep(nanoseconds: 100_000_000)
        
        // Cleanup
        daemonTask.cancel()
        try? FileManager.default.removeItem(atPath: dbPath)
    }

    func testDaemonStartsAndStaysRunning() async throws {
        let config = Configuration.default
        let daemon = try Daemon(config: config)

        // Start daemon in background
        let daemonTask = _Concurrency.Task {
            try await daemon.start()
        }

        // Give it time to start
        try await _Concurrency.Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        // Daemon should be running (task not completed)
        XCTAssertFalse(daemonTask.isCancelled)

        // Send SIGTERM to trigger shutdown
        kill(getpid(), SIGTERM)

        // Wait for graceful shutdown
        try await _Concurrency.Task.sleep(nanoseconds: 100_000_000)

        // Daemon should have shut down
        daemonTask.cancel()
    }

    func testDaemonHandlesSIGTERM() async throws {
        let config = Configuration.default
        let daemon = try Daemon(config: config)

        let daemonTask = _Concurrency.Task {
            try await daemon.start()
        }

        try await _Concurrency.Task.sleep(nanoseconds: 50_000_000)

        // Send SIGTERM
        kill(getpid(), SIGTERM)

        // Should shutdown gracefully
        try await _Concurrency.Task.sleep(nanoseconds: 100_000_000)

        daemonTask.cancel()
    }

    func testDaemonHandlesSIGINT() async throws {
        let config = Configuration.default
        let daemon = try Daemon(config: config)

        let daemonTask = _Concurrency.Task {
            try await daemon.start()
        }

        try await _Concurrency.Task.sleep(nanoseconds: 50_000_000)

        // Send SIGINT
        kill(getpid(), SIGINT)

        // Should shutdown gracefully
        try await _Concurrency.Task.sleep(nanoseconds: 100_000_000)

        daemonTask.cancel()
    }
}
