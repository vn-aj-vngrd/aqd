# PR and release stages

Owner update, October16: feature delivery uses Core/native unit tests only. All E2E authoring/execution and integrated UI acceptance are deferred to #30, including feature-focused runs. Preserve existing tests and evidence for that ticket. No simulator is allowed locally or in hosted CI. The expensive native iOS CI workflow is removed; fast repository unit checks and existing protected delivery remain. Native unit checks use the connected, unlocked physical iPhone17ProMax. E2E/proof procedures below apply only to #30. Known product, data-loss and security defects still require fixes; deferred E2E is not a claim of full V1 acceptance.


Read only when PR delivery or release is authorized. [Lifecycle scope and authority](lifecycle.md#scope-and-authority) applies; explicit docs-only, draft, local-review, leave-open or no-merge instructions narrow scope. [Workflow](../delivery/workflow.md) owns conventions and release mechanics.

For a full issue run, [aqd-ship](../../.agents/skills/aqd-ship/SKILL.md) continues these stages without routine confirmation. Resume at the first unsatisfied gate after checking actual branch/PR state. The [shipping checkpoint convention](../pan/README.md#shipping-checkpoints) separates persisted local evidence from live GitHub results.

## 5. Open the PR

Commit with hooks enabled, push the named feature branch, and create a PR targeting `main`. Use the template and final combined change in its title. Link the ticket, show actual evidence, and attach the created PR to the agent's task when its environment supports that operation. Keep draft PRs draft when review is requested before completion.

Search for the issue's existing PR before creation. Reuse its feature branch and update the same PR through review fixes. If creation/push times out, read remote state before retrying so an unknown outcome does not create duplicate PRs or overwrite work. For a delivered feature include the actual issue-closing reference; state which runtime checks remain in #30.

For UI changes, [aqd-prove](../../.agents/skills/aqd-prove/SKILL.md) publishes the required [AC proof](acceptance-proof.md): actual selected E2E results, inspected screenshots/video and linked reports, with tested revision and device/OS. Open as draft while required evidence is being published, and read back its table/media/artifact access before marking ready. Keep a requested draft as draft. A draft can truthfully show pending proof; ready-to-merge delivery requires passing published proof.

Complete when the PR description matches the diff and a reader can understand the change, actions, evidence, risks, and remaining work without reading the chat.

## 6. Finish CI and automated review

Establish expected checks from live branch protection, applicable workflow triggers and the implementation plan. Wait for every required check and relevant scheduled PR workflow to succeed on the latest head. A workflow legitimately not scheduled by path filters is Not applicable, not a test pass. Missing required checks, no registered checks yet, and failed/cancelled jobs do not satisfy the gate. Preserve the approved feature-unit versus final-#30 execution policy; a required check cannot be disabled to create that deferral.

Inspect check logs, security results, conversation comments, submitted reviews, and all inline threads, including outdated unresolved threads. Fix valid findings, explain inapplicable findings with evidence, and resolve only addressed threads. Re-run affected local checks after each fix, push normally, and update the PR's verification table. A finding labelled pre-existing still needs a fix or an explicit authorized disposition before it can stop blocking delivery.

Codex automated review is required by the project owner even when another agent implements. Verify the AQD repository has access to the Codex GitHub review integration; unavailable setup/access is a blocker. Check for an automatic review on the current head before requesting `@codex review`. Record the requested head, request identity/time and completion evidence. A findings-free Codex thumbs-up or completed review is review evidence, not a CI result. Check reviewer identity and request/review timestamps/head association; a reaction must belong to the identified request for that unchanged head. A response acknowledging a queued review is not completion.

Request at most one successful review per distinct head; while it is pending, wait rather than posting duplicates. Any pushed change, including an evidence-only documentation commit, needs review evidence for the resulting head. Read back GitHub state after a failed/unknown request before retrying. New findings return to focused fixes and the same CI/review loop without another user prompt.

A quota error, unavailable integration, or no response is **unavailable**, not passed. Keep the PR open and report the blocker until required Codex review is available or the owner explicitly changes that requirement. Do not resolve findings just to clear a gate. Do not use admin merge, bypass flags, disabled hooks, or weakened checks.

Refresh affected acceptance proof after code/test/fixture/build/runtime fixes, update the same PR proof section, and qualify any unchanged-input reuse explicitly. Missing or inaccessible required UI proof blocks this gate independently of unit CI or Codex success.

Complete when latest-head checks pass, required automated review has completed, feature AC proof passes and is accessible in the PR, valid findings are fixed, and no blocking/unresolved review threads remain. For non-UI issues, apply the contract's appropriate evidence/Not-applicable branch.

### Wait and recovery

Wait within the active run while jobs/review make progress. Use bounded waits/polls with backoff up to 60 seconds, observe service retry guidance, and keep meaningful progress updates. Refresh head/base and gate evidence after each state change. Continue useful independent work while waiting; a pending service alone does not require another prompt.

Inspect failures before rerunning jobs. One targeted rerun can test an identified transient infrastructure failure; repeated reruns require new evidence. After three attempts with the same failure and no new diagnostic evidence, switch to focused diagnosis or fresh review rather than repeating the same mutation. Authentication/permission denial, exhausted review quota or an unavailable required integration produces an exact external blocker. A gate with no observable progress for 45 minutes produces a resumable service-wait checkpoint, never a pass. Preserve the last observed head, failure/request evidence, attempt history and next action; the same ship invocation refreshes state before continuing.

## 7. Squash merge

Immediately refresh PR head SHA, up-to-date base, checks, review evidence, threads, and mergeability. If the base advanced, merge the current base into the published branch, resolve conflicts, and repeat relevant validation/review. Preserve published history unless rewriting is explicitly authorized.

Verify the live protection and allowed merge method still match the required workflow. Snapshot the final head only after all gates agree; any head change invalidates that snapshot. With full ship authority, a successful gate proceeds directly to merge. A narrower leave-open endpoint stops before this operation.

The merge snapshot also verifies the PR's AC proof coverage, tested-input identity and artifact access. A current-feature UI failure cannot be waived by moving it into #30; only genuinely broader qualification remains deferred. User review of proof is available in the PR, while an additional human approval is required only when the current request explicitly selects that endpoint.

Squash is the only merge method. Use the validated PR title as squash subject and preserve ticket references and breaking-change footer in the body. Use `gh pr merge --squash --match-head-commit <verified-sha>` so a changed head cannot slip through. Respect an explicit leave-open/review-only instruction.

Complete when GitHub confirms the squash merge and records its resulting main SHA. Delete the feature branch only when no remaining work depends on it.

## 8. Verify release and hand off

Verify main CI and Release independently for the merged SHA. Confirm the new tag/GitHub release points to that SHA, or explain an observed newer-main run that included it. Check release notes and expected version bump. Never create a manual tag to conceal failed automation. Native builds/distribution are separate gates when included in the task.

Reuse and inspect the actual main/release workflow runs. Diagnose failures and retry the existing idempotent release path when supported by evidence and the workflow; a required source/config fix returns through a scoped branch/PR and its gates. Do not reopen or repeat a confirmed merge. If a newer-main release includes this change, verify ancestry and identify its actual SHA rather than claiming an exact tag match. Retain missing or failed release proof as the remaining delivery blocker.

Complete when the handoff links the issue/PR, identifies review and test results, merged SHA and release version, and states any unavailable device/service/distribution evidence. For an intentional draft or blocker, name exactly where delivery stopped. A future agent should resume from those recorded facts without repeating decisions.
