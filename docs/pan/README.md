# Persisted issue plans

Store implementation plans here. The `pan` directory name is the owner's chosen convention.

## Naming and ownership

Use exactly **`docs/pan/issue-<GitHub-number>.md`**, for example `docs/pan/issue-21.md`. The filename, heading, issue link and branch must identify the same real issue. Keep one plan per issue across sessions and review fixes. The issue and feature contracts own requirements; this file owns execution progress and evidence pointers.

Before the first product-code edit, read the issue/comments and copy [TEMPLATE.md](TEMPLATE.md) into that path. If the plan exists, resume it. Resolve the issue number before creating a numbered plan; never infer it from the current branch or reuse another issue's plan. Unticketed setup work can remain local until assigned a real issue, then adopts this convention before product implementation.

## Plan vertical slices

Each slice delivers a user-visible journey or a necessary executable foundation. Include the UI, domain behavior, persistence/media, recovery and focused tests that journey needs. A file list, all-models pass, all-screens pass, or tests-at-the-end pass is not a vertical slice.

Map every scoped acceptance ID to a slice and a check. Separate checks required for feature delivery from runtime/device acceptance deferred by the [implementation plan](../delivery/implementation-plan.md#verification-policy--owner-approved-october15). Include cross-section support needed to avoid dead actions. Keep existing product scope; use implementation judgment without reopening settled planning.

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
