# SnabbleCoupons

**Layer:** 3 (Domain Features)
**Status:** Active
**Dependencies:** SnabbleCore, SnabbleAssetProviding, SnabbleComponents

## Overview

SnabbleCoupons provides SwiftUI views for displaying, activating, and deactivating promotional coupons. It renders a horizontal card carousel as an overview and a detail screen for individual coupons. Activation state is persisted through `Snabble.shared.couponManager`.

## Entry Points

```swift
import SnabbleCoupons

// Horizontal card carousel — host is responsible for providing coupons and handling taps
CouponsView(coupons: project.coupons) { coupon in
    // navigate to CouponView
}

// Detail view for a single coupon
CouponView(coupon: coupon) { coupon in
    // return true to allow activation
    return true
}
```

## Key Components

### Views

| View | Purpose |
|------|---------|
| `CouponsView` | Horizontal `LazyHStack` of `CouponCardView` cards; shows an empty-state message when the list is empty |
| `CouponCardView` | Card thumbnail: remote image, title, subtitle, promotion text, expiry, and "new" badge |
| `CouponView` | Full-screen detail: large image, all text fields, validity, and activate/deactivate button |

### CouponViewModel

`@Observable @MainActor` class driving both card and detail views:

| Property / Method | Purpose |
|-------------------|---------|
| `title`, `subtitle`, `text`, `disclaimer` | Display strings from `Coupon` |
| `validUntil` | Localised expiry string ("expires on …" / "valid indefinitely" / "expired") |
| `isNew` | `true` when `validFrom` is within the last 72 hours |
| `isActivated` | Observable activation state, reflects `Coupon.isActivated` |
| `activateCoupon()` / `deactivateCoupon()` | Toggle activation via `Snabble.shared.couponManager` |
| `toggleActivation()` | Convenience wrapper |
| `loadImage(completion:)` | Async image download into `self.image` |

The optional `shouldActivateCoupon` closure allows the host to gate activation (e.g. show a login prompt before activating).

### Coupon+Validation

Extension on `SnabbleCore.Coupon` that adds a computed `isValid: Bool` property based on the current date and the coupon's `validFrom`/`validUntil` range.

## Activation Flow

```
CouponsView
    └─ tap → CouponView
            ├─ shouldActivateCoupon?(coupon) → true
            │       └─ couponManager.activate → isActivated = true
            └─ shouldActivateCoupon?(coupon) → false
                    └─ no state change (host handles e.g. auth)
```

When `shouldActivateCoupon` is `nil`, activation is always allowed.

## Dependencies

| Module | Role |
|--------|------|
| `SnabbleCore` | `Coupon` model, `Snabble.shared.couponManager` |
| `SnabbleAssetProviding` | Localised strings |
| `SnabbleComponents` | `cardStyle()` modifier, `ProjectPrimaryButtonStyle` |
