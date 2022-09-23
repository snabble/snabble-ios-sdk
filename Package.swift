// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SnabbleSDK",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "SnabbleSDK",
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
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/datatheorem/TrustKit.git", from: "2.0.1"),
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.2"),
        .package(url: "https://github.com/mattrubin/Base32.git", branch: "1.1.2+spm"),
        .package(url: "https://github.com/mattrubin/OneTimePassword.git", branch: "develop"),
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "6.0.0"),
        .package(url: "https://github.com/marmelroy/Zip.git", from: "2.1.2"),
        .package(url: "https://github.com/datatrans/ios-sdk.git", from: "2.2.0"),
        .package(url: "https://github.com/snabble/AutoLayout-Helper.git", branch: "main"),
        .package(url: "https://github.com/sberrevoets/SDCAlertView.git", branch: "master"),
        .package(url: "https://github.com/devicekit/DeviceKit.git", from: "4.7.0"),
        .package(url: "https://github.com/52inc/Pulley.git", branch: "master"),
        .package(url: "https://github.com/chrs1885/WCAG-Colors.git", from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
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
            path: "Core",
            resources: [
                .process("Resources")
            ]
        ),
        .target(
            name: "SnabbleUI",
            dependencies: [
                "SnabbleCore",
                "AutoLayout-Helper",
                "SDCAlertView",
                "DeviceKit",
                "Pulley",
                "WCAG-Colors",
            ],
            path: "UI",
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
            path: "Datatrans/Sources"
        )
    ]
)
