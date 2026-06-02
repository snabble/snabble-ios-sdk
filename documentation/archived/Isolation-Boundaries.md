# Isolation Boundaries - Swift 6.2 Migration

**Author:** Uwe Tilemann
**Date:** 2026-02-19
**Status:** DRAFT - Review Required
**Goal:** Define actor isolation strategy for Swift 6.2 migration

---

## Phase 0 Audit Results

**Completed:** 2026-02-19

### Dependencies
- ✅ GRDB.swift 6.29.3 (Swift 6 compatible)
- ✅ Datatrans 3.8.0 (updated from 3.7.3)
- ✅ All dependencies up-to-date

### Technical Debt
- **31 ObservableObject classes** (found, not 25 as originally planned)
- **90 @Published properties** (found, not 69 as originally planned)
- **Top 3 complex classes**:
  - `Shopper.swift`: 12 @Published properties
  - `SepaDataModel.swift`: 7 @Published properties
  - `LoginViewModel.swift`: 5 @Published properties

---

## Core Module Isolation Strategy

### ShoppingCart (Core/Sources/Cart/ShoppingCart.swift)

**Current State:**
```swift
public final class ShoppingCart: Codable, PaymentConsumer {
    public private(set) var items: [CartItem]
    // ... DB + Network operations
}
```

**✅ DECISION: Migrate to Actor**

**Isolation:** Custom Actor
**Reason:** Performs DB writes (GRDB) + Network calls (checkout info)
**Pattern:** Mixed isolation with MainActor.run for UI updates

**Target Implementation:**
```swift
actor ShoppingCart {
    private var items: [CartItem] = []
    private let database: DatabaseQueue

    func add(_ item: CartItem) async {
        items.append(item)
        await saveToDatabase()
        await notifyBackend()
    }

    func getAllItems() -> [CartItem] {
        items
    }

    private func saveToDatabase() async {
        // GRDB write on actor's executor
    }
}
```

**Migration Risk:** Medium
**Estimated Effort:** 8-12 hours
**Dependencies:** ProductDatabase, ShoppingCartViewModel

---

### ProductDatabase (Core/Sources/Products/ProductDatabase.swift)

**Current State:** Unclear (needs investigation)

**✅ DECISION: Custom Executor (GRDB Queue)**

**Isolation:** Custom Actor with DispatchQueueExecutor
**Reason:** GRDB requires specific serial queue
**Pattern:** Custom executor (see swift-concurrency skill actors.md:435)

**Target Implementation:**
```swift
actor ProductDatabase {
    private let executor: DispatchQueueExecutor

    nonisolated var unownedExecutor: UnownedSerialExecutor {
        executor.asUnownedSerialExecutor()
    }

    init(grdbQueue: DatabaseQueue) {
        executor = DispatchQueueExecutor(queue: grdbQueue.serializedDatabase)
    }

    func fetchProduct(sku: String) async -> Product? {
        // Runs on GRDB's serial queue
    }
}
```

**Migration Risk:** High (GRDB integration)
**Estimated Effort:** 16-24 hours
**Dependencies:** GRDB 6.29.3+

---

### CheckInManager (Core/Sources/Checkin/CheckInManager.swift)

**Current State:**
```swift
public class CheckInManager: NSObject {
    public var shop: Shop?
    public var shopPublisher = CurrentValueSubject<Shop?, Never>(nil)
    // ... CLLocationManagerDelegate
}
```

**✅ DECISION: @MainActor + nonisolated delegates**

**Isolation:** @MainActor
**Reason:** CLLocationManagerDelegate requires main thread
**Pattern:** nonisolated delegate + Task wrapper

**Target Implementation:**
```swift
@MainActor
class CheckInManager: NSObject, CLLocationManagerDelegate {
    private(set) var shop: Shop?

    // ⚠️ MIGRATE: Combine → AsyncStream
    private var shopContinuation: AsyncStream<Shop?>.Continuation?
    lazy var shopStream: AsyncStream<Shop?> = {
        AsyncStream { [weak self] continuation in
            self?.shopContinuation = continuation
        }
    }()

    // ✅ nonisolated delegate pattern
    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        Task { @MainActor in
            self.handleLocationUpdate(locations)
        }
    }

    private func handleLocationUpdate(_ locations: [CLLocation]) {
        // Runs on @MainActor
        updateShops(locations)
        shopContinuation?.yield(shop)
    }
}
```

**Migration Risk:** Medium
**Estimated Effort:** 6-8 hours
**Dependencies:** None
**⚠️ Critical:** Must fix Combine + @MainActor safety issue (see migration.md:536-581)

---

## UI Module Isolation Strategy

### ShoppingCartViewModel (UI/Sources/ShoppingCart/Models/ShoppingCartViewModel.swift)

**Current State:**
```swift
class ShoppingCartViewModel: ObservableObject {
    @Published var items: [CartEntry]
    let shoppingCart: ShoppingCart
}
```

**✅ DECISION: @Observable @MainActor**

**Isolation:** @MainActor
**Reason:** Pure UI state management
**Pattern:** @Observable with async cart access

**Target Implementation:**
```swift
@Observable
@MainActor
class ShoppingCartViewModel {
    private let cart: ShoppingCart // Actor reference
    private(set) var items: [CartEntry] = []

    func addItem(_ item: CartItem) async {
        await cart.add(item)
        items = await cart.getAllItems().map { CartEntry($0) }
    }
}
```

**Migration Risk:** Low
**Estimated Effort:** 4-6 hours
**Dependencies:** ShoppingCart (must be Actor first)

---

### PaymentMethodManager (UI/Sources/Payment/PaymentMethodManager.swift)

**Current State:**
```swift
class PaymentMethodManager: ObservableObject {
    @Published var availableMethods: [PaymentMethod]
}
```

**✅ DECISION: @Observable @MainActor**

**Isolation:** @MainActor
**Reason:** UI-bound payment selection
**Pattern:** Standard @Observable migration

**Migration Risk:** Low
**Estimated Effort:** 3-4 hours

---

### SepaDataModel (UI/Sources/PaymentMethods/Models/SepaDataModel.swift)

**Current State:**
```swift
class SepaDataModel: ObservableObject {
    @Published var ibanNumber: String = ""
    // ... 7 @Published properties + Combine validation
}
```

**✅ DECISION: @Observable @MainActor with Hybrid Combine**

**Isolation:** @MainActor
**Reason:** PCI-critical validation logic
**Pattern:** Hybrid @Observable + Combine validation (see migration plan)

**Target Implementation:**
```swift
@Observable
@MainActor
class SepaDataModel {
    private var _ibanNumber: String = ""

    // ✅ Keep Combine for validation
    private let ibanSubject = CurrentValueSubject<String, Never>("")

    var ibanNumber: String {
        get { _ibanNumber }
        set {
            _ibanNumber = newValue
            ibanSubject.send(newValue) // Validation stays
        }
    }

    // Existing Combine validation pipeline
    lazy var isValid: AnyPublisher<Bool, Never> = {
        ibanSubject
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .map { validateIBAN($0) }
            .eraseToAnyPublisher()
    }()
}
```

**Migration Risk:** High (PCI compliance)
**Estimated Effort:** 8-12 hours
**⚠️ Critical:** Must preserve validation logic exactly

---

## ScanAndGo Module Isolation Strategy

### Shopper (ScanAndGo/Shopping/Models/Shopper.swift)

**Current State:**
```swift
public final class Shopper: ObservableObject {
    @ObservedObject public var barcodeManager: BarcodeManager
    @ObservedObject public var cartModel: ShoppingCartViewModel
    @Published public var paymentManager: PaymentMethodManager
    // ... 12 @Published properties total
}
```

**✅ DECISION: @Observable @MainActor**

**Isolation:** @MainActor
**Reason:** UI coordinator for shopping session
**Pattern:** @Observable with @State child ViewModels

**Target Implementation:**
```swift
@Observable
@MainActor
public final class Shopper: BarcodeProcessing, Equatable {
    public var barcodeManager: BarcodeManager
    public var cartModel: ShoppingCartViewModel
    public var paymentManager: PaymentMethodManager

    public var hasValidPayment: Bool = false

    // ✅ No @Published needed - @Observable tracks all properties
}
```

**Migration Risk:** Medium
**Estimated Effort:** 8-10 hours
**Dependencies:** BarcodeManager, ShoppingCartViewModel, PaymentMethodManager (all must migrate first)

---

### BarcodeManager (ScanAndGo/Shopping/Models/BarcodeManager.swift)

**Current State:**
```swift
class BarcodeManager: ObservableObject {
    @Published var scannedCode: String?
}
```

**✅ DECISION: @Observable @MainActor**

**Isolation:** @MainActor
**Reason:** Scanner UI state
**Pattern:** Standard @Observable migration

**Migration Risk:** Low
**Estimated Effort:** 2-3 hours

---

## Migration Order (Critical Path)

### Phase 2: Core Concurrency (Week 2-4)

**Week 2:**
1. ✅ ProductDatabase → Custom Executor (16-24h)
2. ✅ ShoppingCart → Actor (8-12h)

**Week 3:**
3. ✅ CheckInManager → @MainActor + nonisolated delegates (6-8h)

**Week 4:**
- Testing + Verification

### Phase 3: @Observable Migration (Week 4-9)

**Tier 1 - Core Dependencies (Week 4-5):**
1. ✅ BarcodeManager → @Observable @MainActor (2-3h)
2. ✅ PaymentMethodManager → @Observable @MainActor (3-4h)
3. ✅ ShoppingCartViewModel → @Observable @MainActor (4-6h)

**Tier 2 - Coordinators (Week 6-7):**
4. ✅ Shopper → @Observable @MainActor (8-10h)
5. ✅ SepaDataModel → Hybrid @Observable + Combine (8-12h)

**Tier 3 - Remaining (Week 8-9):**
6. All other ObservableObject classes

---

## Sendable Strategy

### Core Module Types

**Must be Sendable:**
- `CartItem` → `struct` (value type, implicit Sendable)
- `Product` → `struct` (value type, implicit Sendable)
- `Shop` → `struct` (value type, implicit Sendable)
- `Project` → needs audit

**Actor-isolated (implicit Sendable):**
- `ShoppingCart` → Actor
- `ProductDatabase` → Actor

**@unchecked Sendable (temporary):**
None planned - avoid if possible

---

## @unchecked Sendable Policy

**Rule:** Every `@unchecked Sendable` requires:
1. ✅ GitHub Issue/Ticket for migration
2. ✅ Code comment with safety invariant
3. ✅ Code comment with ticket reference
4. ✅ Code comment with last verification date

**Example:**
```swift
// TODO: Migrate to actor in Phase 6 (#SWIFT6-123)
// Last verified: 2026-02-19
// Thread-safety: NSLock protects all access to `items`
final class Cache: @unchecked Sendable {
    private let lock = NSLock()
    private var items: [String: Data] = [:]
}
```

---

## Combine Migration Strategy

### Notifications

**Current Pattern:**
```swift
NotificationCenter.default.publisher(for: .paymentUpdated)
    .sink { [weak self] _ in
        self?.handlePayment() // ⚠️ Unsafe with @MainActor
    }
```

**✅ Fix Pattern (Temporary):**
```swift
NotificationCenter.default.publisher(for: .paymentUpdated)
    .sink { [weak self] _ in
        Task { @MainActor in
            self?.handlePayment() // ✅ Safe
        }
    }
```

**Target Pattern (Phase 6):**
```swift
Task {
    for await _ in NotificationCenter.default.notifications(named: .paymentUpdated) {
        await handlePayment() // ✅ Compile-time safe
    }
}
```

### Complex Validation (SepaDataModel)

**Strategy:** Hybrid @Observable + Combine
**Reason:** Preserve PCI-critical validation logic
**Timeline:** Keep Combine until Phase 6, then evaluate AsyncAlgorithms

---

## Risk Assessment

### High Risk (Requires careful review)

1. **ProductDatabase Custom Executor** - GRDB integration complex
2. **SepaDataModel Combine Validation** - PCI compliance critical
3. **ShoppingCart Actor Migration** - Core component, many dependents

### Medium Risk

1. **CheckInManager CLLocationManager** - Delegate pattern known
2. **Shopper @Observable** - 12 @Published properties, but straightforward
3. **ShoppingCartViewModel** - Depends on ShoppingCart actor

### Low Risk

1. **BarcodeManager** - Simple @Observable migration
2. **PaymentMethodManager** - Standard UI ViewModel

---

## Success Criteria

### Phase 2 Complete
- [ ] ProductDatabase builds without errors
- [ ] ShoppingCart builds without errors
- [ ] CheckInManager builds without errors
- [ ] All Core module tests pass
- [ ] Thread Sanitizer clean (0 warnings)

### Phase 3 Complete
- [ ] All 31 ObservableObject classes migrated
- [ ] All 90 @Published properties removed
- [ ] All UI tests pass
- [ ] No Combine + @MainActor safety issues
- [ ] Performance validation passed

---

## Next Steps

1. ✅ Review this document with team
2. ⏭️ Start Phase 1: Package.swift update
3. ⏭️ Start Phase 2: ProductDatabase migration
4. ⏭️ Create migration tickets for each component
5. ⏭️ Setup Thread Sanitizer CI check

---

## Open Questions

**For Discussion:**

1. Should we migrate Combine to AsyncAlgorithms in Phase 6, or keep hybrid approach?
2. Do we need custom executors for anything besides GRDB?
3. Should `Snabble.shared` singleton be @MainActor or actor-isolated?
4. Performance impact of ShoppingCart as actor vs class?

---

**Document Status:** DRAFT - Awaiting Review
