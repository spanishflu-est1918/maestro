import Foundation
import MaestroCore
import _Concurrency

/// Maestro Daemon Entry Point
/// Starts the MCP server with stdio transport

// Keep strong reference to prevent deallocation
var maestroServer: MaestroMCPServer?

// Start MCP server in async context
_Concurrency.Task {
    do {
        maestroServer = try MaestroMCPServer()
        try await maestroServer!.start()
    } catch {
        exit(1)
    }
}

// Keep main thread alive while server runs
RunLoop.main.run()
