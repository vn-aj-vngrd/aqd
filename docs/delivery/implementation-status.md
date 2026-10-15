# Implementation status

## Current handoff, October 16, 2026

Foundation #20 shipped in [PR #31](https://github.com/vn-aj-vngrd/aqd/pull/31), squash `8b06880`, repository release v1.1.1. [Issue #21](../plan/issue-21.md) shipped in [PR #33](https://github.com/vn-aj-vngrd/aqd/pull/33), squash `f89a2de`, with green final-head unit CI/Codex, resolved findings, successful merged-main CI/Release and published v1.2.0 pointing to that SHA. Section01 source is delivered; historical physical evidence remains scoped and all final E2E acceptance stays #30.

The active grouped branch is `van/issue-24/outfits-and-closet`, covering [#24](../plan/issue-24.md) and [#23](../plan/issue-23.md) in one PR. All ten planned feature slices are implemented with separate commits: manual outfits, independent themes, pinned readiness/rules, actual Plan/Wear, outfit lifecycle, three Closet collections/scoped search, piece management/reviewed deletion and theme lifecycle. Core52/native129 pass; the final dispatcher-only correction also passes its five affected native tests. Repository tooling51 and final unsigned Release pass. Independent Standards/Spec findings are resolved and rechecked. The [source-bound unit receipt](../plan/evidence/issue-24-23/README.md) records checks and scope. Remote current-head CI/Codex/protected delivery remains before merge. Actual UI/E2E acceptance and optional model activation/quality qualification remain #30.

The [implementation plan](implementation-plan.md#approved-pr-groups--october16) retains issues #20–29 and final E2E/hardening [#30](https://github.com/vn-aj-vngrd/aqd/issues/30). The owner approved grouped delivery: #24 + #23, then #25 + #26, #28 + #22, #27 + #29, then #30. Each group uses one PR, separate issue plans in `docs/plan` and commits per working vertical slice. PR33 delivery is complete; the current authorized implementation is #24 + #23, in that internal order. No additional planning approval is needed.

Feature delivery uses affected Core/native unit checks and fast repository/tooling unit CI. Expensive hosted native CI is removed; all E2E authoring/execution and integrated UI acceptance are deferred to #30. Native checks use the owner's connected, unlocked physical iPhone17ProMax only; no simulator locally or in CI. Existing execution results remain historical/source-bound; canceled hosted runs are not passes. Known product/data-loss/security defects remain blocking, and unit passes do not certify integrated UI acceptance.

### Foundation capability and known gaps

Shared native actions, fields, feedback, selection and source-aware task navigation serve the existing capture/photo/details/save/reopen journey. The committed checkpoint adds semantic Back/Close behavior, exposed native metadata, task-owned focus/scroll handling, idempotent tab selection and bootstrap revalidation. [Foundation inventory](../../apps/ios/FOUNDATIONS.md) owns reuse; [verification](verification.md) owns exact execution history.

Current iPhone 17 Pro Max/iOS27 focused Notes proof passes after anchoring the focused editor bottom. Actual short-text and seventh-line OCR, inspected caret/keyboard screenshots and Apply/cancel/discard/relaunch assertions pass. Older runtime/full-matrix failures remain in #30; this scoped result does not certify every device or editing scenario. Existing scoped simulator passes do not establish complete native accessibility, physical media/protection/backup, performance or on-device model quality. Required latest-head CI/Codex and protected delivery remain separate gates.

### Agent execution foundation

[Autonomous workflow](../agents/autonomous-workflow.md) routes full issue delivery through `aqd-ship`, which orchestrates implementation, verification and review plus protected delivery stages. #20's published proof, current-head CI/Codex, protected merge and repository release passed. [Persisted issue plans](../plan/README.md) hold vertical slices, commit SHAs, checks and the next action. Local native checks use the owner's physical iPhone 17 Pro Max, discovered on iOS27.0.1/24A446 for #21; the owner confirmed readiness and its baseline Core/native unit checks passed. Local simulators remain shut down. Hosted native CI is removed; all E2E and broad personal-phone acceptance remain #30. Current deployment settings stay in place.

[Issue #20 execution record](../plan/issue-20.md) retains its delivery receipt; [issue #21](../plan/issue-21.md) retains its source-bound receipts. PR33 delivery is verified above; the #24/#23 plans own active implementation. Neither a repository release nor these unit checks establish complete V1 acceptance or native distribution.

## Earlier handoffs

[October 15 pre-cleanup status](archive/implementation-status-2026-10-15.md) retains all prior Foundation experiments, counts, pauses and baseline chronology. Read it only to investigate those receipts. [Verification](verification.md) retains the detailed observed results; the current implementation plan supersedes older per-feature runtime gates.
