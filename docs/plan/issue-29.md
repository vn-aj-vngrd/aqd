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

| S5 | Owner-requested Planner week strip fills its container evenly | Owner follow-up | Native Debug compile; rendered acceptance deferred to issue30 | Committed | `AQD-Slice: #29/S5` | Pending |

## Acceptance and evidence

Contracts: [Agent](../features/agent.md), [Profile/Settings](../features/profile-account.md), [local architecture](../architecture/v1.md), [LOCAL acceptance](../product/v1-release.md#local-acceptance), [Agent input](../design/agent-input.md), [response experience](../design/agent-experience.md), native presentations and DQ01–12. Live Paper V1 file/page inspected, token hash `fdeb7346`; canonical and supporting controls from the issue inventory own composition. Existing manual editors/validation/media ownership remain authoritative.

Each slice will record actual commands, revision, result and local artifact. AC evidence is published in the grouped PR; synthetic provider tests are not real model/speech/garment qualification. No UI pass is claimed from units.

## Review and delivery

Pending implementation, bounded slice review, independent full Standards/Spec review, physical unit/build receipt, current-head CI/Codex, resolved findings, protected SHA-bound squash and merged-SHA release verification.

## Shipping and resume

Repository vn-aj-vngrd/aqd, head branch above. Resolve/reuse its single PR. Persist slice SHAs immediately in the next slice/receipt. GitHub owns live remote gates; no extra commits for polling or the new PR URL. Current next action: implement issue27 S1 before subsequent slices. No dirty unrelated files or known baseline failures.

## S1 receipt

Settings owns persistent System/Light/Dark appearance, actual capability/help/privacy copy and shared Style/tour/weather tasks. Appearance changes use revision-bound immutable receipts; failed writes retain prior settings, unknown results retry the same request, and old acknowledgments never rewind a newer setting. Open Agent uses an explicit native full-screen request rather than selecting the inert fourth-slot root. Shared questionnaire/tour/weather retain source and separate consent.

Schema22 freezes earlier versions and adds Settings/receipts plus a transaction-bound local mutation stamp for reviewed data replacement. The stamp changes only inside a successful store transaction; failure rolls back both records and stamp. Missing Core API failed `/tmp/aqd-29-s1-red.log`. Core70/native185, comprising172 Swift Testing plus13 XCTest, pass `/tmp/aqd-29-s1-unit.log` on the physical iPhone17ProMax/iOS27.0.1. Tests cover failure/unknown/reopen, old receipt after newer settings, actual AppState appearance and shared consent/tour return. Existing populated migration and bootstrap protections pass. Bounded Standards/Spec review covered state ownership, revision/receipt integrity, current schema fixtures, native request identity and privacy routes. Export/restore/erase follow S2–S4; all E2E remains issue30.

## S2 receipt

Export prepares a consistent standalone SQLite snapshot with versioned records and all referenced AQD media, including original/derived sources and edit renditions. The native bounded `.aqdarchive` format has an allowlisted path table, per-file size/SHA256, schema/model integrity, explicit 512 MB budget and no zip dependency. Actual counts/bytes appear before explicit Save to Files. Preparing/cancelled/ready/failed and Files-cancel/failure retain the closet. Source mutation stamps reject a changing snapshot. Private staging uses file protection/backup exclusion; media work and encoding run off the UI actor with cancellation propagation.

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
