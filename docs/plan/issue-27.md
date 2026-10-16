# Issue 27: Agent, conversations and recovery

https://github.com/vn-aj-vngrd/aqd/issues/27

## Scope

Authorized endpoint: one grouped PR through current-head unit CI/Codex fixes, protected squash merge and merged-SHA repository release verification. Companion: [issue29](issue-29.md). Baseline: `1a5b44ecf06536d6bb1dae0551348f44a9747d5b`, merged PR36/v1.5.0; clean main verified. Branch `van/issue-27/agent-and-local-controls`. Actual issues and comments inspected; both open with no comments. Approved grouping supersedes historical separate-PR dependency wording.

Use existing public Core validators and actual PieceStore/model save/read/reopen seams for unit coverage. Owner confirmed the physical iPhone17ProMax connected/unlocked/ready; all simulators shut down. All E2E authoring/execution, rendered/native acceptance, real capability quality/performance remain issue30. No cloud model, backend, human Inbox, signed distribution or automatic capability activation.

## Slices

| Slice | Working outcome | Acceptance | Unit verification | State | Commit marker | SHA |
| --- | --- | --- | --- | --- | --- | --- |
| S1 | Durable conversations, drafts/history/new/delete and reason-specific availability/manual routes | LOCAL12/15, A2/A11 | Actual store failure/unknown/reopen + populated migration | Committed | `AQD-Slice: #27/S1` | Pending |
| S2 | Explicit bounded context, generation/cancel/retry/interruption, Markdown/copy/details and real-provider gated path | A2/A7/A8/A12/A14/A15, LOCAL12 | Core context/stream/copy policy + native model/state tests | Planned | `AQD-Slice: #27/S2` | Pending |
| S3 | Version-bound domain reviews/receipts, weather context and honest voice/image recovery | A1/A3–6/A13, LOCAL09/16 | Owned/stale/exactly-once approval and parent draft tests | Planned | `AQD-Slice: #27/S3` | Pending |

## Acceptance and evidence

Contracts: [Agent](../features/agent.md), [Profile/Settings](../features/profile-account.md), [local architecture](../architecture/v1.md), [LOCAL acceptance](../product/v1-release.md#local-acceptance), [Agent input](../design/agent-input.md), [response experience](../design/agent-experience.md), native presentations and DQ01–12. Live Paper V1 file/page inspected, token hash `fdeb7346`; canonical and supporting controls from the issue inventory own composition. Existing manual editors/validation/media ownership remain authoritative.

Each slice will record actual commands, revision, result and local artifact. AC evidence is published in the grouped PR; synthetic provider tests are not real model/speech/garment qualification. No UI pass is claimed from units.

## Review and delivery

Pending implementation, bounded slice review, independent full Standards/Spec review, physical unit/build receipt, current-head CI/Codex, resolved findings, protected SHA-bound squash and merged-SHA release verification.

## Shipping and resume

Repository vn-aj-vngrd/aqd, head branch above. Resolve/reuse its single PR. Persist slice SHAs immediately in the next slice/receipt. GitHub owns live remote gates; no extra commits for polling or the new PR URL. Current next action: implement issue27 S1 before subsequent slices. No dirty unrelated files or known baseline failures.

## S1 receipt

Durable owner/revision-bound conversations retain typed drafts, received source and interrupted attempts. New/history/delete remain readable independent of runtime availability; fourth-slot dismissal preserves native origin. Same-operation acknowledgments reconcile unknown saves/deletes without resurrecting deleted text or changing wardrobe/plans/wear. Schema21 preserves all earlier versions and includes Agent rows in exact empty-bootstrap checks.

Missing Core API failed `/tmp/aqd-27-s1-red.log`; Core66 and native176 passed `/tmp/aqd-27-s1-unit.log` on the physical iPhone17ProMax/iOS27.0.1. Final three focused actual-store/model tests passed `/tmp/aqd-27-s1-final.log`, including populated V20 migration and retaining newer typing after an unknown write. Bounded Standards/Spec review inspected owner/revision/receipt/delete scope, failed/unknown/reopen paths, availability/manual/history UI and source return; no remaining slice finding. All E2E/rendered acceptance remains issue30. Context/generation/approval closure follows S2/S3.
