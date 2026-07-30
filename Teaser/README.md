# SnabbleTeaser

**Layer:** 5 (Complete Flows)
**Status:** Active
**Dependencies:** SnabbleCore, SnabbleTheme, SnabbleComponents, SnabbleAssetProviding

## Overview

SnabbleTeaser renders promotional content cards defined in a project's `CustomizationConfig`. It provides a paged horizontal scroll carousel with dot navigation for the overview and a detail screen that supports images and embedded YouTube videos. Teasers are loaded from the Snabble backend and images are fetched and cached per session.

## Entry Points

```swift
import SnabbleTeaser

// Paged teaser carousel — embed directly in a screen
let model = TeaserModel(shop: currentShop)

TeaserView(model: model) { teaser, image in
    // navigate to TeaserDetailView
    navigationPath.append(TeaserNavItem(teaser: teaser, image: image))
}

// Detail view
TeaserDetailView(model: model, teaser: teaser, image: preloadedImage)
```

`TeaserView` renders nothing (returns `EmptyView`) when the project has no valid teasers, so it is safe to embed unconditionally.

## Key Components

### Views

| View | Purpose |
|------|---------|
| `TeaserView` | Horizontal paged carousel with dot-indicator; hides itself when `model.teasers` is empty |
| `TeaserItemView` | Single card: remote image (124 pt tall) + title + subtitle; fires `onNavigation` after image loads |
| `TeaserDetailView` | Full-screen detail: image or embedded YouTube video, detail title/subtitle, and optional "Learn More" URL button |

### TeaserModel

`@Observable @MainActor final class` that owns the data:

| Member | Purpose |
|--------|---------|
| `teasers` | Filtered list of `CustomizationConfig.Teaser` from the active project's `CustomizationConfig.validTeasers` |
| `load(for:)` | Reloads teasers for a given `Shop`; clears the list if no project is found |
| `loadImage(from:)` | Async image fetch with in-memory cache; images are keyed by URL string |

`TeaserModel` must be passed to `TeaserItemView` via the SwiftUI environment:

```swift
TeaserItemView(teaser: teaser) { image in ... }
    .environment(model)
```

`TeaserView` does this automatically for each card.

## Navigation

The host app controls navigation. `TeaserView.onNavigation` is called with the tapped `CustomizationConfig.Teaser` and the already-loaded `UIImage?` so the detail view can display the image without a second download:

```swift
TeaserView(model: model) { teaser, image in
    coordinator.showTeaserDetail(teaser: teaser, image: image, model: model)
}
```

## Architecture

```
SnabbleTeaser (Layer 3)
    ├── TeaserView               (paged carousel + dot nav)
    │   └── TeaserItemView       (single card, env: TeaserModel)
    └── TeaserDetailView         (full-screen: image or YouTube + text + CTA)
    
    TeaserModel                  (@Observable — shared across all views)
        └── CustomizationConfig.Teaser[]  (from SnabbleCore project config)
```

## Dependencies

| Module | Role |
|--------|------|
| `SnabbleCore` | `CustomizationConfig.Teaser`, `Shop`, `Snabble.shared` |
| `SnabbleTheme` | Theme colors (`projectPrimary`, `projectFaq`) and fonts |
| `SnabbleComponents` | `YouTubeView`, `ProjectBorderedPrimaryButtonStyle` |
| `SnabbleAssetProviding` | Localised strings (`Snabble.Teaser.title`, `Snabble.Teaser.moreButtonTitle`) |
