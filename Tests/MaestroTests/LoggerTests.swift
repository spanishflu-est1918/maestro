import XCTest
@testable import Maestro

final class LoggerTests: XCTestCase {
    let testLogPath = "/tmp/maestro-test.log"

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(atPath: testLogPath)
        // Clean up rotated logs
        for i in 1...5 {
            try? FileManager.default.removeItem(atPath: "\(testLogPath).\(i)")
        }
    }

    func testLoggerBasicLogging() throws {
        let logger = Logger(path: testLogPath, maxSizeMB: 1, minLevel: .debug)

        logger.info("Test info message")
        logger.warning("Test warning message")
        logger.error("Test error message")

        // Give async queue time to write
        Thread.sleep(forTimeInterval: 0.1)

        let contents = try String(contentsOfFile: testLogPath, encoding: .utf8)
        XCTAssertTrue(contents.contains("INFO"))
        XCTAssertTrue(contents.contains("Test info message"))
        XCTAssertTrue(contents.contains("WARNING"))
        XCTAssertTrue(contents.contains("ERROR"))
    }

    func testLoggerLevelFiltering() throws {
        let logger = Logger(path: testLogPath, maxSizeMB: 1, minLevel: .warning)

        logger.debug("Debug message")
        logger.info("Info message")
        logger.warning("Warning message")
        logger.error("Error message")

        Thread.sleep(forTimeInterval: 0.1)

        let contents = try String(contentsOfFile: testLogPath, encoding: .utf8)

        // Should not contain debug or info
        XCTAssertFalse(contents.contains("Debug message"))
        XCTAssertFalse(contents.contains("Info message"))

        // Should contain warning and error
        XCTAssertTrue(contents.contains("Warning message"))
        XCTAssertTrue(contents.contains("Error message"))
    }

    func testLoggerCreatesDirectory() throws {
        let nestedPath = "/tmp/maestro-test-dir/logs/test.log"
        let logger = Logger(path: nestedPath, maxSizeMB: 1, minLevel: .info)

        logger.info("Test message")
        Thread.sleep(forTimeInterval: 0.1)

        XCTAssertTrue(FileManager.default.fileExists(atPath: nestedPath))

        // Cleanup
        try? FileManager.default.removeItem(atPath: "/tmp/maestro-test-dir")
    }

    func testLoggerRotation() throws {
        // Create logger with very small max size to trigger rotation
        let logger = Logger(path: testLogPath, maxSizeMB: 0, minLevel: .info)

        // Write enough to trigger rotation
        for i in 1...100 {
            logger.info("Test message number \(i) with some extra content to make it longer")
        }

        Thread.sleep(forTimeInterval: 0.2)

        // Check that rotation occurred (backup file should exist)
        let rotatedExists = FileManager.default.fileExists(atPath: "\(testLogPath).1")
        XCTAssertTrue(rotatedExists, "Rotated log file should exist")
    }
}
