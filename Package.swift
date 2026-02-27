// swift-tools-version: 5.9
// This is an alternative build method using Swift Package Manager

import PackageDescription

let package = Package(
    name: "EyeBreak",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "EyeBreak",
            path: "EyeBreak",
            resources: [
                .process("Assets.xcassets")
            ]
        )
    ]
)
