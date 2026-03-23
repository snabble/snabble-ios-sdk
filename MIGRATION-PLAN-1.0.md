# SDK 1.0 Migration Plan
## From Monolithic UI Package to Feature-Based Architecture

**Version:** 0.73.2 → 1.0.0  
**Date:** March 2026  
**Status:** 🚧 Ready for Execution

---

## Executive Summary

This migration restructures the SnabbleSDK from a monolithic `SnabbleUI` package into modular, feature-based packages. The goal is a clean, Swift 6.2-compliant, SwiftUI-first SDK for version 1.0.

**Key Changes:**
- ✅ Remove deprecated UIKit ViewControllers
- ✅ Delete legacy Example/Snabble app
- ✅ Split `SnabbleUI` into feature packages
- ✅ Extract `DynamicView` to separate package
- ✅ Remove Pulley dependency
- ✅ Update SwiftySnabble example app

---

## Prerequisites

### Before Starting

```bash
# 1. Ensure you're working in the SDK repository
cd /path/to/snabble-ios-sdk

# 2. Create a new branch
git checkout -b feature/sdk-1.0-restructure

# 3. Commit current state
git add .
git commit -m "Checkpoint before 1.0 restructure"

# 4. Open SDK as standalone project
open Package.swift  # Opens in Xcode
```

### Backup Strategy
```bash
# Create backup of current state
cd ..
cp -R snabble-ios-sdk snabble-ios-sdk-backup-pre-1.0
```

---

## Phase 1: Cleanup (✅ Completed)

### 1.1 Delete Legacy Sample App
```bash
# Already removed via XcodeRM
# Example/Snabble/ → DELETED
```

### 1.2 Delete Deprecated UIKit ViewControllers
```bash
# Already removed:
# - UI/Sources/Receipts/ReceiptsDetailViewController.swift
# - UI/Sources/Receipts/ReceiptsListViewController.swift  
# - UI/Sources/Checkout/InflightCheckoutContinuationViewController.swift
# - UI/Sources/Checkout/CheckoutStepsViewController.swift
```

**Status:** ✅ Phase 1 Complete

---

## Phase 2: Create Feature Package Structure

### 2.1 Create Directories

Run this script to create all feature package directories:

```bash
#!/bin/bash
# Run from SDK root directory

echo "📁 Creating feature package directories..."

mkdir -p PaymentMethods/Sources
mkdir -p Receipts/Sources  
mkdir -p Coupons/Sources
mkdir -p ShoppingCart/Sources
mkdir -p ShopFinder/Sources
mkdir -p DynamicView/Sources

echo "✅ Directories created"
ls -d */Sources
```

### 2.2 Move Files to Feature Packages

**IMPORTANT:** Use `git mv` to preserve history!

```bash
#!/bin/bash
# Move PaymentMethods
git mv UI/Sources/PaymentMethods/* PaymentMethods/Sources/

# Move Receipts  
git mv UI/Sources/Receipts/* Receipts/Sources/

# Move Coupons
git mv UI/Sources/Coupons/* Coupons/Sources/

# Move ShoppingCart
git mv UI/Sources/ShoppingCart/* ShoppingCart/Sources/

# Move ShopFinder
git mv UI/Sources/ShopFinder/* ShopFinder/Sources/

# Move DynamicView
git mv UI/Sources/DynamicView/* DynamicView/Sources/

echo "✅ Files moved with git history preserved"
```

### 2.3 Verify Structure

```bash
# Check that files moved correctly
ls -R PaymentMethods/Sources | head -20
ls -R Receipts/Sources
ls -R Coupons/Sources  
ls -R ShoppingCart/Sources
ls -R ShopFinder/Sources
ls -R DynamicView/Sources
```

**Expected Result:**
```
PaymentMethods/Sources/
├── Models/
│   └── PaymentMethodListManager.swift
├── SwiftUI/
│   ├── List/
│   ├── Edit/
│   └── Display/
├── UIKit/  (will be deprecated)
└── Extensions/

Receipts/Sources/
├── Models/
│   └── PurchasesViewModel.swift
└── Views/
    ├── ReceiptsListScreen.swift
    └── ReceiptDetailScreen.swift

... etc
```

---

## Phase 3: Update Package.swift

### 3.1 Backup Current Package.swift
```bash
cp Package.swift Package.swift.backup-0.73.2
```

### 3.2 Replace with New Structure

See `Package-1.0.swift` (created separately) for complete new version.

**Key Changes:**

1. **Remove Pulley dependency:**
```swift
// DELETE this line:
.package(url: "https://github.com/snabble/Pulley.git", from: "2.9.2"),
```

2. **Add new feature products:**
```swift
products: [
    // Complete SDK (convenience)
    .library(name: "Snabble", targets: [
        "SnabbleCore",
        "SnabblePaymentMethods",
        "SnabbleReceipts", 
        "SnabbleCoupons",
        "SnabbleShoppingCart",
        "SnabbleShopFinder",
        "SnabbleScanAndGo",
        "SnabbleUser",
        "SnabblePhoneAuth"
    ]),
    
    // Feature packages (granular)
    .library(name: "SnabblePaymentMethods", targets: ["SnabblePaymentMethods"]),
    .library(name: "SnabbleReceipts", targets: ["SnabbleReceipts"]),
    .library(name: "SnabbleCoupons", targets: ["SnabbleCoupons"]),
    .library(name: "SnabbleShoppingCart", targets: ["SnabbleShoppingCart"]),
    .library(name: "SnabbleShopFinder", targets: ["SnabbleShopFinder"]),
    
    // Deprecated (separate package, optional)
    .library(name: "SnabbleDynamicView", targets: ["SnabbleDynamicView"]),
]
```

3. **Add new targets:**
```swift
targets: [
    // Feature Modules
    .target(
        name: "SnabblePaymentMethods",
        dependencies: [
            "SnabbleCore",
            "SnabbleComponents",
            "SDCAlertView",  // For some legacy payment UIs
            "DeviceKit"
        ],
        path: "PaymentMethods/Sources",
        resources: [.process("Resources")],
        swiftSettings: [.swiftLanguageMode(.v6)]
    ),
    
    .target(
        name: "SnabbleReceipts",
        dependencies: ["SnabbleCore", "SnabbleComponents"],
        path: "Receipts/Sources",
        swiftSettings: [.swiftLanguageMode(.v6)]
    ),
    
    .target(
        name: "SnabbleCoupons",
        dependencies: ["SnabbleCore", "SnabbleComponents"],
        path: "Coupons/Sources",
        swiftSettings: [.swiftLanguageMode(.v6)]
    ),
    
    .target(
        name: "SnabbleShoppingCart",
        dependencies: ["SnabbleCore", "SnabbleComponents"],
        path: "ShoppingCart/Sources",
        swiftSettings: [.swiftLanguageMode(.v6)]
    ),
    
    .target(
        name: "SnabbleShopFinder",
        dependencies: ["SnabbleCore", "SnabbleComponents"],
        path: "ShopFinder/Sources",
        swiftSettings: [.swiftLanguageMode(.v6)]
    ),
    
    .target(
        name: "SnabbleDynamicView",
        dependencies: ["SnabbleCore", "SnabbleComponents"],
        path: "DynamicView/Sources",
        swiftSettings: [.swiftLanguageMode(.v6)]
    ),
]
```

4. **Remove SnabbleUI target completely** (it's now split into features)

### 3.3 Update SnabbleScanAndGo Dependencies

```swift
.target(
    name: "SnabbleScanAndGo",
    dependencies: [
        "SnabbleCore",
        "SnabbleAssetProviding",
        "SnabbleShoppingCart",  // Changed from SnabbleUI
        "SnabblePaymentMethods", // Add explicit dependency
    ],
    path: "ScanAndGo",
    swiftSettings: [.swiftLanguageMode(.v6)]
),
```

---

## Phase 4: Fix Remaining UI Module References

Some files still reference the old `SnabbleUI`. We need to keep a minimal `SnabbleUI` target temporarily for:

1. **Payment ViewControllers** (still UIKit, use third-party SDKs)
   - `Payment/ApplePay/ApplePayCheckoutViewController.swift`
   - `Payment/QRCheckoutViewController.swift`
   - `Payment/CustomerCardCheckoutViewController.swift`
   - `Payment/EmbeddedCodesCheckoutViewController.swift`
   - `Payment/PaymentProcess.swift`

2. **Other utilities** not yet moved

### Option A: Keep Minimal SnabbleUI (Recommended for 1.0)

```swift
.target(
    name: "SnabbleUI",
    dependencies: [
        "SnabbleCore",
        "SnabblePaymentMethods",
        "SnabbleShoppingCart",
        "SDCAlertView",
        "DeviceKit",
        "SnabbleComponents",
        "CameraZoomWheel"
    ],
    path: "UI/Sources",
    resources: [.process("Resources")],
    swiftSettings: [.swiftLanguageMode(.v6)]
),
```

**Remaining in UI/Sources after moves:**
- `Payment/` (UIKit checkout VCs)
- `Barcode/` (utilities)
- `EAN/` (utilities)
- `Utilities/` (helpers)
- `Login/` (if not moved to User)
- `Onboarding/` (if still needed)

### Option B: Move Everything Now (More Work)

Move all remaining UI files to appropriate packages or delete if obsolete.

**Recommendation:** Use Option A for 1.0, plan Option B for 1.1/2.0.

---

## Phase 5: Update Import Statements

After restructuring, some files will have broken imports.

### 5.1 Find Files Needing Updates

```bash
# Find all Swift files importing SnabbleUI
grep -r "import SnabbleUI" --include="*.swift" . | grep -v ".build"
```

### 5.2 Update Imports Based on Usage

**Example migrations:**

```swift
// OLD
import SnabbleUI

// NEW - depending on what's used:
import SnabblePaymentMethods  // For PaymentMethodListView
import SnabbleReceipts        // For ReceiptsListScreen
import SnabbleCoupons         // For CouponsView
import SnabbleShoppingCart    // For ShoppingCartView
import SnabbleShopFinder      // For ShopListView
```

### 5.3 Update ScanAndGo Imports

```swift
// In ScanAndGo/Shopping/Models/Shopper.swift
// OLD
import SnabbleUI

// NEW
import SnabbleShoppingCart
import SnabblePaymentMethods
```

---

## Phase 6: Update SwiftySnabble Example App

### 6.1 Update Package Dependencies

In `Example/SwiftySnabble/Package.swift` (if exists) or Xcode project:

```swift
// OLD
.product(name: "SnabbleUI", package: "snabble-ios-sdk")

// NEW - use granular imports
.product(name: "SnabbleScanAndGo", package: "snabble-ios-sdk"),
.product(name: "SnabblePaymentMethods", package: "snabble-ios-sdk"),
.product(name: "SnabbleReceipts", package: "snabble-ios-sdk"),
// ... etc
```

### 6.2 Update Imports in SwiftySnabble

```swift
// In SwiftySnabble source files
// OLD
import SnabbleUI

// NEW
import SnabbleScanAndGo
import SnabblePaymentMethods
import SnabbleReceipts
```

---

## Phase 7: Build & Test

### 7.1 Build SDK Package

```bash
# Clean build
rm -rf .build

# Build all products
swift build

# Or in Xcode: Cmd+B
```

**Expected Issues:**
- Import errors → Fix with Phase 5
- Missing symbols → Check target dependencies
- Resource not found → Verify Resources in Package.swift

### 7.2 Build SwiftySnabble Example

```bash
cd Example/SwiftySnabble
open SwiftySnabble.xcodeproj

# In Xcode: Product → Clean Build Folder
# Then: Product → Build
```

### 7.3 Run Tests

```bash
swift test
```

---

## Phase 8: Update Documentation

### 8.1 Update README.md

Add new installation instructions:

```markdown
## Installation (SDK 1.0+)

### Complete SDK
```swift
dependencies: [
    .package(url: "https://github.com/snabble/snabble-ios-sdk", from: "1.0.0")
]

.target(
    name: "MyApp",
    dependencies: [
        .product(name: "Snabble", package: "snabble-ios-sdk")
    ]
)
```

### Modular (Only Features You Need)
```swift
.target(
    name: "MyApp",
    dependencies: [
        .product(name: "SnabbleCore", package: "snabble-ios-sdk"),
        .product(name: "SnabbleScanAndGo", package: "snabble-ios-sdk"),
        .product(name: "SnabblePaymentMethods", package: "snabble-ios-sdk")
    ]
)
```
```

### 8.2 Update CHANGELOG.md

```markdown
## [1.0.0] - 2026-03-XX

### 🎉 Breaking Changes - SDK 1.0

#### Restructured to Feature Packages
- **BREAKING:** `SnabbleUI` split into feature-based packages
  - `SnabblePaymentMethods` - Payment method management
  - `SnabbleReceipts` - Receipt viewing
  - `SnabbleCoupons` - Coupon management
  - `SnabbleShoppingCart` - Shopping cart UI
  - `SnabbleShopFinder` - Shop search & details
  
#### Removed Deprecated APIs
- **BREAKING:** Removed UIKit ViewControllers
  - `ReceiptsDetailViewController` → Use `ReceiptDetailScreen` (SwiftUI)
  - `ReceiptsListViewController` → Use `ReceiptsListScreen` (SwiftUI)
  - `InflightCheckoutContinuationViewController` → Use ScanAndGo checkout
  
#### Removed Dependencies
- **BREAKING:** Removed Pulley dependency (legacy scanner removed)

#### Migration Guide
See `MIGRATION-PLAN-1.0.md` for detailed migration instructions.

### Requirements
- iOS 17.0+
- Swift 6.2+
- Xcode 16.0+
```

### 8.3 Create Migration Guide for Apps

Create `MIGRATION-FROM-0.73.md`:

```markdown
# Migrating from SDK 0.73 to 1.0

## Import Changes

### Before (0.73)
```swift
import SnabbleUI

let receipts = ReceiptsListScreen()
let payment = PaymentMethodListView()
```

### After (1.0)
```swift
import SnabbleReceipts
import SnabblePaymentMethods

let receipts = ReceiptsListScreen()
let payment = PaymentMethodListView()
```

## Deprecated APIs Removed

### Receipts
- ❌ `ReceiptsDetailViewController` 
- ✅ Use `ReceiptDetailScreen` instead

### Scanner
- ❌ `ScannerViewController` 
- ✅ Use `ShopperView` from `SnabbleScanAndGo` instead
```

---

## Phase 9: Git Workflow

### 9.1 Review Changes

```bash
git status
git diff Package.swift
```

### 9.2 Commit Restructure

```bash
# Stage new package structure
git add PaymentMethods/ Receipts/ Coupons/ ShoppingCart/ ShopFinder/ DynamicView/

# Stage Package.swift changes
git add Package.swift

# Stage deleted files
git add -u

# Commit
git commit -m "Restructure SDK to feature-based packages for v1.0

BREAKING CHANGES:
- Split SnabbleUI into feature packages
- Remove deprecated UIKit ViewControllers  
- Remove Pulley dependency
- Remove Example/Snabble legacy app

New packages:
- SnabblePaymentMethods
- SnabbleReceipts
- SnabbleCoupons
- SnabbleShoppingCart
- SnabbleShopFinder
- SnabbleDynamicView (deprecated)

See MIGRATION-PLAN-1.0.md for details."
```

### 9.3 Tag Version

```bash
git tag -a v1.0.0 -m "SDK 1.0 - Feature-based packages, SwiftUI-first, Swift 6.2"
git push origin feature/sdk-1.0-restructure
git push origin v1.0.0
```

---

## Phase 10: Update teo App

### 10.1 Update SDK Reference

In teo app:

```bash
cd /Users/ut/Projects/teo-ios

# Update submodule (if using git submodule)
cd snabble-ios-sdk
git pull origin main
cd ..

# Or in Xcode: File → Packages → Update to Latest Package Versions
```

### 10.2 Update Imports in teo

```swift
// In teo/Sources/**/*.swift
// Update imports as needed (likely already using modular imports)
```

### 10.3 Build & Test teo

```bash
# In Xcode
# Product → Clean Build Folder
# Product → Build
# Product → Test
```

---

## Rollback Plan

If issues occur:

```bash
# Restore from backup
rm -rf snabble-ios-sdk
mv snabble-ios-sdk-backup-pre-1.0 snabble-ios-sdk

# Or git reset
git reset --hard HEAD~1
git tag -d v1.0.0
```

---

## Success Criteria

- ✅ SDK builds without errors
- ✅ All tests pass
- ✅ SwiftySnabble example app builds and runs
- ✅ teo app builds and runs
- ✅ No Pulley dependency
- ✅ All feature packages accessible independently
- ✅ Documentation updated

---

## Post-Migration Tasks

### Optional Cleanup (Future 1.x/2.0)

1. **Extract DynamicView to separate repo** (if not used by any active apps)
2. **Migrate remaining UIKit Payment VCs to SwiftUI** (big task)
3. **Remove SnabbleUI target completely** (after all migrations)
4. **Add feature package tests** (PaymentMethodsTests, ReceiptsTests, etc.)

---

## Timeline Estimate

- **Phase 1-2:** 30 minutes (directory setup, file moves)
- **Phase 3:** 1 hour (Package.swift rewrite)
- **Phase 4-5:** 2 hours (import fixes, compilation)
- **Phase 6:** 1 hour (SwiftySnabble updates)
- **Phase 7:** 2 hours (build, test, debug)
- **Phase 8-9:** 1 hour (docs, git)
- **Phase 10:** 1 hour (teo app update)

**Total:** ~8-10 hours

---

## Contact & Support

For issues during migration:
- Check `SDK-MODERNIZATION.md` for architecture details
- Review commit history for context
- Test incrementally after each phase

**Good luck! 🚀**
