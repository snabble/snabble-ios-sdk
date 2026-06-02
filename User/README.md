# SnabbleUser

**Layer:** 3 (Domain Features)
**Status:** Active
**Dependencies:** SnabbleCore, SnabbleNetwork

## Overview

SnabbleUser provides user management and authentication functionality for the Snabble iOS SDK. It handles user profiles, consent management, and provides the public API for client ID and app user access.

**Architecture Note:** User provides the **public API** for `Snabble.clientId` and `Snabble.appUser` via extensions (resolved circular dependency on 2026-03-27).

## Purpose

- User profile management
- Client ID generation and storage
- AppUser authentication
- Consent management (GDPR)
- User data fields (name, email, etc.)
- User deletion workflows

## Public API

### Client ID

```swift
import SnabbleUser

// Get stable client ID (device identifier)
let clientId = Snabble.clientId
// Stored in Keychain, survives app uninstallation
```

### AppUser

```swift
import SnabbleUser

// Set app user
Snabble.shared.appUser = AppUser(id: "user-123", secret: "secret-456")

// Get app user
if let appUser = Snabble.shared.appUser {
    print("Logged in as: \(appUser.id)")
}

// Logout
Snabble.shared.appUser = nil
```

### User Management

```swift
import SnabbleUser

// Create user
let user = User(name: "John Doe", email: "john@example.com")

// Update user fields
user.name = "Jane Doe"
user.email = "jane@example.com"

// Delete user account
UserManager.deleteUser { success in
    if success {
        print("User deleted")
    }
}
```

## Key Components

### 1. Client ID
- **Location:** `Core/Sources/User/Client.swift` (moved from User on 2026-03-27)
- Stable device identifier
- Keychain storage
- Survives app uninstallation
- Used for analytics and tracking

### 2. AppUser API
- **Public API:** `User/Sources/Extensions/Snabble+User.swift`
- **Internal accessor:** `Core/Sources/API/Snabble+AppUser.swift`
- Authentication credentials
- Config-specific storage
- Automatic token invalidation on change

### 3. User Model
- User profile data (name, email, phone)
- Consent tracking
- User fields management
- GDPR compliance

### 4. User Providing
- **Protocol:** `Core/Sources/User/UserProviding.swift` (type-erased)
- **Implementation:** `User/Sources/Utility/UserProviding.swift`
- Dependency injection for user data
- Used by payment and other modules

## Architecture

```
SnabbleUser (Layer 3)
    ├── Public API Extensions
    │   ├── Snabble+User.swift (clientId, appUser)
    │   └── Config+Configurable.swift
    ├── User Management
    │   ├── User.swift (profile model)
    │   ├── UserFields.swift (data fields)
    │   └── UserManager.swift
    ├── UI Components (UIKit)
    │   ├── UserViewController
    │   ├── UserProfileView
    │   └── UserConsentScreen
    └── Protocols
        └── UserProviding (concrete User type)
```

## Dependencies

### Internal
- **SnabbleCore**: Business logic, Client type
- **SnabbleNetwork**: AppUser model, API calls

### External
- **KeychainAccess**: Secure credential storage

## Circular Dependency Resolution (2026-03-27)

User previously had a circular dependency with Core. This was resolved by:

### What Changed

1. **Client.swift moved to Core**
   - From: `User/Sources/Model/Client.swift`
   - To: `Core/Sources/User/Client.swift`
   - Reason: Core needs direct access for internal use

2. **Public API in User via Extension**
   - File: `User/Sources/Extensions/Snabble+User.swift`
   - Provides: `Snabble.clientId` and `Snabble.appUser`
   - Delegates to Core's internal implementation

3. **UserProviding Type Erasure**
   - Core version: Returns `Any?` (no User dependency)
   - User version: Returns `User?` (concrete type)
   - Protocol refinement pattern

### Impact

✅ **No breaking changes** for SDK consumers
✅ `Snabble.clientId` still works the same way
✅ `Snabble.appUser` still works the same way
✅ Clean layered architecture maintained

## Client ID Storage

```swift
// Storage location
Service: "io.snabble.sdk"
Key: "Snabble.api.clientId"

// Generation (if not exists)
UUID().uuidString.lowercased().replacingOccurrences(of: "-", with: "")
// Example: "a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6"
```

**Important:** Client ID survives app uninstallation per [Apple Developer Forums](https://developer.apple.com/forums/thread/36442?answerId=281900022#281900022)

## AppUser Lifecycle

### Login

```swift
import SnabbleUser

func login(userId: String, secret: String) {
    let appUser = AppUser(id: userId, secret: secret)
    Snabble.shared.appUser = appUser

    // Side effects (automatic):
    // - Token registry invalidated
    // - Order cache cleared
    // - New authentication token requested
}
```

### Logout

```swift
import SnabbleUser

func logout() {
    Snabble.shared.appUser = nil

    // Side effects (automatic):
    // - Token registry invalidated
    // - Order cache cleared
    // - Anonymous shopping available
}
```

### Check Login Status

```swift
import SnabbleUser

var isLoggedIn: Bool {
    return Snabble.shared.appUser != nil
}
```

## User Consent Management

```swift
import SnabbleUser

// Show consent screen
let consentVC = UserConsentViewController(
    onAccept: {
        print("User accepted terms")
    },
    onDecline: {
        print("User declined")
    }
)
present(consentVC, animated: true)

// Save consent
UserManager.saveConsent(version: "1.0") { success in
    print("Consent saved: \(success)")
}
```

## UserProviding Protocol

The `UserProviding` protocol allows other modules to access user data without depending on the concrete `User` type:

### Core Version (Type-Erased)

```swift
// In Core module
public protocol UserProviding: AnyObject {
    func getUser() -> Any?  // Type-erased
}
```

### User Version (Concrete)

```swift
// In User module
public protocol UserProviding: SnabbleCore.UserProviding {
    func getUser() -> User?  // Concrete User type
}
```

### Usage in Other Modules

```swift
// In Payment or other modules
let user = Snabble.shared.userProvider?.getUser()
// Cast to User if needed
```

## Testing

Test coverage includes:
- Client ID generation and persistence
- AppUser keychain storage
- User profile CRUD operations
- Consent tracking

## Usage Examples

### Complete User Flow

```swift
import SnabbleUser
import SnabbleCore

class UserManager {
    // Check if user has valid session
    func checkLoginStatus() -> Bool {
        return Snabble.shared.appUser != nil
    }

    // Login with credentials
    func login(email: String, password: String, completion: @escaping (Bool) -> Void) {
        // Call your auth API
        AuthAPI.login(email: email, password: password) { result in
            switch result {
            case .success(let credentials):
                // Store app user
                let appUser = AppUser(
                    id: credentials.userId,
                    secret: credentials.secret
                )
                Snabble.shared.appUser = appUser
                completion(true)

            case .failure:
                completion(false)
            }
        }
    }

    // Logout
    func logout() {
        Snabble.shared.appUser = nil
        // Clear local user data
        UserDefaults.standard.removeObject(forKey: "userData")
    }

    // Get stable device ID for analytics
    func getDeviceId() -> String {
        return Snabble.clientId
    }
}
```

### Custom User Provider

```swift
import SnabbleUser
import SnabbleCore

class MyUserProvider: UserProviding {
    func getUser() -> User? {
        // Fetch from your user management system
        return User(
            name: "John Doe",
            email: "john@example.com"
        )
    }
}

// Register provider
Snabble.shared.userProvider = MyUserProvider()
```

## Migration Notes

### From Pre-1.0.0 (Before Circular Dependency Fix)

**No code changes required!** The public API remains identical:

```swift
// Still works exactly the same
let clientId = Snabble.clientId
let appUser = Snabble.shared.appUser
```

**Internal changes** (only relevant if you modified Core internals):
- `Client.swift` is now in Core, not User
- Core has internal `appUser` accessor
- User provides public `appUser` via extension

## See Also

- [SnabbleCore](../Core/README.md) - Client and internal accessors
- [SnabbleNetwork](../Network/README.md) - AppUser model
- [SDK Architecture Guide](../documentation/SDK-Architecture.md)
- [Circular Dependencies Analysis](../documentation/Circular-Dependencies-Analysis.md)
