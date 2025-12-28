import Foundation

/// Maestro Configuration
/// Loads and manages daemon configuration from JSON files
public struct Configuration: Codable {
    public var logLevel: LogLevel
    public var logPath: String
    public var logRotationSizeMB: Int
    public var databasePath: String
    public var refreshInterval: Int

    public enum LogLevel: String, Codable {
        case debug, info, warning, error
    }

    // MARK: - Defaults

    public static var `default`: Configuration {
        Configuration(
            logLevel: .info,
            logPath: "~/Library/Logs/Maestro/maestro.log",
            logRotationSizeMB: 10,
            databasePath: "~/Library/Application Support/Maestro/maestro.db",
            refreshInterval: 5
        )
    }

    // MARK: - Loading

    /// Load configuration from file, falling back to defaults if not found
    public static func load(from path: String? = nil) throws -> Configuration {
        let configPath = path ?? defaultConfigPath()

        // Return defaults if file doesn't exist
        guard FileManager.default.fileExists(atPath: configPath) else {
            var config = Configuration.default
            // Expand tilde paths in defaults too
            config.logPath = expandPath(config.logPath)
            config.databasePath = expandPath(config.databasePath)
            return config
        }

        let data = try Data(contentsOf: URL(fileURLWithPath: configPath))
        var config = try JSONDecoder().decode(Configuration.self, from: data)

        // Expand tilde paths
        config.logPath = expandPath(config.logPath)
        config.databasePath = expandPath(config.databasePath)

        return config
    }

    /// Save configuration to file
    public func save(to path: String? = nil) throws {
        let configPath = path ?? Configuration.defaultConfigPath()

        // Create directory if needed
        let configDir = URL(fileURLWithPath: configPath).deletingLastPathComponent()
        try FileManager.default.createDirectory(at: configDir, withIntermediateDirectories: true)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(self)
        try data.write(to: URL(fileURLWithPath: configPath))
    }

    // MARK: - Paths

    private static func defaultConfigPath() -> String {
        expandPath("~/.config/maestro/config.json")
    }

    private static func expandPath(_ path: String) -> String {
        (path as NSString).expandingTildeInPath
    }
}
