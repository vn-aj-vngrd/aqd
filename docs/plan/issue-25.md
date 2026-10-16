# Issue 25: Planner, routines and trips

## Scope

- Issue: https://github.com/vn-aj-vngrd/aqd/issues/25
- Companion: [#26](issue-26.md), shared PR, internal order #25 then #26.
- Branch: `van/issue-25/planner-and-history`; baseline `e71e1ded830db3ae2568c547af2de846aeaf0b60` (PR34/v1.3.0).
- Endpoint: one PR for #25 + #26, current-head unit CI/Codex, resolved findings, protected squash and exact merged-SHA repository release verification.
- Verification: Core/public PieceStore/native state unit seams and final unsigned Release. Physical iPhone17ProMax only; readiness confirmed October16 and discovered available. All simulators shutdown; never start one. All E2E authoring/execution, integrated UI/accessibility/device/model qualification remain #30.
- Contracts: [planning/history](../features/planning-history.md), [calendar design](../design/planner-calendar.md), [interactions](../design/v1-interactions.md), [V1 acceptance](../product/v1-release.md), [iOS standards](../agents/ios-standards.md).
- Extend actual Plan/Wear records/drafts/receipts and preserve schema V1–V10. No sample records, automatic wear, cloud model, notifications or external calendar. Optional weather consumer qualification completes in #22/#29; manual/offline planning must work with weather off. Journal-dependent P10 is scoped to #28, with reusable wear semantics here.

## Slices

| Slice | Working outcome | Acceptance | State | Marker | SHA |
| --- | --- | --- | --- | --- | --- |
| S1 | Week/Month/selected date, real agenda and date-prefilled Add; edit/move/remove/Undo same entry | P1/P3/P4, scoped LOCAL-04/05 | Committed | `AQD-Slice: #25/S1` | Pending |
| S2 | Named two-week plan authoring, reviewed assignments/gaps and atomic conflict decisions/recovery | P1/P3/P6 | Planned | `AQD-Slice: #25/S2` | Pending |
| S3 | Three-calendar-month weekday routine authoring/detail/edit scopes with resolved saved entries | P2/P4/P6 | Planned | `AQD-Slice: #25/S3` | Pending |
| S4 | Trip dates/destination/activities/detail and persistent deduplicated packing that retains checks | P5/P6, scoped P11/manual-offline | Planned | `AQD-Slice: #25/S4` | Pending |

## Evidence and review

Each slice records actual unit/build results, failures, reviewed increment and its commit. Use pure calendar/range/packing/statistic tests and actual temporary populated-store save/read/reopen/retry/migration checks. UI source follows live Paper; no rendered acceptance claim from units. Final grouped Standards/Spec review includes all new files and tests, then source-bound unit receipt/AC table in the PR. Keep all existing media/ownership/corruption guards.

## Resume

S1 verified and ready for its slice commit; next S2 completes named multi-day authoring, reviewed gaps/conflicts and atomic save. Continue on the shared branch. No simulator or E2E.

## S1 calendar and entry management receipt

The dedicated Planner now defaults to Week, with retained Month/date state, real localized calendar grids, selected-day agenda, upcoming entries and date-prefilled Add. Native labels expose date/today/selection/count. Shared timezone selection changes the draft only. Editing/moving an entry preserves entry/plan IDs and other assignments. Reviewed removal and temporary Save Undo remove only the exact entry; an unknown Undo stays retryable after the normal deadline. V10→V11 adds preserving deletion receipts without changing delivered schemas or wear.

Core calendar tracer first failed compilation against absent APIs, then its leap-year/DST literals passed. Full Core53 and physical native132 (119 Swift Testing plus13 XCTest) pass in `/tmp/aqd-25-s1-unit.log`. Bounded review identified a missing persisted future-plan flag on outfit edits. Its actual seven-case suite reproduced one failing expectation (`/tmp/aqd-25-s1-revision-suite-red.log`); an earlier method selector selected zero cases and is not a behavioral result. The fix shares future flags with archive/availability and leaves past intent/history unchanged; affected Plan/archive12 native cases pass (`/tmp/aqd-25-s1-revision-green.log`). The final Undo-after-deadline correction refreshes all seven Plan cases successfully (`/tmp/aqd-25-s1-undo-final.log`). Unchanged cases retain the full-run scope.

Standards/Spec self-review covered stable calendar dates/locale/first weekday, Dynamic Type/neutral Back, exact ownership/revision/request checks, no implicit wear, preserving migration, stale edits and lost acknowledgment. All E2E/rendered/accessibility/device quality acceptance remains #30. Final grouped review/Release/remote gates remain.
