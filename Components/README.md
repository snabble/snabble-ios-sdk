# SnabbleComponents

**Layer:** 2 (UI Primitives)
**Status:** Active
**Dependencies:** SnabbleAssetProviding, WindowKit, SnabbleCore

## Overview

SnabbleComponents provides reusable SwiftUI UI primitives and components for the Snabble iOS SDK. These are the building blocks used by higher-level modules like ScanAndGo, Payment, and other feature modules.

**Architecture Note:** Components depends on Core (since 2026-03-27 circular dependency resolution) for project trait mapping.

## Purpose

- Reusable SwiftUI components
- Consistent UI design system
- Common UI patterns (buttons, dialogs, toasts)
- Web views and browser integration
- User notification toggles
- Project-specific UI traits

## Public API

### Buttons

```swift
import SnabbleComponents

// Primary button
PrimaryButton("Continue") {
    // Action
}

// Secondary button
SecondaryButton("Cancel") {
    // Action
}

// Icon button
IconButton(systemImage: "plus") {
    // Action
}
```

### Dialogs

```swift
import SnabbleComponents

// Alert dialog
.alert("Title", isPresented: $showAlert) {
    Button("OK") { }
    Button("Cancel", role: .cancel) { }
} message: {
    Text("Message text")
}

// Confirmation dialog
.confirmationDialog("Delete item?", isPresented: $showConfirmation) {
    Button("Delete", role: .destructive) {
        deleteItem()
    }
    Button("Cancel", role: .cancel) { }
}
```

### Toast Notifications

```swift
import SnabbleComponents

// Show toast
ToastView(message: "Item added to cart")
    .toast(isPresented: $showToast)

// Success toast
ToastView(message: "Success!", style: .success)
    .toast(isPresented: $showSuccess)

// Error toast
ToastView(message: "Error occurred", style: .error)
    .toast(isPresented: $showError)
```

### Web Views

```swift
import SnabbleComponents

// Simple web view
WebView(url: URL(string: "https://snabble.io")!)

// In-app browser
InAppBrowserView(url: URL(string: "https://snabble.io")!)
    .toolbar {
        // Browser controls included
    }
```

## Key Components

### 1. Buttons
- `PrimaryButton` - Main action button
- `SecondaryButton` - Secondary action button
- `IconButton` - Icon-only button
- `TextButton` - Text-only button
- Consistent styling across SDK

### 2. Dialogs & Sheets
- `AlertDialog` - Standard alerts
- `ConfirmationDialog` - Action sheets
- `BottomSheet` - Bottom sheet modals
- `FullScreenModal` - Full-screen modals

### 3. Notifications
- `ToastView` - Temporary messages
- `BannerView` - Persistent banners
- `UserNotificationToggle` - Permission toggle
- Auto-dismiss support

### 4. Web Integration
- `WebView` - Basic WKWebView wrapper
- `InAppBrowserView` - Full browser with controls
- `HTMLContentView` - Render HTML strings
- Navigation controls
- Progress indicators

### 5. UI Traits
- `Project` trait - Project-specific styling
- Environment-based configuration
- Theme integration

## Architecture

```
SnabbleComponents (Layer 2)
    ├── Buttons
    │   ├── PrimaryButton
    │   ├── SecondaryButton
    │   └── IconButton
    ├── Dialogs
    │   ├── AlertDialog
    │   └── ConfirmationDialog
    ├── Notifications
    │   ├── ToastView
    │   └── BannerView
    ├── Web
    │   ├── WebView
    │   └── InAppBrowserView
    ├── Utilities
    │   ├── AsyncContentView
    │   └── LoadingView
    └── Traits
        └── Project (UI trait system)
```

## Dependencies

### Internal
- **SnabbleAssetProviding**: Asset protocol definitions
- **SnabbleCore**: Project model for traits
- **WindowKit**: Window management utilities

### External
- **SwiftUI**: UI framework
- **WebKit**: WKWebView for web content

## Usage

### Button Styles

```swift
import SnabbleComponents

struct CheckoutView: View {
    var body: some View {
        VStack(spacing: 16) {
            // Primary action
            PrimaryButton("Checkout") {
                startCheckout()
            }
            .disabled(cart.isEmpty)

            // Secondary action
            SecondaryButton("Add More Items") {
                dismissCheckout()
            }

            // Text-only link
            TextButton("Cancel") {
                cancel()
            }
        }
    }
}
```

### Toast Notifications

```swift
import SnabbleComponents

struct CartView: View {
    @State private var showToast = false
    @State private var toastMessage = ""

    var body: some View {
        VStack {
            List {
                // Cart items
            }

            PrimaryButton("Add Item") {
                addItem()
                toastMessage = "Item added"
                showToast = true
            }
        }
        .toast(message: toastMessage, isPresented: $showToast)
    }
}
```

### Web Content

```swift
import SnabbleComponents

struct TermsView: View {
    let termsURL = URL(string: "https://snabble.io/terms")!

    var body: some View {
        NavigationView {
            InAppBrowserView(url: termsURL)
                .navigationTitle("Terms & Conditions")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// Or render HTML directly
struct HTMLTermsView: View {
    let htmlContent = """
    <h1>Terms & Conditions</h1>
    <p>Content here...</p>
    """

    var body: some View {
        HTMLContentView(html: htmlContent)
    }
}
```

### User Notification Permission

```swift
import SnabbleComponents

struct SettingsView: View {
    var body: some View {
        List {
            Section("Notifications") {
                UserNotificationToggle()
            }
        }
    }
}
```

### Async Content Loading

```swift
import SnabbleComponents

struct ProductDetailView: View {
    @State private var product: Product?
    @State private var isLoading = true

    var body: some View {
        AsyncContentView(isLoading: isLoading) {
            if let product {
                ProductDetails(product: product)
            } else {
                Text("Product not found")
            }
        }
        .task {
            await loadProduct()
        }
    }

    func loadProduct() async {
        isLoading = true
        product = await fetchProduct()
        isLoading = false
    }
}
```

## Project Traits

Components provides a trait system for project-specific styling:

### Usage

```swift
import SnabbleComponents
import SnabbleCore

struct ShoppingView: View {
    let project: SnabbleCore.Project

    var body: some View {
        VStack {
            Text("Shopping")
        }
        .trait(project.trait)  // Apply project-specific styling
    }
}
```

### Implementation

The trait extension is in `Components/Sources/Extensions/Project+Trait.swift`:

```swift
extension SnabbleCore.Project {
    public var trait: SnabbleComponents.Project {
        .project(id: id.rawValue)
    }
}
```

**Note:** This extension was moved from Core to Components on 2026-03-27 to resolve circular dependencies.

## Customization

### Custom Button Styles

```swift
import SnabbleComponents

// Extend button styles
extension PrimaryButton {
    func withCustomStyle() -> some View {
        self
            .font(.headline)
            .padding()
            .background(Color.customPrimary)
            .cornerRadius(12)
    }
}
```

### Custom Toast Appearance

```swift
import SnabbleComponents

// Custom toast
struct CustomToastView: View {
    let message: String

    var body: some View {
        Text(message)
            .padding()
            .background(Color.black.opacity(0.8))
            .foregroundColor(.white)
            .cornerRadius(10)
            .shadow(radius: 10)
    }
}
```

## Accessibility

All components support:
- **VoiceOver**: Proper labels and hints
- **Dynamic Type**: Scalable text
- **High Contrast**: Accessible colors
- **Reduced Motion**: Respects animation preferences

### Example

```swift
PrimaryButton("Checkout") {
    checkout()
}
.accessibilityLabel("Proceed to checkout")
.accessibilityHint("Double tap to start checkout process")
```

## Testing

Components are tested through:
- SwiftUI Previews
- Integration tests in example app
- Manual QA

### SwiftUI Previews

```swift
#Preview {
    VStack(spacing: 20) {
        PrimaryButton("Primary") { }
        SecondaryButton("Secondary") { }
        IconButton(systemImage: "plus") { }
    }
    .padding()
}
```

## Migration Notes

### Circular Dependency Resolution (2026-03-27)

The `Project+Trait.swift` extension was moved from Core to Components:

**Before:**
```
Core/Sources/Utilities/Project+Trait.swift
  import SnabbleComponents  // Caused circular dependency
```

**After:**
```
Components/Sources/Extensions/Project+Trait.swift
  import SnabbleCore  // Correct dependency direction
```

**Impact:** None for SDK consumers. Internal architecture improvement only.

## Best Practices

### 1. Use Semantic Components

```swift
// ✅ Good - semantic meaning
PrimaryButton("Checkout") { }
SecondaryButton("Cancel") { }

// ❌ Avoid - styling-based naming
BlueButton("Checkout") { }
GrayButton("Cancel") { }
```

### 2. Consistent Spacing

```swift
// ✅ Good - consistent padding
VStack(spacing: 16) {
    PrimaryButton("Action 1") { }
    SecondaryButton("Action 2") { }
}

// ❌ Avoid - arbitrary spacing
VStack(spacing: 7) { }
```

### 3. Accessibility Labels

```swift
// ✅ Good - descriptive labels
IconButton(systemImage: "plus") { }
    .accessibilityLabel("Add item")

// ❌ Avoid - no label
IconButton(systemImage: "plus") { }
```

## See Also

- [SnabbleTheme](../Theme/README.md) - Theme and asset management
- [SnabbleScanAndGo](../ScanAndGo/README.md) - Uses Components
- [SnabblePayment](../Payment/README.md) - Uses Components
- [SDK Architecture Guide](../documentation/SDK-Architecture.md)
- [Circular Dependencies Analysis](../documentation/Circular-Dependencies-Analysis.md)
