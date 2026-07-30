# SnabbleOnboarding

**Layer:** 5 (Complete Flows)
**Status:** Active
**Dependencies:** SnabbleComponents, SnabbleTheme

## Overview

SnabbleOnboarding provides a paged onboarding experience that walks users through a series of informational screens. It supports both SwiftUI and UIKit presentation, persists completion state to `UserDefaults`, and is fully configurable via a `Codable` view model — making it easy to load from a JSON file or a remote configuration.

## Entry Points

### SwiftUI

```swift
import SnabbleOnboarding

let viewModel = OnboardingViewModel(
    configuration: OnboardingConfiguration(imageSource: "logo"),
    items: [
        OnboardingItem(imageSource: "onboarding-1", text: "Welcome to snabble!"),
        OnboardingItem(imageSource: "onboarding-2", text: "Scan products with your phone."),
        OnboardingItem(text: "Pay quickly at self-checkout.", customButtonTitle: "Get started"),
    ]
)

// Observe completion
onChange(of: viewModel.isDone) { done in
    if done { dismiss() }
}

OnboardingView(viewModel: viewModel)
```

### UIKit (modal)

```swift
let vc = OnboardingViewController(viewModel: viewModel)
vc.delegate = self
present(vc, animated: true)

// OnboardingViewControllerDelegate
func onboardingViewControllerDidFinish(_ viewController: OnboardingViewController) {
    viewController.dismiss(animated: true)
}
```

`OnboardingViewController` sets `isModalInPresentation = true` by default, preventing accidental dismissal by swipe.

### JSON / Codable

`OnboardingViewModel` and `OnboardingItem` both conform to `Codable`:

```swift
let viewModel = try JSONDecoder().decode(OnboardingViewModel.self, from: data)
```

## Checking whether onboarding is needed

```swift
if Onboarding.isRequired {
    // show onboarding
}
```

`Onboarding.isRequired` returns `true` until `OnboardingViewModel.isDone` is set to `true`, which writes a flag to `UserDefaults` under `io.snabble.onboarding.wasPerformed`.

## Key Components

### Model

| Type | Purpose |
|------|---------|
| `OnboardingViewModel` | `@Observable` root model; tracks `currentPage`, `isDone`, and `item`; drives page navigation |
| `OnboardingItem` | Single onboarding page: `imageSource`, `text` (Markdown supported), optional `customButtonTitle` and `link` |
| `OnboardingConfiguration` | Optional logo `imageSource` shown in the header above the page carousel |
| `Onboarding` | Namespace; provides `isRequired: Bool` and the private `wasPerformed()` setter |

### Views

| View | Purpose |
|------|---------|
| `OnboardingView` | Root layout: header logo → `PageViewController` + `PageControl` → button row |
| `OnboardingItemView` | Renders a single `OnboardingItem`: image and Markdown-attributed text |
| `OnboardingButtonView` | "Next" button (or custom label on the last page); tapping advances the page or sets `isDone = true` |
| `OnboardingViewController` | `UIHostingController<OnboardingView>` for UIKit modal presentation; notifies delegate via `OnboardingViewControllerDelegate` |

### OnboardingItem.attributedString

`OnboardingItem.text` is rendered as Markdown using `AttributedString(markdown:)`, so items can include inline links:

```swift
OnboardingItem(text: "Read our [Privacy Policy](https://example.com/privacy).")
```

## Architecture

```
SnabbleOnboarding (Layer 3)
    ├── OnboardingViewController    (UIKit modal entry point)
    │   └── OnboardingView          (SwiftUI root)
    │       ├── PageViewController  (UIPageViewController wrapper)
    │       │   └── OnboardingItemView  (per-page content)
    │       ├── PageControl         (dot indicator)
    │       └── OnboardingButtonView (next / finish)
    └── OnboardingViewModel         (@Observable — shared state)
        ├── OnboardingConfiguration  (header logo)
        └── OnboardingItem[]         (page content)
```

## Dependencies

| Module | Role |
|--------|------|
| `SnabbleComponents` | `PageViewController`, `PageControl` |
| `SnabbleTheme` | `ImageSourcing` protocol used by `OnboardingConfiguration` and `OnboardingItem` |
