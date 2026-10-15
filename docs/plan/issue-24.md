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
| S1 | Build/save/reopen and edit a manual outfit from owned pieces; durable draft, chooser and private receipt with failure/retry recovery | O1, O2, O7 | Committed | `AQD-Slice: #24/S1` | Pending |
| S2 | Create/select multiple themes during outfit save; preserve names, memberships and identity | O3, O4, O7 | Planned | `AQD-Slice: #24/S2` | Pending |
| S3 | Readiness/pinned first outfit and labelled rules/manual fallback; reviewed suggestions and safe replacement | O5, O6, O8, O9; W8–9 | Planned | `AQD-Slice: #24/S3` | Pending |
| S4 | Outfit detail/More/favorite/edit/delete plus real date-prefilled Plan and separate Record wear save paths | O1, O9; scoped LOCAL-04/09/11 | Planned | `AQD-Slice: #24/S4` | Pending |

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
