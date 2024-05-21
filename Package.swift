// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Snabble",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "Snabble",
            targets: ["SnabbleAssetProviding", "SnabbleCore", "SnabbleUI"]
        ),
        .library(
            name: "SnabbleAssetProviding",
            targets: ["SnabbleAssetProviding"]
        ),
        .library(
            name: "SnabbleCore",
            targets: ["SnabbleCore"]
        ),
       .library(
            name: "SnabbleUI",
            targets: ["SnabbleAssetProviding", "SnabbleUI"]
        ),
        .library(
            name: "SnabbleDatatrans",
            targets: ["SnabbleDatatrans"]
        ),
        .library(
            name: "SnabbleNetwork",
            targets: ["SnabbleNetwork"]),
    ],
    dependencies: [
        .package(url: "https://github.com/lachlanbell/SwiftOTP", from: "3.0.2"),
        .package(url: "https://github.com/datatheorem/TrustKit.git", from: "3.0.4"),
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.2"),
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "6.27.0"),
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", .upToNextMajor(from: "0.9.19")),
        .package(url: "https://github.com/datatrans/ios-sdk.git", from: "3.6.3"),
        .package(url: "https://github.com/sberrevoets/SDCAlertView.git", from: "12.0.3"),
        .package(url: "https://github.com/devicekit/DeviceKit.git", from: "5.2.3"),
        .package(url: "https://github.com/snabble/Pulley.git", from: "2.9.2"),
        .package(url: "https://github.com/chrs1885/WCAG-Colors.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "SnabbleNetwork",
            dependencies: ["SwiftOTP"],
            path: "Network/Sources"
        ),
        .testTarget(
            name: "SnabbleNetworkTests",
            dependencies: ["SnabbleNetwork"],
            path: "Network/Tests",
            resources: [
                .process("Resources")
            ]
        ),
        .target(
            name: "SnabbleAssetProviding",
            dependencies: [
                "WCAG-Colors",
            ],
            path: "Sources/AssetProviding",
            resources: [
                .process("Resources")
            ]
        ),
        .target(
            name: "SnabbleCore",
            dependencies: [
                "TrustKit",
                "KeychainAccess",
                "SwiftOTP",
                .product(name: "GRDB", package: "GRDB.swift"),
                "ZIPFoundation",
            ],
            path: "Sources/Core",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "SnabbleCoreTests",
            dependencies: [
                "SnabbleCore"
            ],
            path: "Tests/Core",
            resources: [
                .process("Resources")
            ]
        ),
        .target(
            name: "SnabbleUI",
            dependencies: [
                "SnabbleCore",
                "SDCAlertView",
                "DeviceKit",
                "Pulley",
                "WCAG-Colors",
            ],
            path: "Sources/UI",
            resources: [
                .process("Resources")
            ]
        ),
        .target(
            name: "SnabbleDatatrans",
            dependencies: [
                "SnabbleCore",
                "SnabbleUI",
                .product(name: "Datatrans", package: "ios-sdk"),
            ],
            path: "Sources/Datatrans"
        )
    ]
)
