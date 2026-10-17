---
name: aqd-ship
description: Ship an AQD GitHub issue from implementation through PR, CI and Codex fixes, squash merge and release verification, or resume an interrupted run. Use for end-to-end delivery of an issue.
---

# Ship an AQD issue

`aqd-ship 27` delivers issue #27. Run only when the user asks for actual delivery. The endpoint follows the request:

| Endpoint | Stop after |
| --- | --- |
| Full ship (default) | Merge and release verified |
| Leave PR open | Current-head CI and Codex pass, findings resolved |
| Draft PR | PR opened or updated |
| Local review | Slices verified and reviewed locally |

Conventions, protections and release mechanics are in [delivery](../../../docs/delivery.md).

## 1. Resolve and resume

Read the issue and comments, confirm the repository, GitHub account, branch, dirty files and any existing PR. Reuse the issue branch and PR; an already merged PR resumes at release verification. Resume at the first unsatisfied phase.

## 2. Local gate

If work, checks or review are incomplete, run [aqd-implement](../aqd-implement/SKILL.md). Done when behavior is implemented, [verified](../aqd-verify/SKILL.md), [reviewed](../aqd-review/SKILL.md) and committed per slice, and the diff matches the issue.

## 3. PR

Push normally, reuse or create the one PR to `main` with the template, a conventional title and `Closes #<n>`. Done when the remote head equals the local head and the body describes the real diff and checks.

## 4. CI and review loop

Wait for every required check and the Codex review on the **current head**, with bounded polling. Inspect failures before rerunning. Fix valid findings in focused commits, explain inapplicable ones with source evidence and resolve only addressed threads. After each push, get fresh CI and review. A pending, missing or older review is a wait state, not a pass. After three identical failures without new evidence, diagnose instead of rerunning. Never bypass checks, hooks or protection.

Done when all checks pass on the same head, Codex has reviewed that head, and no actionable thread remains.

## 5. Merge and release

Refresh head, base, checks and threads, then squash-merge bound to the verified head SHA. Verify main CI and the repository release for the merged SHA. A post-merge failure resumes at release verification, never a new PR. Close the issue once its scope is delivered.

## 6. Finish

Post to the issue: PR, slice SHAs, observed checks, merged SHA and release tag, and any remaining limits (end-to-end tests stay in #30). On a genuine blocker, post the exact next action and last confirmed state; the same invocation resumes from actual state.
