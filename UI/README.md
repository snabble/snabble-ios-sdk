# UI Module (Legacy)

**Status:** Deprecated / Utilities Only
**SDK Version:** 1.0.0 rc

## Overview

The `UI` module was the original UIKit-based UI layer of the Snabble SDK. Most of its functionality has been migrated to:

- **SnabbleComponents** (SwiftUI components)
- **SnabbleTheme** (Asset management)
- **SnabbleScanAndGo** (Complete scan-and-go flow)
- **SnabblePayment** (Payment UI)

## Remaining Files

The following UIKit utilities are still in use and **cannot be removed**:

### `Sources/Utilities/`

1. **UIButton+BackgroundColor.swift**
   - Extension for setting button background colors by state
   - Used in Payment module

2. **Lists+Register.swift**
   - `ReuseIdentifiable` protocol for type-safe cell registration
   - Used in Payment and other UIKit-based views
   - Extensions for `UITableView` and `UICollectionView`

3. **UIView+IndexPathInCollections.swift**
   - Utility for finding index paths in collection views

4. **UIStackView+Remove.swift**
   - Extension for removing arranged subviews

## Migration Plan

These utilities should eventually be:

1. **Option A:** Moved to a dedicated `SnabbleUIKitUtilities` module
2. **Option B:** Moved directly into the modules that use them (Payment, etc.)
3. **Option C:** Kept here until all UIKit code is migrated to SwiftUI

## Usage

These utilities are **not exposed** in Package.swift products. They are only available to internal SDK modules.

---

**Note:** This module is not listed in Package.swift and does not produce any library products. The files are used via direct file references in other modules.
