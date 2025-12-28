/// Maestro Core Library
/// Headless organizational system for macOS

// Re-export GRDB so consumers don't need to import it separately
@_exported import GRDB

public struct Maestro {
    public static let version = "0.1.0"

    public init() {}

    public func hello() -> String {
        return "Maestro v\(Maestro.version)"
    }
}
