# Engineering lifecycle

This is AQD's delivery procedure for any coding agent or human contributor. `AGENTS.md` routes here; skills provide methods, not a second project policy. Read [development conventions](../DEVELOPMENT-WORKFLOW.md) for GitHub identity, branches, commits, and release mechanics.

## Scope and authority

A request to implement a feature/fix authorizes its scoped ticket/spec, branch, implementation, commit, PR, review fixes, squash merge, and repository-release verification once the gates below pass. An explicit docs-only, draft, local-review, leave-open, or no-merge request narrows that scope. Preserve unrelated work and keep required checks and protection enabled. Native distribution and production data changes need their own authorized scope; a GitHub release is not an App Store deployment.

Ask only for missing product decisions, unavailable required access, or a step outside that scope. Read the issue, prior discussion, product decisions, and current code before asking. Continue independent work while blocked, and report the exact remaining gate.

## 1. Understand and triage

Read [tracker configuration](issue-tracker.md), [domain guidance](domain.md), the issue and all relevant comments. Search for existing behavior, duplicates, and conflicting decisions. Reproduce reported bugs before designing a fix.

Use Matt Pocock's `triage` for ticket evaluation; use `grilling` and `domain-modeling` when a product decision is genuinely unsettled. Resolve the installed skill through the agent's skill catalog and read it before applying it. Follow the user's already confirmed decisions; skip an unnecessary interview for a clear task.

Complete when the problem, current behavior, expected outcome, category, dependencies, and triage state are recorded. Use `needs-info` for missing facts and `ready-for-human` for decisions/access an agent cannot supply. The confirmed label mapping lives in [triage labels](triage-labels.md).

## 2. Specify one deliverable

Use `to-spec` to synthesize settled decisions into a GitHub issue. Use `to-tickets` only when the change needs independently deliverable slices. Reference the relevant `docs/features/` acceptance IDs instead of copying full feature specs. Record user-visible behavior, boundaries, loading/empty/error states, migration/privacy impact, and verification seams. Architecture decisions with lasting consequences belong in an ADR.

Complete when each scoped acceptance criterion is checkable, the verification approach is known, dependencies are named, and unresolved choices cannot change the implementation. Mark the issue `ready-for-agent`. Skill-specific confirmations apply when actually using that skill; already settled seams need no repeated interview.

## 3. Implement and verify

Fetch the integration branch and start or resume the ticket branch under the development conventions. Use `implement` with the spec and `tdd` for meaningful behavioral/domain changes at agreed seams. Inspect existing patterns first; complete one vertical slice and reuse components before extracting abstractions.

Run focused checks during changes, then the relevant full checks once. UI changes require rendered simulator evidence and navigation/accessibility review. Update implementation and verification docs when scope or evidence changes.

Complete when every scoped acceptance item is verified or explicitly deferred with a reason/dependency, failed writes/retries recover correctly, and existing data and unrelated behavior are preserved. A successful build alone is not functional verification.

## 4. Review against standards and spec

Use `code-review` against the fixed merge-base of the integration branch and the originating issue/spec. Review both axes: documented standards and requested behavior. Follow the skill's separate review process; fix actionable findings, re-run affected checks, and record any justified exception. For uncommitted/new files, include those explicitly in review; an empty HEAD diff is not a review of working changes.

Complete when the review covers the actual final diff and all valid findings are addressed. If a required skill is unavailable, report it; use this documented procedure only as a clearly disclosed fallback, never claim the skill ran.

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
