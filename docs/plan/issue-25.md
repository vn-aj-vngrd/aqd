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
| S1 | Week/Month/selected date, real agenda and date-prefilled Add; edit/move/remove/Undo same entry | P1/P3/P4, scoped LOCAL-04/05 | Committed | `AQD-Slice: #25/S1` | `a17d683` |
| S2 | Named two-week plan authoring, reviewed assignments/gaps and atomic conflict decisions/recovery | P1/P3/P6 | Committed | `AQD-Slice: #25/S2` | `37b2f56` |
| S3 | Three-calendar-month weekday routine authoring/detail/edit scopes with resolved saved entries | P2/P4/P6 | Committed | `AQD-Slice: #25/S3` | `c6c4e3b` |
| S4 | Trip dates/destination/activities/detail and persistent deduplicated packing that retains checks | P5/P6, scoped P11/manual-offline | Committed | `AQD-Slice: #25/S4` | `66fdd75` |

## Evidence and review

Each slice records actual unit/build results, failures, reviewed increment and its commit. Use pure calendar/range/packing/statistic tests and actual temporary populated-store save/read/reopen/retry/migration checks. UI source follows live Paper; no rendered acceptance claim from units. Final grouped Standards/Spec review includes all new files and tests, then source-bound unit receipt/AC table in the PR. Keep all existing media/ownership/corruption guards.

## Resume

All four #25 feature slices are verified and committed. Continue companion #26/S1 linked wear/planned/worn/skipped states on the same branch; do not open separate PRs. Continue on the shared branch. No simulator or E2E.

## S1 calendar and entry management receipt

The dedicated Planner now defaults to Week, with retained Month/date state, real localized calendar grids, selected-day agenda, upcoming entries and date-prefilled Add. Native labels expose date/today/selection/count. Shared timezone selection changes the draft only. Editing/moving an entry preserves entry/plan IDs and other assignments. Reviewed removal and temporary Save Undo remove only the exact entry; an unknown Undo stays retryable after the normal deadline. V10→V11 adds preserving deletion receipts without changing delivered schemas or wear.

Core calendar tracer first failed compilation against absent APIs, then its leap-year/DST literals passed. Full Core53 and physical native132 (119 Swift Testing plus13 XCTest) pass in `/tmp/aqd-25-s1-unit.log`. Bounded review identified a missing persisted future-plan flag on outfit edits. Its actual seven-case suite reproduced one failing expectation (`/tmp/aqd-25-s1-revision-suite-red.log`); an earlier method selector selected zero cases and is not a behavioral result. The fix shares future flags with archive/availability and leaves past intent/history unchanged; affected Plan/archive12 native cases pass (`/tmp/aqd-25-s1-revision-green.log`). The final Undo-after-deadline correction refreshes all seven Plan cases successfully (`/tmp/aqd-25-s1-undo-final.log`). Unchanged cases retain the full-run scope.

Standards/Spec self-review covered stable calendar dates/locale/first weekday, Dynamic Type/neutral Back, exact ownership/revision/request checks, no implicit wear, preserving migration, stale edits and lost acknowledgment. All E2E/rendered/accessibility/device quality acceptance remains #30. Final grouped review/Release/remote gates remain.

## S2 named multi-day plan receipt

Planner Add now offers real one-day and multi-day tasks; routine/trip options arrive only when their working slices exist. The new named plan has an inclusive one-to-fourteen-day range and timezone, retains date IDs/choices while rebuilding the range, and reviews every date. Empty assignments need explicit Leave unassigned or Leave remaining dates unassigned; there are no invented sample outfits. Conflict review is a dedicated native destination with explicit Keep both/Replace and unchanged Back. Parent Save validates exact current outfit/availability/conflict snapshots and writes the complete definition/entries/replacements/immutable receipt atomically. Cancel and failed writes leave existing dates unchanged; restart/lost acknowledgments retain the exact draft/result. V11→V12 adds dedicated plan-definition/draft/receipt records without changing delivered models.

The Core range tracer first failed compilation against missing APIs; Core55 then passed and physical native136 (123 Swift Testing plus13 XCTest) passed with zero failures in `/tmp/aqd-25-s2-unit.log`. Cases exercise fourteen dates with intentional gaps, Keep both, changed conflict rejection, explicit Replace, denied/unknown bulk save, cancel, reopen and populated V11 migration. Final conflict-destination presentation and indentation-only changes compile in the generic iOS Debug build `/tmp/aqd-25-s2-build.log`; unchanged rule/store results retain their full-run scope. No UI/E2E pass is inferred.

Bounded Standards/Spec self-review covered all-or-nothing replacement, completed-state protection, exact receipt contents, owned availability, independent modal guards, date/timezone identity and recoverable invalid drafts. All E2E remains #30; final grouped independent/remote gates remain.

## S3 weekday routine and edit scopes receipt

Create a routine resolves selected weekdays over up to three calendar months, using actual calendar arithmetic rather than ninety days. Occasion, selected outfits and rotate/repeat-a-favorite preferences are retained. Fill dates is explicitly labelled rule-based and creates only a reviewable draft; manual choices and intentional gaps remain available. No recurrence runs in the background or records wear. Existing multiple occasions/IDs survive date rebuilds; new unreviewed duplicate slots are rejected.

The actual scope chooser opens one entry through the existing editor, or this/future/whole through the atomic plan task. Completed worn/skipped entries are excluded from mutation, earlier out-of-scope intentions stay intact and every removed entry is counted before Save. Exact definition plus full entry snapshots protect against stale edits; lost acknowledgments reconcile the same operation. Refresh reviewed entries preserves proposed new-date IDs/outfits while updating the acknowledged source. Changed outfit compositions are shown before parent Save. Optional payload fields preserve V12 records/receipts without modifying native schema attributes.

Routine tracer first failed compilation against absent APIs. Core57 and physical native138 (125 Swift Testing plus13 XCTest) pass, zero failures, `/tmp/aqd-25-s3-unit.log`. Independent literal October–December2026 office weekdays resolves66 dates; Core covers completed-entry exclusion and multiple-occasion rebuilds. Native cases cover actual rule-draft→66 persisted dates with no wear, future-edit identity/earlier-intent preservation and unknown-save restart/retry. The final stale-refresh/presentation correction refreshes all13 Plan native cases successfully (`/tmp/aqd-25-s3-refresh-final.log`); unchanged native cases retain their full-run scope. Xcode27.0/27A266a and physical iPhone17ProMax/iOS27.0.1 are confirmed. All E2E/device quality acceptance remains #30.

Bounded Standards/Spec self-review covered explicit recurrence/rotation, calendar-month boundaries, protected states/scope, current dependency snapshots, no silently lost proposed dates, truthful rule provenance and offline/manual continuation. Final grouped independent/remote gates remain.

## S4 trip and packing receipt

Plan an event or trip uses the same bounded date authoring and atomic review, with private optional destination/activities and explicit timezone. Destination text makes no location/weather request; Weather remains Off and the manual path requires no network/model. Trip detail opens actual shared date/entry and packing destinations. Packing deduplicates owned piece IDs, labels scheduled-use counts, keeps full-Fit photos and exposes actual missing/unassigned/unavailable/changed-assignment gaps. A deleted date can be repaired inside the same parent plan; single-entry saves/moves stay inside a named plan’s reviewed range.

Packing checks have their own revision-bound immutable receipts. Assignment/outfit/piece-reference changes prune obsolete checked IDs inside the same transaction, retaining checks for surviving pieces. Removing/readding a piece does not resurrect an obsolete check; retrying a historical acknowledgment never rewinds current packing. V12→V13 preserves prior plan/date/draft/receipt records, adding only packing state/check models; no packing snapshot owns photo media.

The Core packing tracer first failed compilation against absent APIs. Core58 and physical native143 (130 Swift Testing plus13 XCTest) pass, zero failures, `/tmp/aqd-25-s4-unit.log`. Public-seam cases cover dedup/use counts, unknown/denied checks, replacement/prune/restart/re-add, exact historical retry, same-parent gap repair and preserving populated V12 migration. The final range correction refreshes all18 Plan/Packing native cases (`/tmp/aqd-25-s4-range-final.log`), including new/moved out-of-range rejection and corresponding native date-picker bounds. Unchanged cases retain the full-run scope; all UI/E2E/device/model quality acceptance remains #30.

Bounded Standards/Spec self-review covered named-range integrity, owner/ID/revision guards, packing check pruning at every actual assignment/reference mutation, no invented quantity/capacity/weather, manual city/timezone identity and recoverable faults. #26 will exercise actual wear linkage/Undo across these plan/routine/trip records. Final grouped independent/Release/remote gates remain.

## Group local gate and remote resume

Companion #26’s three slices and four independent review corrections complete this approved group’s source. Final Core59/native148 and unsigned Release pass; Tooling51 and agent-doc checks pass. [Grouped AC evidence](evidence/issue-25-26/README.md) and [source hashes](evidence/issue-25-26/unit-receipt.json) retain observed unit limits. Continue the existing branch’s single #25/#26 PR through CI/Codex, protected squash and merged-main release. All rendered/E2E/device/model qualification remains #30; journal-dependent P10 #28. The PR body and GitHub checks own post-push/merge facts under the checkpoint convention.

## PR35 second Codex review corrections

Codex completed on `db0f7c4` and found entry-scope shared-definition mutation, stale outfit snapshots surviving source refresh, and undisclosed assignment availability conflicts. All three new public-store/state regressions failed before fixing (`/tmp/aqd-25-26-codex2-red.log`). Entry-scope authoring now rejects changed shared definitions; retained earlier/completed dates must still fit the parent range/zone. The actual UI continues routing This entry through the single-entry task, while defensive bulk fields are locked for that scope. Refresh explicitly replaces original slots from current persisted entries/outfits, retains genuinely added-date IDs and refreshes their outfit references. The button explains its replacement semantics. Single and multi-day review identify actual date/outfit/unavailable piece names before Save, disable invalid assignments and retain explicit unassigned choices.

Final Core59/native152 (139 Swift Testing +13 XCTest) pass `/tmp/aqd-25-26-codex2-unit.log` on the same confirmed physical iPhone. Refreshed unsigned Release passes `/tmp/aqd-25-26-codex2-release.log`. Source hashes/coverage bind to the verified code commit through the accompanying evidence receipt. No simulator or E2E ran. Continue same PR35’s current-head CI/Codex, resolved threads, protected squash and merged-main release.
