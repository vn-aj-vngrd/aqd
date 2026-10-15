# Issue 24: feat(ios): Build V1 section 04 — Outfit creation and review

## Scope

- Issue: https://github.com/vn-aj-vngrd/aqd/issues/24
- Companion: [issue 23](issue-23.md), one shared PR, internal order #24 then #23.
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
| S1 | Build/save/reopen and edit a manual outfit from owned pieces; durable draft, chooser and private receipt with failure/retry recovery | O1, O2, O7 | Committed | `AQD-Slice: #24/S1` | `261be64` |
| S2 | Create/select multiple themes during outfit save; preserve names, memberships and identity | O3, O4, O7 | Committed | `AQD-Slice: #24/S2` | `0f4666d` |
| S3 | Readiness/pinned first outfit and labelled rules/manual fallback; reviewed suggestions and safe replacement | O5, O6, O8, O9; W8–9 | Committed; model activation deferred #30 | `AQD-Slice: #24/S3` | `75c01c1` |
| S4 | Date-prefilled real Plan review/save/restart, distinct from wear | O9; scoped LOCAL-04/09 | Committed | `AQD-Slice: #24/S4` | Pending |
| S5 | Explicit Record wear review/save/deduplication and historical snapshots | O9; scoped LOCAL-04/09 | Planned | `AQD-Slice: #24/S5` | Pending |
| S6 | Outfit More/favorite/edit/delete with exact reference impact | O1; scoped LOCAL-04/11 | Planned | `AQD-Slice: #24/S6` | Pending |

## Acceptance and evidence

Each slice adds focused behavior tests at the affected public seam. Record genuine RED/GREEN, source revision, unit/build results and review coverage when executed. UI runtime acceptance is Deferred to #30, never inferred from units or Paper. No test result is claimed yet.

## Deferred final verification

All E2E, physical integrated acceptance, accessibility/media/privacy/performance qualification and cross-domain matrix stay in #30. Implement real success/cancel/empty/error/stale/unknown-write recovery now; known product/data-loss/security defects are blocking. Preserve ordinary local data and delivered schema versions.

## Review and shipping

One grouped PR closes #24 and #23. Keep per-slice commits and separate issue acceptance; complete latest-head unit CI/Codex, resolved threads, protected squash and merged-SHA CI/repository release. No TestFlight/App Store scope.

## Resume

- Discovery complete for the first manual outfit seam. The owner confirmed physical iPhone readiness; no native run yet.
- Next: verify PR33 delivery, create branch from merged main, inspect live Paper descendants/styles for the first slice and implement its complete manual journey.


### S1 unit receipt

Manual outfit builder/chooser/private receipt and collection/detail/edit paths are implemented. V4 adds outfit/draft/operation records through preserving V3→V4 migration; delivered V1–V3 model definitions remain unchanged. Immutable receipts prevent duplicate/conflicting retries. Unmarked populated outfit storage is rejected rather than reseeded. Media stays piece-owned.

Core40 pass, including four new public outfit-rule tests. Focused output: `/tmp/aqd-outfits-core-green.log`; full Core: `/tmp/aqd-24-unit-s1.log`. Final physical native100 pass:87 Swift Testing +13 XCTest, zero failures; `/tmp/aqd-24-unit-s1-final.log`. Initial sandbox Core execution was blocked by compiler-cache permissions, not behavioral RED; escalated focused4/full40 passed. No E2E or simulator execution. UI acceptance is Deferred to #30.

Bounded self-review covers Standards (preserving migration, operation identity, accessible controls and failed-write/draft preservation) and Spec (manual O1/O2/O7 subset). It found/fixed the unmarked-populated-store bootstrap gap and disabled edits during unknown-save reconciliation. Full independent group review remains before PR completion. Live Paper builder/chooser/outfit collection/detail JSX was read from the approved file, tokenfdeb7346. No runtime visual fidelity claim. Next S2 adds themes; S3/S4 complete assistance and real Plan/Wear before group delivery. Resolve S1's SHA using its unique marker; persist it in S2.

Native result bundle: `/tmp/aqd-24-device-s1/Logs/Test/Run-AQD-2026.10.16_00-59-28-+0800.xcresult`.


### S2 theme membership receipt

Create/select themes from the outfit editor, with native nested forms and independent recoverable theme drafts/receipts. Empty collections and case-insensitively unique names are supported. Outfit save updates all selected memberships in the same transaction as the outfit and receipt; editing preloads current memberships. Rename preserves membership and identity; theme deletion/collection management remains #23/S4. No earlier native schema stored prototype outfits or theme strings, so no legacy names are fabricated. V5 adds dedicated theme records through preserving V4→V5 migration.

The piece chooser now follows the live Paper two-column134pt photo tiles, compact category chips, retained selected count and Add selected pieces. It edits a local selection until Apply, so native Back cancels without changing the parent draft. No rendered-device claim is inferred from these source changes.

Passed Core42 and physical native102 (89 Swift Testing +13 XCTest), zero failures; `/tmp/aqd-24-s2-core-final.log`, `/tmp/aqd-24-s2-unit-final.log`. Native result: `/tmp/aqd-24-device-s1/Logs/Test/Run-AQD-2026.10.16_01-05-56-+0800.xcresult`. The first test build failed on a nested require macro; corrected it before the passing final run. Bounded Standards/Spec self-review covered owner/name/membership validation, atomic writes, immutable receipts, draft cancellation and source-compatible schema fixtures. All E2E and integrated UI acceptance remain #30. Next S3 completes readiness/pins/replacement and supported assistance/manual fallback.


### S3 first outfit, pins and reviewed suggestions

First saved piece → Build my first outfit persists its pin and category-based readiness. Missing-category capture preselects only a genuinely empty draft, retains the parent outfit and resumes after native dismissal/cancel/relaunch. Manual partial looks remain valid. Selection/replacement preserves name/context/themes and pins; changed piece revisions require review. Rule-based suggestions are explicitly labelled, form a reviewed draft and never save automatically. Provenance survives restart. Model availability distinguishes hardware, Apple Intelligence off, preparation and unsupported locale; cloud/photo/notes/body uploads are absent.

The actual typed Foundation Models on-device request path is compiled, bounds candidates/response/deadline through a qualification record, checks owned IDs/pins/completeness/current revisions and rejects cancellation/stale results. Activation intentionally remains off until #30 supplies measured on-device quality/latency qualification; do not set arbitrary budgets or pretend runtime availability proves quality. Manual/rules paths remain available. This is an explicit final-hardening activation gate, not a passing model/device-quality claim.

New readiness/pin tests first failed compilation against absent APIs (`/tmp/aqd-24-s3-red.log`). Core45 then passed, generic iOS Debug built and physical native104 passed (91 Swift Testing +13 XCTest), zero failures, `/tmp/aqd-24-s3-unit.log`. Source review then corrected the pure replacement validator to permit partial manual looks and added its regression; current Core46 pass in `/tmp/aqd-24-s3-core-final.log`. The preceding native104 result is reused only for unchanged native flows; final grouped native units will compile the later pure change. All E2E/UI runtime acceptance remains #30. Bounded Standards/Spec review covered exact task return, pin/provenance durability, no-write proposals, revision guards and manual fallback. Next S4 completes real Plan/Wear and outfit More/favorite/delete.


### S4 real Plan review and save

Outfit detail and saved receipt now open a real date-prefilled Plan task. Explicit selected timezone/calendar day survive restart/travel; changing timezone preserves the chosen year/month/day. Selecting an outfit uses its current owned revision; Leave unassigned is explicit and saves a labelled gap. Same-day/occasion collisions require Keep both; no prior assignment is overwritten. Plan/draft/operation records migrate through V6 without altering delivered schemas. A minimal actual Planner list/detail exposes the saved entries and shared outfit identity; #25 extends this same model/calendar rather than replacing a placeholder route.

Core48, generic iOS Debug build and physical native107 (94 Swift Testing +13 XCTest) pass with zero failures. Logs: `/tmp/aqd-24-s4-core-final.log`, `/tmp/aqd-24-s4-build.log`, `/tmp/aqd-24-s4-unit.log`. New tests cover V5 outfits/themes preserving migration, exact dates/reopen, explicit unassigned/overlap and denied/unknown save retries. This native run also compiles/tests S3's later pure partial-replacement correction. Bounded Standards/Spec review covers snapshot/revision ownership, exact acknowledgments, explicit no-overwrite choices, stable date identity and no implicit wear. Actual wear is implemented separately in S5; all E2E/UI acceptance stays #30.

Native result: `/tmp/aqd-24-device-s1/Logs/Test/Run-AQD-2026.10.16_01-24-22-+0800.xcresult`.
