---
name: aqd-prove
description: Run consolidated physical-iPhone E2E and inspected acceptance proof for AQD issue 30. Feature delivery is unit-only; do not invoke for other issues.
---


Owner update, October16: feature delivery uses Core/native unit tests only. All E2E authoring/execution and integrated UI acceptance are deferred to #30, including feature-focused runs. Preserve existing tests and evidence for that ticket. No simulator is allowed locally or in hosted CI. The expensive native iOS CI workflow is removed; fast repository unit checks and existing protected delivery remain. Native unit checks use the connected, unlocked physical iPhone17ProMax. E2E/proof procedures below apply only to #30. Known product, data-loss and security defects still require fixes; deferred E2E is not a claim of full V1 acceptance.

# Prove an AQD feature

Read [lifecycle authority](../../../docs/agents/lifecycle.md), the issue/comments, its persisted plan, and the [acceptance-proof contract](../../../docs/agents/acceptance-proof.md). Apply this method to the authorized feature, not the complete V1 regression matrix. Authoring/refining this workflow does not execute native tests or ship an issue.

## 1. Map the acceptance

Keep the originating AC IDs and wording. Split compound criteria into traceable subcases without reducing their meaning. For every scoped criterion, record the expected observable outcome, real scenario/test identifier, proof method, source/environment and evidence needed in `docs/plan/issue-<number>.md`.

Complete when every issue AC and required branch has an appropriate check. Each UI outcome needs a focused app-driven E2E scenario and rendered evidence; units/builds alone cannot cover it. Requirements genuinely outside the issue remain in #30 rather than replacing an issue's acceptance.

## 2. Author and execute focused tests

Under implementation authority, generate or extend native XCUITests in `apps/ios/AQDUITests`, reusing the actual app, isolated-store setup and existing fixtures. Base expectations on the AC, including its relevant failure/cancel/relaunch behavior. Read-only proof work reports missing tests rather than editing without authority.

Persist the exact identifiers in `apps/ios/acceptance/issue-<number>.txt`. Use [aqd-verify](../aqd-verify/SKILL.md) and `./scripts/prove-ios.sh <number>` on the physical iPhone after its required readiness prompt, retaining actual result bundles and attachments. Set the discovered physical destination, local signing team and confirmed readiness explicitly. Keep local simulators shut down; hosted CI is separate. A declared focused subcase may use `IOS_TEST_CASES_FILE`; it does not pass unselected ACs. Execute the cases; generated test source is not a result. Capture failure artifacts and repair valid feature defects within implementation scope. A broken test premise needs evidence and review, not weaker assertions solely to get green.

Complete when the selected tests finish with real assertions about the expected user outcome. Failed, skipped, unavailable and unexecuted cases stay explicit. Missing required proof blocks feature acceptance; broad regression/device qualification stays in #30.

## 3. Qualify the evidence

Inspect actual rendered screenshots and relevant video against the AC and applicable design criteria. Check the observed value/state and any required persistence, return, keyboard or layout behavior. Accessibility-tree geometry and a test-success banner cannot establish correct painted output. Let the Spec review inspect the test expectations and evidence, as defined by [aqd-review](../aqd-review/SKILL.md).

Record the tested revision, selected tests, fixture identity, device/OS, command, result and artifacts in the plan's acceptance rows. Refresh affected proof when implementation, tests, fixtures or build/runtime inputs change. Evidence reuse across a documentation-only head requires a recorded comparison showing relevant inputs are unchanged.

Complete when each Passed AC has qualifying observed evidence, and failures/limitations are accurately separated from success. Before PR creation, return locally qualified proof with publication Pending; local review can stop here.

## 4. Publish and read back

When PR delivery is authorized, publish the contract's AC proof table, inline visual evidence and linked result artifacts in the existing PR. Use its supported attachment/CI-artifact route; if no route exists, implement the smallest selected-test/artifact step within the authorized feature slice. A local artifact path cannot satisfy publication.

Read the PR back and verify every evidence link resolves to the intended run/artifact and can be accessed by the owner. Update the same table after fixes and retain failed/superseded receipts with their source identity. The [shipping checkpoint convention](../../../docs/plan/README.md#shipping-checkpoints) avoids extra commits for polling or URLs.

Complete when every scoped AC has truthful status and reviewable evidence in the PR, the source/environment identity is clear, and all required UI proof passes. Publication or execution failure keeps the proof gate blocked. This method returns the proof result to `aqd-ship`; it does not merge the PR itself.
