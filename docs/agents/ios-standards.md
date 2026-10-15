# iOS implementation standards

Use these conventions when implementing or reviewing `apps/ios`. [V1 architecture](../architecture/v1.md) owns privacy/storage boundaries. [DESIGN.md](../../DESIGN.md) and the affected design contract own UI decisions. Inspect existing consumers before extending a shared type.

## Locate the owner

| Change | Existing seam |
| --- | --- |
| Pure rules, validation, stable value types | `Core/Sources/AQDCore`, with tests in the Core package |
| Local records, receipts, migrations and media references | `AQD/Persistence/PieceStore.swift`, `StoredTodayConfiguration.swift` and their native tests |
| App navigation and task coordination | `AQD/AppState.swift`, `AQD/AQDApp.swift`, `AQD/UI/RootViews.swift` |
| Media preparation and framing | `AQD/Media/PhotoPreparer.swift`, Core photo values and existing editor/capture views |
| Shared native UI | `AQD/UI/AppTheme.swift`, `AppMetrics.swift`, `AppActions.swift`, `AppFields.swift`, `AppRows.swift`, `AppFeedback.swift`, `NativeTabs.swift` |

Paths are relative to `apps/ios`. These are current extension points, not a requirement to grow one file forever. Keep feature-specific views/models beside their existing consumers. Extract a focused file when its responsibility is clear. A new architecture layer or cross-platform adapter needs an actual consumer.

## Swift and state

- Match existing Swift naming, access levels and Observation/SwiftUI state ownership. Prefer explicit value types and typed errors at domain boundaries. Reuse Core validators in native save paths.
- Keep UI/coordinator and SwiftData operations on their existing `@MainActor` boundary. Keep media work in the existing isolated preparer. Preserve cancellation and request/draft identity checks so stale results cannot replace a newer choice.
- Give one owner responsibility for each draft and navigation selection. Back, Cancel and interactive dismissal preserve the documented source, selection and unsaved changes. Successful receipts describe acknowledged writes, not optimistic UI state.
- Retain the current deployment target and availability guards. Verify a new API against installed SDK declarations or official Apple documentation before using it. Product docs describe intended APIs, not proof that the current SDK compiles them.

## Local data and media

- Extend the existing versioned schema and migration plan. Freeze delivered schema versions; test populated old-store migration and reopen for structural changes. A corrupt/newer store stays recoverable rather than becoming an empty closet.
- Preserve stable IDs, revisions and operation receipts through save/retry. Test the actual public save/read path, including failed writes and unknown completion when affected.
- Prepare required media before storing references. Preserve originals and old referenced media until replacement commits. Extend reference-scoped cleanup for every new owner, including drafts and historical snapshots.
- Keep CloudKit disabled, file protection and backup exclusions intact. Debug fixtures use temporary directories or the existing isolated test-store guard. Keep ordinary user data out of test setup and logs.
- Keep private/manual journeys usable without account, network or model readiness. Follow the approved WeatherKit exception and on-device capability contracts only when those branches are in scope.

## Native UI

- Reuse semantic colors, metrics, actions, fields, feedback and rows from the current foundation. Use native navigation, forms, sheets, menus and confirmations as routed by [design procedure](../design/rules.md).
- Implement each affected loading, empty, editing, invalid, disabled, error, cancelled and successful state. Keep labels and errors explicit; destructive actions describe their actual local effect.
- Keep native accessibility labels/traits, Dynamic Type, at least 44-point targets, light/dark appearance and keyboard-safe editing in the implementation. Record rendered/device checks for the verification stage authorized by the plan.
- Update [interaction coverage](../design/v1-interactions.md) when controls/routes change and the [implementation ledger](../design/evidence/v1-implementation-coverage.json) when owned root status changes. Design-complete and runtime-passed remain distinct fields.

## Tests and review

Test pure rules in Core and persistence/media/recovery through the existing native test seams. Swift Testing and XCTest both exist; follow the neighboring suite. Prefer temporary populated stores and actual file operations to tests of private implementation details. Add regression tests for changed behavior. UI ACs require focused app-driven E2E and inspected/rendered PR evidence under [acceptance proof](acceptance-proof.md); cosmetic acceptance needs actual visual evidence rather than mirrored unit tests. Documentation-only work uses its appropriate checks.

Use [`aqd-verify`](../../.agents/skills/aqd-verify/SKILL.md) to select checks and [`aqd-review`](../../.agents/skills/aqd-review/SKILL.md) before delivery. The [issue-plan convention](../pan/README.md) owns slice commits and resumable evidence.
