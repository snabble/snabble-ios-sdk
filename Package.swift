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
            name: "SnabblePay",
            targets: ["SnabblePay"]
        ),
        .library(
            name: "SnabbleNetwork",
            targets: ["SnabbleNetwork"]
        ),
        .library(
            name: "SnabblePhoneAuth",
            targets: ["SnabblePhoneAuth"]
        ),
        .library(
            name: "SnabblePhoneAuthUI",
            targets: ["SnabblePhoneAuthUI"]
        ),
        .library(name: "SnabbleUser",
                 targets: ["SnabbleUser"])
    ],
    dependencies: [
        .package(url: "https://github.com/lachlanbell/SwiftOTP", from: "3.0.2"),
        .package(url: "https://github.com/datatheorem/TrustKit.git", from: "3.0.4"),
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.2"),
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "6.27.0"),
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", .upToNextMajor(from: "0.9.19")),
        .package(url: "https://github.com/datatrans/ios-sdk.git", from: "3.6.3"),
        .package(url: "https://github.com/sberrevoets/SDCAlertView.git", from: "12.0.3"),
        .package(url: "https://github.com/devicekit/DeviceKit.git", from: "5.3.0"),
        .package(url: "https://github.com/snabble/Pulley.git", from: "2.9.2"),
        .package(url: "https://github.com/chrs1885/WCAG-Colors.git", from: "1.0.0"),
        .package(url: "https://github.com/pointfreeco/swift-tagged", from: "0.10.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.3")
    ],
    targets: [
        .target(
            name: "SnabbleNetwork",
            dependencies: ["SwiftOTP", "SnabbleUser"],
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
            path: "AssetProviding/Sources",
            resources: [
                .process("Resources")
            ]
        ),
        .target(
            name: "SnabbleCore",
            dependencies: [
                "TrustKit",
                "SwiftOTP",
                .product(name: "GRDB", package: "GRDB.swift"),
                "ZIPFoundation",
                "SnabbleUser",
            ],
            path: "Core/Sources",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "SnabbleCoreTests",
            dependencies: [
                "SnabbleCore"
            ],
            path: "Core/Tests",
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
                "SnabbleUser"
            ],
            path: "UI/Sources",
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
        ),
        .target(
            name: "SnabbleLogger",
            dependencies: [
                .product(name: "Logging", package: "swift-log"),
            ],
            path: "Pay/Sources/Logger"
        ),
        .target(
            name: "SnabblePayNetwork",
            dependencies: [
                "SnabbleLogger",
            ],
            path: "Pay/Sources/Network"
        ),
        .target(
            name: "SnabblePay",
            dependencies: [
                .product(name: "Tagged", package: "swift-tagged"),
                "SnabblePayNetwork",
                "SnabbleLogger",
            ],
            path: "Pay/Sources/Core"
        ),
        .target(
            name: "TestHelper",
            dependencies: [],
            path: "Pay/Tests/Helper"
        ),
        .testTarget(
            name: "SnabblePayCoreTests",
            dependencies: [
                "SnabblePay",
                "TestHelper"
            ],
            path: "Pay/Tests/Core",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "SnabblePayNetworkTests",
            dependencies: [
                "SnabblePayNetwork",
                "TestHelper",
            ],
            path: "Pay/Tests/Network",
            resources: [
                .process("Resources")
            ]
        ),
        .target(
            name: "SnabblePhoneAuth",
            dependencies: [
                "SnabbleNetwork",
                "SnabbleUser"
            ],
            path: "PhoneAuth/Sources",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "SnabblePhoneAuthTests",
            dependencies: ["SnabblePhoneAuth"],
            path: "PhoneAuth/Tests",
            resources: [
                .process("Resources")
            ]
        ),
        .target(
            name: "SnabblePhoneAuthUI",
            dependencies: [
                "SnabblePhoneAuth",
            ],
            path: "PhoneAuthUI/Sources"
        ),
        .testTarget(
            name: "SnabblePhoneAuthUITests",
            dependencies: [
                "SnabblePhoneAuthUI",
            ],
            path: "PhoneAuthUI/Tests"
        ),
        .target(
            name: "SnabbleUser",
            dependencies: ["KeychainAccess"],
            path: "User/Sources"
        )
    ]
)
