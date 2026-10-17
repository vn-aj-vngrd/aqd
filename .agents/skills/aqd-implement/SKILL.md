---
name: aqd-implement
description: Implement or resume an approved AQD issue or fix in tested, committed vertical slices. Use when starting or continuing feature work on an issue.
---

# Implement an AQD issue

Read `AGENTS.md`, the issue with its comments (`gh issue view <n> --comments`), the affected [feature contract](../../../docs/features) and [DESIGN.md](../../../DESIGN.md) for UI. For native work also read `apps/ios/AGENTS.md`. Settled specs need no new interview.

## 1. Plan in the issue

List the vertical slices (each a working outcome with its UI, rules, save and recovery paths) and their checks as one issue comment. Plans and status live in GitHub, never in repo files. Check `git status` and own only your files.

Done when every acceptance item has an owning slice and a check, and the comment is posted before product edits.

## 2. Build one slice

Take the next ready slice. Read its callers and tests. Reuse shared components and store seams. Write a failing test at the public seam first for behavior changes (installed `tdd` skill if available). Preserve drafts, stable IDs and acknowledged outcomes. Keep unrelated cleanup out.

Done when the slice delivers its whole outcome including failure, cancel and empty states, and its focused checks pass. A scaffold with dead actions is unfinished.

## 3. Verify and commit

Run [aqd-verify](../aqd-verify/SKILL.md), then [aqd-review](../aqd-review/SKILL.md) on the increment; fix valid findings. Commit only this slice's code, tests and affected docs with a one-line `action(part): Description` subject. Post the checks and SHA to the issue.

Done when checks pass and the slice is its own commit. One commit for all slices does not satisfy this.

## 4. Continue and close out

Repeat 2–3 for each slice without waiting for prompts. When blocked by access, continue independent work and name the exact blocker in the issue. After the last slice, review the full diff and run the final checks. Under [aqd-ship](../aqd-ship/SKILL.md), hand back at this local gate. Finishing one issue does not authorize the next.
