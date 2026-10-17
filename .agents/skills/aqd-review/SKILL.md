---
name: aqd-review
description: Review an AQD slice or finished issue diff against repo standards and its feature contract. Use before committing a slice or handing off.
---

# Review an AQD change

A review request authorizes read-only findings; inside an implementation task, fix valid findings too.

## 1. Fix the inputs

Read the issue, the affected [feature contract](../../../docs/features) and [DESIGN.md](../../../DESIGN.md) for UI. Record the base (merge-base) and reviewed head. Include staged, unstaged and new files that belong to the task, and inspect affected callers. Review the slice increment while working, the whole issue diff at closeout.

Done when every in-scope file, requirement and revision is identified.

## 2. Review two axes

At closeout use the installed `code-review` skill when available; otherwise do both passes and say so.

- **Standards:** correctness, state ownership, schema and media preservation, concurrency and cancellation, accessibility, privacy and shared-component reuse (hand-built chips, choosers, photo menus or shadows are defects per DESIGN.md).
- **Spec:** map each acceptance item to code and to a check. Cover success, recovery, cancel and empty states. Missing behavior and data-loss or security defects are actionable.

Each finding states severity, file and line, trigger, consequence and the smallest fix. Separate unverified suspicions from proven defects. A clean review names what it did not cover.

## 3. Resolve

Fix valid findings, rerun affected checks with [aqd-verify](../aqd-verify/SKILL.md), and commit the fixes with their slice. Post findings and dispositions to the issue. Local review does not replace current-head CI and Codex review.
