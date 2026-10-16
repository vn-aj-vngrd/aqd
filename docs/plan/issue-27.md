# Issue 27: Agent, conversations and recovery

https://github.com/vn-aj-vngrd/aqd/issues/27

## Scope

Authorized endpoint: one grouped PR through current-head unit CI/Codex fixes, protected squash merge and merged-SHA repository release verification. Companion: [issue29](issue-29.md). Baseline: `1a5b44ecf06536d6bb1dae0551348f44a9747d5b`, merged PR36/v1.5.0; clean main verified. Branch `van/issue-27/agent-and-local-controls`. Actual issues and comments inspected; both open with no comments. Approved grouping supersedes historical separate-PR dependency wording.

Use existing public Core validators and actual PieceStore/model save/read/reopen seams for unit coverage. Owner confirmed the physical iPhone17ProMax connected/unlocked/ready; all simulators shut down. All E2E authoring/execution, rendered/native acceptance, real capability quality/performance remain issue30. No cloud model, backend, human Inbox, signed distribution or automatic capability activation.

## Slices

| Slice | Working outcome | Acceptance | Unit verification | State | Commit marker | SHA |
| --- | --- | --- | --- | --- | --- | --- |
| S1 | Durable conversations, drafts/history/new/delete and reason-specific availability/manual routes | LOCAL12/15, A2/A11 | Actual store failure/unknown/reopen + populated migration | Committed | `AQD-Slice: #27/S1` | `5a149ff` |
| S2 | Explicit bounded context, generation/cancel/retry/interruption, Markdown/copy/details and real-provider gated path | A2/A7/A8/A12/A14/A15, LOCAL12 | Core context/stream/copy policy + native model/state tests | Committed | `AQD-Slice: #27/S2` | `d347a75` |
| S3 | Version-bound domain reviews/receipts, weather context and honest voice/image recovery | A1/A3–6/A13, LOCAL09/16 | Owned/stale/exactly-once approval and parent draft tests | Committed | `AQD-Slice: #27/S3` | `18fb6e2` |

## Acceptance and evidence

Contracts: [Agent](../features/agent.md), [Profile/Settings](../features/profile-account.md), [local architecture](../architecture/v1.md), [LOCAL acceptance](../product/v1-release.md#local-acceptance), [Agent input](../design/agent-input.md), [response experience](../design/agent-experience.md), native presentations and DQ01–12. Live Paper V1 file/page inspected, token hash `fdeb7346`; canonical and supporting controls from the issue inventory own composition. Existing manual editors/validation/media ownership remain authoritative.

Each slice will record actual commands, revision, result and local artifact. AC evidence is published in the grouped PR; synthetic provider tests are not real model/speech/garment qualification. No UI pass is claimed from units.

## Review and delivery

Local implementation, slice review and independent Standards/Spec review are complete. Core71/native194 and unsigned Release pass. Current-head CI/Codex, resolved remote findings, protected SHA-bound squash and merged-SHA release verification remain required.

## Shipping and resume

Repository vn-aj-vngrd/aqd, head branch above. Resolve/reuse its single PR. Persist slice SHAs immediately in the next slice/receipt. GitHub owns live remote gates; no extra commits for polling or the new PR URL. Current next action: resume PR37 current-head Repository tooling/Codex gates, fix any further findings, then protected squash merge and verify exact merged-SHA CI/release. No dirty unrelated files or known local failures.

## S1 receipt

Durable owner/revision-bound conversations retain typed drafts, received source and interrupted attempts. New/history/delete remain readable independent of runtime availability; fourth-slot dismissal preserves native origin. Same-operation acknowledgments reconcile unknown saves/deletes without resurrecting deleted text or changing wardrobe/plans/wear. Schema21 preserves all earlier versions and includes Agent rows in exact empty-bootstrap checks.

Missing Core API failed `/tmp/aqd-27-s1-red.log`; Core66 and native176 passed `/tmp/aqd-27-s1-unit.log` on the physical iPhone17ProMax/iOS27.0.1. Final three focused actual-store/model tests passed `/tmp/aqd-27-s1-final.log`, including populated V20 migration and retaining newer typing after an unknown write. Bounded Standards/Spec review inspected owner/revision/receipt/delete scope, failed/unknown/reopen paths, availability/manual/history UI and source return; no remaining slice finding. All E2E/rendered acceptance remains issue30. Context/generation/approval closure follows S2/S3.

## S2 receipt

Explicit context supports general/no closet, bounded eligible metadata and selected owned piece/outfit/theme revisions. Style uses allowed answers and separate body-use permission; selected wear summaries use the selected included pieces. Notes/photos are excluded. Draft context changes affect only later requests. The provider bridge uses guarded native Foundation Models streaming, with no tools or cloud fallback; qualification remains nil until measured issue30 evidence supplies budgets. Complete user history is retained or the request refuses the context budget.

Received source, stable message/attempt identities, partial output, prior response versions, measured timing, Stop acknowledgment, hard timeout, interruption and same-turn retry persist locally. Markdown renders safe links/code/prose without remote images/HTML; plain/Markdown/code copy and details are explicit. Busy controls use real provider events, not staged delays. Missing Core APIs failed `/tmp/aqd-27-s2-red.log`. Core68/native181 passed `/tmp/aqd-27-s2-unit.log` on the iPhone. Final six focused generation/persistence cases passed `/tmp/aqd-27-s2-final.log` after selected-wear scope and terminal-reason corrections. Synthetic provider tests prove actual model/store lifecycle, not physical model capability/quality. Bounded Standards/Spec review traced cancellation, stale chunks, budgets, context exclusion, ownership, persistence and source returns. Full native/rendered qualification remains issue30.

## S3 receipt

Local tools prepare exact outfit/theme/plan/wear/availability drafts for a separate immutable review. Explicit approval persists its version before dispatching the existing domain operation, validates current sources, reconciles the original operation after unknown completion, and exposes a receipt only after acknowledgment. Cancellation writes no domain records; cancelled/stale approvals do not acquire fresh authority. Theme source outfits carry captured revisions. Conversation deletion refuses unconfirmed actions. Digest/revision/timestamp save acknowledgments preserve exact retry results without duplicating entire chat bodies.

Shared Weather selection changes only this context draft; requests include only fresh matching qualified cached data with place/day/zone/provider/fetch provenance. Voice has explicit permission, on-device-only recognition, measured listening level/time, transcript review/concurrent-input append review, discard/interrupt cleanup and manual fallback; activation remains disabled until issue30. Image assistance remains honestly unavailable with description/closet/manual routes. No recording/model/weather qualification is claimed. Markdown includes accessible table rows and safe copy; all rendered acceptance remains issue30.

Missing action APIs failed `/tmp/aqd-27-s3-red.log`. An actual proposal-only lost-ack/restart failure reproduced in `/tmp/aqd-27-s3-proposal-red.log`; empty-conversation detection now includes proposals. Core69/native183 pass `/tmp/aqd-27-s3-unit.log`; final five action/generation cases pass `/tmp/aqd-27-s3-final.log`, then five persistence/action cases pass `/tmp/aqd-27-s3-receipts.log` after reducing acknowledgment payloads. Device: physical iPhone17ProMax/iOS27.0.1, no simulator/E2E. Bounded Standards/Spec review covered unchanged shared validators, revision-bound reviews, exactly-once receipts, cancellation/privacy, unavailable capabilities and source-preserving manual routes. Full independent group review follows Settings/data controls.

## S2 terminal-state review correction

A focused Core regression reproduced empty responses being marked complete and stale failure copy surviving retry (`/tmp/aqd-agent-final-red.log`). Completion now requires received nonblank text and retry clears the previous failure. Background suspension retains an interrupted attempt rather than claiming a user Stop; explicit Stop still acknowledges cancellation. Stored optional Weather selections use their shared validator. Full Core71/native193, comprising180 Swift Testing and13 XCTest, pass `/tmp/aqd-27-29-final-unit.log` on the confirmed physical iPhone17ProMax/iOS27.0.1. The native regression includes an empty provider and suspension before any chunk, rejecting late text and preserving interruption on reopen. No E2E ran.

## Full independent review correction

Standards found two recovery/current-state defects across the group; Spec found the same erase retry defect plus a conversation deletion deadlock. A refused deletion now releases its pending latch for confirmed conflict/stale refusals, preserving uncertain deletion identity. This permits the original unconfirmed domain action to reconcile. The new regression additionally reproduced repeated approval resetting a terminal proposal; approval now rejects wrong versions and terminal states before mutation. Succeeded/cancelled outcomes remain unchanged across repeated approval and reopen.

Actual failures: `/tmp/aqd-27-29-review-red.log` and `/tmp/aqd-27-29-review-unit.log`. Final Core71/native194, comprising181 Swift Testing and13 XCTest, pass `/tmp/aqd-27-29-review-final-unit.log`. Both independent reviewers rechecked all corrections and direct consumers, with no remaining findings. All E2E remains issue30; current-head Codex review is a separate required gate.

## Local closeout receipt

Final source `1356ebbf655ac1b5edbdc5ac493762308e1bc8f7` includes terminal-state correction `1272f2a`, Agent review correction `f485d0f` and Settings correction `1356ebb`; erase slice `08e727d` and Planner width slice `e7c4eb8` remain separate. [Grouped AC evidence](evidence/issue-27-29/README.md) and [source-bound receipt](evidence/issue-27-29/unit-receipt.json) retain source hashes and local log digests. Final Core71/native194 and unsigned Release pass; Tooling51, agent-doc links and whitespace pass. Standards2/Spec2 findings, including the overlapping erase issue, and the additionally reproduced terminal approval defect are fixed and independently rechecked. All E2E/rendered/capability qualification remains issue30. Live GitHub gates are the next action, not a local pass claim.

## PR37 Codex corrections

[PR37](https://github.com/vn-aj-vngrd/aqd/pull/37), initial head `0b910aa`, passed Repository tooling. Codex completed with two P2 findings: retry included the completed answer it was replacing, and erase cleanup recovery was hidden before main. Retry now omits only the targeted assistant message while retaining preceding turns and its user request. Welcome, Style and tour use the shared observable cleanup wrapper, preserving warning/retry before onboarding completes.

Prompt assertions reproduced the defect in `/tmp/aqd-pr37-codex-red.log`. Refreshed Core71/native194 pass `/tmp/aqd-pr37-codex-unit.log`; the all-domain erase test confirms a new welcome AppState retains pending cleanup. Both independent reviewers rechecked the changed consumers with no findings. Refreshed unsigned Release passed `/tmp/aqd-pr37-codex-release.log`; agent-doc/whitespace checks pass. Final-head CI/Codex remain required. All E2E remains issue30.

## PR37 second Codex review corrections

Current remote head `53a9fb4` has three Codex findings: archive payload buffering, duplicate unchanged conversation retry writes and lost latest appearance choice during reconciliation. Owned local fixes reduce/disclose the archive limit to64MiB, return the checked summary without another full decode, acknowledge unchanged chat retries without a new operation, and retain the latest desired appearance separately from immutable pending requests. Explicit appearance Retry uses that latest intent, including repeated storage failure. Both independent reviewers rechecked without remaining source findings.

Original regressions fail in `/tmp/aqd-pr37-codex2-red.log`. The first full run `/tmp/aqd-pr37-codex2-unit.log` FAILED with one missing UIWindowScene and two test-runner exits (194 passed,3 failed); it remains failed evidence. After the owner reconfirmed the connected/unlocked/untouched iPhone, the complete rerun PASSED Core71/native197, comprising184 Swift Testing and13 XCTest, in `/tmp/aqd-pr37-codex2-final-unit.log`. The previously interrupted cases pass without weakened assertions. The appearance regression covers failure both before and after a committed write, with storage recovery before or after the second choice, plus explicit Retry. Generic unsigned Release PASSED `/tmp/aqd-pr37-codex2-release.log`; agent-doc/whitespace checks pass. Both independent reviewers rechecked final source and direct consumers without remaining findings. All simulators stayed shut down and no E2E ran. Next: commit/push corrections and refreshed source-bound evidence, resolve addressed threads, obtain new-head CI/Codex, then protected squash/release.
