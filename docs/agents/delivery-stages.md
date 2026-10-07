# PR and release stages

Read only when PR delivery or release is authorized. [Lifecycle scope and authority](lifecycle.md#scope-and-authority) applies; explicit docs-only, draft, local-review, leave-open or no-merge instructions narrow scope. [Workflow](../delivery/workflow.md) owns conventions and release mechanics.

## 5. Open the PR

Commit with hooks enabled, push the named feature branch, and create a PR targeting `main`. Use the template and final combined change in its title. Link the ticket, show actual evidence, and attach the created PR to the agent's task when its environment supports that operation. Keep draft PRs draft when review is requested before completion.

Complete when the PR description matches the diff and a reader can understand the change, actions, evidence, risks, and remaining work without reading the chat.

## 6. Finish CI and automated review

Wait for every required check on the latest PR head. Inspect check logs, security results, conversation comments, submitted reviews, and all inline threads, including outdated unresolved threads. Fix valid findings, explain inapplicable findings with evidence, and resolve only addressed threads. Re-run affected checks after each fix; update the PR's verification table.

Codex automated review is required by the project owner even when another agent implements. Enable the AQD repository in the Codex GitHub review integration, request `@codex review` when necessary, and wait for completion against the latest changed head. A findings-free Codex thumbs-up or completed review is review evidence, not a CI result. Check reviewer identity and request/review timestamps/head association. After changes, request a fresh review rather than reusing an old response.

A quota error, unavailable integration, or no response is **unavailable**, not passed. Keep the PR open and report the blocker until required Codex review is available or the owner explicitly changes that requirement. Do not resolve findings just to clear a gate. Do not use admin merge, bypass flags, disabled hooks, or weakened checks.

Complete when latest-head checks pass, required automated review has completed, valid findings are fixed, and no blocking/unresolved review threads remain.

## 7. Squash merge

Immediately refresh PR head SHA, up-to-date base, checks, review evidence, threads, and mergeability. If the base advanced, merge the current base into the published branch, resolve conflicts, and repeat relevant validation/review. Preserve published history unless rewriting is explicitly authorized.

Squash is the only merge method. Use the validated PR title as squash subject and preserve ticket references and breaking-change footer in the body. Use `gh pr merge --squash --match-head-commit <verified-sha>` so a changed head cannot slip through. Respect an explicit leave-open/review-only instruction.

Complete when GitHub confirms the squash merge and records its resulting main SHA. Delete the feature branch only when no remaining work depends on it.

## 8. Verify release and hand off

Verify main CI and Release independently for the merged SHA. Confirm the new tag/GitHub release points to that SHA, or explain an observed newer-main run that included it. Check release notes and expected version bump. Never create a manual tag to conceal failed automation. Native builds/distribution are separate gates when included in the task.

Complete when the handoff links the issue/PR, identifies review and test results, merged SHA and release version, and states any unavailable device/service/distribution evidence. For an intentional draft or blocker, name exactly where delivery stopped. A future agent should resume from those recorded facts without repeating decisions.
