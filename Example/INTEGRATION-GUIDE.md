# SwiftySnabble Integration Guide

Anleitung zur Integration von SwiftySnabble in das bestehende Xcode-Projekt.

## 🎯 Aktuelle Situation

Du hast SwiftySnabble als **eigenständiges Xcode-Projekt** erstellt:
- ✅ `SwiftySnabble/SwiftySnabble.xcodeproj` - Funktioniert perfekt
- ✅ Lokale Package-Referenz zum SDK
- ✅ Alle Features implementiert
- ✅ Branch: `main` (im SwiftySnabble-Verzeichnis)

Du möchtest SwiftySnabble jetzt in den `swift6-again` Branch des Haupt-Repositories integrieren.

## 🔄 Empfohlene Lösung: Eigenständiges Projekt behalten

**Begründung:**
- ✅ Sauber getrennt von UIKit-Version
- ✅ Eigenes Git-Repository im Unterverzeichnis
- ✅ Keine Konflikte zwischen UIKit und SwiftUI
- ✅ Einfacher zu warten
- ✅ Kann unabhängig versioniert werden

**Struktur:**
```
snabble-ios-sdk/
├── .git/                          # Haupt-Repository (swift6-again branch)
├── Example/
│   ├── SnabbleSampleApp.xcodeproj # UIKit Version
│   ├── Snabble/                   # UIKit Source
│   ├── SwiftySnabble/             # SwiftUI Version
│   │   ├── .git/                  # Eigenes Git (main branch)
│   │   ├── SwiftySnabble.xcodeproj
│   │   └── SwiftySnabble/         # SwiftUI Source
│   └── README.md
└── [SDK Source...]
```

### So bleibt die Struktur

**Keine Änderungen nötig!** Die aktuelle Struktur ist optimal.

## 📋 Alternative Optionen

Falls du doch ein gemeinsames Target möchtest (nicht empfohlen):

### Option A: Als Workspace

Erstelle einen Workspace, der beide Projekte enthält:

1. **In Xcode:**
   ```
   File > New > Workspace
   Name: SnabbleExamples.xcworkspace
   Speichere in: Example/
   ```

2. **Projekte hinzufügen:**
   - Drag & Drop `SnabbleSampleApp.xcodeproj`
   - Drag & Drop `SwiftySnabble/SwiftySnabble.xcodeproj`

3. **Vorteile:**
   - Beide Projekte bleiben unabhängig
   - Gemeinsame Schemes
   - Einfaches Wechseln zwischen Apps

**Struktur danach:**
```
Example/
├── SnabbleExamples.xcworkspace    # Öffne dies!
├── SnabbleSampleApp.xcodeproj
├── SwiftySnabble/
│   └── SwiftySnabble.xcodeproj
└── ...
```

### Option B: Als zusätzliches Target (kompliziert)

**⚠️ Nicht empfohlen** - Viel Aufwand, wenig Nutzen

Falls trotzdem gewünscht:

1. **Öffne SnabbleSampleApp.xcodeproj**

2. **Neues Target erstellen:**
   - File > New > Target
   - iOS > App
   - Product Name: "SwiftySnabble"
   - Interface: SwiftUI
   - Language: Swift

3. **Source-Dateien kopieren:**
   ```bash
   # Kopiere von SwiftySnabble/SwiftySnabble/ nach Snabble/SwiftySnabble/
   cp -r SwiftySnabble/SwiftySnabble/Core Snabble/SwiftySnabble/
   cp -r SwiftySnabble/SwiftySnabble/Features Snabble/SwiftySnabble/
   # etc.
   ```

4. **In Xcode:**
   - Füge die kopierten Dateien zum Projekt hinzu
   - Target Membership: Nur "SwiftySnabble" auswählen

5. **Package Dependencies:**
   - Project Settings > Package Dependencies
   - Für "SwiftySnabble" Target:
     - SnabbleCore
     - SnabbleUI
     - SnabbleScanAndGo
     - SnabbleAssetProviding
     - SnabbleComponents

6. **Build Settings:**
   - Swift Language Version: Swift 6
   - Strict Concurrency: Complete
   - iOS Deployment Target: 17.0

**Nachteile:**
- ❌ Doppelte Source-Dateien
- ❌ Muss manuell synchronisiert werden
- ❌ Mehr Maintenance
- ❌ Komplexeres Projekt-Setup

## ✅ Was du tun solltest

### Schritt 1: SwiftySnabble Verzeichnis ins Haupt-Repo committen

```bash
cd /Users/ut/Projects/snabble-ios-sdk

# Checke aus, dass du im richtigen Branch bist
git branch
# Sollte zeigen: * swift6-again

# SwiftySnabble ist bereits vorhanden, füge es hinzu
git add Example/SwiftySnabble/
git commit -m "Add SwiftySnabble as standalone SwiftUI sample app"
```

### Schritt 2: .gitignore anpassen (optional)

Falls du das SwiftySnabble Git-Sub-Repository nicht ins Haupt-Repo möchtest:

```bash
# In /Users/ut/Projects/snabble-ios-sdk/.gitignore
echo "Example/SwiftySnabble/.git" >> .gitignore
```

### Schritt 3: README aktualisiert

Die README-Dateien wurden bereits aktualisiert:
- ✅ `Example/README.md` - Vergleich beider Versionen
- ✅ `Example/SwiftySnabble/README.md` - SwiftySnabble Dokumentation

### Schritt 4: Obsolete Dateien gelöscht

Die temporären `SnabbleSwiftUI/` Dateien wurden bereits entfernt.

## 🎯 Finales Setup

**Öffnen der UIKit-Version:**
```bash
cd Example
open SnabbleSampleApp.xcodeproj
```

**Öffnen der SwiftUI-Version:**
```bash
cd Example/SwiftySnabble
open SwiftySnabble.xcodeproj
```

## 📝 Git-Strategie

### Mit Sub-Repository (aktuell)

```
snabble-ios-sdk/.git (swift6-again)
└── Example/SwiftySnabble/.git (main)
```

**Vorteile:**
- SwiftySnabble hat eigene Historie
- Kann unabhängig entwickelt werden

**Commands:**
```bash
# Im Haupt-Repo
cd /Users/ut/Projects/snabble-ios-sdk
git add Example/SwiftySnabble/
git commit -m "Update SwiftySnabble"

# Im SwiftySnabble-Repo
cd Example/SwiftySnabble
git add .
git commit -m "Fix shopping view"
```

### Ohne Sub-Repository (alternative)

Falls du das SwiftySnabble `.git` entfernen möchtest:

```bash
cd Example/SwiftySnabble
rm -rf .git
cd ../..
git add Example/SwiftySnabble/
git commit -m "Add SwiftySnabble to main repository"
```

**Vorteile:**
- Einheitliche Git-Historie
- Einfacheres Branching

**Nachteile:**
- Verliert SwiftySnabble Historie
- Kann nicht unabhängig versioniert werden

## 🎓 Empfehlung

**Behalte das aktuelle Setup:**

1. ✅ SwiftySnabble als eigenständiges Projekt
2. ✅ Eigenes `.xcodeproj`
3. ✅ Mit oder ohne Sub-Repository (deine Wahl)
4. ✅ Parallel zur UIKit-Version

**Warum?**
- Saubere Trennung
- Keine Konflikte
- Einfacher zu warten
- Beide Apps können unabhängig entwickelt werden
- Neue Entwickler können wählen, welche Version sie anschauen

## 🚀 Zusammenfassung

**Du musst nichts ändern!** Das aktuelle Setup ist optimal:

```
Example/
├── SnabbleSampleApp.xcodeproj    # UIKit ← Öffne dies für UIKit
├── Snabble/                       # UIKit Source
├── SwiftySnabble/                 # SwiftUI
│   ├── SwiftySnabble.xcodeproj   # SwiftUI ← Öffne dies für SwiftUI
│   └── SwiftySnabble/            # SwiftUI Source
└── README.md                      # Vergleich
```

**Workflow:**
- UIKit entwickeln: Öffne `SnabbleSampleApp.xcodeproj`
- SwiftUI entwickeln: Öffne `SwiftySnabble/SwiftySnabble.xcodeproj`
- Beide funktionieren unabhängig
- Beide nutzen das gleiche SDK

**Fertig!** 🎉
