# Issue 23: feat(ios): Build V1 section 03 — Closet, search and themes

## Scope

- Issue: https://github.com/vn-aj-vngrd/aqd/issues/23
- Companion: [issue 24](issue-24.md), one shared PR, internal order #24 then #23.
- Branch: `van/issue-24/outfits-and-closet`
- Authorized endpoint: full lifecycle for the owner-approved grouped delivery.
- Predecessor: #21 / PR33; merged in PR33 as `f89a2dee7bbfb661721730ad2f43a92b5f916c88`; merged-main CI/Release passed and published v1.2.0 points exactly to that SHA.
- Baseline: `f89a2de`; working source inspection finds only pieces implemented, Outfits/Themes explicitly unimplemented.
- Contracts: [outfits/themes](../features/outfits-themes.md), [wardrobe](../features/wardrobe.md), [planning/wear](../features/planning-history.md), [trusted Agent actions](../features/agent.md), [design](../../DESIGN.md), [interactions](../design/v1-interactions.md).
- Verification: affected Core/native units, fast repository/tooling unit CI and Codex review. All E2E authoring/execution and integrated physical UI acceptance deferred to #30; no simulators. Ask for connected/unlocked physical iPhone readiness before native tests.
- Agreed existing test seams: public Core validation and actual PieceStore save/read/reopen/retry/migration; no new interview required.

## Slices

| Slice | Working outcome | Acceptance | State | Commit marker | SHA |
| --- | --- | --- | --- | --- | --- |
| S1 | Three real Closet collections, source-preserving navigation, Add and scoped search start/results/empty/failure | W4, O2; scoped LOCAL-11 | Planned | `AQD-Slice: #23/S1` | Pending |
| S2 | Piece metadata, availability/filter/sort and archive/Undo/restore; retained records and references | W3–5, W7; scoped LOCAL-03 | Planned | `AQD-Slice: #23/S2` | Pending |
| S3 | Reviewed piece deletion with exact outfit/theme/future-plan impact and historical snapshots retained | W6; scoped LOCAL-03/04 | Planned | `AQD-Slice: #23/S3` | Pending |
| S4 | Theme collection/create/detail/options/edit/multiple membership/favorite/search/delete without deleting outfits | O3, O4, O7; scoped LOCAL-04/11 | Planned | `AQD-Slice: #23/S4` | Pending |

## Acceptance and evidence

Each slice adds focused behavior tests at the affected public seam. Record genuine RED/GREEN, source revision, unit/build results and review coverage when executed. UI runtime acceptance is Deferred to #30, never inferred from units or Paper. No test result is claimed yet.

## Deferred final verification

All E2E, physical integrated acceptance, accessibility/media/privacy/performance qualification and cross-domain matrix stay in #30. Implement real success/cancel/empty/error/stale/unknown-write recovery now; known product/data-loss/security defects are blocking. Preserve ordinary local data and delivered schema versions.

## Review and shipping

One grouped PR closes #24 and #23. Keep per-slice commits and separate issue acceptance; complete latest-head unit CI/Codex, resolved threads, protected squash and merged-SHA CI/repository release. No TestFlight/App Store scope.

## Resume

- Discovery complete for the first manual outfit seam. The owner confirmed physical iPhone readiness; no native run yet.
- Next: verify PR33 delivery, create branch from merged main, inspect live Paper descendants/styles for the first slice and implement its complete manual journey.
