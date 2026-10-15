# Implementation status

## Current handoff, October 15, 2026

Foundation #20 shipped in [PR #31](https://github.com/vn-aj-vngrd/aqd/pull/31), squash `8b06880`, repository release v1.1.1. It extends the PR #9 native capture/store baseline. [Issue #21](../plan/issue-21.md) now has committed physical-device policy, shared preferences, complete entry/tour/logo and optional body-input slices. Its [local scoped acceptance](../plan/evidence/issue-21/README.md) passes with explicit unchanged-input reuse and a successful five-case refresh of the notification-interrupted base case and affected consumers. PR publication, current-head CI/Codex, merge and release remain pending. Sections 01–09 remain incomplete; baseline capture is not complete V1.

The [implementation plan](implementation-plan.md) owns ten implementation issues, #20–29, followed by final E2E/hardening [#30](https://github.com/vn-aj-vngrd/aqd/issues/30). Its clarified verification policy requires unit/build/repository/review plus focused native E2E and published evidence for each feature's UI ACs. Broad full-suite/device qualification remains in #30. Missing/failed/unpublished proof of a current AC blocks its feature; unit/build passes alone do not satisfy the new proof gate.

Owner update October16: expensive hosted native CI has been removed and all E2E is deferred to #30. Feature delivery is unit-only with physical-iPhone native checks. Existing execution results remain historical/source-bound; the canceled hosted run is not a pass. PR33 remains open while the owner considers a dependency-based multi-issue PR proposal. No further section implementation is authorized yet.

### Foundation capability and known gaps

Shared native actions, fields, feedback, selection and source-aware task navigation serve the existing capture/photo/details/save/reopen journey. The committed checkpoint adds semantic Back/Close behavior, exposed native metadata, task-owned focus/scroll handling, idempotent tab selection and bootstrap revalidation. [Foundation inventory](../../apps/ios/FOUNDATIONS.md) owns reuse; [verification](verification.md) owns exact execution history.

Current iPhone 17 Pro Max/iOS27 focused Notes proof passes after anchoring the focused editor bottom. Actual short-text and seventh-line OCR, inspected caret/keyboard screenshots and Apply/cancel/discard/relaunch assertions pass. Older runtime/full-matrix failures remain in #30; this scoped result does not certify every device or editing scenario. Existing scoped simulator passes do not establish complete native accessibility, physical media/protection/backup, performance or on-device model quality. Required latest-head CI/Codex and protected delivery remain separate gates.

### Agent execution foundation

[Autonomous workflow](../agents/autonomous-workflow.md) routes full issue delivery through `aqd-ship`, which orchestrates implementation, verification and review plus protected delivery stages. #20's published proof, current-head CI/Codex, protected merge and repository release passed. [Persisted issue plans](../plan/README.md) hold vertical slices, commit SHAs, checks and the next action. Local native checks use the owner's physical iPhone 17 Pro Max, discovered on iOS27.0.1/24A446 for #21; the owner confirmed readiness and its baseline Core/native unit checks passed. Local simulators remain shut down. Hosted simulator CI is separate evidence; broad personal-phone acceptance remains #30. Current deployment settings stay in place.

[Issue #20 execution record](../plan/issue-20.md) retains its delivery receipt; [issue #21](../plan/issue-21.md) owns the active implementation. #21 local focused proof and source review are complete; published proof and remote delivery gates remain open. Neither a repository release nor these unit checks establish complete V1 acceptance or native distribution.

## Earlier handoffs

[October 15 pre-cleanup status](archive/implementation-status-2026-10-15.md) retains all prior Foundation experiments, counts, pauses and baseline chronology. Read it only to investigate those receipts. [Verification](verification.md) retains the detailed observed results; the current implementation plan supersedes older per-feature runtime gates.
