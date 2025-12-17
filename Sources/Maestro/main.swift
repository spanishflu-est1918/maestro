import Foundation
import MaestroCore
import _Concurrency

/// Maestro Daemon Entry Point
/// Starts the MCP server with stdio transport

// Start MCP server in async context
_Concurrency.Task {
    do {
        let server = try MaestroMCPServer()
        try await server.start()
    } catch {
        exit(1)
    }
}

// Keep main thread alive while server runs
RunLoop.main.run()
