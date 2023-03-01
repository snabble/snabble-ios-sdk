// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Snabble",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "Snabble",
            targets: ["SnabbleCore", "SnabbleUI"]
        ),
        .library(
            name: "SnabbleCore",
            targets: ["SnabbleCore"]
        ),
        .library(
            name: "SnabbleUI",
            targets: ["SnabbleUI"]
        ),
        .library(
            name: "SnabbleDatatrans",
            targets: ["SnabbleDatatrans"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/snabble/OneTimePassword.git", from: "3.2.1"),
        .package(url: "https://github.com/datatheorem/TrustKit.git", from: "2.0.1"),
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.2"),
        .package(url: "https://github.com/mattrubin/Base32.git", from: "1.2.0"),
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "6.8.0"),
        .package(url: "https://github.com/marmelroy/Zip.git", from: "2.1.2"),
        .package(url: "https://github.com/datatrans/ios-sdk.git", from: "2.6.0"),
        .package(url: "https://github.com/sberrevoets/SDCAlertView.git", from: "12.0.3"),
        .package(url: "https://github.com/devicekit/DeviceKit.git", from: "5.0.0"),
        .package(url: "https://github.com/52inc/Pulley.git", from: "2.9.1"),
        .package(url: "https://github.com/chrs1885/WCAG-Colors.git", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "SnabbleCore",
            dependencies: [
                "TrustKit",
                "KeychainAccess",
                "Base32",
                "OneTimePassword",
                .product(name: "GRDB", package: "GRDB.swift"),
                "Zip",
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
