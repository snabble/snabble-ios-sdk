# Archived Documentation

This directory contains historical documentation for completed migrations and deprecated features.

## 📦 Contents

### Completed Migrations

**Swift-6-Migration-Plan.md** (484 lines)
- **Status:** ✅ Complete (2026-02)
- **Purpose:** Guide for migrating the SDK to Swift 6
- **Archived:** Migration is complete, kept for historical reference
- **Key Outcomes:**
  - 25 ObservableObject classes migrated to @Observable
  - Full strict concurrency checking enabled
  - All UI bugs resolved

**CheckInManager-Migration-Guide.md** (282 lines)
- **Status:** ✅ Complete
- **Purpose:** Migrate from Combine publishers to AsyncStream
- **Archived:** API migration is complete
- **Note:** New code should use AsyncStream API directly

**SDK-Consumer-Migration-Guide.md** (299 lines)
- **Status:** ✅ Complete
- **Purpose:** Guide for SDK consumers migrating to new APIs
- **Archived:** All known consumers have migrated

**Isolation-Boundaries.md** (505 lines)
- **Status:** ✅ Complete (draft from 2026-02-19)
- **Purpose:** Actor isolation strategy for Swift 6.2 migration
- **Archived:** Migration complete, kept as technical reference
- **Key Decisions:**
  - ShoppingCart → Actor
  - CheckInManager → @MainActor with nonisolated delegates
  - SepaDataModel → Hybrid @Observable + Combine validation
  - ProductDatabase → Custom executor for GRDB

## 🔍 When to Reference

These documents are useful for:

1. **Understanding migration decisions** - See why certain patterns were chosen
2. **Future migrations** - Learn from past migration strategies
3. **Historical context** - Understand the evolution of the SDK architecture
4. **Troubleshooting legacy code** - If you encounter old patterns in the codebase

## 📚 Current Documentation

For up-to-date documentation, see:

- **[SDK-Integration-Best-Practices.md](../SDK-Integration-Best-Practices.md)** - Main integration guide
- **[SDK-Architecture.md](../SDK-Architecture.md)** - Architecture overview
- **[Sample-App-Comparison.md](../Sample-App-Comparison.md)** - UIKit vs SwiftUI comparison

## ⚠️ Important Note

**Do not use patterns from archived documents in new code.** These documents reflect the state of the SDK at the time of writing and may contain outdated patterns or APIs.

---

**Last Updated:** 2026-03-03
