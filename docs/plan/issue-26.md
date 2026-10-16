# Issue 26: Actual wear, history and insights

## Scope

- Issue: https://github.com/vn-aj-vngrd/aqd/issues/26
- Companion: [#25](issue-25.md), shared PR, internal order #25 then #26.
- Branch: `van/issue-25/planner-and-history`; baseline `e71e1ded830db3ae2568c547af2de846aeaf0b60` (PR34/v1.3.0).
- Endpoint: one PR for #25 + #26, current-head unit CI/Codex, resolved findings, protected squash and exact merged-SHA repository release verification.
- Verification: Core/public PieceStore/native state unit seams and final unsigned Release. Physical iPhone17ProMax only; readiness confirmed October16 and discovered available. All simulators shutdown; never start one. All E2E authoring/execution, integrated UI/accessibility/device/model qualification remain #30.
- Contracts: [planning/history](../features/planning-history.md), [calendar design](../design/planner-calendar.md), [interactions](../design/v1-interactions.md), [V1 acceptance](../product/v1-release.md), [iOS standards](../agents/ios-standards.md).
- Extend actual Plan/Wear records/drafts/receipts and preserve schema V1–V14. No sample records, automatic wear, cloud model, notifications or external calendar. Optional weather consumer qualification completes in #22/#29; manual/offline planning must work with weather off. Journal-dependent P10 is scoped to #28, with reusable wear semantics here.

## Slices

| Slice | Working outcome | Acceptance | State | Marker | SHA |
| --- | --- | --- | --- | --- | --- |
| S1 | Explicit planned/worn/skipped state with matching-record consent and linked immutable wear snapshots | P7/P8, scoped P10 | Implemented, unit verified | `AQD-Slice: #26/S1` | `6327367` |
| S2 | Wear detail/backdate/correct/Undo with exactly-once counts and duplicate-safe recovery | P7/P8, scoped LOCAL-03/05 | Implemented, unit verified | `AQD-Slice: #26/S2` | `28be512` |
| S3 | History/calendar/empty states and reproducible period insights with estimate/denominator labels | P9, supporting P10 | Implemented, unit verified | `AQD-Slice: #26/S3` | `e067a73` |

## Evidence and review

Each slice records actual unit/build results, failures, reviewed increment and its commit. Use pure calendar/range/packing/statistic tests and actual temporary populated-store save/read/reopen/retry/migration checks. UI source follows live Paper; no rendered acceptance claim from units. Final grouped Standards/Spec review includes all new files and tests, then source-bound unit receipt/AC table in the PR. Keep all existing media/ownership/corruption guards.

## Resume

Companion #25 S1–S4 is implemented and unit verified on this shared branch. All seven feature slices are implemented and unit verified. Local implementation/review/unit/Release gates pass. Continue PR creation on the existing branch, current-head CI/Codex, protected squash and exact merged-SHA release verification. The physical iPhone remains the only native destination; all E2E stays #30.

## S1 explicit wear receipt

Explicit plan-entry Record wear carries the reviewed entry/day/timezone into the retained task. Saving atomically creates or explicitly reuses the matching item-set/day wear, marks only that exact entry Worn and links its record ID. Skip is revision-bound and creates no wear. Reviewed whole-plan deletion removes only that plan/entries/packing state, preserving actual wear snapshots/counts. New optional payload fields preserve older records; schema V14 adds immutable history-operation receipts and a preserving V13 migration stage. Source photos/notes never become history owners.

The new public-store tracer failed compilation before implementation (`/tmp/aqd-26-s1-red.log`). Core58 and physical iPhone native145 (132 Swift Testing +13 XCTest) passed `/tmp/aqd-26-s1-unit.log`. The compiler first exposed the new skip action’s shadowed error binding, corrected before the successful run. The actual-store case covers explicit link, historical provenance, idempotent plan deletion and skip with unchanged actual counts. Existing denied/unknown wear, snapshot/deletion/reopen and V6 migration cases remain green. Bounded Standards/Spec increment review covered atomicity, stale guards, completed states, owner checks, historical isolation and receipt-first retries. Final independent group review and UI/E2E qualification remain pending, with all E2E in #30.

## S2 correction and Undo receipt

Wear detail exposes read-only minimal recorded names/categories, correction and confirmed Undo. Correction retains the same record ID, increments its revision, preserves snapshots for retained item IDs including deleted source pieces, and rechecks identical item-set/day duplicates. Changing date/items resets surviving linked intentions rather than silently moving a plan. Undo removes the exact reviewed wear once and resets every surviving linked entry; deleted plans stay deleted. Historical save acknowledgments do not recreate undone wear. The timezone picker reuses the shared searchable chooser; changed dates/zones visibly detach plan linkage.

The correction tracer first failed compilation against absent APIs (`/tmp/aqd-26-s2-red.log`). All5 focused native Wear cases pass on the physical iPhone (`/tmp/aqd-26-s2-final.log`), including two-entry existing-record consent, duplicate refusal, same-ID backdate/correction, lost acknowledgment and exactly-once Undo. SwiftUI name lookup was split to correct compiler timeouts; an accidentally overlapping retry hit the Xcode build lock and was discarded, followed by the successful serial run. No simulator/E2E ran. Bounded Standards/Spec increment review checked stale record equality, snapshot preservation, receipt-first recovery and aggregate count derivation. Full unit/Release/independent review follows S3.

## S3 history and insights receipt

Real recent history opens each actual wear detail, with an alternate selected-day calendar and source-period filtering. Toolbar recording carries the selected date; empty history/day has a useful Record a look path and Planner return. Profile exposes the shared history/insights destinations. Monthly factual insights distinguish wear occasions from individual item occurrences, expose the exact inclusive calendar window, and compute utilization from active recorded IDs / active owned IDs. Period calculations exclude prior estimates; all-time totals separately label recorded and estimated earlier counts. Unknown/zero denominator shows Not enough recorded history. Source history retains the chosen period.

The literal monthly tracer failed before its API existed (`/tmp/aqd-26-s3-red.log`). Core59 and physical native146 (133 Swift Testing +13 XCTest) pass `/tmp/aqd-26-s3-unit-final.log`, including October’s inclusive bounds, archived/deleted denominator behavior, two occasions versus three item occurrences, estimate exclusion and empty denominators. The first implementation’s Swift initialization-order error was corrected before this pass. Tooling51 and agent-doc checks pass. Independent grouped Standards/Spec review identified four source defects to fix next: receipt→history task ownership, named-entry timezone, completed entry removal and recorded calendar accessibility labels. All E2E/rendered/whole-device quality qualification remains #30.

## Independent review corrections and final unit receipt

Independent read-only Standards and Spec reviewers inspected the full baseline `e71e1de` through seven slices plus current files. Standards found task ownership on receipt→history and mixed parent/entry timezone. Spec found completed single-entry removal and incorrect VoiceOver plan labels in wear calendar. All four were fixed and both reviewers rechecked with no further findings. Period-source history also now shows the complete selected period regardless of ordinary History’s calendar selection. Duplicate-record previews explain why editing/Undo waits for the active draft to close.

The new public-store assertions reproduced completed removal and mixed timezone failures before fixes (`/tmp/aqd-25-26-review-red.log`). Final Core59/native148 (135 Swift Testing plus13 XCTest) pass `/tmp/aqd-25-26-final-unit.log`, including saved-task acknowledgment→actionable history, restart/shared-link Undo and preserving populated V13 migration. Xcode27.0/27A266a; physical iPhone17ProMax/iOS27.0.1. All simulators remained shutdown; no E2E authored/executed. Synthetic garment media tests mechanics only. Unsigned Release passed `/tmp/aqd-25-26-release.log`. Tooling51, agent docs (135 Markdown/1663 links/292 fragments) and whitespace checks passed. [Sanitized source-bound receipt](evidence/issue-25-26/unit-receipt.json) and [AC table](evidence/issue-25-26/README.md) are ready for PR publication. Remote current-head CI/Codex/protected merge/release remain.

## PR35 Codex corrections

[PR35](https://github.com/vn-aj-vngrd/aqd/pull/35) at `4d0d126` passed Repository tooling CI; Codex completed with three valid P2 findings. Timezone-only wear corrections now reset links by comparing the full recorded day, not only its dedup key. Profile exposes Wear insights in More and source history through insights, removing duplicate root/body links. The coverage ledger will bind to this verified code commit in the companion evidence receipt.

The timezone-only tracer reproduced two failed linkage assertions before fixing (`/tmp/aqd-25-26-codex-red.log`). Refreshed Core59/native149 (136 Swift Testing +13 XCTest) pass `/tmp/aqd-25-26-codex-unit.log`, zero failures on the physical iPhone. No simulator/E2E ran. Bounded Standards/Spec recheck covered changed-day equality, unchanged dedup semantics, explicit parent route and evidence identity. Unsigned Release refresh follows before final-head publication/review.
