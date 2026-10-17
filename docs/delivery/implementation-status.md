# Implementation status

## Current handoff, October 16, 2026

Foundation #20 shipped in [PR #31](https://github.com/vn-aj-vngrd/aqd/pull/31), squash `8b06880`, repository release v1.1.1. [Issue #21](../plan/issue-21.md) shipped in [PR #33](https://github.com/vn-aj-vngrd/aqd/pull/33), squash `f89a2de`, with green final-head unit CI/Codex, resolved findings, successful merged-main CI/Release and published v1.2.0 pointing to that SHA. Section01 source is delivered; historical physical evidence remains scoped and all final E2E acceptance stays #30.

[#24/#23](../plan/issue-24.md) shipped together in [PR34](https://github.com/vn-aj-vngrd/aqd/pull/34), squash `e71e1de`, with successful current-head unit CI/completed Codex review, resolved threads, merged-main CI/Release and published v1.3.0 pointing exactly to that SHA. Source-bound unit evidence retains its limits; all runtime/E2E acceptance stays #30.

[#25/#26](../plan/issue-25.md) shipped in [PR35](https://github.com/vn-aj-vngrd/aqd/pull/35), squash `51c87f3`, with successful current-head unit CI/Codex, resolved findings, merged-main CI/Release and published v1.4.0 exactly at that SHA. E2E remains #30.

[#28/#22](../plan/issue-28.md) shipped together in [PR36](https://github.com/vn-aj-vngrd/aqd/pull/36), squash `1a5b44e`, repository release [v1.5.0](https://github.com/vn-aj-vngrd/aqd/releases/tag/v1.5.0). Source-bound unit evidence and all runtime/E2E deferrals remain in their plans.

Active group: [#27](../plan/issue-27.md) + [#29](../plan/issue-29.md), branch `van/issue-27/agent-and-local-controls`, baseline PR36. Private conversations/context/reviewed actions and Settings/all-domain export/restore/erase are implemented in committed vertical slices. Final Core73/native213, unsigned Release and independent Standards/Spec rechecks pass. PR37 reviewed recovery and Agent-context corrections are committed; final Core73/native213 and both independent rechecks pass. Current-head CI/Codex/protected delivery remains. Model, voice, image-assistance and numerical Weather activation remain gated pending issue30 qualification. All simulators stay shut down; unit-only CI and all E2E in issue30 remain unchanged.

The [approved sequence](implementation-plan.md#approved-pr-groups--october16) remains #25+#26, #28+#22, #27+#29, then consolidated #30. No additional planning approval is needed.

Feature delivery uses affected Core/native unit checks and fast repository/tooling unit CI. Expensive hosted native CI is removed; all E2E authoring/execution and integrated UI acceptance are deferred to #30. Native checks use the owner's connected, unlocked physical iPhone17ProMax only; no simulator locally or in CI. Existing execution results remain historical/source-bound; canceled hosted runs are not passes. Known product/data-loss/security defects remain blocking, and unit passes do not certify integrated UI acceptance.

### Foundation capability and known gaps

Shared native actions, fields, feedback, selection and source-aware task navigation serve the existing capture/photo/details/save/reopen journey. The committed checkpoint adds semantic Back/Close behavior, exposed native metadata, task-owned focus/scroll handling, idempotent tab selection and bootstrap revalidation. [Foundation inventory](../../apps/ios/FOUNDATIONS.md) owns reuse; [verification](verification.md) owns exact execution history.

Current iPhone 17 Pro Max/iOS27 focused Notes proof passes after anchoring the focused editor bottom. Actual short-text and seventh-line OCR, inspected caret/keyboard screenshots and Apply/cancel/discard/relaunch assertions pass. Older runtime/full-matrix failures remain in #30; this scoped result does not certify every device or editing scenario. Existing scoped simulator passes do not establish complete native accessibility, physical media/protection/backup, performance or on-device model quality. Required latest-head CI/Codex and protected delivery remain separate gates.

### Agent execution foundation

[Autonomous workflow](../agents/autonomous-workflow.md) routes full issue delivery through `aqd-ship`, which orchestrates implementation, verification and review plus protected delivery stages. #20's published proof, current-head CI/Codex, protected merge and repository release passed. [Persisted issue plans](../plan/README.md) hold vertical slices, commit SHAs, checks and the next action. Local native checks use the owner's physical iPhone 17 Pro Max, discovered on iOS27.0.1/24A446 for #21; the owner confirmed readiness and its baseline Core/native unit checks passed. Local simulators remain shut down. Hosted native CI is removed; all E2E and broad personal-phone acceptance remain #30. Current deployment settings stay in place.

[Issue #20 execution record](../plan/issue-20.md) retains its delivery receipt; [issue #21](../plan/issue-21.md) retains its source-bound receipts. PR33 delivery is verified above; the #27/#29 plans own active implementation. Neither a repository release nor these unit checks establish complete V1 acceptance or native distribution.

## Earlier handoffs

[October 15 pre-cleanup status](archive/implementation-status-2026-10-15.md) retains all prior Foundation experiments, counts, pauses and baseline chronology. Read it only to investigate those receipts. [Verification](verification.md) retains the detailed observed results; the current implementation plan supersedes older per-feature runtime gates.

October17 owner Agent refinement: automatic relevant local grounding, AI source settings, local response ratings/reports, Feedback management/export, deterministic synthetic evaluations, native DEBUG live-evaluation runner, conversation-list/Markdown preview improvements and reviewed Camera/Photos/Files references are implemented locally. The text Agent has runtime model availability gates; iOS27 image summaries are separately availability-gated with labelled OCR fallback. This supersedes the older disabled-text statement above. Core/build evidence remains separate from model/image correctness and rendered acceptance; no server reporting, cloud model or automatic wardrobe mutation is added. See [issue27 plan](../plan/issue-27.md) and [evaluation procedure](../design/agent-evaluations.md).

Owner local Agent tools October17: automatic chats now register native lookup and typed reviewed mutations for existing piece metadata/availability, outfits/themes, basic Planner assignments, actual wear and Profile name/bio. New-piece capture, routine/trip structural editing, destructive changes and consent remain existing manual flows. Explicit review/Apply, source permissions, stale validation, idempotent saves and receipts remain required. Core107 pass and native test compilation are source-level evidence; live tool-selection/response quality and visual acceptance remain unverified.
