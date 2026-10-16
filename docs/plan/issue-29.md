# Issue 29: Settings, preferences and local data

https://github.com/vn-aj-vngrd/aqd/issues/29

## Scope

Authorized endpoint: one grouped PR through current-head unit CI/Codex fixes, protected squash merge and merged-SHA repository release verification. Companion: [issue27](issue-27.md). Baseline: `1a5b44ecf06536d6bb1dae0551348f44a9747d5b`, merged PR36/v1.5.0; clean main verified. Branch `van/issue-27/agent-and-local-controls`. Actual issues and comments inspected; both open with no comments. Approved grouping supersedes historical separate-PR dependency wording.

Use existing public Core validators and actual PieceStore/model save/read/reopen seams for unit coverage. Owner confirmed the physical iPhone17ProMax connected/unlocked/ready; all simulators shut down. All E2E authoring/execution, rendered/native acceptance, real capability quality/performance remain issue30. No cloud model, backend, human Inbox, signed distribution or automatic capability activation.

## Slices

| Slice | Working outcome | Acceptance | Unit verification | State | Commit marker | SHA |
| --- | --- | --- | --- | --- | --- | --- |
| S1 | Persistent appearance, capability/help/privacy, Style/tour/weather settings | PREF, LOCAL10/15/16 | Actual settings save/reopen/recovery | Committed | `AQD-Slice: #29/S1` | `67bb29a` |
| S2 | Complete sensitive local archive export and native Files states | LOCAL06, J6/TODAY07/PREF | All-domain archive integrity/count/size/media round-trip | Committed | `AQD-Slice: #29/S2` | `444e45c` |
| S3 | Staged validated reviewed replacement and recovery entry | LOCAL07, J6/TODAY07/PREF | Invalid/newer/cancel/failure/unknown/restart preservation | Committed | `AQD-Slice: #29/S3` | `a02a8d5` |
| S4 | Exact typed global erase and acknowledged records versus pending AQD cleanup | LOCAL08, J6/TODAY07 | All-domain erase/restart/failure and outside-file preservation | Committed | `AQD-Slice: #29/S4` | `08e727d` |

| S5 | Owner-requested Planner week strip fills its container evenly | Owner follow-up | Native Debug compile; rendered acceptance deferred to issue30 | Committed | `AQD-Slice: #29/S5` | `e7c4eb8` |

## Acceptance and evidence

Contracts: [Agent](../features/agent.md), [Profile/Settings](../features/profile-account.md), [local architecture](../architecture/v1.md), [LOCAL acceptance](../product/v1-release.md#local-acceptance), [Agent input](../design/agent-input.md), [response experience](../design/agent-experience.md), native presentations and DQ01–12. Live Paper V1 file/page inspected, token hash `fdeb7346`; canonical and supporting controls from the issue inventory own composition. Existing manual editors/validation/media ownership remain authoritative.

Each slice will record actual commands, revision, result and local artifact. AC evidence is published in the grouped PR; synthetic provider tests are not real model/speech/garment qualification. No UI pass is claimed from units.

## Review and delivery

Local implementation, slice review and independent Standards/Spec review are complete. Core71/native194 and unsigned Release pass. Current-head CI/Codex, resolved remote findings, protected SHA-bound squash and merged-SHA release verification remain required.

## Shipping and resume

Repository vn-aj-vngrd/aqd, head branch above. Resolve/reuse its single PR. Persist slice SHAs immediately in the next slice/receipt. GitHub owns live remote gates; no extra commits for polling or the new PR URL. Current next action: resume PR37 current-head Repository tooling/Codex gates, fix any further findings, then protected squash merge and verify exact merged-SHA CI/release. No dirty unrelated files or known local failures.

## S1 receipt

Settings owns persistent System/Light/Dark appearance, actual capability/help/privacy copy and shared Style/tour/weather tasks. Appearance changes use revision-bound immutable receipts; failed writes retain prior settings, unknown results retry the same request, and old acknowledgments never rewind a newer setting. Open Agent uses an explicit native full-screen request rather than selecting the inert fourth-slot root. Shared questionnaire/tour/weather retain source and separate consent.

Schema22 freezes earlier versions and adds Settings/receipts plus a transaction-bound local mutation stamp for reviewed data replacement. The stamp changes only inside a successful store transaction; failure rolls back both records and stamp. Missing Core API failed `/tmp/aqd-29-s1-red.log`. Core70/native185, comprising172 Swift Testing plus13 XCTest, pass `/tmp/aqd-29-s1-unit.log` on the physical iPhone17ProMax/iOS27.0.1. Tests cover failure/unknown/reopen, old receipt after newer settings, actual AppState appearance and shared consent/tour return. Existing populated migration and bootstrap protections pass. Bounded Standards/Spec review covered state ownership, revision/receipt integrity, current schema fixtures, native request identity and privacy routes. Export/restore/erase follow S2–S4; all E2E remains issue30.

## S2 receipt

Export prepares a consistent standalone SQLite snapshot with versioned records and all referenced AQD media, including original/derived sources and edit renditions. The native bounded `.aqdarchive` format has an allowlisted path table, per-file size/SHA256, schema/model integrity, explicit bounded byte budget, reduced to 64 MiB after PR37 memory review and no zip dependency. Actual counts/bytes appear before explicit Save to Files. Preparing/cancelled/ready/failed and Files-cancel/failure retain the closet. Source mutation stamps reject a changing snapshot. Private staging uses file protection/backup exclusion; media work and encoding run off the UI actor with cancellation propagation.

The disposable export copy compacts acknowledged Today operations to input digests, retaining exact retries without exporting deleted private card text. Pending recovery payloads and actual draft/Undo owners remain. Only the copy is changed. Staging validates every file, SQLite integrity/model version, decoded media, actual domain counts/relationships and current/base photo ownership before producing a reviewable copy; S3 adds the replacement UI/commit boundary.

Missing native APIs failed `/tmp/aqd-29-s2-red.log`. Populated staging reproduced a WAL-sidecar failure in `/tmp/aqd-29-s2-wal-red.log`; the snapshot now explicitly checkpoints and switches its disposable output to DELETE journaling before compaction. Final eight physical unit cases pass `/tmp/aqd-29-s2-native.log`, including synthetic all-domain round-trip, IDs/settings/style/conversations/journal/plans/packing/wear, retained editor drafts/Today Undo, original/derived/edited media, exact deletion receipts without deleted text, damaged/newer/unsafe/missing-media refusal and existing Today recovery units. Source Core remains unchanged from S1; no E2E ran. Bounded Standards/Spec review traced snapshot consistency, path/size/media/schema validation, cancellation, sensitive payloads and original-data preservation. Full feature units and independent review follow S4.

## S3 receipt

Restore selects a native Files document, validates a separate protected generation, discloses actual incoming/current counts and any preservation migration, and requires an explicit critical replacement alert. Cancel/invalid/newer/stale/failure preserves the current records. Refreshed review increments its version and invalidates the earlier review.

A protected installation-local pointer publishes the validated generation atomically; an open SQLite database is never moved or repointed. Legacy storage is resolved in place until an explicit replacement. A durable review/operation record distinguishes preparing, reviewed, published, acknowledged and failed recovery. Retry reads the published operation first and never rewinds later edits. Missing active store files are corruption, not permission to seed an empty store. An unacknowledged installed copy that cannot reopen recovers the validated original, retaining the failed candidate until explicit cancellation. Previous store/file cleanup stays separately visible and cannot run while the previous store owner is alive or current records cannot be validated.

Missing coordinator APIs failed `/tmp/aqd-29-s3-red.log`. Five focused archive/replacement cases pass `/tmp/aqd-29-s3-native.log`; after adding missing-store rollback, full Core70/native191, comprising178 Swift Testing plus13 XCTest, pass `/tmp/aqd-29-s3-unit.log` on the physical iPhone17ProMax/iOS27.0.1. Tests cover cancel, versioned stale-review refusal, pre-switch failure, lost acknowledgment/restart, all-domain preservation, no rewind of later edits and recovering a missing unacknowledged installed DB without empty reseeding. Native Files/presentation/accessibility and all E2E remain issue30. Bounded Standards/Spec review covered stable paths, source/candidate stamps, publication/acknowledgment ordering, initial/corrupt recovery routes and source-preserving exits. S4 closes erase and final cleanup checks before full independent review.

## S4 receipt

Erase creates a separate empty local generation, shows the current all-domain impact, offers Export first and requires exact typed ERASE plus a destructive confirmation. The acknowledged new owner has no prior wardrobe, memories, preferences, conversations, drafts or Undo. Original Photos and external archive copies remain untouched. File cleanup is separately tracked, waits for old store and archive owners, validates active data before removal and retains retry receipts on failure. Recovery from an unreadable installed copy can retain its previous operation before selecting another validated archive.

The physical iPhone unit `LocalEraseTests` passed in `/tmp/aqd-29-s4-native.log`, covering populated erase, case-sensitive confirmation, old-store leases, denied cleanup, retry and preservation of an external original/export sentinel. The bounded review covered publication-before-acknowledgment, same-operation recovery and AQD-only cleanup. No E2E ran. Final combined units and independent review follow.

## S5 receipt

The owner supplied a Planner screenshot showing unused width to the right of the seven dates. The shared week row now takes the available width and gives each date an equal flexible column, including its selected highlight. A horizontal fallback retains all seven accessible targets when their minimum sizes cannot fit. The calendar keeps the existing seven-day week and navigation behavior. Native Debug build passed `/tmp/aqd-planner-width-build.log`. Bounded review traced both Planner and shared calendar consumers; no domain change or mirrored layout test was needed. Rendered/device E2E remains issue30 as authorized.

## Full independent review correction

Failed erase preparation can retry on the same model once storage recovers, provided no reviewed operation exists. The coordinator retains pending/published guards. Style Settings refreshes acknowledged answers when its shared editor closes. Standards identified both defects; Spec independently identified erase retry and an Agent deletion-recovery defect, recorded in issue27. The erase retry failed before the fix in `/tmp/aqd-27-29-review-red.log`. Final Core71/native194 pass `/tmp/aqd-27-29-review-final-unit.log` on the confirmed iPhone; both reviewers rechecked the corrected source with no remaining findings. Rendered and E2E acceptance remains issue30.

## Local closeout receipt

Final source `1356ebbf655ac1b5edbdc5ac493762308e1bc8f7` includes terminal-state correction `1272f2a`, Agent review correction `f485d0f` and Settings correction `1356ebb`; erase slice `08e727d` and Planner width slice `e7c4eb8` remain separate. [Grouped AC evidence](evidence/issue-27-29/README.md) and [source-bound receipt](evidence/issue-27-29/unit-receipt.json) retain source hashes and local log digests. Final Core71/native194 and unsigned Release pass; Tooling51, agent-doc links and whitespace pass. Standards2/Spec2 findings, including the overlapping erase issue, and the additionally reproduced terminal approval defect are fixed and independently rechecked. All E2E/rendered/capability qualification remains issue30. Live GitHub gates are the next action, not a local pass claim.

## PR37 Codex corrections

[PR37](https://github.com/vn-aj-vngrd/aqd/pull/37), initial head `0b910aa`, passed Repository tooling. Codex completed with two P2 findings: retry included the completed answer it was replacing, and erase cleanup recovery was hidden before main. Retry now omits only the targeted assistant message while retaining preceding turns and its user request. Welcome, Style and tour use the shared observable cleanup wrapper, preserving warning/retry before onboarding completes.

Prompt assertions reproduced the defect in `/tmp/aqd-pr37-codex-red.log`. Refreshed Core71/native194 pass `/tmp/aqd-pr37-codex-unit.log`; the all-domain erase test confirms a new welcome AppState retains pending cleanup. Both independent reviewers rechecked the changed consumers with no findings. Refreshed unsigned Release passed `/tmp/aqd-pr37-codex-release.log`; agent-doc/whitespace checks pass. Final-head CI/Codex remain required. All E2E remains issue30.

## PR37 second Codex review corrections

Current remote head `53a9fb4` has three Codex findings: archive payload buffering, duplicate unchanged conversation retry writes and lost latest appearance choice during reconciliation. Owned local fixes reduce/disclose the archive limit to64MiB, return the checked summary without another full decode, acknowledge unchanged chat retries without a new operation, and retain the latest desired appearance separately from immutable pending requests. Explicit appearance Retry uses that latest intent, including repeated storage failure. Both independent reviewers rechecked without remaining source findings.

Original regressions fail in `/tmp/aqd-pr37-codex2-red.log`. The first full run `/tmp/aqd-pr37-codex2-unit.log` FAILED with one missing UIWindowScene and two test-runner exits (194 passed,3 failed); it remains failed evidence. After the owner reconfirmed the connected/unlocked/untouched iPhone, the complete rerun PASSED Core71/native197, comprising184 Swift Testing and13 XCTest, in `/tmp/aqd-pr37-codex2-final-unit.log`. The previously interrupted cases pass without weakened assertions. The appearance regression covers failure both before and after a committed write, with storage recovery before or after the second choice, plus explicit Retry. Generic unsigned Release PASSED `/tmp/aqd-pr37-codex2-release.log`; agent-doc/whitespace checks pass. Both independent reviewers rechecked final source and direct consumers without remaining findings. All simulators stayed shut down and no E2E ran. Next: commit/push corrections and refreshed source-bound evidence, resolve addressed threads, obtain new-head CI/Codex, then protected squash/release.

Second-review code receipts: Agent `8fdaf85`, archive `a717b38`, appearance `b10de1c`. Final tested source `b10de1c2bbf1de9717e7dfef1d610d772456c6eb`; the grouped receipt binds this source to Core71/native197 and unsigned Release. Final remote gates follow after this evidence commit.

## PR37 third Codex review correction

Codex on `41de30c` found that unknown deletion retry depended on a history row which disappears after the committed delete. Retry now uses its retained ID/revision/operation tuple directly. Independent review traced two related hidden-recovery paths: history reload and an unchanged save during suspension. Pending-operation errors are retained, and both Agent and Conversations show Retry independently of error text. History Retry reconciles the pending operation; New/open controls stay disabled while unresolved.

The regression failed in `/tmp/aqd-pr37-codex3-red.log`; visibility and noncurrent-background variants failed in `/tmp/aqd-pr37-codex3-visibility-red.log` and `/tmp/aqd-pr37-codex3-suspend-red.log`. Final Core71/native198, comprising185 Swift Testing and13 XCTest, pass `/tmp/aqd-pr37-codex3-recovery-unit.log` on the confirmed physical iPhone. The test covers deleting current/other conversations, reload, suspension, retained recovery and no resurrection, preserving the correct current draft. Both independent reviewers rechecked without remaining findings. Refreshed unsigned Release PASSED `/tmp/aqd-pr37-codex3-release.log`; new-head CI/Codex/protected delivery remain. All E2E remains issue30.

Third-review correction commit: `ae22f54e15ae0ffc888eec504ed70af92707e866`. The refreshed grouped receipt binds final source to Core71/native198 and unsigned Release. Next action remains current-head PR37 CI/Codex, resolved review threads, protected squash and exact merged-SHA release verification.


## PR37 fourth review correction

PR37 fourth review at `afdcee3` found invalid-pointer restore deadlock and synchronous SQLite export work. Correction `819b5a5c19996a25b05ec37b9131f757a2629100` reconstructs a pointer only for a validated matching generation, preserves later edits, quarantines invalid/stale receipts and keeps another reviewed archive available without empty reseeding. Retained cleanup requires a new acknowledged replacement and protects the active generation. Existing damaged stores are fingerprinted incrementally independently of the64MiB archive budget, preserving mutation checks. Raw SQLite snapshots/integrity now run in detached cancellable workers, retaining store ownership and mutation validation.

Original regressions failed in `/tmp/aqd-pr37-codex4-red.log`; the larger damaged-store regression failed in `/tmp/aqd-pr37-codex4-large-red.log`. The first complete correction run failed only a raw URL equality assertion; it now compares normalized paths like neighboring tests, retaining data/current-generation assertions. Final Core71/native203, comprising190 Swift Testing and13 XCTest, pass `/tmp/aqd-pr37-codex4-final-unit.log` on the confirmed physical iPhone. Both independent reviewers rechecked without remaining findings. All E2E and capability activation remain issue30. Current-head CI/Codex and protected delivery remain separate gates.

Unsigned generic iOS Release PASSED `/tmp/aqd-pr37-codex4-release.log`. Agent-doc links and whitespace pass.


## PR37 selected-context correction

PR37 fifth Codex review at `c0b8b58` found that parent outfit/theme revisions did not bind consent to their resolved descendants. Correction `8878b6b091df446722475780142d8375a48b682f` captures piece/outfit revision maps at selection and requires exact current recapture before building a prompt. Missing legacy descendant consent requires reselection while old conversations still decode. Changed, missing or archived descendants refuse sending; explicit reselection accepts the current records. UI uses the shared capture factory and retains actionable failure feedback.

The actual parent-only consent regression failed in `/tmp/aqd-pr37-codex5-consent-red.log`; the earlier API red and fixture compile failure are retained in local logs. Final Core72/native203, comprising190 Swift Testing and13 XCTest, pass `/tmp/aqd-pr37-codex5-final-unit.log` on the physical iPhone. JSON round-trip, changed descendants, reselection and unavailable records are covered. Both independent reviewers rechecked without findings. All E2E, rendered acceptance and real capability activation remain issue30; new-head CI/Codex and protected shipping remain separate gates.

Refreshed unsigned Release PASSED `/tmp/aqd-pr37-codex5-release.log`; agent-doc links and whitespace pass.


## PR37 sixth review correction

Codex at `f246ba7` found that an invalid unacknowledged candidate with a missing/corrupt pointer did not reopen its intact original. Correction `1faff5ff1b19cd40a7595479932e48dd1f5a60fb` shares validated original recovery across both pointer paths, checking directory/database/marker/domain contents and recorded owner before republishing. Acknowledged replacements never roll back. Failed candidates remain retained for explicit cancellation or reviewed recovery.

The physical regression additionally exposed URL representation equality rejecting a second restore from an installed generation. Source identity now compares normalized filesystem paths while retaining generation, owner and mutation checks. The initial full run and focused diagnosis failed for both generated-original cases; these remain failed evidence in `/tmp/aqd-pr37-codex6-unit.log` and `/tmp/aqd-pr37-codex6-diagnostic.log`.

After renewed owner readiness, final Core72/native204, comprising191 Swift Testing and13 XCTest, PASSED `/tmp/aqd-pr37-codex6-final-unit.log`. The parameterized regression covers missing/corrupt pointer × legacy/generated original, retained conversation content, correct active path, failed-review cancellation and a second restore from an installed generation. Both independent reviewers rechecked the final correction without findings. All checks use the physical iPhone17ProMax; no simulator or E2E. All real capability activation and rendered acceptance remain issue30. Current-head CI/Codex/protected merge and exact merged-SHA release remain separate gates.

Final unsigned iOS Release PASSED `/tmp/aqd-pr37-codex6-final-release.log`; agent-doc links and whitespace pass.


## PR37 seventh review correction

Codex at `5063ea7` found omitted Colors & patterns in Style context and arbitrary UUID-prefix closet truncation. Correction `5a8d8ff8623ad86528fc8ae5c61855bebebfacfb` includes preference summaries0/1/2/3/5 under Style consent, keeping body details behind their separate permission. Over-budget eligible/selected context now refuses before consuming the draft or invoking the provider and offers explicit Selected pieces/reduce or Without closet. No arbitrary subset is sent; explicit selection supplies the relevant bounded records.

Actual regressions failed in `/tmp/aqd-pr37-codex7-core-red.log` and `/tmp/aqd-pr37-codex7-native-red.log`. Final Core73/native206, comprising193 Swift Testing and13 XCTest, PASSED `/tmp/aqd-pr37-codex7-unit.log` on the physical iPhone. Coverage includes all four Style/body-consent combinations, preferred/avoided colors/patterns, over-budget draft preservation, no provider invocation and successful explicit bounded reselection. Both independent reviewers rechecked without findings. All E2E, rendered acceptance and real capability activation remain issue30. New-head CI/Codex/protected merge and exact merged-SHA release remain separate gates.

Unsigned iOS Release PASSED `/tmp/aqd-pr37-codex7-release.log`; agent-doc links and whitespace pass.


## PR37 eighth review and recovery audit

Codex at `3537d2e` found pointer loss after acknowledged cleanup could seed a new empty legacy closet while generated data remained on disk. Independent whole-path review also found the empty legacy-directory variant, readable sources with missing media, malformed pointer/operation/retired metadata, publication before the installed receipt, failed erase creation and two combined recovery deadlocks. Correction `4212dfee6d80fdfa1da24cedc6e692a91be42444` addresses these together.

Strict opening requires valid existing storage whenever generated copies exist; no missing/empty legacy root can authorize reseeding. Source identity checks do not reopen/full-validate a damaged source. Unreadable control bytes are protected and quarantined without trusting their contents or deleting associated data. Closed source/generation/opaque-metadata fingerprints bind reviewed replacement to the observed state, excluding only the separately validated candidate. Matching publication validates the exact candidate's regular files, graph and owner before recording installed. Invalid candidate/original pairs retain a failed receipt and permit another reviewed archive. Erase records preparation ownership before creation; failed cleanup stays attributable and can complete after a new acknowledged operation. Unknown generations or unreadable metadata retain cleanup warnings and receipts; Retry alone cannot establish unknown ownership.

All actual regressions reproduced in `/tmp/aqd-pr37-codex8-red.log`, `/tmp/aqd-pr37-codex8-empty-red.log`, `/tmp/aqd-pr37-codex8-recovery-red.log` and `/tmp/aqd-pr37-codex8-combined-red.log`. Intermediate unit runs are retained separately and do not qualify later source. Final Core73/native213, comprising200 Swift Testing and13 XCTest, PASSED `/tmp/aqd-pr37-codex8-complete-unit.log` on the confirmed physical iPhone. Regressions exercise missing/empty legacy paths; malformed control kinds; mutation/refresh of recovery metadata; original/valid-published/both-invalid recovery; model choose/commit; missing media and failed creation/removal retry. Both independent whole-path rechecks found no remaining concrete findings. All simulators stay shut down, no E2E ran and real capability activation remains issue30. New-head remote CI/Codex/protected merge/release remain separate gates.

Unsigned iOS Release PASSED `/tmp/aqd-pr37-codex8-release.log`; agent-doc links and whitespace pass.

## Owner UI follow-up slice

Owner screenshots authorize shared compact empty-state typography, native centered draft-discard alerts, native glass on the UIKit-backed Piece More control, neutral capture/photo controls, full-width category selection with trailing chevrons, and direct Add fit/Edit profile toolbar actions beside Profile More. Keep existing save/discard recovery, category selection and destination behavior. Verify by native unit/build checks and independent source review; rendered acceptance stays issue30. This slice follows context-count correction `529bb93`, whose Core73/native213 unit run passed in `/tmp/aqd-pr37-codex9-unit.log`.

Owner additionally requests one Closet search entry and a full-screen Piece photo option. Remove only the redundant toolbar Search action, preserving native searchable state. Tappable photos open their saved full-resolution rendition with bounded zoom, accessible controls, unavailable/loading states and Close; no editing or data mutation. Include these in the same UI follow-up slice.

Latest owner steering supersedes the earlier search choice: retain only the toolbar Search launcher by default; attach the native field when active and remove on Cancel. Outfit filters move to the trailing toolbar menu, with separate search/browse filter bindings. Today gains visible Weather setup, contextual card icons/compact text and a minimal grid Customize icon. Numerical WeatherKit remains disabled until signed service/attribution qualification; no synthetic conditions or silent activation. Inactive tabs use regular symbol weight; selected tabs retain semibold and available filled variants.

### UI request coverage and unit receipt

| Owner request | Source outcome |
| --- | --- |
| Smaller empty labels | Shared native unavailable states use headline/subheadline; Profile journal matches |
| Discard like native examples | Eleven editor callers use the shared native Cancel/destructive alert; existing callbacks and failure states retained |
| Glass More | UIKit Piece menu uses iOS26+ native glass with deployment18 fallback |
| Neutral capture/photo controls | Add/replace photo, source choices, Close and category use semantic ink |
| Full-width category | Custom full-width Menu label has trailing chevrons, with native Picker selected state inside |
| Profile three icons | Add fit, Edit profile, More; remaining destinations stay in More |
| Piece actions | Style toolbar icon before More; Edit in More; duplicate body actions removed |
| Full-screen photo | Tappable saved rendition, bounded pinch zoom, scroll pan, accessible zoom and Close; no media mutation |
| Closet search, latest instruction | Toolbar Search launcher; field exists only while searching |
| Outfit filtering | Favorites/Theme move to top-right Filter, preserving separate browse/search selections |
| Today polish and Weather | Contextual compact headings, visible Weather setup and attributed matching-cache display; live qualification unchanged |
| Minimal Customize and tab weights | Regular17 grid Customize; explicit regular inactive icons and semibold/filled selected variants |

Final Core73/native213, comprising200 Swift Testing and13 XCTest, pass `/tmp/aqd-pr37-ui-icons-unit.log` on the confirmed physical iPhone17ProMax. Bounded independent Standards/Spec reviews found stale Profile instructions; those and the authoritative feature/design owners were corrected and rechecked. No remaining source findings. An intermediate viewer build rejected an ambiguous percent format; converting zoom to Double fixes it, and subsequent native builds/tests pass. All rendered qualification/E2E remains issue30.

## Owner layout and navigation follow-up

Previous UI slice committed as `56d4fb6`; Core73/native213 and unsigned Release passed. New owner requests: page empty messages centered with actions at bottom, separated native Agent action beside four grouped destinations, Closet scope rail36 points, readable localized Planner day labels, and consistent compact Today action rows with trailing chevrons. Preserve inline card states, plan timezone/day, source returns and Agent full-screen interception. Installed SDK27 exposes `prominentTabIdentifier`; use that native capability with an availability guard instead of impersonating a Search tab. Implement and unit/build-review as a separate slice; all E2E remains issue30.

### Immediate preview checkpoint

Owner asks to build/install the current preview now before continuing UI iteration. Preview source is `56d4fb6` plus uncommitted EmptyStatePage and Closet pieces/outfits/themes page-layout changes. New Agent separation, selector height, readable Planner day and uniform Today action rows remain pending, not implemented or claimed. Preview uses a fresh physical-device Debug build/install/normal launch with no fixtures. This is a local review checkpoint, not UI acceptance, a new unit-pass claim or merge readiness. PR37 remains open; final-head evidence/CI/Codex/merge still await completion of the owner's UI iteration.

Preview result: fresh physical Debug build PASSED `/tmp/aqd-pr37-ui-preview-build.log`; device install and normal launch both returned success (`/tmp/aqd-pr37-preview-install.json`, `/tmp/aqd-pr37-preview-launch.json`). Source/executable SHA256 bindings are in `/tmp/aqd-pr37-preview-receipt.json`. No simulator, E2E, fixtures or data reset. The new three Closet page-empty layouts received bounded source review with no urgent findings; their rendered behavior is for owner review now. Pending work above remains unimplemented. No final-head push/merge readiness is implied.

### Implementation resumed after preview

Owner explicitly requested completion of every pending UI request. Implemented the native iOS27 prominent Agent tab via public UITab APIs,36-point Closet rail with expanded44-point UIKit hit testing, localized recorded-timezone Planner dates, compact consistent Today action rows, and centered page empties with bottom safe-area actions. Independent review found and corrected accessibility month-calendar overflow, undersized segment touch bounds, an inline composition inheriting page height, remaining empty recovery/insights footer placement and missing date/Retry labels. Two native unit regressions cover logical root selection/Agent interception without rebuilding roots, and extreme-timezone day-label stability. Final device units/build/recheck are pending. No E2E or simulator is authorized or used.

Layout/navigation checks PASSED: Core73/native215 (202 Swift Testing across31 suites plus13 XCTest) in `/tmp/aqd-pr37-ui-layout-complete-unit.log`, unsigned Release in `/tmp/aqd-pr37-ui-layout-release.log`, Tooling51 and agent-doc links. Both independent reviewers rechecked the corrections without remaining source findings. Physical install and normal launch succeeded (`/tmp/aqd-pr37-layout-install.json`, `/tmp/aqd-pr37-layout-launch.json`); no fixtures or data reset. Rendered qualification remains issue30.

Next owner-requested slice: unify simple selection/action sheets with native iOS grouped List rows, icons, Close chrome and neutral tint. Scope Closet Add, Planner Add and capture/shared photo-source choices; preserve dismissal-before-next-presentation, lock guards and selection callbacks. Do not change editor or destructive-confirmation semantics. Verify unit/build and source review, install on the same physical phone.

### Additional owner sheet/Agent cleanup

Expanded the current native-choice slice to neutral Availability/Back, blue More details, one-primary Plan entry with guarded secondary More commands, centered Agent unavailable state/retained drafts, paired About background and blue refresh primary. Weather now uses X and text Save/Done; the redundant Continue without weather command is removed. Other toolbar confirmation glyphs become text Done, preserving selection checks. Native choice rows explicitly use semantic white/dark surfaces. Planner’s duplicate Upcoming section is removed and its arrow targets are adjacent. Compact disclosure symbols apply across related rows.

Intermediate build failed on an incorrect extracted availability type; restored the existing OutfitSuggestionAvailability type. Review identified long retained-draft layout/selection loss; the shared empty page now uses intrinsic message height and separate selectable retained text. Core73/native215 pass `/tmp/aqd-pr37-native-choice-complete-unit.log` before the final row-color/calendar-gap adjustments. Final checks and review are pending.

Native-choice/action cleanup final Core73/native215 PASSED `/tmp/aqd-pr37-native-choice-final-complete-unit.log`. Standards rechecked intrinsic/selectable retained drafts and all current callbacks/guards without remaining findings; Spec likewise found no remaining scope defects. Owner then broadened the next slice: all bottom-sheet editor confirmations move to top-right text Save/Done, retaining unknown-result controls and removing duplicate bottom saves. Inactive tab glyphs must remain light outline variants even when UIKit auto-selects filled SF Symbol variants. Audit covers creation/editing/nested choice forms; onboarding/full-screen wizard, critical typed reviews and non-save task/navigation actions retain their own contracts.

### Editor, Today and Profile refinement

Completed the sheet confirmation audit with guarded top-right text Save/Done, preserving staged review, unknown-result reconciliation and receipt/navigation commands. Native tabs render light inactive outline templates and stronger selected symbols. Today cards use gray contextual eyebrows without heading icons; the discovery-only weather build sentence is removed, while live qualification stays disabled. Profile avatar opens identity editing; redundant privacy copy is removed and an optional editable/clearable caption defaults to "A little of what I wear." Captions share existing JSON identity/draft persistence and archives without a structural schema change.

Caption regressions failed before implementation (`/tmp/aqd-profile-caption-red.log`) and passed afterward. Core75 in23 suites and native216 (203 Swift Testing in31 suites plus13 XCTest) passed `/tmp/aqd-pr37-editor-caption-unit.log` on the confirmed physical iPhone. Tests cover legacy identity decoding, trim/limit/clear, save retry, reopen and cancel retention. Copy-only consistency fixes and removal of redundant condition wrappers followed. Final independent review, Release and install are recorded below when complete. E2E/rendered qualification remains #30; no simulator or ordinary-data reset.

Owner added App Store Today references as inspiration for richer home content. Preserve configured widgets/order and existing semantic surfaces. Add larger editorial headings for visual cards, real Closet photo previews with piece destinations, actual wear-week dates/markers, larger planned compositions, and favorite/rediscovery artwork. No sample inventory, invented weather or implicit wear. This extends the current owner refinement slice.

Final refinement source review found two caption defects and both were fixed: root preview now caps at3 lines, and draft retention validates structure independently from final caption validity so over-limit text plus other edits survives restart. A new native regression proves retained invalid input, refused final commit and successful correction. Final Core75/native217 (204 Swift Testing in31 suites plus13 XCTest) PASSED `/tmp/aqd-pr37-editor-rich-today-unit.log`. Both source reviewers rechecked these corrections and richer Today content without remaining implementation findings. Updated authoritative Profile/Today/native-presentation/architecture/interaction contracts resolve the documentation finding.

Unsigned Release PASSED `/tmp/aqd-pr37-editor-rich-today-release.log`; repository tooling51 and agent-doc links passed (`/tmp/aqd-pr37-editor-final-tooling.log`, `/tmp/aqd-pr37-editor-final-docs.log`). This is the final source checkpoint for local owner review. Fresh physical install/normal launch follows without fixtures or data reset; PR37 stays open during UI iteration.

Final local owner-preview checkpoint `d1032c46945b0e1007d91e4411ed859cbb05c0f2`: Core75/native217, unsigned Release and Tooling51 pass. Fresh physical install and normal launch both returned success (`/tmp/aqd-pr37-editor-preview-install.json`, `/tmp/aqd-pr37-editor-preview-launch.json`). Executable/source hashes and outcomes are bound in `/tmp/aqd-pr37-editor-preview-receipt.json`; no fixtures, uninstall or data reset. Scope includes every current owner UI request, including richer actual-record Today cards and editable captions. Live Weather/Agent qualification is unchanged. PR37 remains open for continued local owner iteration; latest-head remote CI/Codex/protected merge/release and #30 rendered acceptance are separate gates.

Planner spacing follow-up: removed the agenda ScrollView’s duplicate20-point top inset so the selected date and first row use the existing16-point section gap. Unassigned text-only rows use an80-point minimum; rows with outfit artwork retain108 points and all content can grow for accessibility text. Cosmetic source change; physical Debug build/install verification follows.

The owner also requests a lighter date heading: Planner now uses a localized abbreviated weekday/month/day, for example "Fri, Oct16", in regular17-point secondary text. The calendar already supplies month/year; full recorded-timezone dates remain in detail and history. The formatter explicitly keeps the selected day’s saved timezone. This joins the spacing preview slice.

Planner date/spacing cosmetic checks: Debug BUILD SUCCEEDED (`/tmp/aqd-pr37-planner-date-spacing-build.log`), physical install and normal launch both success (`/tmp/aqd-pr37-planner-date-spacing-install.json`, `/tmp/aqd-pr37-planner-date-spacing-launch.json`). Source review checked row sizing/content growth and explicit date timezone; no data or navigation changes. No new unit/E2E claim. Existing data retained. PlannerViews SHA256 291ad5027b848f31d9ea42a1c8ff27efbaf137676dc8235b0006c841b5e983bf, installed executable SHA256 d07efc3704f60f150a298b76dc4f538512ae252142b82c4b6f48ed576b0f167d.

### Theme filtering owner request

Add the missing Themes top-right native filter menu, consistent with Pieces/Outfits. Content options: All themes, With outfits, Empty themes. Sorting: Name A–Z, Name Z–A, Most outfits with name ties. Browse/search retain separate choices; changing Search options refreshes query-matched results and caches by the full input. Clear filters restores default name sorting/content. Filtered browse emptiness offers Clear filters at the bottom while genuine empty Closet offers Create theme. No theme or outfit mutations and no schema change. Verify pure selection/sort rules and native search/cache behavior; unit-only/E2E #30 boundary remains.

Additional owner scope: remove the Edit profile optional-fields sentence. Add a Photos-inspired compact gray metadata line below Closet segments: visible Pieces/category counts, Outfits/favorites and selected theme, Themes/empty counts and active content/sort choices. Existing Search keeps its result summary. Collection errors explicitly say unavailable instead of claiming zero. Source tests first reproduced missing ThemeCollectionQuery (`/tmp/aqd-theme-filter-red.log`); final checks follow.

Owner additionally requests richer Instagram-inspired Profile. Use a larger avatar with actual local Fits/Outfits/active Pieces counts, name/caption below, a close-spaced photographic journal and readable saved dates. Preserve three toolbar actions/avatar editing, privacy boundaries and real records. No social counts/network/public projection. Empty Profile header/message must scroll for accessibility while Add fit stays at bottom. Unit/build/source review/install remain required for the combined current iteration.

Theme filter first full run PASSED Core77/native218 (`/tmp/aqd-theme-filter-unit.log`). Spec review identified filtered Search recovery lacking Clear filters; added a separate reset that keeps the query, while Clear search remains available. Source review otherwise found no defects. Owner Profile refinement then added real statistics,88-point avatar, adaptive header and readable journal dates; empty Profile now scrolls header/message together with bottom Add fit. Final combined checks follow.

Combined final source reviews rechecked Theme filter reset/query retention, actual visible Closet metadata and the adaptive Profile header/empty page without actionable findings. Final Core77 in24 suites and native218 (205 Swift Testing in31 suites plus13 XCTest) PASSED `/tmp/aqd-closet-profile-refinement-unit.log`. Agent-doc links and whitespace pass. No E2E/rendered acceptance claim; physical owner preview follows Release.

Final unsigned Release PASSED `/tmp/aqd-closet-profile-refinement-release.log`. Source is ready for physical owner preview; no new qualification of live capabilities or rendered #30 paths.

Closet/Profile preview source `bd5c9f6506ac53efa616efdc8572f1f2226aa3b5`: Core77/native218, unsigned Release and agent-doc links pass. Both independent source reviews have no remaining findings. Physical install and normal launch returned success (`/tmp/aqd-closet-profile-refinement-install.json`, `/tmp/aqd-closet-profile-refinement-launch.json`). Source/executable binding is in `/tmp/aqd-closet-profile-refinement-preview-receipt.json`. No fixtures or data reset; owner may review the new Theme filters, actual Closet metadata and richer private Profile now. PR37 remains open and rendered qualification remains #30.

Owner simplification: removed the redundant Clear name button in Edit profile. Direct field deletion still saves an absent name through the existing validated draft path, with cancellation/retry semantics unchanged. Audited related profile controls and updated current feature/design/control-registry guidance; caption/photo actions remain intact. Cosmetic change, verify Debug build and refresh physical preview.

Owner further refines Closet metadata: count and actual sort become distinct aligned header elements, with a second contextual line for ready-to-wear/laundry/unavailable/category, favorites/theme membership, or populated/empty theme counts. Labels derive from the same visible records and current sort; accessibility text stacks, errors suppress numeric claims. This cosmetic summary replaces the sparse single line and joins the Clear name removal preview. No filter/sort or data mutation behavior changes.

Cosmetic Profile/Closet follow-up checks: Debug BUILD SUCCEEDED `/tmp/aqd-closet-metadata-polish-build.log`, agent-doc links and whitespace pass. Source review confirmed actual filtered counts and Outfits updatedAt ordering. A reported archived-count concern was independently retracted after tracing the separate Archive destination and active-only root query; no unresolved source finding. Physical install and normal launch succeeded (`/tmp/aqd-closet-metadata-polish-install.json`, `/tmp/aqd-closet-metadata-polish-launch.json`), with no fixtures/data reset. Installed executable SHA256 7d8c285eaf9e915733eeb53a1b912510df7c563ac511ffca24706dd9b72d7b12. Existing unit results remain bound to prior source; no new unit/E2E claim for this cosmetic slice.

### Explicit owner sample-data request

Owner authorizes populating the current app, overriding the earlier no-seeding preview boundary for this operation only. Add clearly labelled sample records to the ordinary store without resetting/replacing it:12 pieces from existing generated garment artwork,6 outfits,4 themes,7 future/current plans and8 illustrative fit memories. Preserve identity, preferences, drafts, existing collections and actual wear. A Debug-only explicit launch command creates a protected local archive first, stages media with mutation checks, atomically inserts a stable-ID sample graph, and writes a local receipt. Repeating the command adds no duplicates; partial/deleted sample graphs refuse silent replacement. Unit-check preservation/idempotence/commit failure on temporary stores before the real operation. Normal launch/Release never seeds; E2E #30 remains unactivated.

Sample-population first Core77/native220 PASSED `/tmp/aqd-preview-samples-unit.log`; tests use temporary stores and did not seed ordinary data. Standards review corrected backup protection to reuse LocalArchiveIO’s Complete protection and backup exclusion. Added a protection assertion plus a protected diagnostic file for an explicitly requested Debug seed failure. Spec review found no gaps. Final checks precede any real population.

Final sample-population Core77/native220 PASSED `/tmp/aqd-preview-samples-final-unit.log`, including Complete backup protection, idempotence, preserved identity/unfinished draft and failed-commit retry. Both independent source reviews are clear after the protection correction. Owner keeps adding Settings refinement scope; install/populate this verified Debug sample checkpoint first, then continue that UI slice. No ordinary-store seed has run at this documentation checkpoint.

Real owner-requested population succeeded at source e24549e: device receipt `/tmp/aqd-sample-content-receipt.json` confirms added12 pieces/6 outfits/4 themes/7 plans/8 fits after graph readback. Protected pre-operation archive remains in app Documents as `AQD-before-samples-4A7E6FC1-EB83-446B-9120-F81500D1E7AF.aqdarchive`. Explicit command launch and subsequent ordinary launch succeeded; no wipe or actual-wear seed. Sample display is for owner review, not E2E qualification.

### Settings owner refinement

Owner requests clearer native Settings structure, personal settings before local data, symbols/disclosures, appearance labels/icons, circular icon chrome, no bottom tabs while Settings is open, and full-screen restore/erase pages instead of sheets. Rework erase impact as grouped readable counts with a bottom full-width destructive action, keeping exact ERASE plus final critical alert and all model/reconciliation guards. Reuse structured summaries in export/restore. Preserve dismissal-before-store replacement and existing recovery source handling. No restore/erase operation is authorized or executed as part of this UI work.

Initial Settings Core77/native220 pass (`/tmp/aqd-settings-structure-unit.log`). Independent review caught retained Profile Settings hiding chrome after Agent → Open Closet; visibility now derives from selected Profile root AND retained Settings destination. Added a state regression for cross-root return and retained Settings. Review pages refresh an existing uncommitted review when reopened so count/impact matches the current source, resetting typed ERASE through existing review version handling. No commit/cancel/reconciliation logic changed. Final combined checks follow.

Final Settings Core77/native221 PASSED `/tmp/aqd-settings-structure-final-unit.log` (208 Swift Testing across32 suites plus13 XCTest). Both independent reviewers rechecked visible-Settings scoping and refreshed-impact return without findings. Agent-doc links/whitespace pass. No restore or erase was performed; those current app paths remain owner-review/#30 rendered acceptance. Final Release and fresh install follow.

Final unsigned Release PASSED `/tmp/aqd-settings-samples-release.log`; the Release executable contains no `--aqd-add-preview-samples` command string. Native/Core checks remain Core77/native221. Latest Debug preview install will preserve already-populated ordinary records and run without the seed flag.

Owner sees populated UI and requests: simplify Closet to count/current sort only, fix uneven Profile photo/composition tiles, and replace the cramped plan-removal popover. Remove the secondary Closet statistics line for all scopes. Journal thumbnails now have one explicit3:4 geometry, photo-only presentation crop, larger adaptive2-column piece cells and a quiet composition marker; details retain full-source Fit. Plan More keeps native controls with clearer labels and removal uses a centered native alert with explicit Cancel/Remove and the same scoped request/retry guards. No record mutations are authorized by these UI changes.

Populated-UI cosmetic checks: Debug BUILD SUCCEEDED `/tmp/aqd-profile-grid-plan-polish-build.log`; both independent source reviews report no actionable findings. Agent-doc links and whitespace pass. Physical install and ordinary launch succeeded (`/tmp/aqd-profile-grid-plan-polish-install.json`, `/tmp/aqd-profile-grid-plan-polish-launch.json`), with empty launch arguments, no seed command and no reset. Latest units/Release remain bound to Settings source8b5a543; this later cosmetic source has Debug/source checks only. All rendered/E2E acceptance remains #30.

Owner scroll refinement: keep the Closet title/toolbars and segment rail fixed, but move count/sort metadata into each collection's existing scroll container. Pieces, Outfits and Themes share the same small summary view; no nested scroll views or changes to stored collection anchors. Empty pages keep their existing centered guidance and bottom action.

Scroll refinement checks: the first compile required explicit memberwise callback arguments; corrected and final Debug BUILD SUCCEEDED `/tmp/aqd-closet-scrolling-summary-final-build.log`. Independent Standards source review has no actionable findings; doc links and whitespace pass. No new unit or E2E claim for this layout-only change.

Latest owner preview source `1125307370f91cb3261f4021a67480349e9425f1`: physical install and normal launch succeeded with no arguments or data reset. Executable SHA256 `d16106dc59d69e1c0f603e6d903142920ea58ce8bd16e456ba527c796e226d70`; local binding `/tmp/aqd-closet-scrolling-summary-preview-receipt.json`. Consolidated receipt separates Settings unit/Release source8b5a543 from subsequent cosmetic Debug-only previews. PR37 remains open.
