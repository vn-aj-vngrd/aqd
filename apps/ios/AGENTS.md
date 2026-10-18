# Native iOS

Read [DESIGN.md](../../DESIGN.md) before UI work and the affected [feature contract](../../docs/features). Inspect the seam and its callers before editing, and reuse before adding. Verify with [`aqd-verify`](../../.agents/skills/aqd-verify/SKILL.md) on the physical iPhone 17 Pro Max; never start a simulator.

## Layers

Dependencies point down. `scripts/check-ios-layers.mjs` enforces the import rules in the pre-commit hook and `pnpm check`.

```text
AQD/
  App/            Composition root: AQDApp, AppState (navigation, coordination), root views, tabs, Debug/
  Features/<X>/   One folder per feature: Closet, Outfits, Planner, Wear, Today, Agent, Profile, Settings, Onboarding, Weather
  DesignSystem/   Foundation/ (AppTheme, AppMetrics), Components/ (shared controls and presentation)
  Services/       Adapters over Apple frameworks and the model: Agent, Weather, Archive, Media
  Persistence/    SwiftData store (one `PieceStore+<Aggregate>.swift` per aggregate), stored models, schemas, receipts
  Resources/      Assets, launch colors, bundled artwork
Core/             Swift package: pure rules, validation, value types (the domain layer)
AQDTests/         Mirrors the layers: App, DesignSystem, Features, Persistence, Services, Support
```

| Layer | May import | Must not |
| --- | --- | --- |
| Core | Foundation | SwiftUI, UIKit, SwiftData |
| Persistence | Core, SwiftData | SwiftUI, UIKit |
| Services | Core, system frameworks | SwiftUI, SwiftData |
| DesignSystem | Core, SwiftUI, UIKit | SwiftData, feature code |
| Features | Core, DesignSystem, Services; storage only through `AppState` | SwiftData; another feature's internals |
| App | everything | |

## Conventions

- **Placement.** Put a file in the layer that owns its reason to change. A pure rule goes to Core with a Core test. A framework adapter goes to Services. A reusable control goes to DesignSystem. Code used by one feature stays in that feature. Never add files at the `AQD/` root or an `UI/` folder.
- **Features.** View models are `@Observable` types named `*Model.swift` and never import SwiftUI. Views are `*View.swift` or `*Views.swift`. Name files after their main type, one primary type per file.
- **Sharing.** Features do not call each other's views or models. Shared behavior moves down into DesignSystem, Services or Core. Navigation between features goes through `AppState`.
- **State.** Each draft and navigation selection has one owner. Check draft and request identity before applying async results. Keep UI and storage on the main actor and media work in the isolated preparer.
- **Labels.** No middle-dot (" · ") separators in any UI string; follow the no-dot rule in [DESIGN.md](../../DESIGN.md).
- **Safety.** No `try!`, forced casts, or force unwraps outside tests. Typed errors at domain seams. A receipt reports an acknowledged write only.
- **Guards.** Deployment is iOS 18. Guard iOS 26+ APIs with `#available` and a flat fallback. Verify new APIs against the installed SDK.
- **Tests.** Swift Testing for new tests, following the neighboring suite. Test through the public interface, including failed and unknown-completion writes. Mirror the source layer in `AQDTests`.
- **Moves.** Use `git mv` so history follows. The Xcode groups are folder-synchronized: no project edits are needed for add, move or delete.

## Lint and format

- `swiftlint lint --quiet` (config `.swiftlint.yml`): errors fail the commit hook; warnings (line length 160, file length 800, force unwraps, complexity) are targets for code you touch. No inline disables without a reason on the same line.
- `swiftformat .` (config `.swiftformat`): whitespace only. Never reformat files you did not change.
- `node scripts/check-ios-layers.mjs`: import and folder rules above.
- Install once: `brew install swiftlint swiftformat`. Editors and agents can use `sourcekit-lsp` from the Xcode toolchain for diagnostics and navigation.
