# SnabbleNetwork

**Layer:** 1 (Foundation)
**Status:** Active
**Dependencies:** None (Foundation only)

## Overview

SnabbleNetwork provides the API communication layer for the Snabble iOS SDK. It handles HTTP requests, authentication, error handling, and data models for network responses.

## Purpose

- HTTP request/response handling
- API authentication and token management
- Network error handling and retry logic
- Data models for API responses
- AppUser management (keychain storage)

## Public API

### Basic Request

```swift
import SnabbleNetwork

// Perform GET request
let request = URLRequest(url: apiURL)
SnabbleAPI.request(request) { (result: Result<MyModel, SnabbleError>) in
    switch result {
    case .success(let data):
        print("Success: \(data)")
    case .failure(let error):
        print("Error: \(error)")
    }
}
```

### AppUser Management

```swift
import SnabbleNetwork

// Create app user
let appUser = AppUser(id: "user-123", secret: "secret-456")

// Store in keychain
AppUser.set(appUser, forConfig: config)

// Retrieve from keychain
if let appUser = AppUser.get(forConfig: config) {
    print("AppUser: \(appUser.id)")
}

// Remove
AppUser.set(nil, forConfig: config)
```

### Configurable Protocol

```swift
import SnabbleNetwork

// Any type can conform to Configurable
extension MyConfig: Configurable {
    var appId: String { "my-app-id" }
    var domainName: String { "production" }
}
```

## Key Components

### 1. API Client
- HTTP request construction
- Response parsing
- Error mapping
- Retry logic

### 2. AppUser
- User identification model
- Keychain persistence
- Config-based storage keys
- String representation (id:secret format)

### 3. Error Handling
- `SnabbleError` enum
- HTTP status code mapping
- User-friendly error messages
- Retry strategies

### 4. Models
- `Configurable` protocol
- `AppUser` struct
- API response models

## Architecture

```
SnabbleNetwork (Layer 1)
    ├── API Layer
    │   ├── Request building
    │   ├── Response parsing
    │   └── Error handling
    ├── Authentication
    │   ├── Token management
    │   └── AppUser storage
    └── Models
        ├── Configurable protocol
        ├── AppUser
        └── SnabbleError
```

## Dependencies

### Internal
- None (Foundation layer)

### External
- **KeychainAccess**: Secure AppUser storage
- **Foundation**: URLSession, Codable

## AppUser Storage

AppUser credentials are stored securely in the Keychain:

```swift
// Storage format
Service: "io.snabble.sdk"
Key: "Snabble.api.appUserId.{domainName}.{appId}"
Value: "{userId}:{secret}"
```

**Security Notes:**
- Survives app uninstallation
- Protected by iOS Keychain encryption
- Per-config isolation (multi-tenant support)

## Error Handling

### SnabbleError Types

```swift
public enum SnabbleError {
    case networkError(Error)
    case invalidResponse
    case unauthorized
    case notFound
    case serverError(Int)
    case decodingError(Error)
    case clientError
    case empty
}
```

### Usage

```swift
SnabbleAPI.request(request) { (result: Result<Data, SnabbleError>) in
    switch result {
    case .success(let data):
        // Handle success

    case .failure(let error):
        switch error {
        case .unauthorized:
            // Show login screen
        case .networkError:
            // Show network error message
        case .serverError(let code):
            // Log server error
        default:
            // Handle other errors
        }
    }
}
```

## Configuration

### Configurable Protocol

The `Configurable` protocol allows any type to provide configuration for API requests:

```swift
public protocol Configurable {
    /// The appID assigned by Snabble
    var appId: String { get }

    /// The Snabble domain (environment)
    var domainName: String { get }
}
```

**Implementation in Core:**
```swift
// Core's Config conforms to Network's Configurable
extension Config: SnabbleNetwork.Configurable {
    // appId and domainName are already implemented
}
```

## Testing

```bash
# Run Network tests
xcodebuild -scheme SnabbleNetworkTests test
```

Test coverage includes:
- AppUser encoding/decoding
- Keychain storage/retrieval
- Config-based key generation
- Error handling

## Usage Examples

### Custom API Request

```swift
import SnabbleNetwork

struct MyResponse: Codable {
    let status: String
    let data: [String]
}

func fetchData(config: Configurable) {
    let url = URL(string: "https://api.snabble.io/my-endpoint")!
    var request = URLRequest(url: url)
    request.addValue(config.appId, forHTTPHeaderField: "Client-Id")

    SnabbleAPI.request(request) { (result: Result<MyResponse, SnabbleError>) in
        switch result {
        case .success(let response):
            print("Data: \(response.data)")
        case .failure(let error):
            print("Error: \(error)")
        }
    }
}
```

### AppUser Lifecycle

```swift
import SnabbleNetwork

// Login flow
func login(userId: String, secret: String, config: Configurable) {
    let appUser = AppUser(id: userId, secret: secret)
    AppUser.set(appUser, forConfig: config)

    // Use appUser for authenticated requests
    print("Logged in: \(appUser.id)")
}

// Logout flow
func logout(config: Configurable) {
    AppUser.set(nil, forConfig: config)
    print("Logged out")
}

// Check login status
func isLoggedIn(config: Configurable) -> Bool {
    return AppUser.get(forConfig: config) != nil
}
```

## Migration Notes

### Circular Dependency Resolution (2026-03-27)

Network previously depended on Core for the `Config` type. This was resolved by:

1. Extracting `Configurable` protocol to Network (no dependencies)
2. Making Core's `Config` conform to `Configurable` via extension
3. Using protocol instead of concrete type in Network APIs

See `documentation/Circular-Dependencies-Analysis.md` for details.

## Best Practices

### 1. Use Configurable Protocol
```swift
// Good: Accept protocol
func makeRequest(config: Configurable) { }

// Avoid: Depend on concrete Config type
func makeRequest(config: SnabbleCore.Config) { }
```

### 2. Handle All Error Cases
```swift
// Always handle all SnabbleError cases
switch error {
case .networkError: // No connection
case .unauthorized: // Invalid credentials
case .serverError: // Server issues
case .decodingError: // Invalid response format
default: // Unknown errors
}
```

### 3. Secure AppUser Storage
```swift
// Never log or expose AppUser secrets
let appUser = AppUser.get(forConfig: config)
print(appUser?.id) // OK
// print(appUser?.secret) // NEVER DO THIS
```

## See Also

- [SnabbleCore](../Core/README.md) - Uses Network for API calls
- [SnabbleUser](../User/README.md) - Uses AppUser for authentication
- [SDK Architecture Guide](../documentation/SDK-Architecture.md)
