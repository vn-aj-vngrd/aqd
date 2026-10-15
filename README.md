# AQD

**Your wardrobe, understood.**

V1 is a complete private, device-only iPhone closet app: Today, Closet, Planner, Agent, local Profile with a private fit journal, Settings, onboarding and light/dark modes. V2 extends the same app and preserves the complete connected product, including community, Inbox, sync and broader styling/planning.

## Repository layout

```text
apps/
  ios/        Native SwiftUI iPhone app and Xcode project
  android/    Reserved for future Android development (not created yet)
docs/         Shared product, design, architecture and delivery documentation
```

Start with [product documentation](docs/README.md), the local [V1 release definition](docs/product/v1-release.md) and [V2 backlog](docs/product/v2-backlog.md). The tracked [native SwiftUI baseline](apps/ios/README.md) includes an Xcode project, local piece capture/persistence and native tests; it is not complete V1. The [active implementation plan](docs/delivery/implementation-plan.md) has ten implementation issues: reusable Foundation first, then one vertical-slice issue/PR per Paper V1 section01–09, followed by final E2E/hardening #30.

Historical prototype notes describe private wardrobe persistence, clothing photos, outfits, wear tracking, search and rule-based suggestions, with limited auth/Agent/community work. These are not current-release verification. See [implementation status](docs/delivery/implementation-status.md). Android can be added independently under `apps/android/` when development begins.

V1 targets Apple Foundation Models on supported iOS 26 devices, with a clearly labeled Quick rules fallback. No cloud AI service, account, app backend or managed sync is required. Core manual work remains available without the model or network. Optional native Apple WeatherKit live context now belongs to V1 and is retained in V2: off until chosen, selected place/date only, direct Apple calls without AQD sign-in/backend, with honest forecast bounds and manual/offline recovery. Local storage is not a zero-network promise. See the [weather contract](docs/product/v1-release.md#optional-live-weather-contract) and [Apple evidence](docs/references/weatherkit-v1.md); weather capability and complete native release acceptance remain unverified. See separate [V1](docs/architecture/v1.md) and [V2](docs/architecture/v2.md) architectures. iOS 26 uses native Liquid Glass navigation; iOS 18 retains translucent system navigation.

For approved feature work, use the [autonomous workflow](docs/agents/autonomous-workflow.md) and persist [issue-keyed slice plans](docs/pan/README.md). The immediate personal-MVP target is iPhone 17 Pro Max; broader launch compatibility stays in release hardening.

Repository hooks and automatic versioning: [development workflow](docs/delivery/workflow.md).

GitHub: [vn-aj-vngrd/aqd](https://github.com/vn-aj-vngrd/aqd). Use `gh auth switch --hostname github.com --user vn-aj-vngrd` for the personal account (`vanajvanguardia@gmail.com`). With two accounts logged in, check the active account first when a GitHub operation fails. Agents start from [AGENTS.md](AGENTS.md) and the [engineering lifecycle](docs/agents/lifecycle.md).
