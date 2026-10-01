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

Start with [product documentation](docs/README.md), the complete [V1 release definition](docs/V1-RELEASE.md) and [V2 backlog](docs/V2-BACKLOG.md). The current checkout has no tracked Swift source/build definition or iOS setup guide matching the historical prototype; establish a reproducible app baseline before implementation.

Historical prototype notes describe private wardrobe persistence, clothing photos, outfits, wear tracking, search and rule-based suggestions, with limited auth/Agent/community work. These are not current-release verification. See [implementation status](docs/IMPLEMENTATION.md). Android can be added independently under `apps/android/` when development begins.

V1 targets Apple Foundation Models on supported iOS 26 devices, with a clearly labeled Quick rules fallback. No cloud AI service or account is required. iOS 26 uses native Liquid Glass navigation; iOS 18 retains translucent system navigation.

Repository hooks and automatic versioning: [development workflow](docs/DEVELOPMENT-WORKFLOW.md).

GitHub: [vn-aj-vngrd/aqd](https://github.com/vn-aj-vngrd/aqd). Use `gh auth switch --hostname github.com --user vn-aj-vngrd` for the personal account (`vanajvanguardia@gmail.com`). With two accounts logged in, check the active account first when a GitHub operation fails. Agents start from [AGENTS.md](AGENTS.md) and the [engineering lifecycle](docs/agents/LIFECYCLE.md).
