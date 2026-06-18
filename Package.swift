// swift-tools-version: 5.9
// Swift Package Manager build + test configuration

import PackageDescription

let package = Package(
    name: "EyeBreak",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .target(
            name: "FarawayCore",
            path: "Faraway",
            exclude: ["FarawayApp.swift", "Info.plist", "Faraway.entitlements", "png"],
            resources: [
                .process("Assets.xcassets"),
                .process("en.lproj"),
                .process("zh-Hans.lproj")
            ]
        ),
        .testTarget(
            name: "FarawayTests",
            dependencies: ["FarawayCore"],
            path: "Tests"
        )
    ]
)
