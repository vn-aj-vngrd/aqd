# Engineering lifecycle

This is AQD's delivery procedure for any coding agent or human contributor. `AGENTS.md` routes here; skills provide methods, not a second project policy. Select the authorized stage below before loading its references. Read [development conventions](../delivery/workflow.md) only for authorized branch/commit/PR/release operations.

## Scope and authority

A request to implement a feature/fix authorizes its scoped ticket/spec, branch, implementation, commit, PR, review fixes, squash merge, and repository-release verification once the gates below pass. An explicit docs-only, draft, local-review, leave-open, or no-merge request narrows that scope. Preserve unrelated work and keep required checks and protection enabled. Native distribution and production data changes need their own authorized scope; a GitHub release is not an App Store deployment.

Ask only for missing product decisions, unavailable required access, or a step outside that scope. Read the issue, prior discussion, product decisions, and current code before asking. Continue independent work while blocked, and report the exact remaining gate.

An actual `aqd-ship <issue-number>` request selects the [shipping orchestrator](../../.agents/skills/aqd-ship/SKILL.md) and full issue lifecycle without routine phase confirmations. A request to design/refine that workflow remains documentation-only. A newer delivery instruction can supersede an earlier local-only checkpoint; explicit current scope limits still govern.

## Task branches

- **Read-only review:** scope/authority above, affected contracts and current source; then stage 4. No ticket mutation or delivery operations implied.
- **Documentation/spec refinement:** stages 1–2 only as relevant to settled scope; validate links, anchors, preserved acceptance and evidence boundaries. Documentation completion is separate from implementation acceptance.
- **Implementation/fix:** stages 1–4; load the relevant plan slice and feature acceptance. Stages 5–8 apply only within authorized delivery scope.
- **PR/release:** stages 5–8 live in [delivery stages](delivery-stages.md); read them before those operations. Every gate remains mandatory.

Use the repo-local [aqd-implement](../../.agents/skills/aqd-implement/SKILL.md), [aqd-verify](../../.agents/skills/aqd-verify/SKILL.md) and [aqd-review](../../.agents/skills/aqd-review/SKILL.md) entry points for approved implementation. Read their files directly if the host has not refreshed discovery. Global methods supplement these workflows when installed; disclose unavailable methods rather than claiming they ran.

## 1. Understand and triage

For ticket operations read [tracker configuration](issue-tracker.md); for domain changes read [domain guidance](domain.md). Read the issue and all relevant comments when the task has an issue. Search for existing behavior, duplicates, and conflicting decisions. Reproduce reported bugs before designing a fix.

Existing approved issues/specs enter implementation without another planning interview. Use Matt Pocock's `triage` for genuinely new ticket evaluation; use `domain-modeling` when terminology changes. Resolve the installed skill through the agent's skill catalog and read it before applying it. Follow the user's already confirmed decisions; skip an unnecessary interview for a clear task.

Complete when the problem, current behavior, expected outcome, category, dependencies, and triage state are recorded. Use `needs-info` for missing facts and `ready-for-human` for decisions/access an agent cannot supply. The confirmed label mapping lives in [triage labels](triage-labels.md).

## 2. Specify one deliverable

Use `to-spec` to synthesize settled decisions into a GitHub issue. Use `to-tickets` only when the change needs independently deliverable slices. Reference the relevant `docs/features/` acceptance IDs instead of copying full feature specs. Record user-visible behavior, boundaries, loading/empty/error states, migration/privacy impact, and verification seams. Architecture decisions with lasting consequences belong in an ADR.

Complete when each scoped acceptance criterion is checkable, the verification approach is known, dependencies are named, and unresolved choices cannot change the implementation. Mark the issue `ready-for-agent`. Skill-specific confirmations apply when actually using that skill; already settled seams need no repeated interview.

## 3. Implement and verify

For authorized branch work, fetch the integration branch and start or resume the ticket branch under the development conventions. For docs-only/local work, preserve the user's current branch and scope. Use [aqd-implement](../../.agents/skills/aqd-implement/SKILL.md). Persist `docs/plan/issue-<number>.md` before product edits, map acceptance to vertical slices, then implement, verify and commit each slice before continuing. The [plan convention](../plan/README.md) owns naming, slice markers and SHA receipts. Reuse existing components and focused test seams.

Run focused checks during slices, then relevant feature unit/build/repository checks at final source. UI ACs also require focused app-driven E2E, inspected rendered evidence and publication through [aqd-prove](../../.agents/skills/aqd-prove/SKILL.md). The [implementation plan verification policy](../delivery/implementation-plan.md#verification-policy--owner-approved-october15) retains the broad full-suite/device matrix in #30; it does not defer proof of the current feature. Update the issue plan and capability/evidence documents as they change.

Complete feature implementation when scoped behavior is implemented, required feature checks pass, failed writes/retries recover correctly, and existing data and unrelated behavior are preserved. Record genuinely broader final qualification in #30 without marking it passed. Missing/failed/unpublished proof of a current UI AC, missing behavior, required checks and data-loss/security defects remain blockers. A successful build alone is not functional verification. A documentation task may complete after its documentation checks while naming unverified native/runtime requirements, without claiming implementation completion.

## 4. Review against standards and spec

Use [aqd-review](../../.agents/skills/aqd-review/SKILL.md) against the fixed merge-base of the integration branch and the originating issue/spec. Review both axes: documented standards and requested behavior. Follow the skill's separate review process; fix actionable findings, re-run affected checks, and record any justified exception. For uncommitted/new files, include those explicitly in review; an empty HEAD diff is not a review of working changes.

Complete when the review covers the actual final diff and all valid findings are addressed. If a required skill is unavailable, report it; use this documented procedure only as a clearly disclosed fallback, never claim the skill ran.

## 5. Open the PR

[Authorized PR stage](delivery-stages.md#5-open-the-pr).

## 6. Finish CI and automated review

[Latest-head CI/Codex and thread gates](delivery-stages.md#6-finish-ci-and-automated-review).

## 7. Squash merge

[Protected SHA-bound squash gate](delivery-stages.md#7-squash-merge).

## 8. Verify release and hand off

[Merged-SHA CI/release and distribution boundary](delivery-stages.md#8-verify-release-and-hand-off).
