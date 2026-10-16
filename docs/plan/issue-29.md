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
