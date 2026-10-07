# Engineering lifecycle

This is AQD's delivery procedure for any coding agent or human contributor. `AGENTS.md` routes here; skills provide methods, not a second project policy. Select the authorized stage below before loading its references. Read [development conventions](../delivery/workflow.md) only for authorized branch/commit/PR/release operations.

## Scope and authority

A request to implement a feature/fix authorizes its scoped ticket/spec, branch, implementation, commit, PR, review fixes, squash merge, and repository-release verification once the gates below pass. An explicit docs-only, draft, local-review, leave-open, or no-merge request narrows that scope. Preserve unrelated work and keep required checks and protection enabled. Native distribution and production data changes need their own authorized scope; a GitHub release is not an App Store deployment.

Ask only for missing product decisions, unavailable required access, or a step outside that scope. Read the issue, prior discussion, product decisions, and current code before asking. Continue independent work while blocked, and report the exact remaining gate.

## Task branches

- **Read-only review:** scope/authority above, affected contracts and current source; then stage 4. No ticket mutation or delivery operations implied.
- **Documentation/spec refinement:** stages 1–2 only as relevant to settled scope; validate links, anchors, preserved acceptance and evidence boundaries. Documentation completion is separate from implementation acceptance.
- **Implementation/fix:** stages 1–4; load the relevant plan slice and feature acceptance. Stages 5–8 apply only within authorized delivery scope.
- **PR/release:** stages 5–8 live in [delivery stages](delivery-stages.md); read them before those operations. Every gate remains mandatory.

Resolve named methods through the installed skill catalog. If a method is unavailable, disclose that and use the documented stage procedure as fallback; never claim an unavailable skill ran.

## 1. Understand and triage

For ticket operations read [tracker configuration](issue-tracker.md); for domain changes read [domain guidance](domain.md). Read the issue and all relevant comments when the task has an issue. Search for existing behavior, duplicates, and conflicting decisions. Reproduce reported bugs before designing a fix.

Use Matt Pocock's `triage` for ticket evaluation; use `grilling` and `domain-modeling` when a product decision is genuinely unsettled. Resolve the installed skill through the agent's skill catalog and read it before applying it. Follow the user's already confirmed decisions; skip an unnecessary interview for a clear task.

Complete when the problem, current behavior, expected outcome, category, dependencies, and triage state are recorded. Use `needs-info` for missing facts and `ready-for-human` for decisions/access an agent cannot supply. The confirmed label mapping lives in [triage labels](triage-labels.md).

## 2. Specify one deliverable

Use `to-spec` to synthesize settled decisions into a GitHub issue. Use `to-tickets` only when the change needs independently deliverable slices. Reference the relevant `docs/features/` acceptance IDs instead of copying full feature specs. Record user-visible behavior, boundaries, loading/empty/error states, migration/privacy impact, and verification seams. Architecture decisions with lasting consequences belong in an ADR.

Complete when each scoped acceptance criterion is checkable, the verification approach is known, dependencies are named, and unresolved choices cannot change the implementation. Mark the issue `ready-for-agent`. Skill-specific confirmations apply when actually using that skill; already settled seams need no repeated interview.

## 3. Implement and verify

For authorized branch work, fetch the integration branch and start or resume the ticket branch under the development conventions. For docs-only/local work, preserve the user's current branch and scope. Use `implement` with the spec and `tdd` for meaningful behavioral/domain changes at agreed seams. Inspect existing patterns first; complete one vertical slice and reuse components before extracting abstractions.

Run focused checks during changes, then the relevant full checks once. UI changes require rendered simulator evidence and navigation/accessibility review. Update implementation and verification docs when scope or evidence changes.

Complete implementation only when every required scoped acceptance item passes, failed writes/retries recover correctly, and existing data and unrelated behavior are preserved. A missing required check or behavior is a blocker unless the owner explicitly authorizes a scope reduction; a reason/dependency alone cannot waive acceptance. A successful build alone is not functional verification. A documentation task may complete after its documentation checks while naming unverified native/runtime requirements, without claiming implementation completion.

## 4. Review against standards and spec

Use `code-review` against the fixed merge-base of the integration branch and the originating issue/spec. Review both axes: documented standards and requested behavior. Follow the skill's separate review process; fix actionable findings, re-run affected checks, and record any justified exception. For uncommitted/new files, include those explicitly in review; an empty HEAD diff is not a review of working changes.

Complete when the review covers the actual final diff and all valid findings are addressed. If a required skill is unavailable, report it; use this documented procedure only as a clearly disclosed fallback, never claim the skill ran.

## 5. Open the PR

[Authorized PR stage](delivery-stages.md#5-open-the-pr).

## 6. Finish CI and automated review

[Latest-head CI/Codex and thread gates](delivery-stages.md#6-finish-ci-and-automated-review).

## 7. Squash merge

[Protected SHA-bound squash gate](delivery-stages.md#7-squash-merge).

## 8. Verify release and hand off

[Merged-SHA CI/release and distribution boundary](delivery-stages.md#8-verify-release-and-hand-off).
