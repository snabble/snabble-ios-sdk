// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Snabble",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        // Complete SDK (convenience)
        .library(
            name: "Snabble",
            targets: [
                // Layer 1 (Foundation)
                "SnabbleCore",
                "SnabbleNetwork",
                "SnabbleAssetProviding",
                // Layer 2 (UI Primitives)
                "SnabbleComponents",
                "SnabbleTheme",
                // Layer 3 (Domain Features):
                "SnabbleShops",
                "SnabbleCart",
                "SnabbleUser",
                "SnabbleReceipts",
                // Layer 4 (Payment):
                "SnabblePayment",
                // Layer 5 (Complete Flows)
                "SnabbleScanAndGo",
                "SnabblePhoneAuth",
                "SnabbleCoupons",
                "SnabbleOnboarding",
                "SnabbleTeaser",
            ]
        ),

        // Core modules
        .library(
            name: "SnabbleCore",
            targets: ["SnabbleCore"]
        ),
        .library(
            name: "SnabbleNetwork",
            targets: ["SnabbleNetwork"]
        ),
        .library(
            name: "SnabbleAssetProviding",
            targets: ["SnabbleAssetProviding"]
        ),
        .library(
            name: "SnabbleComponents",
            targets: ["SnabbleAssetProviding", "SnabbleComponents"]
        ),
        // Feature packages (modular - SDK 1.0)
        .library(
            name: "SnabbleTheme",
            targets: ["SnabbleCore", "SnabbleComponents", "SnabbleTheme"]
        ),
        .library(
            name: "SnabblePayment",
            targets: ["SnabbleTheme", "SnabblePayment"]
        ),
        .library(
            name: "SnabbleShops",
            targets: ["SnabbleShops"]
        ),
        .library(
            name: "SnabbleCart",
            targets: ["SnabbleCart", "SnabbleShops"]
        ),
        .library(
            name: "SnabbleUser",
            targets: ["SnabbleUser", "SnabbleAssetProviding"]
        ),
        .library(
            name: "SnabbleReceipts",
            targets: ["SnabbleTheme", "SnabbleReceipts"]
        ),
        .library(
            name: "SnabbleScanAndGo",
            targets: ["SnabbleScanAndGo"]
        ),
        .library(
            name: "SnabblePhoneAuth",
            targets: ["SnabblePhoneAuth"]
        ),
        .library(
            name: "SnabbleOnboarding",
            targets: ["SnabbleOnboarding"]
        ),
       .library(
            name: "SnabbleCoupons",
            targets: ["SnabbleCoupons"]
        ),
        .library(
             name: "SnabbleTeaser",
             targets: ["SnabbleTeaser"]
         ),

        // Other modules
        .library(
            name: "SnabbleDatatrans",
            targets: ["SnabblePayment", "SnabbleDatatrans"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/lachlanbell/SwiftOTP", from: "3.0.2"),
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.2"),
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "6.29.3"),
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", .upToNextMajor(from: "0.9.19")),
        .package(url: "https://github.com/datatrans/ios-sdk.git", from: "3.7.3"),
        .package(url: "https://github.com/devicekit/DeviceKit.git", from: "5.5.0"),
        .package(url: "https://github.com/chrs1885/WCAG-Colors.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.6.1"),
        .package(url: "https://github.com/divadretlaw/WindowKit", from: "2.5.2"),
        .package(url: "https://github.com/utilem/CameraZoomWheel.git", from: "2.0.0")
    ],
    targets: [
        .target(
            name: "SnabbleNetwork",
            dependencies: ["SwiftOTP", "KeychainAccess"],
            path: "Network/Sources",
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
            ],
        ),
        .target(
            name: "SnabbleCore",
            dependencies: [
                "SwiftOTP",
                .product(name: "GRDB", package: "GRDB.swift"),
                "ZIPFoundation",
                "SnabbleNetwork"
            ],
            path: "Core/Sources",
            resources: [
                .process("Resources")
            ],
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
            name: "SnabbleComponents",
            dependencies: [
                "SnabbleAssetProviding",
                "WindowKit"
            ],
            path: "Components/Sources",
        ),
        .target(
            name: "SnabbleTheme",
            dependencies: [
                "SnabbleCore",
                "SnabbleComponents",
                "SnabbleAssetProviding",
                "KeychainAccess",
            ],
            path: "Theme/Sources",
            resources: [
                .process("Resources")
            ],
        ),
        // Feature Modules (minimal for SDK 1.0 - only pure SwiftUI without SnabbleCI)
        .target(
            name: "SnabblePayment",
            dependencies: [
                "SnabbleCore",
                "SnabbleComponents",
                "SnabbleTheme",
                "SnabbleCart",
                "SnabbleReceipts",
                "SnabbleAssetProviding",
                "SnabbleUser",
                "DeviceKit",
            ],
            path: "Payment/Sources",
            resources: [
                .process("Resources")
            ],
        ),
        .target(
            name: "SnabbleShops",
            dependencies: [
                "SnabbleCore",
                "SnabbleTheme"
            ],
            path: "Shops/Sources",
        ),
        .target(
            name: "SnabbleCart",
            dependencies: [
                "SnabbleCore",
                "SnabbleShops",
                "SnabbleTheme"
           ],
            path: "Cart/Sources",
        ),
        .target(
            name: "SnabbleReceipts",
            dependencies: [
                "SnabbleCore",
                "SnabbleComponents",
                "SnabbleTheme"
            ],
            path: "Receipts/Sources",
        ),
        .target(
            name: "SnabbleCoupons",
            dependencies: [
                "SnabbleCore",
                "SnabbleComponents"
            ],
            path: "Coupons/Sources",
        ),
        .target(
            name: "SnabbleTeaser",
            dependencies: [
                "SnabbleCore",
                "SnabbleComponents",
                "SnabbleTheme",
           ],
            path: "Teaser/Sources",
        ),
        .target(
            name: "SnabbleOnboarding",
            dependencies: [
                "SnabbleCore",
                "SnabbleTheme",
            ],
            path: "Onboarding/Sources",
        ),
        
        .target(
            name: "SnabbleDatatrans",
            dependencies: [
                "SnabbleCore",
                "SnabbleTheme",
                "SnabblePayment",
                .product(name: "Datatrans", package: "ios-sdk"),
            ],
            path: "Datatrans/Sources",
        ),
        .target(
            name: "SnabblePhoneAuth",
            dependencies: [
                "SnabbleNetwork",
                "SnabbleUser"
            ],
            path: "PhoneAuth/Sources",
        ),
        .testTarget(
            name: "SnabblePhoneAuthTests",
            dependencies: ["SnabblePhoneAuth"],
            path: "PhoneAuth/Tests"
        ),
        .target(
            name: "SnabbleUser",
            dependencies: [
                "SnabbleAssetProviding",
                "SnabbleNetwork",
                "SnabbleComponents",
                "SnabbleCore"
            ],
            path: "User/Sources",
        ),
        .target(
            name: "SnabbleScanAndGo",
            dependencies: [
                "SnabbleCore",
                "SnabbleAssetProviding",
                "SnabbleTheme",
                "SnabbleCart",
                "SnabblePayment",
                "SnabbleComponents",
                "CameraZoomWheel",
            ],
            path: "ScanAndGo",
        ),
    ]
)
