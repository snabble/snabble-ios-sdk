# Snabble SDK - Example Apps

Dieses Verzeichnis enthält zwei Beispiel-Apps, die verschiedene Ansätze zur Integration des Snabble iOS SDK demonstrieren.

## 📱 Verfügbare Versionen

### 1. [Snabble/](./Snabble/) - UIKit Version (Legacy)

Die ursprüngliche Beispiel-App basierend auf UIKit und dem UIApplicationDelegate-Lifecycle.

**Projekt:** `SnabbleSampleApp.xcodeproj`

**Technologie:**
- UIKit mit UIViewController
- AppDelegate Lifecycle
- UINavigationController & UITabBarController
- Legacy ScannerViewController

**Geeignet für:**
- Bestehende UIKit-Apps
- Migration von älteren Apps
- Teams mit UIKit-Expertise

[→ Zur UIKit-Version](./Snabble/)

---

### 2. [SwiftySnabble/](./SwiftySnabble/) - SwiftUI Version (Modern) ⭐️

Eine moderne, vollständig SwiftUI-basierte Beispiel-App mit Swift 6.2.

**Projekt:** `SwiftySnabble/SwiftySnabble.xcodeproj` (Eigenständiges Projekt)

**Technologie:**
- 100% SwiftUI
- SwiftUI App Lifecycle
- @Observable State Management
- Router-Pattern Navigation
- ShopperView Integration (aus SnabbleScanAndGo)

**Geeignet für:**
- Neue Apps
- Moderne SwiftUI-Projekte
- Swift 6.2 Migration
- Best Practice Referenz

[→ Zur SwiftUI-Version](./SwiftySnabble/)

---

## 🆚 Vergleich

| Aspekt | UIKit | SwiftUI |
|--------|-------|---------|
| **App Lifecycle** | AppDelegate | SwiftUI App |
| **Navigation** | UINavigationController | NavigationStack + Router |
| **State Management** | ViewControllers | @Observable |
| **Tab Navigation** | UITabBarController | TabView |
| **Scanner Integration** | ScannerViewController | ShopperView |
| **Concurrency** | Callbacks + Combine | async/await |
| **Type Safety** | Runtime | Compile-time |
| **Previews** | ❌ | ✅ |
| **Code Menge** | ~2000 LOC | ~1200 LOC |
| **Swift Version** | 5.10 | 6.2 |
| **Maintenance** | Legacy | Active Development |

## 🎯 Welche Version wählen?

### Wähle **UIKit**, wenn:
- ✅ Du eine bestehende UIKit-App hast
- ✅ Dein Team primär UIKit-Erfahrung hat
- ✅ Du iOS < 17 unterstützen musst
- ✅ Du Legacy-Code integrieren musst

### Wähle **SwiftUI**, wenn:
- ✅ Du eine neue App startest
- ✅ Du moderne Swift-Features nutzen willst
- ✅ iOS 17+ deine Mindestversion ist
- ✅ Du Best Practices lernen möchtest
- ✅ Du schnellere Entwicklung bevorzugst

## 🚀 Quick Start

### UIKit Version

```bash
cd Example
open SnabbleSampleApp.xcodeproj
# Wähle "Snabble" scheme
# ⌘R zum Starten
```

### SwiftUI Version (SwiftySnabble)

```bash
cd Example/SwiftySnabble
open SwiftySnabble.xcodeproj
# Wähle "SwiftySnabble" scheme
# ⌘R zum Starten
```

**Hinweis:** SwiftySnabble ist ein eigenständiges Xcode-Projekt mit lokaler Package-Referenz zum SDK.

## 📚 Dokumentation

### Gemeinsame Ressourcen

Beide Apps nutzen:
- **SnabbleCore** - Business Logic, Cart, Checkout
- **SnabbleUI** - UI Components (UIKit-basiert)
- **SnabbleScanAndGo** - Scanner & Shopping Flow
- **SnabbleAssetProviding** - Theming
- **SnabbleComponents** - Shared SwiftUI Components

### SDK Features

Beide Beispiel-Apps demonstrieren:
- 🛒 **Shopping Cart Management**
- 📷 **Barcode Scanning**
- 💳 **Payment Integration**
- 🧾 **Receipt Management**
- 🏪 **Shop Check-in/Check-out**
- 👤 **User Profile & Settings**

## 🔧 Entwicklung

### Voraussetzungen

- **Xcode**: 16.4+
- **iOS**: 17.0+ (SwiftUI) / 15.0+ (UIKit)
- **Swift**: 6.2 (SwiftUI) / 5.10 (UIKit)
- **Snabble Account**: Gültige API Credentials

### API Credentials

Erstelle `SnabbleConfig.swift` mit:

```swift
enum DeveloperMode {
    static let appId = "your-app-id"
    static let appSecret = "your-app-secret"
}
```

## 📱 Features im Vergleich

### UIKit Version Features
- Dashboard mit Dynamic View Controller
- Shop-Liste mit Check-in
- Legacy Scanner Integration
- Shopping Cart (UIKit)
- Receipts List
- Account/Profile
- Onboarding Flow

### SwiftUI Version Features
- **Dashboard** - Hero Cards, Quick Actions
- **Filialen** - Suchbare Shop-Liste, Details
- **Einkaufen** - ShopperView Integration
- **Kassenbons** - Modern mit Pull-to-Refresh
- **Profil** - Settings, Developer Tools
- **Router-Navigation** - Type-safe, Deep Linking Ready
- **Modern UI** - Cards, Gradients, SF Symbols

## 🎨 Screenshots

_(Screenshots können hier eingefügt werden)_

## 🔄 Migration UIKit → SwiftUI

Wenn du von UIKit zu SwiftUI migrieren möchtest:

1. **Schritt für Schritt:**
   - Starte mit einem einzelnen Tab
   - Verwende UIHostingController für SwiftUI-Views
   - Migriere schrittweise weitere Screens

2. **Oder komplett neu:**
   - Nutze die SwiftUI-Version als Vorlage
   - Kopiere relevante Business Logic
   - Adaptiere an deine Bedürfnisse

## 📖 Weitere Ressourcen

- [Snabble SDK Dokumentation](../README.md)
- [Swift 6 Migration Guide](../documentation/Swift-6-Migration-Plan-EN.md)
- [SDK Architecture](../documentation/SDK-Architecture.md)

## 🤝 Support

Bei Fragen oder Problemen:
- **Issues**: [GitHub Issues](https://github.com/snabble/iOS-SDK/issues)
- **Dokumentation**: [docs.snabble.io](https://docs.snabble.io)
- **Email**: support@snabble.io

## 📄 Lizenz

Copyright © 2026 snabble GmbH. All rights reserved.

---

**Empfehlung:** Für neue Projekte empfehlen wir die **SwiftUI-Version** als Ausgangspunkt. Sie demonstriert moderne Best Practices und ist leichter zu warten.
