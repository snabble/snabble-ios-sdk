# SnabbleComponents

**Layer:** 2 (UI Primitives)
**Status:** Active
**Dependencies:** SnabbleAssetProviding, SnabbleCore, WindowKit

## Overview

SnabbleComponents provides reusable SwiftUI UI primitives for the Snabble iOS SDK — buttons, HUD overlay, toast notifications, web views, async content loading, and the project trait system used for project-specific styling.

## Public API

### Buttons

```swift
import SnabbleComponents

PrimaryButtonView(title: "Checkout") {
    startCheckout()
}

SecondaryButtonView(title: "Cancel") {
    dismiss()
}

// With disabled binding
PrimaryButtonView(title: "Pay", disabled: $isProcessing) {
    pay()
}
```

### HUD Overlay

The HUD slides in from the top with a spring animation and a material background:

```swift
import SnabbleComponents

struct ScannerView: View {
    @State private var showHUD = false

    var body: some View {
        CameraView()
            .hud(isPresented: $showHUD) {
                Text("Item added to cart")
                    .padding()
            }
    }
}
```

### Toast Notifications

```swift
import SnabbleComponents

struct CartView: View {
    @State private var toast: Toast?

    var body: some View {
        List { ... }
            .toast(item: $toast)
        }
    }

    func showSuccess() {
        toast = Toast(message: "Item added", style: .success)
    }

    func showError() {
        toast = Toast(message: "Something went wrong", style: .error, duration: 5)
    }
}
```

`Toast.Style`: `.success`, `.warning`, `.error`  
Default duration: 3 seconds.

### Async Content Loading

`AsyncContentView` drives a standard loading/empty/error/loaded state machine via the `LoadableObject` protocol:

```swift
import SnabbleComponents

// Conform your view model to LoadableObject
class ProductViewModel: LoadableObject {
    var state: LoadingState<Product> = .idle

    func load() {
        state = .loading
        Task {
            do {
                let product = try await fetchProduct()
                state = .loaded(product)
            } catch {
                state = .failed(error)
            }
        }
    }
}

// Use in a view
struct ProductView: View {
    @State private var viewModel = ProductViewModel()

    var body: some View {
        AsyncContentView(source: viewModel) { product in
            ProductDetails(product: product)
        }
    }
}
```

`LoadingState<Value>`: `.idle`, `.loading`, `.loaded(Value)`, `.failed(Error)`, `.empty`

### Web Views

```swift
import SnabbleComponents

// WKWebView wrapper
WebView(url: url)

// Full-screen web presentation with navigation
WebViewPresentable(url: url)

// Render an HTML string
HTMLView(html: "<h1>Terms</h1>")

// Embed a YouTube video
YouTubeView(videoId: "dQw4w9WgXcQ")
```

### Dialogs & Sheets

```swift
import SnabbleComponents

// Bottom sheet modal
BottomSheet(isPresented: $showSheet) {
    SheetContent()
}

// Window-level dialog
WindowDialog(isPresented: $showDialog) {
    DialogContent()
}
```

### User Notification Permission

```swift
import SnabbleComponents

List {
    Section("Notifications") {
        UserNotificationToggle()
    }
}
```

### Page Control

```swift
import SnabbleComponents

PageControl(numberOfPages: 3, currentPage: $currentPage)
```

### ActionManager

`ActionManager` ist ein `@Observable`-Singleton, über den Toasts, Dialoge, Sheets und Alerts aus beliebigen Stellen im Code getriggert werden können — ohne direkte View-Referenz.

**Setup (einmalig am Root-View):**

```swift
import SnabbleComponents

RootView()
    .actionState()
```

**Aktionen senden (z.B. aus einem ViewModel):**

```swift
import SnabbleComponents

// Toast
ActionManager.shared.send(.toast(Toast(message: "Artikel hinzugefügt", style: .success)))

// Dialog (View muss sich selbst schließen)
ActionManager.shared.send(.dialog(MyDialogView()))

// Sheet
ActionManager.shared.send(.sheet(MySheetView()))

// Alert
ActionManager.shared.send(.alert(Alert(title: Text("Fehler"))))

// Zurücksetzen
ActionManager.shared.send(.idle)
```

`ActionType`: `.idle`, `.toast(Toast)`, `.dialog(any View)`, `.sheet(any View)`, `.alert(Alert)`

### Project Trait System

Components uses `UITraitDefinition` to pass the active project through the view hierarchy for project-specific styling:

```swift
import SnabbleComponents

// Set the project trait on the root view
rootView.environment(\.projectTrait, .project(id: project.id.rawValue))

// Read in a child view
struct ThemedButton: View {
    @Environment(\.projectTrait) var projectTrait

    var body: some View {
        // projectTrait is .none or .project(id:)
    }
}

// UIKit: read from trait collection
let project = traitCollection.project  // Project enum
```

## Key Components

| Component | File | Description |
|---|---|---|
| `PrimaryButtonView` | `Buttons/PrimaryButtonView.swift` | Full-width primary action button |
| `SecondaryButtonView` | `Buttons/SecondaryButtonView.swift` | Full-width secondary action button |
| `HUD` | `Modifier/HUD.swift` | Top-sliding overlay with material background |
| `.hud(isPresented:content:)` | `Modifier/HUD.swift` | View modifier to attach a HUD |
| `Toast` | `Toast/Toast.swift` | Toast model (message, style, duration) |
| `ToastView` | `Toast/ToastView.swift` | Toast display view |
| `.toast(item:)` | `Toast/View+Toast.swift` | View modifier for toast presentation |
| `AsyncContentView` | `AsyncContent/AsyncContentView.swift` | State-driven loading/content/error view |
| `LoadableObject` | `AsyncContent/AsyncContentView.swift` | Protocol for async data sources |
| `WebView` | `Web/WebView.swift` | WKWebView SwiftUI wrapper |
| `WebViewPresentable` | `Web/WebViewPresentable.swift` | Full-screen web presentation |
| `HTMLView` | `Web/HTMLView.swift` | Renders an HTML string |
| `YouTubeView` | `Web/YouTubeView.swift` | YouTube embed |
| `BottomSheet` | `Dialog/BottomSheet.swift` | Bottom sheet modal |
| `WindowDialog` | `Dialog/WindowDialog.swift` | Window-level dialog |
| `PageControl` | `PageControl/PageControl.swift` | Dot-style page indicator |
| `UserNotificationToggle` | `UserNotification/Toggle/UserNotificationToggle.swift` | Push notification permission toggle |
| `CardShape` | `Misc/CardShape.swift` | Rounded rectangle with per-corner radius |
| `ActionManager` | `Modifier/ActionModifier.swift` | Singleton for sending toasts/dialogs/sheets/alerts |
| `ActionType` | `Modifier/ActionModifier.swift` | Enum: `.toast`, `.dialog`, `.sheet`, `.alert`, `.idle` |
| `.actionState()` | `Modifier/ActionModifier.swift` | Root view modifier — required for ActionManager to work |
| `ProjectTrait` | `Theme/Theme+UITraitDefinition.swift` | UITraitDefinition for project styling |

## Dependencies

### Internal
- **SnabbleAssetProviding** – `Asset` protocol for localized strings and images
- **SnabbleCore** – `Project` model for the trait system

### External
- **WindowKit** – Window management for dialog presentation

## Migration Notes

### Circular Dependency Resolution (2026-03-27)

The `Project+Trait.swift` extension was moved from Core to Components to correct the dependency direction:

```
Before: Core → SnabbleComponents (circular)
After:  Components → SnabbleCore (correct)
```

No impact on SDK consumers.

## See Also

- [SnabbleTheme](../Theme/README.md) – Theme and asset management
- [SnabblePayment](../Payment/README.md) – Uses Components
- [SnabbleScanAndGo](../ScanAndGo/README.md) – Uses Components
