# AQD

**Your wardrobe, understood.**

V1 is a complete private, device-only iPhone closet app: Home, Closet, Agent, local Profile, Settings, onboarding and light/dark modes. V2 extends the same app and preserves the complete connected product, including community, Inbox, sync and broader styling/planning.

## Repository layout

```text
apps/
  ios/        Native SwiftUI iPhone app and Xcode project
  android/    Reserved for future Android development (not created yet)
docs/         Shared product, design, architecture and delivery documentation
```

Start with [product documentation](docs/README.md), the local [V1 release definition](docs/product/v1-release.md) and [V2 backlog](docs/product/v2-backlog.md). The current checkout has no tracked Swift source/build definition or iOS setup guide matching the historical prototype; establish a reproducible app baseline before implementation.

Historical prototype notes describe private wardrobe persistence, clothing photos, outfits, wear tracking, search and rule-based suggestions, with limited auth/Agent/community work. These are not current-release verification. See [implementation status](docs/delivery/implementation-status.md). Android can be added independently under `apps/android/` when development begins.

V1 targets Apple Foundation Models on supported iOS 26 devices, with a clearly labeled Quick rules fallback. No cloud AI service, account, app backend or managed sync is required. Core manual work remains available without the model. See separate [V1](docs/architecture/v1.md) and [V2](docs/architecture/v2.md) architectures. iOS 26 uses native Liquid Glass navigation; iOS 18 retains translucent system navigation.

Repository hooks and automatic versioning: [development workflow](docs/delivery/workflow.md).

GitHub: [vn-aj-vngrd/aqd](https://github.com/vn-aj-vngrd/aqd). Use `gh auth switch --hostname github.com --user vn-aj-vngrd` for the personal account (`vanajvanguardia@gmail.com`). With two accounts logged in, check the active account first when a GitHub operation fails. Agents start from [AGENTS.md](AGENTS.md) and the [engineering lifecycle](docs/agents/lifecycle.md).
