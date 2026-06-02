# ShopFinder Module (Removed)

**Status:** Empty / Deprecated
**SDK Version:** 1.0.0 rc

## Overview

The `ShopFinder` module has been **removed** as part of the SDK 1.0 restructuring. Its functionality has been migrated to:

- **SnabbleShops** - Shop listing and search functionality
- **SnabbleCore** - Shop data models and business logic

## Directory Status

This directory is **empty** and can be safely deleted. It is kept temporarily for:

1. Git history reference
2. Potential rollback scenarios
3. Migration documentation

## Migration

If you were using `ShopFinder` in a previous version:

- **Shop search:** Use `SnabbleShops` module
- **Shop models:** Use `SnabbleCore` module
- **Shop UI:** Use `SnabbleShops` SwiftUI views

See [SDK Consumer Migration Guide](../documentation/SDK-Consumer-Migration-Guide.md) for details.

---

**Action Required:** This directory should be removed before final 1.0.0 release.
