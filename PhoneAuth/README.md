# SnabblePhoneAuth

**Layer:** 5 (Complete Flows)
**Status:** Active
**Dependencies:** SnabbleNetwork, SnabbleUser, SnabbleAssetProviding, SnabbleComponents

## Overview

SnabblePhoneAuth implements phone-number-based authentication using a two-step OTP (one-time password) flow. It provides both the network layer (`PhoneAuthProviding`) and the SwiftUI views for entering a phone number and verifying the OTP code. The same views support two contexts: initial sign-in and changing an existing phone number.

## Entry Points

```swift
import SnabblePhoneAuth

// Step 1 — phone number input (initial sign-in)
NumberView(kind: .initial) { phoneNumber in
    // phoneNumber is non-nil on success; push to CodeView
}

// Step 1 — change existing phone number
NumberView(kind: .management) { phoneNumber in
    // ...
}

// Step 2 — OTP verification
CodeView(kind: .initial, phoneNumber: phoneNumber) { appUser in
    // appUser is non-nil on successful sign-in
}
```

Both views expect a `NetworkManager` instance in the SwiftUI environment:

```swift
ContentView()
    .environment(networkManager)
```

## PhoneAuthKind

| Case | Context |
|------|---------|
| `.initial` | First-time sign-in: sends OTP and signs the user in |
| `.management` | Account management: sends OTP and changes the stored phone number |

## Key Components

### Views

| View | Purpose |
|------|---------|
| `NumberView` | Phone number input with country dialling-code picker and submit button |
| `CodeView` | OTP input with 6-digit field, verify button, and resend option |
| `ProgressButtonView` | Primary button that switches to an activity indicator while a request is in flight |
| `LockedButtonView` | Button that becomes locked after tapping (used for resend-OTP cooldown) |

`NumberView` accepts optional generic `Header` and `Footer` view builders for custom branding:

```swift
NumberView(kind: .initial, header: {
    Image("my-logo").resizable().scaledToFit()
}) { phoneNumber in
    // ...
}
```

### PhoneAuthProviding

`NetworkManager` is extended to conform to `PhoneAuthProviding`:

```swift
public protocol PhoneAuthProviding {
    func startAuthorization(phoneNumber: String) async throws -> String
    func signIn(phoneNumber: String, OTP: String) async throws -> AppUser?
    func changePhoneNumber(phoneNumber: String, OTP: String) async throws -> AppUser?
    func delete(phoneNumber: String) async throws
}
```

All methods are `async throws` and can be called directly when building a custom flow.

## Typical Navigation Flow

```
NumberView (.initial)
    └─ on success → CodeView (.initial, phoneNumber: ...)
            └─ on success → dismiss / continue app flow
```

For phone-number changes in account management:

```
NumberView (.management)
    └─ on success → CodeView (.management, phoneNumber: ...)
            └─ on success → dismiss settings sheet
```

## Dependencies

| Module | Role |
|--------|------|
| `SnabbleNetwork` | `NetworkManager` and `PhoneAuthProviding` implementation |
| `SnabbleUser` | `AppUser` model returned after sign-in |
| `SnabbleAssetProviding` | Localised strings, `CallingCode` country list |
| `SnabbleComponents` | `CountryCallingCodeView`, button styles |
