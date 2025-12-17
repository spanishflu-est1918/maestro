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
        .library(name: "MaestroCore", targets: ["MaestroCore"])
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

        // Executable - daemon, MCP server, menu bar app
        .executableTarget(
            name: "Maestro",
            dependencies: [
                "MaestroCore",
                .product(name: "MCP", package: "swift-sdk")
            ]
        ),

        // Tests
        .testTarget(
            name: "MaestroCoreTests",
            dependencies: ["MaestroCore"]
        )
    ]
)
