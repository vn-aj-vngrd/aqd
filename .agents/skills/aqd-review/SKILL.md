---
name: aqd-review
description: Review an AQD slice or completed issue against repository standards and its approved feature spec. Use before committing a slice or handing off the full issue diff.
---


Owner update, October16: feature delivery uses Core/native unit tests only. All E2E authoring/execution and integrated UI acceptance are deferred to #30, including feature-focused runs. Preserve existing tests and evidence for that ticket. No simulator is allowed locally or in hosted CI. The expensive native iOS CI workflow is removed; fast repository unit checks and existing protected delivery remain. Native unit checks use the connected, unlocked physical iPhone17ProMax. E2E/proof procedures below apply only to #30. Known product, data-loss and security defects still require fixes; deferred E2E is not a claim of full V1 acceptance.

# Review an AQD change

Establish review scope before changing code. A review request authorizes read-only findings; an implementation task includes fixing its valid findings. [Lifecycle](../../../docs/agents/lifecycle.md) owns authority and delivery gates.

## 1. Fix the inputs

Read the issue and persisted plan, affected acceptance contracts and current status. Record the branch's fixed base/merge-base and reviewed head. Include staged, unstaged and new files when they belong to the task. An empty commit diff is not a review of working files. Identify unrelated dirty paths by ownership and inspect affected callers.

Review the actual increment for a slice, and the entire issue diff for closeout. Native changes load [iOS standards](../../../docs/agents/ios-standards.md); UI changes also load applicable [quality criteria](../../../docs/design/quality-criteria.md).

Complete when every in-scope file, requirement and evidence revision is identified.

## 2. Review both axes

For a slice increment, inspect both axes below at that bounded scope. At issue closeout, use installed Matt Pocock `code-review` when available and follow its independent Standards/Spec process. If unavailable, perform the two passes below and disclose the fallback. When independent agents are supported and authorized, give each the same fixed inputs without suggested findings; keep them read-only. A single-agent fallback states that limitation.

- **Standards:** trace affected consumers for correctness, state ownership, schema/media preservation, concurrency/cancellation, accessibility, privacy and existing conventions. Flag complexity when it causes a concrete problem.
- **Spec:** map every scoped acceptance item to implementation and actual evidence. Inspect generated E2E expectations against the AC and actual rendered proof under [acceptance proof](../../../docs/agents/acceptance-proof.md). Check success, recovery/cancel/empty states and supporting routes. Broad #30 qualification stays separate; missing/failed proof of the current feature cannot be deferred. Missing behavior and data-loss/security defects remain actionable.

Each finding states severity, exact file/line, trigger, consequence and smallest useful fix. Separate unverified checks from proven defects. A findings-free review names its coverage limits.

Complete when both passes cover the actual final diff and acceptance mapping, including new files.

## 3. Resolve and record

Within implementation authority, fix valid findings, run affected checks through [aqd-verify](../aqd-verify/SKILL.md), and commit corrections tied to the slice. Recheck changed findings and consumers; repeat full review only when changes justify it. Read-only review ends with findings.

Persist reviewed revision/diff, findings, disposition and checks in the issue plan. Unresolved findings or required unavailable review keep that delivery gate open. Local review does not replace latest-head CI, required Codex review or protected merge.

Complete when actionable findings have fixes or explicit justified dispositions and evidence matches final inputs.
