# Implementation status

## Current handoff, October 16, 2026

Foundation #20 shipped in [PR #31](https://github.com/vn-aj-vngrd/aqd/pull/31), squash `8b06880`, repository release v1.1.1. It extends the PR #9 native capture/store baseline. [Issue #21](../plan/issue-21.md) now has committed physical-device policy, shared preferences, complete entry/tour/logo and optional body-input slices. Its [local scoped acceptance](../plan/evidence/issue-21/README.md) passes with explicit unchanged-input reuse and a successful five-case refresh of the notification-interrupted base case and affected consumers. PR #33 and scoped evidence are published. Final current-head CI/Codex, protected merge and repository release remain delivery gates. Section01 implementation is complete locally; sections02–09 and final #30 acceptance remain incomplete.

The [implementation plan](implementation-plan.md#approved-pr-groups--october16) retains issues #20–29 and final E2E/hardening [#30](https://github.com/vn-aj-vngrd/aqd/issues/30). The owner approved grouped delivery: #24 + #23, then #25 + #26, #28 + #22, #27 + #29, then #30. Each group uses one PR, separate issue plans in `docs/plan` and commits per working vertical slice. After PR33's protected merge and repository-release verification, the next authorized implementation is #24 + #23, in that internal order. No additional planning approval is needed.

Feature delivery uses affected Core/native unit checks and fast repository/tooling unit CI. Expensive hosted native CI is removed; all E2E authoring/execution and integrated UI acceptance are deferred to #30. Native checks use the owner's connected, unlocked physical iPhone17ProMax only; no simulator locally or in CI. Existing execution results remain historical/source-bound; canceled hosted runs are not passes. Known product/data-loss/security defects remain blocking, and unit passes do not certify integrated UI acceptance.

### Foundation capability and known gaps

Shared native actions, fields, feedback, selection and source-aware task navigation serve the existing capture/photo/details/save/reopen journey. The committed checkpoint adds semantic Back/Close behavior, exposed native metadata, task-owned focus/scroll handling, idempotent tab selection and bootstrap revalidation. [Foundation inventory](../../apps/ios/FOUNDATIONS.md) owns reuse; [verification](verification.md) owns exact execution history.

Current iPhone 17 Pro Max/iOS27 focused Notes proof passes after anchoring the focused editor bottom. Actual short-text and seventh-line OCR, inspected caret/keyboard screenshots and Apply/cancel/discard/relaunch assertions pass. Older runtime/full-matrix failures remain in #30; this scoped result does not certify every device or editing scenario. Existing scoped simulator passes do not establish complete native accessibility, physical media/protection/backup, performance or on-device model quality. Required latest-head CI/Codex and protected delivery remain separate gates.

### Agent execution foundation

[Autonomous workflow](../agents/autonomous-workflow.md) routes full issue delivery through `aqd-ship`, which orchestrates implementation, verification and review plus protected delivery stages. #20's published proof, current-head CI/Codex, protected merge and repository release passed. [Persisted issue plans](../plan/README.md) hold vertical slices, commit SHAs, checks and the next action. Local native checks use the owner's physical iPhone 17 Pro Max, discovered on iOS27.0.1/24A446 for #21; the owner confirmed readiness and its baseline Core/native unit checks passed. Local simulators remain shut down. Hosted native CI is removed; all E2E and broad personal-phone acceptance remain #30. Current deployment settings stay in place.

[Issue #20 execution record](../plan/issue-20.md) retains its delivery receipt; [issue #21](../plan/issue-21.md) owns the active implementation. #21 local scoped proof is published; current-head CI/Codex, merge and release must be confirmed from PR33 before beginning its successor group. Neither a repository release nor these unit checks establish complete V1 acceptance or native distribution.

## Earlier handoffs

[October 15 pre-cleanup status](archive/implementation-status-2026-10-15.md) retains all prior Foundation experiments, counts, pauses and baseline chronology. Read it only to investigate those receipts. [Verification](verification.md) retains the detailed observed results; the current implementation plan supersedes older per-feature runtime gates.
