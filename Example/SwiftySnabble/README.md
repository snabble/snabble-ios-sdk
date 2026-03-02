# SwiftySnabble - Moderne SwiftUI Sample App

Eine moderne SwiftUI-basierte Beispiel-App für das Snabble iOS SDK mit Swift 6.2.

## 📱 Überblick

SwiftySnabble ist eine vollständig in SwiftUI entwickelte Sample App, die Best Practices für die Integration des Snabble SDK demonstriert. Sie verwendet moderne Swift 6.2 Features wie @Observable, async/await und type-safe Navigation.

## 🏗️ Projekt-Setup

### Aktuelles Setup

Das Projekt ist als **eigenständiges Xcode-Projekt** angelegt:
- `SwiftySnabble.xcodeproj` - Eigenständiges Projekt
- Lokale Package-Referenz zum SDK
- Separates Git-Repository im `main` Branch

### Integration in SnabbleSampleApp.xcodeproj (Optional)

Wenn du SwiftySnabble als zusätzliches Target im Haupt-Projekt haben möchtest:

#### Option 1: Als Workspace (Empfohlen)

1. **Workspace erstellen:**
   ```bash
   cd Example
   # In Xcode: File > New > Workspace
   # Speichere als: SnabbleExamples.xcworkspace
   ```

2. **Projekte hinzufügen:**
   - Drag & Drop `SnabbleSampleApp.xcodeproj` ins Workspace
   - Drag & Drop `SwiftySnabble/SwiftySnabble.xcodeproj` ins Workspace

3. **Vorteile:**
   - ✅ Beide Projekte bleiben unabhängig
   - ✅ Shared Schemes
   - ✅ Einfaches Wechseln zwischen Apps
   - ✅ Gemeinsame Package-Referenzen

#### Option 2: Als zusätzliches Target

1. **Öffne SnabbleSampleApp.xcodeproj**

2. **Neues Target erstellen:**
   - File > New > Target
   - iOS > App
   - Name: "SwiftySnabble"
   - Interface: SwiftUI
   - Language: Swift
   - Lifecycle: SwiftUI App

3. **Source-Dateien hinzufügen:**
   - Wähle alle Dateien aus `SwiftySnabble/SwiftySnabble/`
   - Drag & Drop ins Projekt
   - Target Membership: Nur "SwiftySnabble" auswählen

4. **Package Dependencies:**
   - Project Settings > Package Dependencies
   - Füge das SDK Package hinzu (falls nicht vorhanden)
   - Wähle "SwiftySnabble" Target
   - Füge folgende Dependencies hinzu:
     - SnabbleCore
     - SnabbleUI
     - SnabbleScanAndGo
     - SnabbleAssetProviding
     - SnabbleComponents

5. **Build Settings:**
   - Target: SwiftySnabble
   - Swift Language Version: Swift 6
   - Strict Concurrency Checking: Complete
   - iOS Deployment Target: 17.0

6. **Info.plist konfigurieren:**
   - Kopiere Permissions aus altem Info.plist:
     - NSCameraUsageDescription
     - NSLocationWhenInUseUsageDescription
     - etc.

#### Option 3: Separates Projekt behalten (Aktuell)

Das ist die aktuelle und empfohlene Lösung:

**Vorteile:**
- ✅ Vollständig unabhängig
- ✅ Eigenes Git-Repository
- ✅ Keine Konflikte mit UIKit-Version
- ✅ Einfacher zu warten
- ✅ Kann separat versioniert werden

**Struktur:**
```
Example/
├── SnabbleSampleApp.xcodeproj    # UIKit Version
├── Snabble/                       # UIKit Source
├── SwiftySnabble/                 # SwiftUI Version
│   ├── SwiftySnabble.xcodeproj   # Eigenes Projekt
│   └── SwiftySnabble/            # SwiftUI Source
└── README.md
```

## 🎯 Features

### 5 Haupt-Tabs

1. **Start (Dashboard)**
   - Hero-Card für eingecheckten Shop
   - Quick Actions Grid
   - Letzte Einkäufe

2. **Filialen**
   - Suchbare Shop-Liste
   - Shop-Details
   - Check-in Management

3. **Einkaufen**
   - ShopperView aus SnabbleScanAndGo
   - Barcode-Scanner
   - Warenkorb
   - Payment

4. **Kassenbon**
   - Order-Historie
   - Pull-to-Refresh
   - Receipt-Details

5. **Profil**
   - Zahlungsmethoden
   - Einstellungen
   - Developer-Tools

## 🚀 Development

### Voraussetzungen

- Xcode 16.4+
- iOS 17.0+
- Swift 6.2
- Snabble API Credentials

### Build & Run

```bash
cd Example/SwiftySnabble
open SwiftySnabble.xcodeproj
# ⌘R zum Starten
```

### Configuration

1. **API Credentials:**
   Bearbeite `Core/SnabbleConfig.swift`:
   ```swift
   enum Config {
       static let appId = "your-app-id"
       static let appSecret = "your-app-secret"
   }
   ```

2. **Environment:**
   Im Profil-Tab kann zwischen Environments gewechselt werden:
   - Production
   - Staging
   - Testing

## 🏛️ Architektur

### Verzeichnisstruktur

```
SwiftySnabble/
├── Core/
│   ├── AppState.swift              # Global State
│   ├── AppRouter.swift             # Navigation
│   ├── AppAssetProvider.swift      # Asset Provider
│   └── SnabbleConfig.swift         # API Config
├── Features/
│   ├── Root/RootView.swift         # TabView
│   ├── Dashboard/
│   ├── Shops/
│   ├── Shopping/
│   ├── Receipts/
│   ├── Profile/
│   └── Onboarding/
└── SwiftySnabbleApp.swift          # @main Entry
```

### Navigation Pattern

Router-basierte Navigation mit Type Safety:

```swift
@Observable
class AppRouter {
    var path: NavigationPath
    var presentedSheet: SheetDestination?
    var presentedFullScreen: FullScreenDestination?
}
```

### State Management

```swift
@Observable
@MainActor
final class AppState {
    var project: Project?
    var shops: [Shop] = []
    var checkedInShop: Shop?
    var recentOrders: [Order] = []
}
```

## 🆚 Vergleich UIKit vs SwiftUI

| Feature | UIKit (Snabble) | SwiftUI (SwiftySnabble) |
|---------|-----------------|-------------------------|
| App Lifecycle | AppDelegate | SwiftUI App |
| Navigation | UINavigationController | NavigationStack + Router |
| State | ViewControllers | @Observable |
| Tab Bar | UITabBarController | TabView |
| Scanner | ScannerViewController | ShopperView |
| Concurrency | Callbacks | async/await |
| Previews | ❌ | ✅ |
| Code Lines | ~2000 | ~1200 |

## 📚 Weitere Infos

### SDK Integration

Die App integriert das SDK via Swift Package Manager:
- **Local Package**: `../../` (relativ zum Projekt)
- **Dependencies**:
  - SnabbleCore
  - SnabbleUI
  - SnabbleScanAndGo
  - SnabbleAssetProviding
  - SnabbleComponents

### Key Components

**AppRouter** - Type-safe Navigation
```swift
router.navigate(to: .shopDetail(shop))
router.showFullScreen(.shopping(shop))
```

**AppState** - Global State Management
```swift
@Environment(AppState.self) var appState
```

**ShopperView** - Scanner Integration
```swift
ShopperView()
    .environment(shopper)
```

## 🔧 Troubleshooting

### Build Errors

**Problem:** "Cannot find type 'Shopper' in scope"
**Lösung:** Füge `SnabbleScanAndGo` Package Dependency hinzu

**Problem:** "Module compiled with Swift 5.x cannot be imported"
**Lösung:** Setze Swift Language Version auf Swift 6 in Build Settings

**Problem:** "Concurrency errors"
**Lösung:** Enable "Strict Concurrency Checking: Complete"

### Package Dependencies

Falls das lokale Package nicht gefunden wird:
1. File > Packages > Reset Package Caches
2. Überprüfe Package-Pfad in Project Settings
3. Neu builden (⌘⇧K dann ⌘B)

## 📄 Lizenz

Copyright © 2026 snabble GmbH. All rights reserved.

---

**Empfehlung:** Behalte das separierte Projekt-Setup. Es ist cleaner, wartbarer und ermöglicht unabhängige Entwicklung beider Sample Apps.
