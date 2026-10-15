# Autonomous feature delivery

The owner supplies approved product scope and reviews the result. Agents derive implementation steps from the existing feature contracts and deliver them through tested vertical slices. Established decisions stay settled; routine implementation choices belong to the agent.

## Start or resume

Use [`aqd-implement`](../../.agents/skills/aqd-implement/SKILL.md) for an approved feature, issue, fix, or implementation continuation. It reaches [`aqd-verify`](../../.agents/skills/aqd-verify/SKILL.md) for evidence and [`aqd-review`](../../.agents/skills/aqd-review/SKILL.md) for Standards and Spec review. All three are repo-local, automatically selectable skills. Hosts that have not refreshed their skill catalog can read these entry points directly through this router.

The [lifecycle](lifecycle.md) owns authority and delivery gates. The [implementation plan](../delivery/implementation-plan.md) owns issue dependencies and verification timing. This workflow supplies the execution method; it does not grant permission to start the next product section.

| Stage | Agent output | Completion criterion |
| --- | --- | --- |
| Select | Existing issue, authorized delivery endpoint, predecessor, affected acceptance IDs | Scope and dependencies permit work; dirty files have identified ownership. |
| Persist | `docs/pan/issue-<number>.md` using the [plan convention](../pan/README.md) | Every scoped acceptance item maps to a slice and a verification method. |
| Implement | One working journey through UI, rules and local storage as needed | That slice's tests pass; existing data and required recovery paths remain intact. |
| Commit | One reviewed code increment with the updated plan | The commit contains only that slice and its tests/docs; its marker and actual SHA are recorded. |
| Repeat | Remaining slices from the same plan | Every implementation slice is committed or an exact external blocker is recorded. |
| Review and deliver | Final diff review, applicable checks, persisted evidence, reviewable build/PR | The authorized endpoint is reached; deferred #30 work stays explicitly unverified. |

The per-issue plan is a working execution record, not another feature specification. Update it in place. [Current status](../delivery/implementation-status.md) summarizes capability; [verification](../delivery/verification.md) records observed evidence. Preserve their historical receipts and add a short current entry only when scope or evidence changes.

## Immediate MVP target

The owner's October 15 direction makes the **iPhone 17 Pro Max** the immediate personal-MVP acceptance device. Read its actual installed OS when the phone is available. Use a matching simulator for automated iOS checks. A different phone or simulator can provide supplemental evidence, but cannot establish compatibility with this phone.

Keep the current deployment setting and existing availability guards while implementing features. The broader iOS 18 minimum and supported-device launch matrix in the [V1 release](../product/v1-release.md) remain later release work. They do not expand the immediate personal-device task. No new tablet, Mac, Android, backend, account or sync work is needed to satisfy this target.

Follow the implementation plan's verification policy: feature slices run meaningful Core/native unit tests, app builds, repository checks and required review/CI. Broad simulator/device/E2E execution belongs to final hardening [#30](https://github.com/vn-aj-vngrd/aqd/issues/30), unless the owner requests a focused runtime check. Preserve existing UI tests and failures in that final queue. Repair known data-loss/security defects during feature work. Before enabling an optional model/media/weather capability, obtain its required capability evidence or keep its documented unavailable/manual path.

Personal-MVP readiness means the integrated journeys and applicable #30 checks work on the owner's physical phone, with no blocking defects. Simulator tests, unsigned builds and repository releases each describe narrower evidence. Signing, installation, TestFlight and public distribution follow the lifecycle's separate authorization/access boundaries.

## Working autonomously

- Read the issue, its comments, its persisted plan and the affected contracts before asking for information. Synthesize execution steps from those sources; planning does not require another product interview.
- Choose the smallest implementation that fits the current app. Use the [iOS standards](ios-standards.md) for native work. Keep source changes and review findings within the selected issue.
- For a failing check, retain the failure, localize the cause, test one hypothesis, and rerun the affected check. If repeated attempts produce no new evidence, record the smallest reproduction and continue independent slices. An unexplained failure stays failed.
- Ask only when a missing product decision, credential, physical interaction or external authorization blocks the remaining work. State the exact missing fact and the useful work already completed.
- Use one implementer by default. When parallel agents are authorized, assign disjoint files or read-only review; one agent owns integration, commits, and the plan. Parallelize independent checks only when they do not share simulator/build state.
- Before a session ends, update the plan's next action, exact dirty/committed state, failed checks and artifact locations. Resume from that record and verify the checkout before rerunning expensive work.

## Example requests

```text
Implement issue #21 using the approved docs. Deliver tested vertical slices.
```

```text
Continue docs/pan/issue-21.md. Leave the final result open for my review.
```

```text
Implement the next dependency-ready issue in the plan, with local review only.
```

The lifecycle resolves the endpoint from the actual request. A local-review instruction stops before PR/merge; an implementation request with full delivery scope retains the existing protected delivery gates. Completion of one issue does not automatically authorize the entire backlog or create a background runner.

## Foundation rollout

1. Establish the repo-local skills, iOS conventions, persisted issue-plan template and deterministic device selection.
2. Use them on the next authorized issue. Review the slice commits and the final app result; correct only observed workflow gaps.
3. Continue the existing dependency order without rebuilding the planning process. Close the target-phone integrated verification in #30 after the feature sections.

These are workflow rollout steps, not claims that product features, native checks or delivery gates have passed.

## Source inspiration

[Addy Osmani's Agent Skills](https://github.com/addyosmani/agent-skills) informs the incremental execution and evidence gates. [Matt Pocock's skills](https://github.com/mattpocock/skills) inform composable methods and focused test/review loops. AQD keeps its own project policy and device scope. Existing `tdd`, `diagnosing-bugs`, and `code-review` skills remain useful methods when installed; repo-local entry points supply a documented path when a particular global skill is unavailable. No upstream pack is copied or installed by this setup.
