# AQD

Private, on-device iPhone closet app (SwiftUI, deploys iOS 18, builds with Xcode 27). Roots: Today, Closet, Planner, Agent, Profile. V1 is local-only (no account, backend or cloud AI). V2 is the connected extension, kept as a backlog in [product](docs/product.md).

## Read by task

| Task | Read |
| --- | --- |
| Scope, decisions, V2 backlog | [docs/product.md](docs/product.md) |
| Storage, media, Agent, weather, privacy boundaries | [docs/architecture.md](docs/architecture.md) |
| Behavior of a feature | [docs/features/](docs/features): wardrobe, outfits-themes, planner, today, agent, profile |
| Any UI | [DESIGN.md](DESIGN.md), the source of truth: tokens, components, modal pattern |
| Domain words | [CONTEXT.md](CONTEXT.md) |
| Swift, Xcode, native tests | [apps/ios/AGENTS.md](apps/ios/AGENTS.md) |
| Lasting decisions | [docs/adr](docs/adr) |

Delivery (tickets, branches, reviews and PRs) runs through Van's factory, outside this repo; its usage is `~/Documents/van/factory/USAGE.md`. The owner squash-merges after CI, and the release workflow tags the merge.

## Rules

- **Plans, status and evidence live in GitHub issues**, never in repo files. Docs hold only stable contracts and decisions; change a contract in the same PR as its behavior.
- **Respect the iOS layers** (App, Features, DesignSystem, Services, Persistence, Core) and their import rules in [apps/ios/AGENTS.md](apps/ios/AGENTS.md); `pnpm check` enforces them.
- **Reuse before building.** UI composes the shared components in `apps/ios/AQD/UI` (`AppChip`, `glassControlSurface`, `SharedPhotoSourceButton`, selection strips, `ToolbarSaveAction`). Colors come from `AppTheme`; charcoal is the only control color.
- **Run native checks on the physical iPhone 17 Pro Max.** Ask the owner to connect and unlock it first. Only the factory's automated runs use a simulator: app unit tests during building and UI proof screenshots for PRs.
- **Preserve user data.** Drafts, stable IDs and acknowledged writes survive failure; corrupt or newer stores are never replaced.
- **Commit subjects** are `action(part): Description`, one line, no body, no co-author lines.
