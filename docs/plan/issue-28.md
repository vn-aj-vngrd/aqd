# Issue28: Profile and private fit journal

- Issue: https://github.com/vn-aj-vngrd/aqd/issues/28
- Companion: [#22](issue-22.md), internal order #28 then #22.
- Branch: `van/issue-28/profile-and-today`; baseline `51c87f3ec2e84a58d6a7efbcb66383def82684eb` (merged PR35/v1.4.0).
- Endpoint: one PR for #28 + #22, current-head unit CI/Codex, resolved findings, protected squash and merged-SHA repository release verification.
- Physical iPhone17ProMax only. Owner confirmed connected/unlocked readiness October16; device discovered available. All simulators shut down. All E2E authoring/execution, rendered accessibility/media/model/device qualification stays #30.
- Methods: existing Core, actual temporary PieceStore and native AppState/editor seams, red/green behavior tests. No new interview for settled specs. Preserve existing tests/data, migrations, stable IDs, drafts, immutable operation receipts and reference-scoped media cleanup.

## Scope and slices

Read Profile/journal feature, fit UI, capture/media and local identity contracts. Cover seven canonical states L160/L161/L162/L48/L165/L163/L49 and delete/discard/remove-photo references. Journal is independent of intended/actual wear. Full export/restore/erase belongs #29; keep data/media ready for it. Private notes/photos never implicitly enter Agent context.

| Slice | Working outcome | Acceptance | State | Marker | SHA |
| --- | --- | --- | --- | --- | --- |
| S1 | Optional local identity and retained edit task with safe photo selection/removal and committed Profile header | Local identity, J1/J3/J5 | Implemented, unit verified | `AQD-Slice: #28/S1` | `6a1700f` |
| S2 | Private dated fit journal CRUD, snapshot link/unlink, note validation, real detail/grid and independent wear route | J1–J5/P10 | Implemented, unit verified | `AQD-Slice: #28/S2` | `3e7f12c` |
| S3 | Shared optional-photo lifecycle, editing/removal/cleanup and preserving migration/restart recovery across Profile/fit tasks | J3/J5, scoped J6/LOCAL-13–15 | Implemented, unit verified | `AQD-Slice: #28/S3` | `4f92293` |

## Verification and resume

Unit-only feature gate; integrated J7 and all E2E #30. Actual store fault/retry/reopen/migration and Core validation tests per slice, then final unsigned Release and independent Standards/Spec review. S1–S3 implemented; continue companion #22. Final grouped review and Release remain. Publish source-bound unit evidence and AC limits in the single PR.

## S1 identity receipt

Optional name/avatar editing uses a retained local task and immutable save acknowledgment, not public identity. Clear name saves absent; Remove photo invalidates pending import identity and changes the draft only. Source choice dismisses before Photos/camera; metadata-minimized full-source Fit copies use existing preparation/storage. Pending/unknown writes lock mutation and reconcile the same operation. Profile reads only acknowledged identity; missing referenced media is labelled unavailable. Startup prioritizes the recovered identity task without opening other editors.

Schema V15 adds identity/draft/save records through a preserving V14 migration. Current identity and both current/base draft photo references protect media during ordinary and legacy cleanup discovery; completed receipts own no bytes. Actual shared-avatar tests retain source media across cancellation and removal while a wardrobe piece still owns it, then release it only after all owners are gone. Original Photos remain outside AQD control.

Tracer failed compilation against absent APIs (`/tmp/aqd-28-s1-red.log`). Core59 and physical native153 (140 Swift Testing +13 XCTest) passed `/tmp/aqd-28-s1-unit.log`. Final focused4 identity cases passed `/tmp/aqd-28-s1-final.log`, adding actual photo ownership, populated V14 migration and competing recovered-task checks. Xcode27.0/27A266a, physical iPhone17ProMax/iOS27.0.1; owner readiness confirmed. Bounded Standards/Spec increment review covered owner/revision, receipt-first unknown retry, optional absence, late import cancellation, reference-safe cleanup and task ownership. Final grouped independent review/Release/CI/Codex remain; all E2E/rendered/device quality remains #30.

## S2 journal receipt

Profile’s one More menu now opens Add fit and Edit profile alongside Style/Wear insights/Settings. The journal shows actual chronological memory counts and responsive dated photo/composition thumbnails, with real detail, retained snapshot metadata, same-ID edit and confirmed scoped deletion. Date/timezone/note/photo/link edits are private drafts. Notes retain over-500-character input with validation; date-only/note-only cannot save. New links require current owned outfits; existing snapshots permit later date/note edits after source outfit edit/deletion. Save/unknown retry uses one immutable receipt and returns to the source with the new memory anchor. Acknowledged deletion never removes wardrobe/wear/plans or another memory’s photos.

Record wear is a separate source-bound action using the saved fit date and existing duplicate-consent task. Photo-only/deleted-outfit memories open explicit piece review, without inferring garments. Repeated explicit wear uses one actual record; deleting the memory leaves actual wear unchanged.

Schema V16 adds fit/draft/save/delete records and keeps identity, journal/current/base drafts in photo-reference cleanup. The missing-API tracer failed `/tmp/aqd-28-s2-red.log`; Core59/native157 (144 Swift Testing +13 XCTest) passed `/tmp/aqd-28-s2-unit.log`. Final2 affected journal cases pass `/tmp/aqd-28-s2-final.log`, adding the actual AppState fit-date → wear → existing-record consent route and a source-aware scroll owner. Actual temporary stores cover invalid/over-limit retention, unknown retry, deleted-source snapshots/reopen, same-ID correction and idempotent deletion without implicit wear. Bounded Standards/Spec increment review checked those contracts and single-task ownership. Shared photo editing/recipe/reference/migration checks continue in S3; all E2E/rendered quality remains #30.

## S3 shared photo receipt

Avatar and journal photos use the same framing editor as capture, including full-source Fit, crop, quarter-turn rotation, reset and draft-only cancellation. The editor accepts an explicit photo owner and rejects late results after the source, recipe or task changes. Identity recipes decode optionally for older payloads. Saved identities, memories and both current/base drafts protect their actual recipe renditions. New/replaced recipes require prepared full-size and thumbnail bytes; unchanged missing photos permit unrelated metadata edits. Obsolete recipe bytes are cleaned only after all actual owners release them.

An actual temporary-store regression failed before the fix in `/tmp/aqd-28-s3-red.log`: unprepared edits were accepted and a pending journal rendition was removed. The fix passes Core59 and physical native159, comprising146 Swift Testing and13 XCTest, in `/tmp/aqd-28-s3-unit.log`. The regression covers pending/current crop ownership, save acknowledgment, deletion and preservation of an original still used by a wardrobe piece. Bounded increment review traced source/recipe cancellation, parent-draft mutation, old optional decoding and shared media cleanup. All rendered/E2E/media quality checks remain #30.

## Independent grouped review corrections

Fixed range `51c87f3...7d4ba1f` received independent Matt Standards/Spec review. Standards found one issue affecting both identity and journal: failed draft retention trapped Discard against the newer unpersisted input. Two physical actual-store regressions reproduced the failure in `/tmp/aqd-28-22-review-red.log`; both editors now discard the retained matching draft/operation/base while keeping receipt guards. Spec found Today’s empty-state read failure and Planner’s obsolete Weather Off label. Today now retains a separate wardrobe-read failure across global-alert dismissal until an actual successful read; Planner displays actual selected context/date/timezone. Three regression cases plus the full Core64/native174 suite pass `/tmp/aqd-28-22-review-unit.log`. Both independent reviewers rechecked the corrections and returned no remaining findings. All E2E remains issue30.

## Local gate and remote resume

Profile slices `6a1700f`, `3e7f12c`, `4f92293` are complete alongside companion Today’s five slices. Grouped reviewed corrections `942ca66` and `1d037b6` protect failed-retention discard and current Today detail identity. Latest code `1d037b6a2dfadcc875f7ad6521919b26a20ab4ea`; final Core64/native175 pass on the physical iPhone. [Grouped source-bound AC evidence](evidence/issue-28-22/README.md) retains actual checks and explicit issue30 limits. Unsigned Release passes; the documentation receipt and the single grouped PR’s CI/Codex/protected squash/release verification continue. GitHub owns live remote delivery facts; no post-merge documentation-only PR is required.
