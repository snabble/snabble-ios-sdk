# Snabble iOS SDK - Swift 6.2 Migration & Technical Debt Plan

**Autor:** Uwe Tilemann
**Datum:** Januar 2026
**Status:** Genehmigt, Umsetzung ausstehend
**Ziel:** Migration zu Swift 6.2 mit Approachable Concurrency, @Observable, und SwiftUI-Modernisierung

---

## Executive Summary

Migration des Snabble iOS SDK von Swift 5.10 zu Swift 6.2 mit:
- Approachable Concurrency (Default MainActor Isolation)
- ObservableObject zu @Observable Migration (25+ Klassen)
- UIKit zu SwiftUI wo sinnvoll (Example App, einfache Views)
- Aufarbeitung technischer Schulden aus 2020-2024

**Geschätzter Gesamtaufwand:** 7-10 Wochen (mit Agent Skills Support) / 14-16 Wochen (manuell)

---

## Aktueller Zustand

### Package-Konfiguration
- **Swift Tools Version:** 5.10 (muss auf 6.2 aktualisiert werden)
- **iOS Target:** 17.0+ (bleibt unverändert - Swift 6.2 ist unabhängig vom iOS Target)
- **Module:** 10 (Network, Core, UI, Components, AssetProviding, Pay, User, PhoneAuth, Datatrans, ScanAndGo)

### Kompatibilitätsstrategie
- **Inkrementelle Migration** mit Soft Deprecations
- Bestehende SDK Consumer weiter unterstützen
- Breaking Changes nur wo unvermeidbar (z.B. ObservableObject → @Observable)

### Technische Schulden Inventar

| Kategorie | Anzahl | Status |
|-----------|--------|--------|
| ObservableObject Klassen | 25 | Migration erforderlich |
| @Published Properties | 69 | Entfernen nach Migration |
| @ObservedObject Usages | 40+ | Zu @Environment/@State |
| UIKit ViewControllers | 64 | Teilweise migrieren |
| Concurrency Annotations (Core) | 0 | Hinzufügen |
| Test Coverage (UI Module) | 0% | Tests hinzufügen |

---

## Phase 1: Foundation Setup (Woche 1-2)

### 1.1 Package.swift Update
**Datei:** `Package.swift`

```swift
// swift-tools-version: 6.2
platforms: [.iOS(.v17)]  // Bleibt iOS 17 für Kompatibilität
```

Für jedes Target Swift Settings hinzufügen:
```swift
swiftSettings: [
    .swiftLanguageMode(.v6)
]
```

**Hinweis:** Swift 6.2 Language Features sind unabhängig vom iOS Deployment Target. Approachable Concurrency, @Observable und alle anderen Swift 6.2 Features funktionieren auch mit iOS 17.0.

### 1.2 Dependencies prüfen
- GRDB.swift 6.29.3+ - Swift 6 kompatibel
- KeychainAccess 4.2.2+ - prüfen
- Datatrans 3.7.3+ - prüfen
- Pulley 2.9.2 - ggf. Fork für Swift 6

### 1.3 Validierung
```bash
swift package resolve
xcodebuild -scheme Snabble-Package -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5' build
```

---

## Phase 2: Network & Core Concurrency (Woche 2-4)

### 2.1 SnabbleNetwork Module
- NetworkManager async/await Enhancement
- @Sendable für Completion Handlers
- Authenticator Thread Safety

### 2.2 SnabbleCore Module
Kritische Klassen:
- `Snabble.shared` - Singleton Isolation
- `ShoppingCart` - MainActor für UI, @concurrent für DB
- `ProductDatabase` - GRDB Integration mit Actor Isolation
- `CheckInManager` - CLLocationManager Delegates

---

## Phase 3: @Observable Migration (Woche 4-9)

### Tier 1 - Einfache Klassen (10 Klassen, ~2 Wochen)

| Klasse | Datei | Aufwand |
|--------|-------|---------|
| RatingModel | UI/Sources/Checkout/CheckoutRatingView.swift | 1h |
| CouponViewModel | UI/Sources/Coupons/CouponViewModel.swift | 1h |
| OnboardingViewModel | UI/Sources/Onboarding/Model/OnboardingViewModel.swift | 2h |
| ShoppingCartViewModel | UI/Sources/ShoppingCart/Models/ShoppingCartViewModel.swift | 4h |
| PaymentMethodManager | UI/Sources/Payment/PaymentMethodManager.swift | 3h |
| ActionManager | ScanAndGo/Shopping/Models/ActionState.swift | 1h |
| BarcodeManager | ScanAndGo/Shopping/Models/BarcodeManager.swift | 2h |
| Shopper | ScanAndGo/Shopping/Models/Shopper.swift | 4h |
| StartShoppingViewModel | UI/Sources/DynamicView/WidgetStartShoppingView.swift | 1h |
| CheckoutModel | UI/Sources/Checkout/CheckoutStepsViewController.swift | 2h |

**Migrations-Pattern:**
```swift
// VORHER
class CouponViewModel: ObservableObject {
    @Published var image: UIImage?
}

// NACHHER
@Observable
class CouponViewModel {
    var image: UIImage?
}
```

### Tier 2 - Komplexe Combine Validation (4 Klassen, ~2 Wochen)

| Klasse | Datei | Komplexität |
|--------|-------|-------------|
| SepaDataModel | UI/Sources/PaymentMethods/Models/SepaDataModel.swift | PCI-kritisch |
| LoginViewModel | UI/Sources/Login/LoginViewModel.swift | Vererbungsbasis |
| PaymentSubjectViewModel | UI/Sources/PaymentMethods/Models/PaymentSubjectViewModel.swift | Debounce |
| SepaAcceptModel | UI/Sources/PaymentMethods/Models/SepaAcceptModel.swift | SEPA Mandate |

**Hybrid-Pattern für Combine:**
```swift
@Observable
class SepaDataModel {
    private let ibanSubject = CurrentValueSubject<String, Never>("")

    var ibanNumber: String = "" {
        didSet { ibanSubject.send(ibanNumber) }
    }

    // Bestehende Combine Publisher bleiben
}
```

### Tier 3 - Special Cases (7 Klassen, ~2 Wochen)

| Klasse | Problem | Lösung |
|--------|---------|--------|
| DynamicViewModel | NSObject + Decodable | nonisolated(unsafe) für Properties |
| DeveloperModeViewModel | NSObject | Direkte Migration |
| LocationPermissionViewModel | CLLocationManager | nonisolated Delegates |
| InvoiceLoginModel | Erbt von LoginViewModel | Swift 6 @Observable Inheritance |
| InvoiceLoginProcessor | ObservableObject | Standard Migration |
| BaseCheckViewModel | Security-kritisch | Vorsichtige Migration |
| CartItemModel | Open Class Hierarchy | Basis zuerst migrieren |

### View Updates

```swift
// VORHER
@ObservedObject var viewModel: CouponViewModel
@StateObject var viewModel: CouponViewModel
@EnvironmentObject var viewModel: CouponViewModel

// NACHHER
@Environment(CouponViewModel.self) var viewModel  // preferred
@State var viewModel: CouponViewModel              // alternative
```

---

## Phase 4: UIKit zu SwiftUI Migration (Woche 9-11)

### Migrieren (Einfach)

| Komponente | Aufwand | Priorität |
|------------|---------|-----------|
| ReceiptsDetailViewController | 4h | Hoch |
| CouponsViewController | 2h | Hoch |
| SelectionSheetController | 3h | Mittel |
| AlertView | 2h | Mittel |
| BarcodeEntryViewController | 3h | Niedrig |

### NICHT Migrieren (Security/Hardware)

- Payment Methods VCs (8) - PCI Compliance
- Payment Processing VCs (5) - Sicherheitskritisch
- ScanningViewController - AVFoundation
- ScannerViewController - Pulley Drawer

---

## Phase 5: Example App Modernisierung (Woche 11-13)

### 5.1 Von UIKit AppDelegate zu SwiftUI App

**Datei:** `Example/Snabble/SnabbleSampleApp.swift` (neu)

```swift
@main
struct SnabbleSampleApp: App {
    @State private var appState = SnabbleAppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
        }
    }
}

@Observable
@MainActor
class SnabbleAppState {
    var isLoaded = false
    var project: Project?
    // ...
}
```

### 5.2 TabView Navigation

```swift
struct ContentView: View {
    @Environment(SnabbleAppState.self) var state

    var body: some View {
        TabView {
            DashboardView().tabItem { Label("Home", systemImage: "house") }
            ShopsView().tabItem { Label("Shops", systemImage: "building.2") }
            ScannerView().tabItem { Label("Scan", systemImage: "barcode.viewfinder") }
            ReceiptsView().tabItem { Label("Receipts", systemImage: "scroll") }
            AccountView().tabItem { Label("Account", systemImage: "person") }
        }
    }
}
```

### 5.3 Zu löschende Dateien
- `AppDelegate.swift` (nach Migration)
- `LoadingViewController.swift`
- Andere UIKit-spezifische Helper

---

## Phase 6: Cleanup & Dokumentation (Woche 13-16)

### 6.1 Legacy Code entfernen
- Alle `objectWillChange.send()` Aufrufe
- Ungenutzte Combine Imports
- `@Published` von @Observable Klassen
- Veraltete Property Wrapper

### 6.2 CI/CD aktualisieren
- GitHub Actions auf Xcode 17+ / macOS 16
- Simulator auf iOS 18.5+
- Swift 6.2 Strict Mode Validierung

### 6.3 Dokumentation
- CLAUDE.md aktualisieren mit finalen Patterns
- README.md Swift 6.2 Requirements
- Migration Guide für SDK Consumer

---

## Zeitschätzung

| Phase | Ohne Agent | Mit Agent Skills | Ersparnis |
|-------|------------|------------------|-----------|
| Phase 1: Foundation | 1 Woche | 2-3 Tage | 50% |
| Phase 2: Concurrency | 2 Wochen | 1 Woche | 50% |
| Phase 3: @Observable | 5 Wochen | 2-3 Wochen | 50% |
| Phase 4: UIKit→SwiftUI | 2 Wochen | 1 Woche | 50% |
| Phase 5: Example App | 2 Wochen | 1 Woche | 50% |
| Phase 6: Cleanup | 1-2 Wochen | 1 Woche | 30% |
| **Gesamt** | **14-16 Wochen** | **7-10 Wochen** | **~50%** |

### Relevante Agent Skills
- `swift-concurrency-expert` - Concurrency Review & Migration
- `swiftui-view-refactor` - SwiftUI View Refactoring
- `swiftui-ui-patterns` - SwiftUI Best Practices
- `swiftui-performance-audit` - Performance Optimierung

---

## Risiken & Mitigationen

| Risiko | Wahrscheinlichkeit | Mitigation |
|--------|-------------------|------------|
| Dependencies nicht Swift 6 kompatibel | Mittel | Early Audit in Phase 1 |
| PCI Compliance bei Payment | Niedrig | Keine Änderung an Validierungslogik |
| GRDB Actor Isolation | Mittel | @concurrent für DB Operationen |
| Breaking Changes für SDK Consumer | Hoch | Siehe Kompatibilitätsstrategie |

---

## Kompatibilitätsstrategie für SDK Consumer

### Unvermeidbare Breaking Changes
Die Migration von `ObservableObject` zu `@Observable` ist ein **Breaking Change** für Consumer:

```swift
// Consumer Code VORHER
@ObservedObject var shopper: Shopper

// Consumer Code NACHHER
@State var shopper: Shopper
// oder
@Environment(Shopper.self) var shopper
```

### Empfohlene Strategie: Soft Deprecation + Major Version

1. **Version 0.74.x** - Deprecation Warnings hinzufügen
   - `@available(*, deprecated, message: "Will be replaced with @Observable in 1.0")`
   - Dokumentation der kommenden Änderungen

2. **Version 1.0.0** - Swift 6.2 Migration
   - Alle ObservableObject → @Observable
   - Klare Migration Guide für Consumer
   - Changelog mit allen Breaking Changes

### Was bleibt kompatibel
- Alle Public API Signaturen (Methodennamen, Parameter)
- Bestehende Protokolle (Shopper, ShopperView Entry Points)
- Datenmodelle (CartItem, Product, Shop, etc.)
- Configuration Pattern (Snabble.setup)

### Was ändert sich
- Property Wrapper in Views (@ObservedObject → @State/@Environment)
- ViewModel Initialization Pattern
- Combine Publishers → @Observable Properties

---

## Verifikation

### Nach jeder Phase
```bash
# Build prüfen
xcodebuild -scheme Snabble-Package -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5' build

# Tests ausführen
xcodebuild -scheme Snabble-Package -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5' test

# SwiftLint
swiftlint --strict --quiet
```

### End-to-End Test
1. Example App starten
2. Shop Check-in testen
3. Produkt scannen
4. Warenkorb prüfen
5. Payment Flow durchlaufen
6. Receipt anzeigen

---

## Kritische Dateien

**Package Configuration:**
- `Package.swift`

**Core ViewModels (Priorität 1):**
- `UI/Sources/ShoppingCart/Models/ShoppingCartViewModel.swift`
- `ScanAndGo/Shopping/Models/Shopper.swift`
- `UI/Sources/Payment/PaymentMethodManager.swift`

**Security-Critical (Vorsicht):**
- `UI/Sources/PaymentMethods/Models/SepaDataModel.swift`
- `UI/Sources/Login/LoginViewModel.swift`

**Example App:**
- `Example/Snabble/AppDelegate.swift`

---

## Migrationsstatus

### Abgeschlossen ✅

**Phase 1: Foundation Setup (Abgeschlossen)**
- ✅ Package.swift auf Swift 6.2 aktualisiert
- ✅ Alle Module mit `.swiftLanguageMode(.v6)` konfiguriert
- ✅ Dependencies verifiziert (GRDB, KeychainAccess, Datatrans, Pulley)
- ✅ Build erfolgreich mit aktiviertem Strict Concurrency Checking

**Phase 2: Strict Concurrency (Abgeschlossen)**
- ✅ Alle Concurrency-Fehler behoben (0 Build-Errors)
- ✅ MainActor-Isolation für UI-Komponenten und ViewModels
- ✅ @Sendable für Completion Handler
- ✅ Task { @MainActor } Wrapper für asynchrone Callbacks
- ✅ nonisolated(unsafe) für Properties über Dispatch Queues hinweg
- ✅ Protokoll-Isolation (LoginProcessing, PaymentDelegate, etc.)

**Phase 3: @Observable Migration (Abgeschlossen - Alle 25 Klassen)**

*UI Module (20 Klassen):*
- ✅ ShoppingCartViewModel (mit NotificationCenter MainActor Fix)
- ✅ CartItemModel, ProductItemModel, CouponCartItemModel
- ✅ SepaDataModel, SepaAcceptModel (mit Combine Hybrid Pattern)
- ✅ PaymentSubjectViewModel, InvoiceLoginModel, InvoiceLoginProcessor
- ✅ PaymentMethodManager, BaseCheckViewModel, RatingModel
- ✅ LoginViewModel, OnboardingViewModel, CouponViewModel, CheckoutModel
- ✅ DynamicViewModel (NSObject + Decodable mit nonisolated(unsafe))
- ✅ StartShoppingViewModel, AllStoresViewModel, ConnectWifiViewModel
- ✅ CustomerCardViewModel

*ScanAndGo Module (3 Klassen):*
- ✅ Shopper (mit @Environment Pattern)
- ✅ BarcodeManager
- ✅ ActionManager

*Pay Example App (4 Klassen):*
- ✅ ErrorHandler
- ✅ AccountViewModel (objectWillChange.send() entfernt)
- ✅ AccountsViewModel (mit Task Wrappern)
- ✅ MotionManager (mit Task Wrapper für Motion Updates)

**UI Fixes:**
- ✅ Shopping Cart Anzeige-Problem behoben (NotificationCenter Handler auf MainActor)
- ✅ Pulley Drawer Höhenberechnung korrigiert (nonisolated(unsafe) für Properties)
- ✅ Pulley Drawer Höhe aktualisiert sich dynamisch bei Warenkorb-Änderungen
- ✅ Camera Barcode Detector Race Conditions behoben
- ✅ ShoppingCartView @State Wrapper für @Observable ViewModel
- ✅ Warenkorb Item-Anzahl aktualisiert sich in Echtzeit
- ✅ CartEntry Equatable berücksichtigt Quantity für korrekte SwiftUI Updates

### Nächste Schritte

**Phase 4: UIKit zu SwiftUI Migration (Optional)**
- Migration einfacher UIKit ViewControllers zu SwiftUI wo sinnvoll
- Security-kritische und Hardware-abhängige Komponenten bleiben in UIKit

**Phase 5: Example App Modernisierung (Optional)**
- Umstellung von UIKit AppDelegate zu SwiftUI App
- Moderne TabView Navigation implementieren
- Legacy UIKit Patterns aufräumen

**Phase 6: Dokumentation & Polish**
- ✅ CLAUDE.md mit @Observable Patterns aktualisiert
- Migrations-Learnings dokumentieren
- Migrations-Guide für SDK-Konsumenten erstellen
- README mit Swift 6.2 Requirements aktualisieren

## Aktueller Branch

Branch: `swift6-again`
Letzter Commit: Phase 2 @Observable Migration complete
