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
        // SQLite wrapper for Swift
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.15.0"),
    ],
    targets: [
        // Core library - database, data models, business logic
        .target(
            name: "MaestroCore",
            dependencies: [
                .product(name: "SQLite", package: "SQLite.swift")
            ]
        ),

        // Executable - daemon, MCP server, menu bar app
        .executableTarget(
            name: "Maestro",
            dependencies: ["MaestroCore"]
        ),

        // Tests
        .testTarget(
            name: "MaestroCoreTests",
            dependencies: ["MaestroCore"]
        )
    ]
)
