# CheckInManager API Migration Guide

## Overview

The `CheckInManager` now supports both legacy Combine publishers and modern Swift concurrency with AsyncStream. This guide shows how to migrate from the deprecated Combine API to the new AsyncStream API.

---

## API Comparison

### Legacy API (Combine - Deprecated)

```swift
import Combine

class MyViewModel {
    private var cancellables = Set<AnyCancellable>()

    func setupCheckIn() {
        // Subscribe to shop changes
        Snabble.shared.checkInManager.shopPublisher
            .sink { shop in
                print("Checked into: \(shop?.name ?? "none")")
            }
            .store(in: &cancellables)

        // Subscribe to authorization changes
        Snabble.shared.checkInManager.authorizationStatusSubject
            .sink { status in
                print("Authorization: \(status)")
            }
            .store(in: &cancellables)
    }
}
```

### Modern API (AsyncStream - Recommended)

```swift
@Observable
@MainActor
class MyViewModel {
    private var shopTask: Task<Void, Never>?
    private var authTask: Task<Void, Never>?

    func setupCheckIn() {
        // Observe shop changes
        shopTask = Task {
            for await shop in Snabble.shared.checkInManager.shopStream {
                print("Checked into: \(shop?.name ?? "none")")
            }
        }

        // Observe authorization changes
        authTask = Task {
            for await status in Snabble.shared.checkInManager.authorizationStream {
                print("Authorization: \(status)")
            }
        }
    }

    deinit {
        shopTask?.cancel()
        authTask?.cancel()
    }
}
```

---

## Migration Examples

### Example 1: SwiftUI AppState (Recommended Pattern)

**Before (Combine):**
```swift
import Combine

@Observable
@MainActor
class AppState: CheckInManagerDelegate {
    var checkedInShop: Shop?
    private var cancellables = Set<AnyCancellable>()

    init() {
        Snabble.shared.checkInManager.delegate = self

        Snabble.shared.checkInManager.shopPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] shop in
                self?.checkedInShop = shop
            }
            .store(in: &cancellables)
    }

    func checkInManager(_ checkInManager: CheckInManager, didCheckInTo shop: Shop) {
        checkedInShop = shop
    }

    func checkInManager(_ checkInManager: CheckInManager, didCheckOutOf shop: Shop) {
        checkedInShop = nil
    }
}
```

**After (AsyncStream):**
```swift
@Observable
@MainActor
class AppState: CheckInManagerDelegate {
    var checkedInShop: Shop?
    private var shopTask: Task<Void, Never>?

    init() {
        Snabble.shared.checkInManager.delegate = self

        shopTask = Task { [weak self] in
            for await shop in Snabble.shared.checkInManager.shopStream {
                self?.checkedInShop = shop
            }
        }
    }

    deinit {
        shopTask?.cancel()
    }

    func checkInManager(_ checkInManager: CheckInManager, didCheckInTo shop: Shop) {
        checkedInShop = shop
    }

    func checkInManager(_ checkInManager: CheckInManager, didCheckOutOf shop: Shop) {
        checkedInShop = nil
    }
}
```

### Example 2: Direct SwiftUI View Usage

**Before (Combine):**
```swift
import SwiftUI
import Combine

struct ShopStatusView: View {
    @State private var currentShop: Shop?
    @State private var cancellables = Set<AnyCancellable>()

    var body: some View {
        Text(currentShop?.name ?? "No shop checked in")
            .onAppear {
                Snabble.shared.checkInManager.shopPublisher
                    .receive(on: DispatchQueue.main)
                    .sink { shop in
                        currentShop = shop
                    }
                    .store(in: &cancellables)
            }
    }
}
```

**After (AsyncStream):**
```swift
import SwiftUI

struct ShopStatusView: View {
    @State private var currentShop: Shop?

    var body: some View {
        Text(currentShop?.name ?? "No shop checked in")
            .task {
                for await shop in Snabble.shared.checkInManager.shopStream {
                    currentShop = shop
                }
            }
    }
}
```

### Example 3: Authorization Handling

**Before (Combine):**
```swift
class LocationPermissionManager {
    private var cancellables = Set<AnyCancellable>()

    func monitorAuthorization() {
        Snabble.shared.checkInManager.authorizationStatusSubject
            .sink { status in
                switch status {
                case .authorizedWhenInUse, .authorizedAlways:
                    print("Location authorized")
                case .denied, .restricted:
                    print("Location denied")
                case .notDetermined:
                    print("Location not determined")
                @unknown default:
                    break
                }
            }
            .store(in: &cancellables)
    }
}
```

**After (AsyncStream):**
```swift
@MainActor
class LocationPermissionManager {
    private var authTask: Task<Void, Never>?

    func monitorAuthorization() {
        authTask = Task {
            for await status in Snabble.shared.checkInManager.authorizationStream {
                switch status {
                case .authorizedWhenInUse, .authorizedAlways:
                    print("Location authorized")
                case .denied, .restricted:
                    print("Location denied")
                case .notDetermined:
                    print("Location not determined")
                @unknown default:
                    break
                }
            }
        }
    }

    deinit {
        authTask?.cancel()
    }
}
```

---

## Benefits of AsyncStream API

1. **Native Swift Concurrency**: No Combine import needed
2. **Automatic Cancellation**: Tasks cancel when scope exits
3. **MainActor Integration**: Works seamlessly with @Observable and SwiftUI
4. **Modern Syntax**: Cleaner, more readable code
5. **Better Memory Management**: No manual AnyCancellable tracking

---

## Delegate Pattern Still Recommended

The `CheckInManagerDelegate` protocol is **NOT deprecated** and remains the recommended way to handle check-in/check-out events in app-level state management.

**Why?**
- Provides structured callbacks for specific events
- Better for app-wide state coordination
- Clear separation of concerns
- Works well with @Observable AppState pattern

**Use AsyncStream when:**
- You need to observe changes in a specific view or component
- You want reactive updates without delegate implementation
- You're building feature-specific logic

**Use Delegate when:**
- You're managing app-wide state (like AppState)
- You need structured event handling
- You want clear lifecycle management

---

## Migration Timeline

- **Current**: Both APIs available
- **Deprecated**: Combine API marked with deprecation warnings
- **Future (2.0)**: Combine API may be removed in major version update

---

## Questions?

If you have questions about migration, please refer to:
- [Swift 6 Migration Plan](Swift-6-Migration-Plan-EN.md)
- [SDK Integration Best Practices](SDK-Integration-Best-Practices.md)
