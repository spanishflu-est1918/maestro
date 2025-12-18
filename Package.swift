// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Maestro",
    platforms: [
        .macOS(.v13)  // Require macOS 13+ for modern APIs
    ],
    products: [
        .executable(name: "maestrod", targets: ["Maestro"]),
        .executable(name: "maestro-app", targets: ["MaestroApp"]),
        .executable(name: "testmcp", targets: ["TestMCP"]),
        .library(name: "MaestroCore", targets: ["MaestroCore"]),
        .library(name: "MaestroUI", targets: ["MaestroUI"])
    ],
    dependencies: [
        // GRDB - SQLite toolkit with migrations, type-safe queries
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "6.0.0"),
        // MCP - Model Context Protocol SDK for AI tool integration
        .package(url: "https://github.com/modelcontextprotocol/swift-sdk.git", from: "0.10.0"),
    ],
    targets: [
        // Core library - database, data models, business logic
        .target(
            name: "MaestroCore",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift")
            ]
        ),

        // UI library - AppKit components for menu bar app
        .target(
            name: "MaestroUI",
            dependencies: [
                "MaestroCore"
            ],
            resources: [
                .process("Resources")
            ]
        ),

        // Executable - daemon, MCP server, menu bar app
        .executableTarget(
            name: "Maestro",
            dependencies: [
                "MaestroCore",
                .product(name: "MCP", package: "swift-sdk")
            ]
        ),

        // Menu bar application
        .executableTarget(
            name: "MaestroApp",
            dependencies: [
                "MaestroUI"
            ]
        ),

        // Test MCP server - minimal example
        .executableTarget(
            name: "TestMCP",
            dependencies: [
                .product(name: "MCP", package: "swift-sdk")
            ]
        ),

        // Tests
        .testTarget(
            name: "MaestroCoreTests",
            dependencies: ["MaestroCore"]
        ),
        .testTarget(
            name: "MaestroTests",
            dependencies: [
                "Maestro",
                "MaestroCore",
                "MaestroUI",
                .product(name: "MCP", package: "swift-sdk")
            ]
        )
    ]
)
