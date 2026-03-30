# Payment Methods - SwiftUI Migration

This directory contains both UIKit (legacy) and SwiftUI implementations for payment method management.

## Architecture Overview

### Business Logic (Shared)
- **`Models/PaymentMethodListManager.swift`** - `@Observable` model managing payment data
  - Loads payment groups for a project
  - Manages project/brand entries
  - Handles payment method counting and removal
  - Swift 6.2 compatible with `@MainActor` isolation

### SwiftUI Views (Modern)
- **`Views/PaymentMethodListView.swift`** - List of payment methods for a specific project
- **`Views/ProjectSelectionView.swift`** - Project/brand selection for multi-project scenarios

### UIKit Views (Legacy - Maintained for compatibility)
- **`PaymentMethodListViewController.swift`** - UIKit version of payment list
- **`PaymentMethodAddViewController.swift`** - UIKit version of project selection
- **`*EditViewController.swift`** - Payment method edit screens (SEPA, Credit Card, etc.)

## Usage

### SwiftUI Usage

#### 1. Show Payment Methods for a Single Project

```swift
import SnabbleTheme

// In your SwiftUI view
PaymentMethodListView(
    projectId: project.id,
    analyticsDelegate: myAnalyticsDelegate
)
```

#### 2. Show Project Selection (Multi-Project)

```swift
// Complete navigation flow
PaymentMethodProjectNavigationView(analyticsDelegate: myAnalyticsDelegate)

// Or integrate into existing NavigationStack
NavigationStack {
    ProjectSelectionList(analyticsDelegate: myAnalyticsDelegate)
}

// Brand-specific selection
ProjectSelectionList(
    brandId: brand.id,
    analyticsDelegate: myAnalyticsDelegate
)
```

#### 3. Example Integration in App

```swift
struct ProfileView: View {
    let project: Project?

    var body: some View {
        NavigationStack {
            List {
                if let project {
                    NavigationLink {
                        PaymentMethodListView(
                            projectId: project.id,
                            analyticsDelegate: nil
                        )
                    } label: {
                        Label("Payment Methods", systemImage: "creditcard")
                    }
                }
            }
        }
    }
}
```

### UIKit Usage (Legacy)

```swift
// Single project
let listVC = PaymentMethodListViewController(for: projectId, analyticsDelegate)
navigationController?.pushViewController(listVC, animated: true)

// Multi-project selection
let addVC = PaymentMethodAddViewController(analyticsDelegate)
navigationController?.pushViewController(addVC, animated: true)

// Brand-specific
let brandVC = PaymentMethodAddViewController(brandId: brandId, analyticsDelegate)
navigationController?.pushViewController(brandVC, animated: true)
```

## Features

### ✅ Implemented in SwiftUI
- Payment method list display
- Add payment method sheet
- Project/brand selection
- Payment method deletion
- Empty state
- Analytics tracking
- Navigation between projects and payment methods

### 🚧 Pending (Still UIKit-based)
- Individual payment method edit screens:
  - SEPA edit
  - Credit card edit (TeleCash, Payone, Datatrans)
  - Giropay edit
  - Invoice login
  - Payment subject edit

These edit screens are still accessed through UIKit `editViewController(with:_:)` methods on `RawPaymentMethod`.

## Migration Path

### Phase 1: Business Logic (✅ Complete)
- Extract business logic into `@Observable` models
- Ensure compatibility with both UIKit and SwiftUI

### Phase 2: List Views (✅ Complete)
- `PaymentMethodListView` - SwiftUI list of payment methods
- `ProjectSelectionView` - SwiftUI project/brand selection

### Phase 3: Edit Views (Future)
- Migrate individual edit screens to SwiftUI
- Create SwiftUI equivalents for:
  - `SepaDataEditViewController` → `SepaDataEditView`
  - `PayoneCreditCardEditViewController` → `PayoneCreditCardEditView`
  - etc.

### Phase 4: Full SwiftUI Flow (Future)
- Complete end-to-end SwiftUI navigation
- Remove UIKit dependencies

## Key Design Decisions

### 1. Separation of Concerns
Business logic (Manager) is separated from UI (View), allowing both UIKit and SwiftUI to use the same data layer.

### 2. Swift 6.2 Compatibility
- Uses `@Observable` macro (not `ObservableObject`)
- `@MainActor` isolation for UI-related code
- Proper `Swift.Identifiable` vs `SnabbleCore.Identifiable` disambiguation

### 3. Backwards Compatibility
Legacy UIKit code remains functional and can coexist with new SwiftUI code.

### 4. Gradual Migration
New code uses SwiftUI while maintaining UIKit for complex edit screens until they can be migrated.

## Testing

```swift
// Preview SwiftUI views
#Preview {
    NavigationStack {
        PaymentMethodListView(
            projectId: Identifier<Project>(rawValue: "test")
        )
    }
}

#Preview("Project Selection") {
    PaymentMethodProjectNavigationView()
}
```

## Analytics

Both UIKit and SwiftUI implementations support `AnalyticsDelegate`:

```swift
extension AnalyticsEvent {
    static let viewPaymentMethodList: AnalyticsEvent
}
```

Tracked automatically when views appear.
