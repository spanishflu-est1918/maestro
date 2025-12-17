import Foundation
import _Concurrency

/// Maestro Daemon Entry Point
/// Starts the daemon with signal handling and graceful shutdown

_Concurrency.Task {
    do {
        let daemon = try Daemon()
        try await daemon.start()
    } catch {
        fputs("Failed to start daemon: \(error)\n", stderr)
        exit(1)
    }
}

RunLoop.main.run()
