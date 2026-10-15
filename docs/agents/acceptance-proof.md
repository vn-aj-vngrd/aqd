# Acceptance proof

Owner update, October16: feature delivery uses Core/native unit tests only. All E2E authoring/execution and integrated UI acceptance are deferred to #30, including feature-focused runs. Preserve existing tests and evidence for that ticket. No simulator is allowed locally or in hosted CI. The expensive native iOS CI workflow is removed; fast repository unit checks and existing protected delivery remain. Native unit checks use the connected, unlocked physical iPhone17ProMax. E2E/proof procedures below apply only to #30. Known product, data-loss and security defects still require fixes; deferred E2E is not a claim of full V1 acceptance.


The [implementation-plan verification policy](../delivery/implementation-plan.md#verification-policy--owner-approved-october15) requires focused UI acceptance proof during feature delivery. This contract owns proof quality and publication. [`aqd-prove`](../../.agents/skills/aqd-prove/SKILL.md) performs it; `aqd-ship` keeps merge blocked until required proof is published and passed.

## Scope and mapping

Use the actual issue's AC IDs and wording, linked to the owning feature/design acceptance. Account for every scoped criterion and its required branches. Compound criteria may have labelled subcases; passing one does not pass the parent. Include supporting routes necessary to complete the feature.

| Criterion | Required proof |
| --- | --- |
| User-visible UI outcome | A focused native E2E test driving the actual app, plus inspected rendered evidence of the claimed state |
| Navigation, editing or persisted UI result | Real actions and outcome assertions, including source return, cancellation or relaunch when required by the AC |
| Appearance, keyboard, clipping or motion | Inspected screenshots at the relevant state; use a short video when sequence/timing matters. A screenshot alone cannot prove persistence or a completed interaction. |
| Non-UI rules, persistence or failure recovery | Appropriate domain/native integration checks and result evidence; add the app journey when the criterion includes UI behavior |
| Documentation/tooling only | Relevant checks with a stated reason UI E2E is Not applicable |

Use Passed, Failed, Blocked, Not run or Not applicable with a reason. Broad cross-feature, supported-device/OS, full accessibility/performance and release qualification remain in #30. A current feature's UI AC cannot become Deferred to #30 to avoid a failure or missing proof. Preserve known failures and repair those that invalidate its required outcome.

## Tests that prove the criterion

- Extend the existing XCUITest target and fixtures. Launch the real app, navigate from the real caller, interact with its controls, and assert the expected user-observable result. Reuse `--aqd-ui-testing` and a unique `AQD_TEST_STORE_ID`; retain it across relaunch within one case.
- Use fixture data only to establish a declared starting state. Exercise the real save/read/media/navigation path that the AC claims. Mocking the behavior being accepted or injecting its final UI state cannot prove it works.
- Generate tests from expected behavior before using the implementation as a reference for selectors. Add an appropriate regression RED before a fix when possible; report an inherited passing baseline honestly rather than inventing a failure.
- Assert values, record identity, source return or durable outcome as applicable. A screen existing, tap succeeding, `isHittable`, test count or process exit alone does not prove the complete AC. Use stable accessibility identifiers and state-based waits; broad catches, conditional skips and relaxed assertions cannot turn a required failure into success.
- Keep scope to the issue's ACs and changed shared consumers. Reuse existing coverage where it already proves them. Run completed UI slices' relevant cases, then the final selected feature set when its inputs change; the full app matrix is not a per-slice prerequisite.
- Review test premises and results against the spec. If a proxy or fixture is wrong, preserve the failure and justify its correction. Existing safety assertions remain intact unless a changed requirement explicitly replaces them.

## Evidence identity and inspection

For each proof run, retain tested commit/dirty-input identity, exact selected test identifiers and command, toolchain, device/OS, declared fixtures, outcomes/skips and result-bundle location. Keep successful-state and failure/recovery attachments inside the real test journey, retaining XCTest attachments with `.keepAlways` as the existing native helpers do. Capture the relevant full viewport so cropping cannot hide a covered control or wrong context.

Inspect the actual images/video using available image or native evidence tools. Check the expected displayed value, state and design criteria. An AX assertion is useful interaction evidence, not a painted-pixel mask. A layout-only screenshot does not prove a data write; a write assertion does not prove the editor is visible. Pair the evidence needed for the criterion.

Simulator and synthetic-fixture evidence must be labelled. Real camera quality, file-protection/backup semantics, physical VoiceOver/performance and on-device model quality require their own device proof when in scope. Use synthetic/non-sensitive test data for PR media; personal closet/photos/notes need explicit sharing authority.

After code/test/fixture/build/runtime changes, reprove affected ACs and refresh the table before merge. Evidence from another head can be reused only with a documented comparison of unchanged relevant inputs; name its actual tested revision rather than relabelling it as a new run. Latest-head CI and Codex remain independent requirements.

## Publication in the PR

Publish an **Acceptance proof** section in the PR body using [the PR template](../../.github/pull_request_template.md). Include:

1. The tested revision, device/OS, fixture boundary and selected test run/command.
2. A row for every scoped AC/subcase with expected outcome, actual E2E/check identifier, observed result and evidence links.
3. Inline screenshots or short video for changed UI outcomes, plus a linked test report/result bundle. Long sequences may link a grouped artifact with a clear case-to-file index; keep representative key states visible in the PR.
4. Exact failures, unavailable proof and the genuinely broader #30 work. Pending proof is not a successful feature or a ready-to-merge PR.

Use available GitHub attachments or an authenticated CI artifact route. Uploaded test reports, result bundles and exported attachments must name their real source/run. When media is tracked, link the file at its actual commit and confirm it is included in Git; ignored/local-only captures are not remotely reviewable. For CI artifacts, link the real run/artifact, describe its contents and retention/expiry limitations, and verify access. `/tmp`, local filesystem links and nonexistent upload commands cannot satisfy the published-proof gate.

Read the PR back after publication. Check table rendering, visual media and artifact access against the intended run. If publishing fails, keep the PR draft/open and the proof gate Blocked; continue other useful work while resolving the supported publication path. Fixes update the existing proof section; retain failed/superseded run identity without presenting it as current success.

## Execution support boundary

Persist selected UI identifiers in `apps/ios/acceptance/issue-<number>.txt`, matching the issue plan's AC mapping. Run `./scripts/prove-ios.sh <number>`. It uses the existing native runner, isolated fixtures and exact `-only-testing:` selection; empty/invalid lists fail before native tools run. `IOS_DESTINATION` and `IOS_DERIVED_DATA` retain their existing meanings. Optional `IOS_PROOF_OUTPUT` must name a fresh directory; `IOS_TEST_CASES_FILE` can select a declared focused subcase instead of the issue's full selection.

Local execution follows the [physical-device procedure](autonomous-workflow.md#immediate-mvp-target): prompt for connected/unlocked iPhone readiness, use its discovered physical destination and local signing, and set `IOS_DEVICE_READY=1` only after confirmation. Local simulators remain shut down. Missing readiness/access blocks the check without fallback. GitHub-hosted simulator artifacts remain separate evidence from GitHub's machines; they never establish physical acceptance.

The proof directory retains `inputs.json`, exact cases, the real run log, `.xcresult`, exported attachments/index and the actual summary. The validator requires all selected cases to pass with zero failures/skips/expected failures and a PNG attachment for each actual case. It does not inspect visual correctness; the agent must still inspect the rendered evidence. Failed runs retain their artifacts and remain failed.

Native PR CI runs unit scope, then the issue selection when the branch has a matching manifest. An explicit dispatch can supply `acceptance_issue`; a missing requested selection fails. CI publishes `native-ios-acceptance` for 30 days, including source/device identity, results and attachments. Read back the actual run/artifact and link it in the PR. Main's routine unit scope and explicit all/E2E hardening remain separate. A skipped optional selection is not proof.

Track a small set of inspected screenshots, the real summary/OCR receipts and their source index under `docs/pan/evidence/issue-<number>/` when durable inline PR media is needed. Link those files at the evidence commit. Keep large bundles in the authenticated CI artifact route, with its retention limit explicit. No generated report or configured CI step counts as execution before its actual run passes.

## Installed build and screen check

Before a UI proof batch, bind the current source hashes to its build output and physical destination. When the owner reports old screens, stop the batch, retain it as interrupted/superseded and rebuild from current source in a fresh task-specific derived-data directory. Never reuse an old `.app`, `test-without-building` product or simulator as a shortcut. Do not uninstall the ordinary app or erase its data to refresh a build.

Run a short focused screen check first. Assert a current screen-specific identifier and inspect its screenshot against the approved design before starting the remaining cases. Visit both the preview and its actual destination when both changed. A polished tour screenshot does not prove actual Profile, Closet or Today is implemented. Test fixtures change data, not permission to accept outdated layouts. If the two differ, fix or document the actual scope before claiming success.

Record the built executable hash, derived-data path, source inputs, test result and inspected screen in the issue receipt. After automation, terminate the test process and launch the same freshly built app normally with no fixture arguments or environment. Tell the owner which screen is ready for review. Never claim the installed version or explain an apparent regression until the build and visible screen have been checked.

Physical iPhone notifications can overlap native header controls. Before tapping Back/X/Done/More or taking acceptance screenshots, wait for SpringBoard’s `NotificationShortLookView` to disappear and require AQD to be foreground. The shared `DeviceTestSupport` guards issue tests without reading notification text, opening notifications or changing the owner’s Focus settings. A persistent banner or other foreground app blocks the action; retain the interruption as unqualified. Never capture or publish another app/private notification as AQD failure evidence. Native test idling delays alone do not establish app performance.
