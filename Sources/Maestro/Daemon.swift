import Foundation
import MaestroCore
import Dispatch

// Global daemon instance for signal handlers
private var globalDaemon: Daemon?

/// Maestro Daemon - Long-running background process
/// Handles process lifecycle and graceful shutdown
public final class Daemon {
    private var server: MaestroMCPServer?
    private var isRunning = false
    private var shutdownContinuation: CheckedContinuation<Void, Never>?
    private let config: Configuration

    public init(config: Configuration? = nil) throws {
        self.config = try config ?? Configuration.load()
        globalDaemon = self

        // Setup logging
        let logLevel: Logger.Level = switch self.config.logLevel {
        case .debug: .debug
        case .info: .info
        case .warning: .warning
        case .error: .error
        }

        logger = Logger(
            path: self.config.logPath,
            maxSizeMB: self.config.logRotationSizeMB,
            minLevel: logLevel
        )
    }

    /// Start the daemon process
    public func start() async throws {
        logger?.info("Starting Maestro daemon")
        logger?.info("Configuration loaded: log=\(config.logPath), db=\(config.databasePath)")

        // Set up signal handlers before starting server
        setupSignalHandlers()
        logger?.info("Signal handlers registered")

        // Create and start MCP server (this initializes database and runs migrations)
        logger?.info("Initializing database at: \(config.databasePath)")
        server = try MaestroMCPServer(databasePath: config.databasePath)
        logger?.info("Database initialized and migrations completed")
        isRunning = true

        logger?.info("Starting MCP server")
        // Start server in background task
        _Concurrency.Task {
            do {
                try await server!.start()
            } catch {
                logger?.error("MCP server error: \(error)")
                await shutdown()
            }
        }

        logger?.info("Maestro daemon running")
        // Wait for shutdown signal
        await withCheckedContinuation { continuation in
            shutdownContinuation = continuation
        }
    }

    /// Gracefully shutdown the daemon
    private func shutdown() async {
        guard isRunning else { return }
        isRunning = false

        logger?.info("Shutting down Maestro daemon")

        // Clean up server resources
        server = nil

        // Signal shutdown complete
        shutdownContinuation?.resume()
        shutdownContinuation = nil
    }

    /// Set up signal handlers for graceful shutdown
    private func setupSignalHandlers() {
        // Handle SIGTERM (kill command)
        signal(SIGTERM) { _ in
            _Concurrency.Task {
                await globalDaemon?.shutdown()
            }
        }

        // Handle SIGINT (Ctrl+C)
        signal(SIGINT) { _ in
            _Concurrency.Task {
                await globalDaemon?.shutdown()
            }
        }

        // Ignore SIGPIPE (broken pipe)
        signal(SIGPIPE, SIG_IGN)
    }
}
