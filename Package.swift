// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Zonly",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/soffes/HotKey", from: "0.2.0"),
        .package(url: "https://github.com/sindresorhus/LaunchAtLogin-Modern", from: "1.0.0")
    ],
    targets: [
        .executableTarget(
            name: "Zonly",
            dependencies: [
                "HotKey",
                .product(name: "LaunchAtLogin", package: "LaunchAtLogin-Modern")
            ],
            path: "Sources",
            resources: [
                .process("Resources")
            ],
            swiftSettings: [
                .unsafeFlags(["-parse-as-library"])
            ]
        )
    ]
)

