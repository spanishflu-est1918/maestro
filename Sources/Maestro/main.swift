import Foundation
import _Concurrency

/// Maestro Entry Point
/// Routes commands to appropriate handlers

let args = CommandLine.arguments.dropFirst() // Skip program name
let command = args.first ?? "daemon"

// Load config for database path
let config: Configuration
do {
    config = try Configuration.load()
} catch {
    fputs("Failed to load configuration: \(error)\n", stderr)
    exit(1)
}

switch command {
case "daemon":
    // Start the daemon (original behavior)
    _Concurrency.Task {
        do {
            let daemon = try Daemon(config: config)
            try await daemon.start()
        } catch {
            fputs("Failed to start daemon: \(error)\n", stderr)
            exit(1)
        }
    }
    RunLoop.main.run()

case "sessions":
    do {
        let cli = try CLI(databasePath: config.databasePath)
        try cli.listSessions()
    } catch {
        fputs("Error: \(error)\n", stderr)
        exit(1)
    }

case "session":
    guard let sessionId = args.dropFirst().first else {
        fputs("Usage: maestrod session <session-id>\n", stderr)
        exit(1)
    }
    do {
        let cli = try CLI(databasePath: config.databasePath)
        try cli.showSession(id: sessionId)
    } catch {
        fputs("Error: \(error)\n", stderr)
        exit(1)
    }

case "resume":
    guard let sessionId = args.dropFirst().first else {
        fputs("Usage: maestrod resume <session-id>\n", stderr)
        exit(1)
    }
    do {
        let cli = try CLI(databasePath: config.databasePath)
        try cli.resumeSession(id: sessionId)
    } catch {
        fputs("Error: \(error)\n", stderr)
        exit(1)
    }

case "help", "--help", "-h":
    CLI.printUsage()

default:
    fputs("Unknown command: \(command)\n", stderr)
    CLI.printUsage()
    exit(1)
}
