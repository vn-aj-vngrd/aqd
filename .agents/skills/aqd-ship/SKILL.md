---
name: aqd-ship
description: Ship an AQD GitHub issue through slice implementation, PR, CI and Codex fixes, protected squash merge and release verification. Use for end-to-end issue delivery or resuming an interrupted shipping run. Workflow-authoring requests stay documentation-only.
---


Owner update, October16: feature delivery uses Core/native unit tests only. All E2E authoring/execution and integrated UI acceptance are deferred to #30, including feature-focused runs. Preserve existing tests and evidence for that ticket. No simulator is allowed locally or in hosted CI. The expensive native iOS CI workflow is removed; fast repository unit checks and existing protected delivery remain. Native unit checks use the connected, unlocked physical iPhone17ProMax. E2E/proof procedures below apply only to #30. Known product, data-loss and security defects still require fixes; deferred E2E is not a claim of full V1 acceptance.

# Ship one AQD issue

`aqd-ship 20` selects GitHub issue #20. `$aqd-ship 20` is the explicit skill form. Execute only when the user requests actual issue delivery; a request to refine this workflow changes documentation only.

Read [lifecycle authority](../../../docs/agents/lifecycle.md) and [delivery stages](../../../docs/agents/delivery-stages.md). This skill orchestrates their existing methods and gates. The current request determines the endpoint; a ship invocation authorizes the full issue lifecycle, while an explicit draft, leave-open or local-review instruction narrows it. Current authorization can supersede a prior local-only checkpoint. Native distribution and the next backlog issue retain their separate scope.

| Requested endpoint | Finish after |
| --- | --- |
| Full ship, the default | Confirmed squash merge and repository release verification |
| Leave the PR open | Successful current-head CI/Codex and resolved findings, before merge |
| Draft PR | Opening/updating the requested draft with local evidence |
| Local review | Verified, reviewed slice commits and a local handoff |

## 1. Resolve and resume

Resolve a positive issue number or canonical AQD issue URL through the [tracker](../../../docs/agents/issue-tracker.md). Read the issue/comments, `docs/pan/issue-<number>.md`, current status and the relevant implementation-plan dependency row. Confirm repository, GitHub identity/access, branch ownership, dirty files and existing PRs before mutations. Derive branch conventions from the [workflow](../../../docs/delivery/workflow.md).

Reconcile the persisted plan with actual source, commits and live GitHub state. Reuse the issue branch and PR; an already merged PR resumes at release verification. A closed unmerged PR or conflicting issue/branch identity requires resolution, not an automatic duplicate. Preserve approved existing slice commits and unrelated work. An unfinished predecessor blocks dependent implementation.

Complete when the real issue, authorized endpoint, branch/PR, dependency status and first unsatisfied phase are known. Resume there; settled specs and satisfied phases need no repeated interview or implementation.

## 2. Complete the local gate

If implementation, checks or local review are incomplete, dispatch [aqd-implement](../aqd-implement/SKILL.md). It owns the persisted plan, vertical-slice commits, [verification](../aqd-verify/SKILL.md) and [Standards/Spec review](../aqd-review/SKILL.md). Under this orchestrator it returns at the local gate; this skill owns remote delivery.

For UI changes, use [aqd-prove](../aqd-prove/SKILL.md) to qualify every scoped UI AC with focused native E2E and inspected screenshots/video. A generated test file or green unit suite is not acceptance proof. Keep locally qualified artifacts ready for publication when the PR exists.

Reuse prior local results only when their recorded inputs are unchanged. Evidence-only documentation commits receive bounded documentation checks/review. Required remote checks and Codex review still bind to the actual final PR head.

Complete when every scoped feature behavior is implemented, required local checks/focused UI proof/review pass, owned changes are committed with slice receipts, and the relevant diff matches the originating issue. Stop here for a local-review endpoint. Broader full-suite/device qualification stays in #30 under the [verification policy](../../../docs/delivery/implementation-plan.md#verification-policy--owner-approved-october15); the current feature's AC proof cannot be deferred there. For #30 itself, its integrated/device hardening checks are required. Missing required behavior or data-loss/security defects stay blocking.

## 3. Publish or reuse the PR

Run [delivery stage 5](../../../docs/agents/delivery-stages.md#5-open-the-pr). Push normally, reuse or create the single issue PR against `main`, and keep its body current using the repository template. Attach the PR to the active task when supported. Preserve slice commits for review before the final squash.

Persist the repository/branch locator and stable local evidence in the issue plan before the final gate head is selected. Record the resolved PR URL in the task/handoff and include it in the next necessary plan update. Follow the [shipping checkpoint convention](../../../docs/pan/README.md#shipping-checkpoints) to avoid extra CI cycles solely for a new URL or polling results.

Have `aqd-prove` publish and read back the PR's AC table, inline visual evidence and linked results under the [acceptance-proof contract](../../../docs/agents/acceptance-proof.md). A UI PR awaiting publication remains draft/not ready. A requested draft may show truthful pending proof; full or leave-open delivery requires all feature proof before readiness.

Complete when the remote PR head equals the intended committed branch head, the PR describes the actual diff and deferred #30 checks, and the PR URL is recorded. Stop here for a draft-PR endpoint; leave-open delivery continues through the review loop.

## 4. Run the CI and review loop

Run [delivery stage 6](../../../docs/agents/delivery-stages.md#6-finish-ci-and-automated-review), including its retry/wait rules. Inspect CI logs, security results, conversation comments, submitted reviews and every inline thread. Fix valid findings in focused commits, run affected local checks, push normally, and refresh the PR body. Explain inapplicable findings with source evidence; resolve only addressed threads.

After every push, refresh the head and obtain current-head CI and Codex evidence. Continue the loop without another user prompt. A pending check/review is a wait state, not a final handoff. External access/quota failures and the documented no-progress bound produce an exact resumable blocker.

Complete only when all expected CI gates are successful on the same current head, required Codex review is complete for that head, current AC proof is passed and accessible in the PR, and no unresolved actionable finding or blocking thread remains. After fixes refresh affected proof as well as CI/review. An empty checks list, an older review or an unanswered review request cannot satisfy this phase. Stop here for a leave-open endpoint.

## 5. Merge and verify the repository release

Run [delivery stage 7](../../../docs/agents/delivery-stages.md#7-squash-merge). Refresh head, base, checks, review and threads immediately before the SHA-bound squash operation. Any changed head or incorporated base returns to the appropriate check/review phase. Full ship scope proceeds to merge without a separate routine confirmation.

Then run [delivery stage 8](../../../docs/agents/delivery-stages.md#8-verify-release-and-hand-off) for the actual merged SHA. A post-merge failure resumes at release verification; it never recreates the implementation PR or repeats a completed merge.

Complete when merge is confirmed, main CI and repository release publication are verified, and the issue is closed consistently with its delivered feature scope. If automatic closure did not occur, verify the issue and close it only after its required scope is delivered. Deferred #30 checks stay open there.

## 6. Finish or checkpoint

Continue inside the active run through every authorized phase. Keep useful progress updates while waiting. On interruption or a genuine blocker, persist the exact next action, last confirmed revision/remote locator and missing access/decision under the [checkpoint convention](../../../docs/pan/README.md#shipping-checkpoints). The same invocation resumes by inspecting actual state.

The final handoff gives the issue/PR, reviewable slice SHAs, observed tests/review, merged SHA and release tag/link, plus any remaining #30/device limits. Keep completed shipping facts in GitHub and the handoff; a new post-merge PR solely to record its own merge SHA is unnecessary. This is an active-session workflow; resuming after the session ends uses the same issue invocation.
