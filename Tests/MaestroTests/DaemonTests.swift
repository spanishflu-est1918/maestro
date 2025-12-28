import XCTest
import _Concurrency
import GRDB
@testable import Maestro
@testable import MaestroCore

/// Daemon Process Tests
/// Tests daemon lifecycle and configuration
/// NOTE: Signal handling tests are skipped because sending SIGTERM/SIGINT
/// to the test process corrupts signal handlers for subsequent tests
final class DaemonTests: XCTestCase {

    func testDaemonInitialization() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let dbPath = tempDir.appendingPathComponent("daemon-test-\(UUID().uuidString).db").path

        let config = Configuration(
            logLevel: .debug,
            logPath: "/tmp/maestro-daemon-test.log",
            logRotationSizeMB: 10,
            databasePath: dbPath,
            refreshInterval: 5
        )

        // Daemon should initialize without error
        let daemon = try Daemon(config: config)
        XCTAssertNotNil(daemon)

        // Cleanup
        try? FileManager.default.removeItem(atPath: dbPath)
    }

    func testDaemonConfigurationPaths() throws {
        let config = Configuration(
            logLevel: .info,
            logPath: "/tmp/test.log",
            logRotationSizeMB: 5,
            databasePath: "/tmp/test.db",
            refreshInterval: 10
        )

        XCTAssertEqual(config.logPath, "/tmp/test.log")
        XCTAssertEqual(config.databasePath, "/tmp/test.db")
        XCTAssertEqual(config.refreshInterval, 10)
    }

    func testDaemonDefaultConfiguration() {
        let config = Configuration.default

        XCTAssertEqual(config.logLevel, .info)
        XCTAssertTrue(config.logPath.contains("Maestro"))
        XCTAssertTrue(config.databasePath.contains("Maestro"))
    }
}
