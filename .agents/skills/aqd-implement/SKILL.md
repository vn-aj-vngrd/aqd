---
name: aqd-implement
description: Implement or resume an approved AQD feature, issue, or fix in tested and committed vertical slices. Use when selecting the next authorized issue from the existing implementation plan.
---

# Implement an AQD issue

Read repository `AGENTS.md` and [lifecycle](../../../docs/agents/lifecycle.md) to establish authority. [Autonomous workflow](../../../docs/agents/autonomous-workflow.md) supplies the target-device and escalation rules.

## 1. Select and persist

Read the real issue/comments, [implementation plan](../../../docs/delivery/implementation-plan.md) dependency row, current status summary and affected contracts. Inspect the current implementation and `git status`; identify dirty-file ownership. For native work, load `apps/ios/AGENTS.md`. Read only affected feature/design branches.

Create or resume `docs/pan/issue-<number>.md` under the [plan convention](../../../docs/pan/README.md). Record the issue, authorized endpoint, predecessor, baseline, scoped acceptance IDs and smallest complete vertical slices. Keep settled requirements; resolve routine implementation choices without another interview. Resolve a missing real issue number before creating a numbered plan or starting product code.

Complete when every scoped acceptance item has an owning slice and a verification method, dependencies permit work, and the plan is persisted before product edits.

## 2. Implement one slice

Choose the next ready slice. Inspect its callers and tests. Implement its UI, rules, save/read paths and recovery together where needed. Reuse native foundation components and existing store/media seams. A code-foundation slice must itself be executable and required by the issue.

Use installed `tdd` for meaningful behavior changes when available; otherwise establish a failing behavior test at the affected public seam and make it pass. Cosmetic/doc edits use appropriate existing checks. Preserve drafts, stable IDs and acknowledged outcomes. Keep unrelated cleanup outside the slice.

Complete when the slice implements its entire stated outcome, including affected failure/cancel states, and its focused checks pass. A scaffold with dead actions is incomplete.

## 3. Verify and commit

Use [aqd-verify](../aqd-verify/SKILL.md) for required checks and [aqd-review](../aqd-review/SKILL.md) on the actual increment, including new files. Fix valid findings before committing.

Update the plan with actual checks and state. Commit only owned slice code/tests/docs, following the plan convention's scoped subject, issue reference and `AQD-Slice` trailer. Immediately record the resulting SHA. Preserve reviewable slice history.

Complete when the slice has a passing required-check record and an actual commit. A progress update or one final commit for all planned slices does not satisfy this step. An explicit no-commit instruction instead leaves a named local checkpoint and narrows this criterion.

## 4. Continue and close out

Repeat steps 2–3 for every remaining authorized slice without waiting for another prompt. Retain failure reproductions and test one hypothesis at a time while diagnosing. Installed `diagnosing-bugs` is useful for an unresolved mechanism. Continue independent work when a slice needs external access.

After the slices, use [aqd-review](../aqd-review/SKILL.md) on the full issue diff and [aqd-verify](../aqd-verify/SKILL.md) for relevant final checks. Commit focused corrections tied to their slice. Persist the last code SHA and evidence in the plan's documentation receipt commit; update status/verification and affected control/root ledgers as needed.

For authorized PR/merge/release, follow [delivery stages](../../../docs/agents/delivery-stages.md). Local-review/leave-open instructions determine the stopping point. Finishing this issue alone does not authorize the next issue.

Complete when every required feature acceptance item is accounted for, required checks/review pass and the authorized endpoint is reached. Deferred #30 runtime checks stay unverified. Handoff includes the plan, slice SHAs, actual results, runnable/review location and exact remaining access/device actions. If blocked, persist the next exact action and describe the observed blocker without claiming completion.
