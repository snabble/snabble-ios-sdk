# Circular Dependencies Analysis

**Created:** 2026-03-27
**Resolved:** 2026-03-27, Updated 2026-03-28
**SDK Version:** 1.0.0 rc
**Status:** ✅ RESOLVED

---

## Overview

The Snabble iOS SDK **had** two circular dependencies that violated the layered architecture principles. **Both have been successfully resolved**:

1. ✅ **SnabbleCore ↔ SnabbleComponents** (Layer 1 ↔ Layer 2) - **RESOLVED 2026-03-27**, **IMPROVED 2026-03-28**
2. ✅ **SnabbleCore ↔ SnabbleUser** (Layer 1 ↔ Layer 3) - **RESOLVED 2026-03-27**

Both dependencies originated from Core (Layer 1 - Foundation) depending on higher layers, which violated clean layered architecture.

**Update 2026-03-28:** Moved `Project+Trait.swift` from Components to Theme for better semantic fit, eliminating Components → Core dependency entirely.

---

## 1. Core → User Circular Dependency

### Current State

**File:** `Core/Sources/API/Snabble.swift:9`
```swift
import SnabbleUser
```

### Usage Analysis

The `import SnabbleUser` is used for:

1. **Protocol Conformance (Line 74):**
   ```swift
   extension Config: SnabbleUser.Configurable, SnabbleNetwork.Configurable {
       public var domainName: String {
           environment.name
       }
   }
   ```

2. **Static Property Access (Line 406):**
   ```swift
   public static var clientId: String {
       SnabbleUser.Client.id
   }
   ```

3. **AppUser Access (Lines 418-428):**
   ```swift
   public var appUser: AppUser? {
       get {
           AppUser.get(forConfig: config)
       }
       set {
           AppUser.set(newValue, forConfig: config)
           tokenRegistry.invalidate()
           OrderList.clearCache()
       }
   }
   ```

### Architecture Violation

- **SnabbleCore** (Layer 1: Foundation - Business Logic) depends on **SnabbleUser** (Layer 3: Domain Features)
- This creates a circular dependency because SnabbleUser depends on SnabbleNetwork (Layer 1)
- Violates the **Dependency Inversion Principle**: High-level modules should not depend on low-level modules

### Refactoring Options

#### Option A: Move User-Related Code to SnabbleUser ✅ Recommended
Move the `clientId` and `appUser` computed properties from `Snabble.swift` to `SnabbleUser` module:

```swift
// In SnabbleUser module
extension Snabble {
    public static var clientId: String {
        Client.id
    }

    public var appUser: AppUser? {
        get { AppUser.get(forConfig: config) }
        set {
            AppUser.set(newValue, forConfig: config)
            tokenRegistry.invalidate()
            OrderList.clearCache()
        }
    }
}
```

**Pros:**
- Clean separation of concerns
- No architectural changes needed
- User-related code stays in User module

**Cons:**
- Requires moving public API to a different module (minor breaking change)

#### Option B: Protocol-Based Abstraction
Create a `SnabbleProtocols` module (Layer 0) with shared protocols:

```swift
// New module: SnabbleProtocols
public protocol Configurable {
    var domainName: String { get }
}

public protocol UserProviding {
    var clientId: String { get }
    var appUser: AppUser? { get set }
}
```

**Pros:**
- Clean architecture with dependency inversion
- No circular dependencies

**Cons:**
- Adds complexity with an additional module
- More boilerplate code

#### Option C: Keep Current Implementation ⚠️ Not Recommended
Document the circular dependency and accept it as technical debt.

**Pros:**
- No code changes needed

**Cons:**
- Violates clean architecture principles
- Makes testing harder
- Reduces module reusability

---

## 2. Core → Components Circular Dependency

### Current State

**File:** `Core/Sources/Utilities/Project+Trait.swift:8`
```swift
import SnabbleComponents
```

### Usage Analysis

```swift
extension SnabbleCore.Project {
    public var trait: SnabbleComponents.Project {
        .project(id: id.rawValue)
    }
}
```

This is a **convenience extension** that maps `SnabbleCore.Project` to `SnabbleComponents.Project` (a UI trait).

### Architecture Violation

- **SnabbleCore** (Layer 1: Foundation - Business Logic) depends on **SnabbleComponents** (Layer 2: UI Primitives)
- Violates the **Separation of Concerns**: Business logic should not depend on UI primitives
- Makes Core dependent on UI concerns, reducing its reusability

### Refactoring Options

#### Option A: Move Extension to SnabbleComponents ✅ Recommended
Move the extension from Core to Components:

```swift
// Move to: Components/Sources/Extensions/Project+Trait.swift
import SnabbleCore

extension SnabbleCore.Project {
    public var trait: SnabbleComponents.Project {
        .project(id: id.rawValue)
    }
}
```

**Pros:**
- Clean separation: UI concerns stay in UI layer
- No architectural violations
- Simple refactor (just move the file)

**Cons:**
- None

#### Option B: Create a Shared Protocol
Define a protocol in Core and conform to it in Components:

```swift
// In SnabbleCore
public protocol Traitable {
    associatedtype Trait
    var trait: Trait { get }
}

// In SnabbleComponents
extension SnabbleCore.Project: Traitable {
    public var trait: SnabbleComponents.Project {
        .project(id: id.rawValue)
    }
}
```

**Pros:**
- Generic approach for future use

**Cons:**
- Overengineering for this simple case

#### Option C: Remove the Extension Entirely
Just use the initializer directly where needed:

```swift
// Instead of: project.trait
// Use: SnabbleComponents.Project.project(id: project.id.rawValue)
```

**Pros:**
- Simplest solution
- No dependencies

**Cons:**
- Less convenient API

---

## Recommended Actions

### Immediate Actions (For 1.0.0 Release)

1. ✅ **Document the circular dependencies** (this file)
2. ⚠️ **Add a note in Package.swift** about the known issues
3. ⚠️ **Create GitHub issues** to track the refactoring work

### Post-Release Actions (For 1.1.0)

1. **Fix Core → Components dependency:**
   - Move `Project+Trait.swift` to SnabbleComponents module
   - Remove `SnabbleComponents` dependency from Core's Package.swift

2. **Fix Core → User dependency:**
   - Move `clientId` and `appUser` computed properties to SnabbleUser
   - Update Package.swift to remove SnabbleUser from Core dependencies
   - Create migration guide for consumers (minor breaking change)

---

## Impact Assessment

### Current Impact

- ✅ **No functional issues**: The SDK works correctly despite the circular dependencies
- ⚠️ **Build time impact**: Circular dependencies can slow down incremental builds
- ⚠️ **Testing complexity**: Harder to test modules in isolation
- ⚠️ **Module reusability**: Core cannot be used without User and Components

### Post-Refactoring Benefits

- ✅ Clean layered architecture
- ✅ Better testability (isolated unit tests)
- ✅ Faster incremental builds
- ✅ Improved module reusability
- ✅ Easier to maintain and extend

---

## Resolution Summary (2026-03-27)

Both circular dependencies have been **successfully resolved** for SDK version 1.0.0 RC:

### ✅ Core → Components (RESOLVED)

**Actions Taken:**
1. Moved `Project+Trait.swift` from `Core/Sources/Utilities/` to `Components/Sources/Extensions/`
2. Added `SnabbleCore` dependency to `SnabbleComponents` in Package.swift
3. Changed import from `import SnabbleComponents` to `import SnabbleCore`

**Result:** Components now depends on Core (correct layer direction), no circular dependency.

### ✅ Core → User (RESOLVED)

**Actions Taken:**
1. Moved `Client.swift` from `User/Sources/Model/` to `Core/Sources/User/`
2. Created `Core/Sources/API/Snabble+AppUser.swift` with **internal** `appUser` accessor for Core
3. Created `User/Sources/Extensions/Snabble+User.swift` with **public** `clientId` and `appUser` API
4. Moved `UserProviding` protocol to Core with type erasure (`Any?` return type)
5. Added `Config.domainName` computed property in Core
6. Declared `Config: SnabbleNetwork.Configurable` conformance in `Snabble+AppUser.swift`
7. Made `OrderList.clearCache()` public for User module access
8. Replaced all `Snabble.clientId` with `Client.id` in Core sources

**Result:**
- Core has **no dependency** on User module (removed from Package.swift)
- User module provides public API via extensions
- Core uses internal accessors for internal operations
- No breaking changes for SDK consumers

---

## Architectural Impact

### Before Resolution
- ❌ Core → User → Core (circular)
- ❌ Core → Components → Core (circular)
- ⚠️ Slower incremental builds
- ⚠️ Difficult to test in isolation
- ⚠️ Poor module reusability

### After Resolution
- ✅ Clean layered architecture maintained
- ✅ No circular dependencies
- ✅ Faster incremental builds
- ✅ Modules can be tested in isolation
- ✅ Better module reusability
- ✅ No breaking changes for consumers

---

## Conclusion

Both circular dependencies have been **fully resolved** on 2026-03-27 as part of the 1.0.0 RC release. The SDK now has a clean layered architecture with proper dependency flow:

```
Layer 1 (Foundation): Core, Network, AssetProviding
         ↓
Layer 2 (UI Primitives): Components, Assets
         ↓
Layer 3 (Domain Features): User, Shops, Cart, Receipts
         ↓
Layer 4 (Payment): Payment
         ↓
Layer 5 (Complete Flows): ScanAndGo, PhoneAuth, Coupons, etc.
```

**No further action required.** The refactoring is complete and production-ready.
