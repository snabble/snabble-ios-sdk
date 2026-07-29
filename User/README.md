# SnabbleUser

**Layer:** 3 (Domain Features)
**Status:** Active
**Dependencies:** SnabbleCore, SnabbleNetwork, SnabbleComponents, SnabbleAssetProviding

## Overview

SnabbleUser provides user profile management and authentication integration for the Snabble iOS SDK. It adds the public `Snabble.clientId` and `Snabble.appUser` API to Core via extensions, and provides SwiftUI views for user profile editing, consent, and account management.

## Purpose

- Public `Snabble.clientId` and `Snabble.appUser` API
- User profile model (`User`) with name, email, phone, address, date of birth
- Configurable field selection via `UserField`
- SwiftUI views for profile editing and account management
- `UserProviding` protocol for dependency injection into other modules

## Public API

### Client ID

```swift
import SnabbleUser

// Stable device identifier — stored in Keychain, survives uninstallation
let clientId = Snabble.clientId
```

### AppUser (Login/Logout)

```swift
import SnabbleUser

// Login
Snabble.shared.appUser = AppUser(id: "user-123", secret: "secret-456")
// Side effects: token registry invalidated, order cache cleared

// Check login status
if let appUser = Snabble.shared.appUser {
    print("Logged in as \(appUser.id)")
}

// Logout
Snabble.shared.appUser = nil
```

### UserView

The primary SwiftUI view for editing a user profile. Fields and required fields are configurable:

```swift
import SnabbleUser

struct ProfileEditScreen: View {
    @State private var user: User?

    var body: some View {
        UserView(user: $user)
        // or with custom field selection:
        UserView(
            user: $user,
            fields: [.firstName, .lastName, .email, .phone],
            requiredFields: [.firstName, .lastName, .email]
        )
    }
}
```

Available fields (`UserField`): `.firstName`, `.lastName`, `.email`, `.phone`, `.dateOfBirth`, `.street`, `.zip`, `.city`, `.country`, `.state`

### UserProviding

Protocol for injecting user data into modules that don't directly depend on `SnabbleUser`:

```swift
import SnabbleUser

class MyUserProvider: UserProviding {
    func getUser() -> User? {
        // Return current user from your data layer
    }
}
```

### UserFieldProviding

Protocol for view controllers that accept user input with custom field sets:

```swift
import SnabbleUser

class MyRegistrationVC: UIViewController, UserInputConformance {
    static var defaultUserFields: [UserField] { [.firstName, .lastName, .email] }
    static var requiredUserFields: [UserField] { [.email] }

    func acceptUser(user: User) -> Bool {
        // Validate and save user
        return true
    }
}
```

## Key Components

| Component | File | Description |
|---|---|---|
| `Snabble.clientId` | `Extensions/Snabble+User.swift` | Static stable device identifier |
| `Snabble.shared.appUser` | `Extensions/Snabble+User.swift` | AppUser login/logout |
| `User` | `Model/User.swift` | User profile model |
| `UserField` | `Model/UserFields.swift` | Enum of all editable profile fields |
| `UserFieldProviding` | `Model/UserFields.swift` | Protocol for field configuration |
| `UserProviding` | `Utility/UserProviding.swift` | Protocol for user data injection |
| `UserView` | `Views/UserView.swift` | SwiftUI profile editing form |
| `UserProfileView` | `Views/UserProfileView.swift` | Read-only profile display |
| `UserConsentScreen` | `Views/UserConsentScreen.swift` | GDPR consent flow |
| `UserNotLoggedInView` | `Views/UserNotLoggedInView.swift` | Placeholder when not authenticated |
| `UserAccountDeletedScreen` | `Views/UserAccountDeletedScreen.swift` | Post-deletion confirmation |
| `UserDeleteButton` | `Component/UserDeleteButton.swift` | Account deletion action |
| `UserViewController` | `Views/UserViewController.swift` | UIKit wrapper |

## Architecture

```
SnabbleUser (Layer 3)
    ├── Extensions
    │   └── Snabble+User.swift     — adds clientId + appUser to Snabble
    ├── Model
    │   ├── User                   — profile data model
    │   ├── UserField              — configurable field enum
    │   └── UserFieldProviding     — protocol for field selection
    ├── SwiftUI Views
    │   ├── UserView               — profile editing form
    │   ├── UserProfileView        — read-only display
    │   ├── UserConsentScreen      — consent/GDPR
    │   ├── UserNotLoggedInView
    │   ├── UserAccountDeletedScreen
    │   └── UserFallBackView
    ├── Components
    │   └── UserDeleteButton
    └── Utility
        └── UserProviding          — protocol for injecting User into other modules
```

## Dependencies

### Internal
- **SnabbleCore** – `Snabble`, `Client`, `UserProviding` (type-erased base)
- **SnabbleNetwork** – `AppUser`, `Configurable`
- **SnabbleComponents** – `PrimaryButtonView`, `CountryCallingCodeView`, `CountryButtonView`
- **SnabbleAssetProviding** – `Asset` for localized strings

## Circular Dependency Resolution (2026-03-27)

`Snabble.clientId` and `Snabble.appUser` were moved from Core to User to break a circular dependency:

- **Before:** Core exposed `clientId`/`appUser` → required User types → circular
- **After:** User adds these via `extension Snabble` → correct one-way dependency

No breaking changes for SDK consumers — the API is identical.

## See Also

- [SnabbleCore](../Core/README.md) – Client and internal token management
- [SnabbleNetwork](../Network/README.md) – AppUser model and Keychain storage
- [SnabblePayment](../Payment/README.md) – Uses UserProviding for payment flows
