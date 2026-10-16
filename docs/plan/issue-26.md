# Issue 26: Actual wear, history and insights

## Scope

- Issue: https://github.com/vn-aj-vngrd/aqd/issues/26
- Companion: [#25](issue-25.md), shared PR, internal order #25 then #26.
- Branch: `van/issue-25/planner-and-history`; baseline `e71e1ded830db3ae2568c547af2de846aeaf0b60` (PR34/v1.3.0).
- Endpoint: one PR for #25 + #26, current-head unit CI/Codex, resolved findings, protected squash and exact merged-SHA repository release verification.
- Verification: Core/public PieceStore/native state unit seams and final unsigned Release. Physical iPhone17ProMax only; readiness confirmed October16 and discovered available. All simulators shutdown; never start one. All E2E authoring/execution, integrated UI/accessibility/device/model qualification remain #30.
- Contracts: [planning/history](../features/planning-history.md), [calendar design](../design/planner-calendar.md), [interactions](../design/v1-interactions.md), [V1 acceptance](../product/v1-release.md), [iOS standards](../agents/ios-standards.md).
- Extend actual Plan/Wear records/drafts/receipts and preserve schema V1–V10. No sample records, automatic wear, cloud model, notifications or external calendar. Optional weather consumer qualification completes in #22/#29; manual/offline planning must work with weather off. Journal-dependent P10 is scoped to #28, with reusable wear semantics here.

## Slices

| Slice | Working outcome | Acceptance | State | Marker | SHA |
| --- | --- | --- | --- | --- | --- |
| S1 | Explicit planned/worn/skipped state with matching-record consent and linked immutable wear snapshots | P7/P8, scoped P10 | Planned | `AQD-Slice: #26/S1` | Pending |
| S2 | Wear detail/backdate/correct/Undo with exactly-once counts and duplicate-safe recovery | P7/P8, scoped LOCAL-03/05 | Planned | `AQD-Slice: #26/S2` | Pending |
| S3 | History/calendar/empty states and reproducible period insights with estimate/denominator labels | P9, supporting P10 | Planned | `AQD-Slice: #26/S3` | Pending |

## Evidence and review

Each slice records actual unit/build results, failures, reviewed increment and its commit. Use pure calendar/range/packing/statistic tests and actual temporary populated-store save/read/reopen/retry/migration checks. UI source follows live Paper; no rendered acceptance claim from units. Final grouped Standards/Spec review includes all new files and tests, then source-bound unit receipt/AC table in the PR. Keep all existing media/ownership/corruption guards.

## Resume

Plans persisted before product edits. Start #25/S1 using existing Plan task and minimal Planner. No additional planning interview is needed.
