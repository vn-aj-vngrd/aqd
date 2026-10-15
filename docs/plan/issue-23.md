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
| S1 | Three real Closet collections, source-preserving navigation, Add and scoped search start/results/empty/failure | W4, O2; scoped LOCAL-11 | Committed | `AQD-Slice: #23/S1` | `c49469b` |
| S2 | Piece metadata, availability/filter/sort and archive/Undo/restore; retained records and references | W3–5, W7; scoped LOCAL-03 | Committed | `AQD-Slice: #23/S2` | `84a5011` |
| S3 | Reviewed piece deletion with exact outfit/theme/future-plan impact and historical snapshots retained | W6; scoped LOCAL-03/04 | Committed | `AQD-Slice: #23/S3` | Pending |
| S4 | Theme collection/create/detail/options/edit/multiple membership/favorite/search/delete without deleting outfits | O3, O4, O7; scoped LOCAL-04/11 | Planned | `AQD-Slice: #23/S4` | Pending |

## Acceptance and evidence

Each slice adds focused behavior tests at the affected public seam. Record genuine RED/GREEN, source revision, unit/build results and review coverage when executed. UI runtime acceptance is Deferred to #30, never inferred from units or Paper. S1 passes Core51 and physical native117 with zero failures (`/tmp/aqd-23-s1-unit-final.log`), plus a subsequent focused five-case search regression run (`/tmp/aqd-23-s1-search-refresh.log`). Generic iOS Debug builds. The additional regression proves malformed stored records produce an error rather than an empty collection. These unit results do not certify rendered UI acceptance.

## Deferred final verification

All E2E, physical integrated acceptance, accessibility/media/privacy/performance qualification and cross-domain matrix stay in #30. Implement real success/cancel/empty/error/stale/unknown-write recovery now; known product/data-loss/security defects are blocking. Preserve ordinary local data and delivered schema versions.

## Review and shipping

One grouped PR closes #24 and #23. Keep per-slice commits and separate issue acceptance; complete latest-head unit CI/Codex, resolved threads, protected squash and merged-SHA CI/repository release. No TestFlight/App Store scope.

## Resume

- Companion #24 S1–S6 now supplies real outfits/themes/Plan/Wear/lifecycle. Native unit verification uses the confirmed-ready physical iPhone; all E2E remains #30.
- Next: #23/S4 independent theme deletion, saved-source polish and final grouped review. PR33 delivery is verified in the baseline above.

## S1 collection and search receipt

Real Pieces/Outfits/Themes collections use owned records and typed shared destinations. Contextual Add opens actual capture, outfit and theme tasks. Native scoped search preserves the originating collection, supports independent outfit favorite/theme filters, includes archived piece badges and distinguishes blank/loading/empty/no-match/failure states. Query identity prevents superseded results from replacing newer input. Explicit saved-result navigation clears old searches; Cancel restores the source. Paper collection cards and photo grids inform layout; physical UI acceptance stays #30.

Bounded Standards/Spec review covered owned search scope, malformed record errors, source returns, stale async results, photo framing, provisional theme membership and Dynamic Type. No unresolved finding in this increment; final independent grouped review remains. Existing E2E selectors will be reconciled in #30, including contextual Add.

## S2 piece management receipt

Piece detail exposes optional metadata, actual recorded wear, separately labelled prior estimate and unknown dated history, a pinned Style this task, edit and real availability choices. Wear sorts use total counts or recorded last-worn dates with deterministic ties and explicit estimate/unknown copy. Archived pieces has its own searchable destination. Archive/availability preserve outfits/history and flag affected future plans; restore/Undo preserves review flags. Availability retries reconcile the exact committed result.

Core52 and physical native121 (108 Swift Testing plus13 XCTest) pass, zero failures, `/tmp/aqd-23-s2-recovery-final.log`. The earlier run failed a first-use recovery case when DB/WAL checkpointing changed its inspected snapshot. Recovery now retries only a detected changing snapshot, at most three times, retaining the protected disposable-copy/refusal rules. The final run includes both first-use windows and populated/corrupt/newer-store refusal tests. An earlier availability feedback compile error was corrected before execution. Bounded Standards/Spec review covered owner state, atomic plan flags, stable identities, actual/estimated counts and unknown-save retry. UI/E2E acceptance remains #30.

## S3 reviewed deletion receipt

Piece More opens a real impact review listing affected outfits and future dates, with exact outfit/theme/plan revision checks before native destructive confirmation. Changed dependencies reject the review without partial mutation. Deletion removes piece references, deletes newly empty outfits and only their theme memberships, and unassigns every affected future plan, including plans using a surviving outfit. Dates/occasions and historical non-photo wear snapshots remain. Revision-only review receipts add preserving V8→V9 migration; delivered schemas stay frozen. Existing deletion acknowledgment, bounded photo ownership/cleanup and corrupt-proof guards remain.

Core52 and physical native124 (111 Swift Testing plus13 XCTest) pass, zero failures, `/tmp/aqd-23-s3-complete.log`. New cases cover exact cascade/reopen/retry, stale dependency rejection and populated V8 preserving migration. Existing wear deletion regression now explicitly reviews the impact. Earlier compile-only failures in SwiftUI localized interpolation/ScrollView overload resolution were corrected before execution. Bounded Standards/Spec review covered exact impact, remaining memberships, future-plan re-selection, receipt privacy and historical media independence. UI/E2E acceptance stays #30.
