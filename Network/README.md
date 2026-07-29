# SnabbleNetwork

**Layer:** 1 (Foundation)
**Status:** Active
**Dependencies:** SwiftOTP, KeychainAccess

## Overview

SnabbleNetwork provides the typed HTTP networking layer for the Snabble iOS SDK. It handles authentication (token management, AppUser), endpoint definition, and request execution via `async/await`.

## Purpose

- Typed `Endpoint<Response>` for all API calls
- `NetworkManager` for authenticated request execution
- `AppUser` model and keychain persistence
- `Configuration` for app credentials and environment
- `Configurable` protocol for dependency injection

## Public API

### NetworkManager

`NetworkManager` is the central class for executing API requests. It handles token acquisition, injection, and automatic retry on 401/403:

```swift
import SnabbleNetwork

let config = Configuration(
    appId: "my-app-id",
    appSecret: "my-app-secret",
    domain: .production
)

let networkManager = NetworkManager(configuration: config)
networkManager.delegate = self

// Execute a typed endpoint
let appUser = try await networkManager.publisher(for: Endpoints.AppUser.create(config))
```

### NetworkManagerDelegate

```swift
extension MyClass: NetworkManagerDelegate {
    func networkManager(_ networkManager: NetworkManager,
                        appUserForConfiguration configuration: Configuration) -> AppUser? {
        // Return stored AppUser for authentication
        return AppUser.get(forConfig: configuration)
    }

    func networkManager(_ networkManager: NetworkManager,
                        appUserUpdated appUser: AppUser) {
        // Persist the updated AppUser
        AppUser.set(appUser, forConfig: networkManager.configuration)
    }

    func networkManager(_ networkManager: NetworkManager,
                        projectIdForConfiguration configuration: Configuration) -> String? {
        return configuration.projectId
    }
}
```

### Endpoint

`Endpoint<Response>` is a typed value that describes a single API request:

```swift
public struct Endpoint<Response> {
    public let method: HTTPMethod
    public let path: String
    public let parse: (Data) throws -> Response

    // Build via predefined factories in Endpoints namespace
}
```

Predefined endpoint factories are grouped in the `Endpoints` namespace as extensions:
- `Endpoints.AppUser.*` – AppUser registration and retrieval
- `Endpoints.Token.*` – Authentication token management
- `Endpoints.Order.*` – Order history
- `Endpoints.Phone.*` – Phone number verification
- `Endpoints.Notification.*` – Push notification registration

### Configuration

```swift
import SnabbleNetwork

let config = Configuration(
    appId: "my-app-id",
    appSecret: "my-app-secret",
    domain: .production,        // or .staging, .testing
    projectId: "my-project-id" // optional
)
```

### AppUser

```swift
import SnabbleNetwork

// Create
let appUser = AppUser(id: "user-123", secret: "secret-456")

// Store securely in Keychain
AppUser.set(appUser, forConfig: config)

// Retrieve from Keychain
if let appUser = AppUser.get(forConfig: config) {
    print(appUser.id)
}

// Remove (logout)
AppUser.set(nil, forConfig: config)

// Parse from string representation ("id:secret")
let appUser = AppUser(stringRepresentation: "user-123:secret-456")
```

AppUser is stored per-config in the Keychain under key `Snabble.api.appUserId.{domainName}.{appId}`.

### Configurable Protocol

```swift
public protocol Configurable {
    var appId: String { get }
    var domainName: String { get }
}

// Configuration conforms to Configurable
// SnabbleCore.Config also conforms to Configurable via extension
```

### Error Handling

```swift
import SnabbleNetwork

do {
    let response = try await networkManager.publisher(for: endpoint)
} catch let HTTPError.invalid(response, clientError) {
    // HTTP error with status code
    print(response.statusCode, clientError?.message ?? "")
} catch HTTPError.unknown(let response) {
    // Non-HTTP response
} catch HTTPError.unexpected(let error) {
    // Underlying URLSession error
}
```

## Key Components

| Type | Description |
|---|---|
| `NetworkManager` | `@Observable @MainActor` class for executing authenticated requests |
| `NetworkManagerDelegate` | Delegate for AppUser provisioning and update callbacks |
| `Endpoint<Response>` | Typed endpoint descriptor (path, method, parser) |
| `Endpoints` | Namespace for predefined endpoint factories |
| `Configuration` | App credentials + environment (`appId`, `appSecret`, `domain`) |
| `Configurable` | Protocol for config injection into `AppUser` storage |
| `AppUser` | User credentials (`id` + `secret`) with Keychain persistence |
| `HTTPError` | Error type: `.invalid`, `.unknown`, `.unexpected` |
| `HTTPMethod` | `.get`, `.post`, `.put`, `.patch`, `.delete` |
| `Domain` | API environment (production, staging, testing) |
| `Token` | Auth bearer token |

## Dependencies

### External
- **SwiftOTP** – TOTP-based request signing
- **KeychainAccess** – Secure AppUser storage

## Security Notes

- Never log `AppUser.secret`
- AppUser survives app uninstallation (Keychain persistence)
- Token is injected per-request and never stored long-term
- 401/403 responses automatically trigger token refresh before retry

## Migration Notes

### Circular Dependency Resolution (2026-03-27)

`Configurable` was extracted from Core to Network so that Network has no dependency on Core. Core's `Config` type now conforms to `Configurable` via extension.

## See Also

- [SnabbleCore](../Core/README.md) – Uses NetworkManager for all API calls
- [SnabbleUser](../User/README.md) – Provides `Snabble.appUser` via AppUser
