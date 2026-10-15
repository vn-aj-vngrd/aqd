# Autonomous feature delivery

The owner supplies approved product scope and reviews the result. Agents derive implementation steps from the existing feature contracts and deliver them through tested vertical slices. Established decisions stay settled; routine implementation choices belong to the agent.

## Start or resume

Use [`aqd-ship`](../../.agents/skills/aqd-ship/SKILL.md) for complete issue delivery, including a partially implemented issue or existing PR. It resumes the first unsatisfied phase, completes implementation if needed, pushes, opens/reuses the PR, fixes CI/Codex findings, squash-merges and verifies the repository release. An actual ship request authorizes those issue-scoped operations; a request to refine the workflow stays documentation-only.

[`aqd-implement`](../../.agents/skills/aqd-implement/SKILL.md) owns vertical-slice implementation, reaching [`aqd-verify`](../../.agents/skills/aqd-verify/SKILL.md) for evidence and [`aqd-review`](../../.agents/skills/aqd-review/SKILL.md) for Standards and Spec review. [`aqd-prove`](../../.agents/skills/aqd-prove/SKILL.md) maps ACs to focused native E2E and inspected UI evidence. Under `aqd-ship`, these methods return locally qualified proof and the orchestrator ensures publication before merge. All five are repo-local, automatically selectable skills. Hosts that have not refreshed discovery can read these entry points directly through this router.

The [lifecycle](lifecycle.md) owns authority and delivery gates. The [implementation plan](../delivery/implementation-plan.md) owns issue dependencies and verification timing. This workflow supplies the execution method; it does not grant permission to start the next product section.

| Stage | Agent output | Completion criterion |
| --- | --- | --- |
| Select | Existing issue, authorized delivery endpoint, predecessor, affected acceptance IDs | Scope and dependencies permit work; dirty files have identified ownership. |
| Persist | `docs/pan/issue-<number>.md` using the [plan convention](../pan/README.md) | Every scoped acceptance item maps to a slice and a verification method. |
| Implement | One working journey through UI, rules and local storage as needed | That slice's tests pass; existing data and required recovery paths remain intact. |
| Commit | One reviewed code increment with the updated plan | The commit contains only that slice and its tests/docs; its marker and actual SHA are recorded. |
| Repeat | Remaining slices from the same plan | Every implementation slice is committed or an exact external blocker is recorded. |
| Prove UI acceptance | Selected E2E results, inspected screenshots/video and an AC proof table | Every scoped UI AC passes; proof is accessible in the PR before merge. |
| Review and deliver | Final diff review, applicable checks, published proof and reviewable PR | The authorized endpoint is reached; broader #30 qualification stays unverified. |

For full delivery, `aqd-ship` publishes the AC proof, then continues through the CI/review loop, protected merge and release using the [delivery stages](delivery-stages.md). The [shipping checkpoints](../pan/README.md#shipping-checkpoints) keep stable plans in Git and live gate status in GitHub. A phase whose completion criterion already holds is verified and skipped; a normal phase transition never waits for a new prompt.

The per-issue plan is a working execution record, not another feature specification. Update it in place. [Current status](../delivery/implementation-status.md) summarizes capability; [verification](../delivery/verification.md) records observed evidence. Preserve their historical receipts and add a short current entry only when scope or evidence changes.

## Immediate MVP target

The owner's October 15 direction makes the **iPhone 17 Pro Max** the immediate personal-MVP acceptance device. Read its actual installed OS when the phone is available. Use a matching simulator for automated iOS checks. A different phone or simulator can provide supplemental evidence, but cannot establish compatibility with this phone.

Keep the current deployment setting and existing availability guards while implementing features. The broader iOS 18 minimum and supported-device launch matrix in the [V1 release](../product/v1-release.md) remain later release work. They do not expand the immediate personal-device task. No new tablet, Mac, Android, backend, account or sync work is needed to satisfy this target.

Follow the implementation plan's verification policy: feature slices run meaningful unit/build/repository checks and required review/CI. UI outcomes additionally require [focused native E2E and published acceptance proof](acceptance-proof.md). Broad cross-feature/device/OS qualification belongs to final hardening [#30](https://github.com/vn-aj-vngrd/aqd/issues/30). Preserve existing UI tests and failures; a failure that invalidates a current AC blocks that issue, while broader qualification remains in the final queue. Repair known data-loss/security defects during feature work. Before enabling an optional model/media/weather capability, obtain its required capability evidence or keep its documented unavailable/manual path.

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
aqd-ship 20
```

This single invocation completes the authorized issue lifecycle. Invoke it again after an interruption to resume from actual local/GitHub state. Add a narrower instruction such as `aqd-ship 20, leave the PR open` when that is the desired endpoint. Existing committed work is reused; it does not trigger a fresh product interview. Broad E2E remains in #30 for feature issues.

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

The orchestrator runs inside the active agent session. Missing required access/review quota and the delivery-stage service-wait bound produce a persisted, exact blocker. Successful phase transitions, ordinary fix rounds and checks still making progress continue without human intervention.

## Foundation rollout

1. Establish the repo-local skills, iOS conventions, persisted issue-plan template and deterministic device selection.
2. Use them on the next authorized issue. Review the slice commits and the final app result; correct only observed workflow gaps.
3. Continue the existing dependency order without rebuilding the planning process. Close the target-phone integrated verification in #30 after the feature sections.

These are workflow rollout steps, not claims that product features, native checks or delivery gates have passed.

## Source inspiration

[Addy Osmani's Agent Skills](https://github.com/addyosmani/agent-skills) informs the incremental execution and evidence gates. [Matt Pocock's skills](https://github.com/mattpocock/skills) inform composable methods and focused test/review loops. AQD keeps its own project policy and device scope. Existing `tdd`, `diagnosing-bugs`, and `code-review` skills remain useful methods when installed; repo-local entry points supply a documented path when a particular global skill is unavailable. No upstream pack is copied or installed by this setup.
