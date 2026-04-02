// swift-tools-version: 5.9
// Swift Package Manager build + test configuration

import PackageDescription

let package = Package(
    name: "EyeBreak",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .target(
            name: "FarawayCore",
            path: "Faraway",
            exclude: ["FarawayApp.swift"],
            resources: [
                .process("Assets.xcassets")
            ]
        ),
        .testTarget(
            name: "FarawayTests",
            dependencies: ["FarawayCore"],
            path: "Tests"
        )
    ]
)
