import XCTest
@testable import Maestro

final class ConfigurationTests: XCTestCase {
    let testConfigPath = "/tmp/maestro-test-config.json"

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(atPath: testConfigPath)
    }

    func testLoggingAndConfiguration() throws {
        // Test default configuration
        let defaultConfig = Configuration.default
        XCTAssertEqual(defaultConfig.logLevel, .info)
        XCTAssertEqual(defaultConfig.refreshInterval, 5)

        // Test saving configuration
        var config = Configuration.default
        config.logLevel = .debug
        config.refreshInterval = 10
        try config.save(to: testConfigPath)

        // Test loading configuration
        let loaded = try Configuration.load(from: testConfigPath)
        XCTAssertEqual(loaded.logLevel, .debug)
        XCTAssertEqual(loaded.refreshInterval, 10)
    }

    func testConfigurationDefaults() throws {
        // Loading non-existent file should return defaults
        let config = try Configuration.load(from: "/tmp/nonexistent-config.json")
        XCTAssertEqual(config.logLevel, .info)
        XCTAssertEqual(config.logRotationSizeMB, 10)
    }

    func testConfigurationPersistence() throws {
        let config1 = Configuration(
            logLevel: .warning,
            logPath: "/tmp/test.log",
            logRotationSizeMB: 20,
            databasePath: "/tmp/test.db",
            refreshInterval: 15
        )

        try config1.save(to: testConfigPath)
        let config2 = try Configuration.load(from: testConfigPath)

        XCTAssertEqual(config1.logLevel, config2.logLevel)
        XCTAssertEqual(config1.logRotationSizeMB, config2.logRotationSizeMB)
        XCTAssertEqual(config1.refreshInterval, config2.refreshInterval)
    }
}
