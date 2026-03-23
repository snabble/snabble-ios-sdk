# Swift 6 Migration Best Practices
## Lessons Learned from SnabbleSDK & teo-ios Migration

**Date:** March 2026  
**SDK Version:** 1.8.0  
**Based on:** Real-world migration of 50,000+ lines of code to Swift 6.2

---

## Executive Summary

This document captures the best practices, patterns, and lessons learned from migrating the SnabbleSDK and teo-ios app to Swift 6.2 with full concurrency compliance. Use this as a reference guide for future Swift 6 migration projects.

### Key Achievements

✅ **Zero Swift 6 compiler errors** in production code  
✅ **Full @MainActor isolation** for UI components  
✅ **Sendable conformance** for all data transfer objects  
✅ **async/await throughout** (Combine eliminated where possible)  
✅ **@Observable instead of ObservableObject** for modern SwiftUI

---

## Phase 1: Assessment & Planning

### 1.1 Identify Your Code Categories

Categorize your codebase into these buckets:

| Category | Action | Priority |
|----------|--------|----------|
| **Modern SwiftUI** | Light refactoring | High |
| **Legacy UIKit** | Plan deprecation path | Medium |
| **Deprecated Code** | Document, don't fix | Low |
| **Third-Party Wrappers** | Isolate with Sendable boundaries | High |

**Tool:** Create a spreadsheet tracking each module's status.

### 1.2 Enable Swift 6 Language Mode Gradually

```swift
// Package.swift - Enable per target
.target(
    name: "ModernModule",
    swiftSettings: [
        .swiftLanguageMode(.v6)  // ✅ Start with newest modules
    ]
)

.target(
    name: "LegacyModule",
    swiftSettings: [
        .swiftLanguageMode(.v5)  // ⏳ Migrate later
    ]
)
```

**Pro Tip:** Enable Swift 6 mode target-by-target, starting with the most modern code.

---

## Phase 2: Data Model Migration

### 2.1 Make All Data Types Sendable

**Pattern:** Any type passed between actors MUST be `Sendable`.

```swift
// ✅ DO: Value types are automatically Sendable if all properties are Sendable
struct User: Sendable {
    let id: UUID
    let name: String
    let email: String
}

// ✅ DO: Explicitly mark reference types
final class Configuration: @unchecked Sendable {
    private let lock = NSLock()
    private var _value: String = ""
    
    var value: String {
        get { lock.withLock { _value } }
        set { lock.withLock { _value = newValue } }
    }
}

// ❌ DON'T: Non-Sendable types crossing actor boundaries
class UnsafeData {  // No Sendable conformance
    var items: [String] = []
}
```

### 2.2 Enum with Associated Values

```swift
// ✅ DO: Make associated values Sendable
enum Result: Sendable {
    case success(Data)  // Data is Sendable
    case failure(Error) // Error is Sendable
}

// ✅ DO: Custom error types
struct NetworkError: Error, Sendable {
    let code: Int
    let message: String
}
```

### 2.3 Common Patterns

```swift
// Pattern 1: Sendable closure types
typealias CompletionHandler = @Sendable (Result<Data, Error>) -> Void

// Pattern 2: Sendable protocol witnesses
protocol DataProvider: Sendable {
    func fetchData() async throws -> Data
}

// Pattern 3: Sendable containers
struct Response<T: Sendable>: Sendable {
    let data: T
    let timestamp: Date
}
```

**Real Example from SnabbleSDK:**

```swift
// Before: Not Sendable
public enum ClientError: Error {
    case validation(ValidationError)  // ValidationError wasn't Sendable
    case restriction(Restriction)      // Restriction wasn't Sendable
}

// After: Fully Sendable
public enum ClientError: Error, Sendable {
    case validation(ValidationError)  // Now Sendable
    case restriction(Restriction)      // Now Sendable
}

public struct ValidationError: Sendable { /* ... */ }
public struct Restriction: Sendable { /* ... */ }
```

---

## Phase 3: SwiftUI View Models

### 3.1 Use @Observable (Not ObservableObject)

```swift
// ✅ DO: Modern @Observable pattern
import Observation

@Observable
@MainActor
final class PaymentViewModel {
    var isLoading: Bool = false
    var payments: [Payment] = []
    var errorMessage: String?
    
    func loadPayments() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            payments = try await paymentService.fetch()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// Usage in SwiftUI
struct PaymentView: View {
    @State private var viewModel = PaymentViewModel()
    
    var body: some View {
        List(viewModel.payments) { payment in
            Text(payment.name)
        }
        .task { await viewModel.loadPayments() }
    }
}

// ❌ DON'T: Old ObservableObject pattern
class OldViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    // Combine-based, requires more boilerplate
}
```

**Why @Observable?**
- ✅ No need for `@Published`
- ✅ Automatic change tracking
- ✅ Better performance
- ✅ Cleaner syntax
- ✅ Works with Swift 6 actor isolation

### 3.2 Dependency Injection Pattern

```swift
// ✅ DO: Inject dependencies, prefer non-optional when possible
@Observable
@MainActor
final class ShoppingCartViewModel {
    private let cart: ShoppingCart
    private let checkoutService: CheckoutService
    
    var items: [CartItem] = []
    
    init(cart: ShoppingCart, checkoutService: CheckoutService = .shared) {
        self.cart = cart
        self.checkoutService = checkoutService
        loadItems()
    }
    
    private func loadItems() {
        items = cart.items
    }
}

// ❌ DON'T: Optional dependencies requiring defensive coding
@Observable
@MainActor
final class BadViewModel {
    weak var cart: ShoppingCart?  // Requires nil checks everywhere
    
    func doSomething() {
        guard let cart else { return }  // Defensive code
        // ...
    }
}
```

---

## Phase 4: MainActor Isolation

### 4.1 Mark UI Classes with @MainActor

```swift
// ✅ DO: Explicit MainActor for UI types
@MainActor
@Observable
final class ViewModel {
    var uiState: UIState = .idle
    
    func updateUI() {
        // Already on MainActor, safe UI updates
        uiState = .loading
    }
}

// ✅ DO: MainActor for UIKit view controllers
@MainActor
final class MyViewController: UIViewController {
    // All properties and methods implicitly MainActor isolated
}
```

### 4.2 Access MainActor-Isolated Properties Safely

```swift
// ✅ DO: Use MainActor.assumeIsolated when you know you're on the main thread
@MainActor
final class Theme {
    static let shared = Theme()
    var primaryColor: UIColor = .blue
}

// Non-MainActor context needing Theme access
func configureStyle() -> UIColor {
    MainActor.assumeIsolated {
        Theme.shared.primaryColor
    }
}

// ✅ DO: Use await when crossing actor boundaries
func loadTheme() async {
    let color = await Theme.shared.primaryColor
    // Use color...
}

// ❌ DON'T: Use nonisolated(unsafe) unless absolutely necessary
class UnsafeTheme {
    nonisolated(unsafe) static var color: UIColor = .blue  // ⚠️ Last resort
}
```

**Real Example from SnabbleSDK:**

```swift
// Core/Sources/Coupons/Coupon+ImageURL.swift:52
func imageURL(for project: Project) -> URL? {
    let scale = MainActor.assumeIsolated {
        UIScreen.main.scale  // UIScreen.main requires MainActor
    }
    
    return imageURL(scale: Int(scale))
}
```

### 4.3 When to Use nonisolated(unsafe)

```swift
// ✅ ONLY when:
// 1. Thread-safe by design (e.g., using locks)
// 2. Changing would break API
// 3. Well-documented

final class ThreadSafeCache {
    private let lock = NSLock()
    private var storage: [String: Data] = [:]
    
    // Safe because internally synchronized
    nonisolated(unsafe) func get(_ key: String) -> Data? {
        lock.withLock { storage[key] }
    }
    
    nonisolated(unsafe) func set(_ key: String, value: Data) {
        lock.withLock { storage[key] = value }
    }
}
```

---

## Phase 5: async/await Migration

### 5.1 Replace Completion Handlers

```swift
// ❌ OLD: Completion handler pattern
func fetchData(completion: @escaping (Result<Data, Error>) -> Void) {
    URLSession.shared.dataTask(with: url) { data, response, error in
        if let error {
            completion(.failure(error))
        } else if let data {
            completion(.success(data))
        }
    }.resume()
}

// ✅ NEW: async/await
func fetchData() async throws -> Data {
    try await URLSession.shared.data(from: url).0
}

// Usage
Task {
    do {
        let data = try await fetchData()
        // Use data
    } catch {
        // Handle error
    }
}
```

### 5.2 Sendable Closures

```swift
// ✅ DO: Mark completion handlers as @Sendable when crossing actors
func performAsync(completion: @Sendable @escaping (Result<String, Error>) -> Void) {
    Task {
        do {
            let result = try await someAsyncWork()
            completion(.success(result))
        } catch {
            completion(.failure(error))
        }
    }
}

// ❌ DON'T: Non-Sendable closures in concurrent contexts
func badAsync(completion: @escaping (Result<String, Error>) -> Void) {
    // Swift 6 warning: non-Sendable type passed to concurrent context
}
```

### 5.3 Actor-Based Services

```swift
// ✅ DO: Use actors for shared mutable state
actor DatabaseManager {
    private var cache: [String: Data] = [:]
    
    func store(_ data: Data, for key: String) {
        cache[key] = data
    }
    
    func retrieve(_ key: String) -> Data? {
        cache[key]
    }
}

// Usage
let db = DatabaseManager()
await db.store(data, for: "user_123")
let cached = await db.retrieve("user_123")
```

---

## Phase 6: Common Migration Patterns

### 6.1 Combine → AsyncStream

```swift
// ❌ OLD: Combine publisher
import Combine

class CheckInManager {
    let shopPublisher = CurrentValueSubject<Shop?, Never>(nil)
}

// Usage
manager.shopPublisher
    .sink { shop in
        // Handle shop change
    }
    .store(in: &cancellables)

// ✅ NEW: AsyncStream
class CheckInManager {
    private let shopContinuation: AsyncStream<Shop?>.Continuation
    let shopStream: AsyncStream<Shop?>
    
    init() {
        (shopStream, shopContinuation) = AsyncStream.makeStream()
    }
    
    func updateShop(_ shop: Shop?) {
        shopContinuation.yield(shop)
    }
}

// Usage
for await shop in manager.shopStream {
    // Handle shop change
}
```

### 6.2 Delegate → async/await

```swift
// ❌ OLD: Delegate pattern
protocol ScannerDelegate: AnyObject {
    func scanner(_ scanner: Scanner, didScan code: String)
}

class Scanner {
    weak var delegate: ScannerDelegate?
    
    func scan() {
        // ...
        delegate?.scanner(self, didScan: "ABC123")
    }
}

// ✅ NEW: async/await
class Scanner {
    func scan() async -> String {
        // Scanning logic
        return "ABC123"
    }
}

// Usage
Task {
    let code = await scanner.scan()
    // Process code
}
```

### 6.3 Notification → AsyncStream

```swift
// ❌ OLD: NotificationCenter
NotificationCenter.default.addObserver(
    self,
    selector: #selector(handleUpdate),
    name: .dataUpdated,
    object: nil
)

// ✅ NEW: AsyncStream wrapper
extension NotificationCenter {
    func notifications(named name: Notification.Name) -> AsyncStream<Notification> {
        AsyncStream { continuation in
            let observer = addObserver(
                forName: name,
                object: nil,
                queue: nil
            ) { notification in
                continuation.yield(notification)
            }
            
            continuation.onTermination = { _ in
                removeObserver(observer)
            }
        }
    }
}

// Usage
for await notification in NotificationCenter.default.notifications(named: .dataUpdated) {
    // Handle notification
}
```

---

## Phase 7: SwiftUI Integration Patterns

### 7.1 Environment Objects

```swift
// ✅ DO: Use Environment with @Observable
@Observable
@MainActor
final class Shopper {
    var cart: ShoppingCart
    var shop: Shop
    
    init(shop: Shop) {
        self.shop = shop
        self.cart = ShoppingCart()
    }
}

// Root view
struct RootView: View {
    @State private var shopper: Shopper
    
    init(shop: Shop) {
        self.shopper = Shopper(shop: shop)
    }
    
    var body: some View {
        ContentView()
            .environment(shopper)
    }
}

// Child view
struct CartView: View {
    @Environment(Shopper.self) private var shopper
    
    var body: some View {
        List(shopper.cart.items) { item in
            Text(item.name)
        }
    }
}
```

### 7.2 Task Lifecycle

```swift
// ✅ DO: Use .task for async work in views
struct ProductListView: View {
    @State private var viewModel = ProductViewModel()
    
    var body: some View {
        List(viewModel.products) { product in
            ProductRow(product: product)
        }
        .task {
            await viewModel.loadProducts()
        }
        // .task automatically cancels when view disappears
    }
}

// ❌ DON'T: Manual Task management
struct BadView: View {
    @State private var task: Task<Void, Never>?
    
    var body: some View {
        Text("Hello")
            .onAppear {
                task = Task {
                    await doWork()
                }
            }
            .onDisappear {
                task?.cancel()
            }
    }
}
```

---

## Phase 8: Testing Strategies

### 8.1 Testing @Observable Models

```swift
import Testing

@Test
@MainActor
func testViewModelLoading() async {
    let viewModel = PaymentViewModel()
    
    #expect(viewModel.payments.isEmpty)
    
    await viewModel.loadPayments()
    
    #expect(!viewModel.payments.isEmpty)
}
```

### 8.2 Testing Actors

```swift
@Test
func testActorIsolation() async {
    let manager = DatabaseManager()
    
    await manager.store(testData, for: "key")
    let retrieved = await manager.retrieve("key")
    
    #expect(retrieved == testData)
}
```

---

## Phase 9: Common Pitfalls & Solutions

### 9.1 Capturing Self in Tasks

```swift
// ❌ DON'T: Implicit strong capture
@MainActor
class ViewModel {
    func loadData() {
        Task {
            // Strong capture of self - potential memory leak
            self.data = try await fetchData()
        }
    }
}

// ✅ DO: Explicit weak capture when needed
@MainActor
class ViewModel {
    func loadData() {
        Task { [weak self] in
            guard let self else { return }
            self.data = try await fetchData()
        }
    }
}

// ✅ BETTER: For @MainActor classes, strong capture is usually fine
@MainActor
class ViewModel {
    func loadData() {
        Task {
            // This is actually fine for @MainActor classes
            // Task lifecycle is managed by the view
            self.data = try await fetchData()
        }
    }
}
```

### 9.2 Force Unwrapping Optional Bindings

```swift
// ❌ DON'T: Force unwrap in Swift 6
func process(_ data: Data?) {
    let unwrapped = data!  // Crash if nil
    // ...
}

// ✅ DO: Use guard/if let
func process(_ data: Data?) {
    guard let data else { return }
    // Safe to use data
}

// ✅ DO: Use optional chaining
func process(_ manager: Manager?) {
    manager?.performWork()
}
```

### 9.3 Mixing Isolation Domains

```swift
// ❌ DON'T: Access MainActor from background
func backgroundWork() {
    Task.detached {
        let color = UIColor.red  // ⚠️ UIColor requires MainActor
    }
}

// ✅ DO: Explicitly switch to MainActor
func backgroundWork() {
    Task.detached {
        await MainActor.run {
            let color = UIColor.red
        }
    }
}

// ✅ BETTER: Design with proper isolation from the start
@MainActor
func mainActorWork() {
    let color = UIColor.red  // Already on MainActor
}
```

---

## Phase 10: Documentation Standards

### 10.1 Document Concurrency Decisions

```swift
/// Thread-safe cache using internal locking.
///
/// This class uses `nonisolated(unsafe)` because:
/// 1. All access is protected by NSLock
/// 2. Changing the API would be breaking
/// 3. Performance-critical code path
///
/// **Thread Safety:** All methods are thread-safe via internal locking.
final class Cache {
    private let lock = NSLock()
    private var storage: [String: Data] = [:]
    
    nonisolated(unsafe) func get(_ key: String) -> Data? {
        lock.withLock { storage[key] }
    }
}
```

### 10.2 Migration Comments

```swift
// MARK: - Legacy Compatibility
// TODO: Remove in v2.0 after all consumers migrate to async API
@available(*, deprecated, message: "Use async variant instead")
func fetchData(completion: @escaping (Data?) -> Void) {
    Task {
        let data = try? await fetchData()
        completion(data)
    }
}

/// Modern async variant. Preferred for new code.
func fetchData() async throws -> Data {
    try await URLSession.shared.data(from: url).0
}
```

---

## Migration Checklist

Use this checklist for each module:

- [ ] Enable Swift 6 language mode in Package.swift
- [ ] Make all data types `Sendable`
- [ ] Convert `ObservableObject` to `@Observable`
- [ ] Replace completion handlers with async/await
- [ ] Add `@MainActor` to UI classes
- [ ] Convert Combine publishers to AsyncStream (where beneficial)
- [ ] Update tests for async patterns
- [ ] Document concurrency decisions
- [ ] Build with zero warnings
- [ ] Run all tests
- [ ] Update consumer documentation

---

## Tool Recommendations

### Xcode Build Settings
```swift
// Package.swift
swiftSettings: [
    .swiftLanguageMode(.v6),
    .enableExperimentalFeature("StrictConcurrency")
]
```

### Git Workflow
```bash
# Create feature branch
git checkout -b feature/swift6-migration-module-name

# Commit incrementally
git commit -m "Make DataModels Sendable"
git commit -m "Convert ViewModel to @Observable"
git commit -m "Add MainActor isolation"

# When complete
git commit -m "Enable Swift 6 mode for ModuleName"
```

---

## Success Metrics

Track these metrics during migration:

| Metric | Target |
|--------|--------|
| Swift 6 compiler errors | 0 |
| Swift 6 warnings (modern code) | 0 |
| Test coverage | > 80% |
| Documentation completeness | 100% |
| Performance regression | < 5% |

---

## Resources

- [Swift 6 Migration Guide](https://www.swift.org/migration/documentation/swift-6-concurrency-migration-guide/)
- [Swift Concurrency](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)
- [Observation Framework](https://developer.apple.com/documentation/Observation)
- [MainActor Documentation](https://developer.apple.com/documentation/swift/mainactor)

---

## Conclusion

Swift 6 migration is a significant undertaking, but following these patterns will result in:

✅ More reliable concurrent code  
✅ Better SwiftUI performance  
✅ Cleaner, more maintainable architecture  
✅ Future-proof codebase

**Estimated Time:** Plan 2-4 weeks per 10,000 lines of code for thorough migration.

---

**Document Version:** 1.0  
**Last Updated:** 2026-03-22  
**Authors:** SDK Team (based on SnabbleSDK & teo-ios migration)  
**Questions:** See SDK-MODERNIZATION.md for project-specific guidance
