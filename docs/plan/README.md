# Persisted issue plans

Store implementation plans in `docs/plan`, with one persisted file per GitHub issue. Approved grouped PRs cross-link their issue plans; each issue retains its ACs, slice markers and progress. Historical captured command output may retain the former `docs/pan` path as evidence of its original execution.

## Naming and ownership

Use exactly **`docs/plan/issue-<GitHub-number>.md`**, for example `docs/plan/issue-21.md`. The filename, heading, issue link and branch must identify the same real issue. Keep one plan per issue across sessions and review fixes. The issue and feature contracts own requirements; this file owns execution progress and evidence pointers.

Before the first product-code edit, read the issue/comments and copy [TEMPLATE.md](TEMPLATE.md) into that path. If the plan exists, resume it. Resolve the issue number before creating a numbered plan; never infer it from the current branch or reuse another issue's plan. Unticketed setup work can remain local until assigned a real issue, then adopts this convention before product implementation.

## Plan vertical slices

Each slice delivers a user-visible journey or a necessary executable foundation. Include the UI, domain behavior, persistence/media, recovery and focused tests that journey needs. A file list, all-models pass, all-screens pass, or tests-at-the-end pass is not a vertical slice.

Map every scoped acceptance ID to a slice and a check. For UI outcomes, also record the focused E2E identifier, required rendered evidence and PR proof link under [acceptance proof](../agents/acceptance-proof.md). Separate checks required for feature delivery from runtime/device acceptance deferred by the [implementation plan](../delivery/implementation-plan.md#verification-policy--owner-approved-october15). Include cross-section support needed to avoid dead actions. Keep existing product scope; use implementation judgment without reopening settled planning.

## Commit each slice

1. Implement the next ready slice and run its focused checks. Inspect the actual diff, including new files, against that slice's acceptance.
2. Fix its failures, then commit its code, tests and updated plan together. Use the [repository's Conventional Commit format](../delivery/workflow.md#branch-and-commit) with a concrete behavior, for example `feat(onboarding): Persist private entry progress`.
3. Include `Refs #21` and a unique `AQD-Slice: #21/S1` trailer in the commit body, substituting the real issue and slice. Stage explicit owned paths/hunks; preserve other work.
4. Record the resulting SHA in the plan immediately after the commit. Persist that receipt in the next slice commit. After the final code slice, use one documentation receipt commit to persist the last SHA, final review and remaining checks. A plan cannot contain the hash of its own commit.
5. Continue with the next ready slice without waiting for another prompt. Keep slice commits visible on the feature branch. Review fixes receive focused fix commits linked to their slice; protected final squash remains the repository's merge method.

Use `git log --format='%h %s%n%b' --grep='AQD-Slice: #21/'` to resolve slice commits. In the handoff, list actual SHAs in slice order. The final squash commit and PR retain the issue link; the PR commit history is the owner's review path before merge. An explicit local-review/leave-open request preserves that checkpoint.

## Resume and finish

At every slice boundary, update status, actual checks, commit marker/SHA and the next action. Use Planned, In progress, Committed, or Blocked for work; use Passed, Failed, Not run, or Deferred to #30 for checks. A blocked check includes its exact cause and next required action. Deferred never means passed.

On resume, compare the plan with the current branch, `git status`, commit log and source changes. Previous results apply only to their recorded revision. Repeat checks only when changed inputs or unresolved failures justify it. Every scoped acceptance item must be implemented and accounted for before feature completion; unexecuted final runtime acceptance remains in #30.

Store selected native UI identifiers in `apps/ios/acceptance/issue-<number>.txt`. `./scripts/prove-ios.sh <number>` retains actual execution inputs, reports and attachments. Curated durable images/reports may live at `docs/plan/evidence/issue-<number>/`, with provenance and the AC mapping linked from the plan.

## Shipping checkpoints

[`aqd-ship`](../../.agents/skills/aqd-ship/SKILL.md) uses this same issue plan. Persist the authorized endpoint, repository/branch locator, slice receipts, local evidence and any already-known PR URL; a separate run/spec/state-file hierarchy is unnecessary. Update local progress at slice boundaries and before handoffs. On an access failure or interruption, persist the exact unsatisfied phase and next action without changing failed/pending gates into passes.

GitHub owns live CI, Codex, thread, merge and release state. After publishing, resume by querying the linked PR or resolving it through the persisted repository/branch and issue, then read its actual head. Record a newly created PR URL in the task attachment and handoff immediately; include it in the plan's next substantive fix or necessary receipt. An extra commit solely to add a newly assigned PR URL is unnecessary. Batch later plan corrections with substantive fixes. Polling results alone do not require new commits, new pushes or another Codex cycle.

Before any push, include intended plan changes and treat that resulting commit as the new remote gate head. A documentation receipt also changes the head and needs fresh remote gates. Record final CI/review/merge/release evidence through GitHub links and the final handoff; keep the committed plan's resume action pointed at those live records. This avoids a post-merge documentation PR solely to describe its own merge. If a blocker adds local-only checkpoint changes after the last push, report those dirty paths explicitly and reconcile them before the next push.
