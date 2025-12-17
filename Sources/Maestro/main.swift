import Foundation
import MaestroCore
import _Concurrency

/// Maestro Daemon Entry Point
/// Starts the MCP server with stdio transport

fputs("Maestro daemon starting...\n", stderr)

// Start MCP server in async context
_Concurrency.Task {
    do {
        let server = try MaestroMCPServer()
        fputs("MCP server initialized\n", stderr)
        try await server.start()
    } catch {
        fputs("Error: \(error.localizedDescription)\n", stderr)
        exit(1)
    }
}

// Keep main thread alive while server runs
RunLoop.main.run()
