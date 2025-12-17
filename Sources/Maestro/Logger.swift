import Foundation

/// Simple file-based logger with rotation
public class Logger {
    public enum Level: Int, Comparable {
        case debug = 0, info = 1, warning = 2, error = 3

        public static func < (lhs: Level, rhs: Level) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    private let logPath: String
    private let maxSizeBytes: Int
    private let minLevel: Level
    private let queue = DispatchQueue(label: "com.maestro.logger", qos: .utility)
    private var fileHandle: FileHandle?

    public init(path: String, maxSizeMB: Int = 10, minLevel: Level = .info) {
        self.logPath = path
        self.maxSizeBytes = maxSizeMB * 1024 * 1024
        self.minLevel = minLevel
        setupLogFile()
    }

    deinit {
        fileHandle?.closeFile()
    }

    // MARK: - Logging Methods

    public func debug(_ message: String, file: String = #file, line: Int = #line) {
        log(.debug, message, file: file, line: line)
    }

    public func info(_ message: String, file: String = #file, line: Int = #line) {
        log(.info, message, file: file, line: line)
    }

    public func warning(_ message: String, file: String = #file, line: Int = #line) {
        log(.warning, message, file: file, line: line)
    }

    public func error(_ message: String, file: String = #file, line: Int = #line) {
        log(.error, message, file: file, line: line)
    }

    // MARK: - Internal

    private func log(_ level: Level, _ message: String, file: String, line: Int) {
        guard level >= minLevel else { return }

        queue.async { [weak self] in
            guard let self = self else { return }

            let timestamp = ISO8601DateFormatter().string(from: Date())
            let filename = URL(fileURLWithPath: file).lastPathComponent
            let levelStr = String(describing: level).uppercased().padding(toLength: 7, withPad: " ", startingAt: 0)
            let logLine = "[\(timestamp)] \(levelStr) [\(filename):\(line)] \(message)\n"

            if let data = logLine.data(using: .utf8) {
                self.write(data)
            }
        }
    }

    private func write(_ data: Data) {
        // Rotate if needed
        if shouldRotate() {
            rotate()
        }

        // Write to file
        fileHandle?.write(data)
    }

    private func setupLogFile() {
        let url = URL(fileURLWithPath: logPath)
        let directory = url.deletingLastPathComponent()

        // Create directory if needed
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        // Create file if doesn't exist
        if !FileManager.default.fileExists(atPath: logPath) {
            FileManager.default.createFile(atPath: logPath, contents: nil)
        }

        // Open file handle
        fileHandle = FileHandle(forWritingAtPath: logPath)
        fileHandle?.seekToEndOfFile()
    }

    private func shouldRotate() -> Bool {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: logPath),
              let fileSize = attributes[.size] as? Int else {
            return false
        }
        return fileSize >= maxSizeBytes
    }

    private func rotate() {
        fileHandle?.closeFile()

        // Move current log to .1, .1 to .2, etc.
        for i in (1...4).reversed() {
            let oldPath = "\(logPath).\(i)"
            let newPath = "\(logPath).\(i + 1)"
            try? FileManager.default.moveItem(atPath: oldPath, toPath: newPath)
        }

        // Move current to .1
        try? FileManager.default.moveItem(atPath: logPath, toPath: "\(logPath).1")

        // Recreate log file
        setupLogFile()
    }
}

// Global logger instance
public var logger: Logger?
