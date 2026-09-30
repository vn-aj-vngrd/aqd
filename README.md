# AQD

**Your wardrobe, understood.**

An iOS-first personal digital closet assistant with optional community discovery.

## Repository layout

```text
apps/
  ios/        Native SwiftUI iPhone app and Xcode project
  android/    Reserved for future Android development (not created yet)
docs/         Shared product documentation
```

Start with [iOS setup](apps/ios/README.md) to run the app or [product documentation](docs/README.md) for scope and product decisions.

Current implementation: a functional private wardrobe with local persistence, clothing photos, outfits, wear tracking, search, and rule-based suggestions. Account, live AI, and community code is also included; deployment and credentials are still required to activate it. See [implementation status](docs/IMPLEMENTATION.md). Android can be added independently under `apps/android/` when development begins.

V1 AI uses Apple Foundation Models on supported iOS 26 devices, with a clearly labeled Quick rules fallback. No cloud AI service or account is required. iOS 26 uses native Liquid Glass navigation; iOS 18 retains translucent system navigation.
