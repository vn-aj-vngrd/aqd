# Issue 20: Native foundations

## Scope

- Issue: https://github.com/vn-aj-vngrd/aqd/issues/20
- Branch: `van/issue-20/native-ui-foundations`
- Authorized endpoint for this cleanup: verify and commit existing work locally. No new PR/merge/distribution is requested by this cleanup.
- Predecessor: native baseline PR #9 at `c5e11c4`, as recorded in the active implementation plan.
- Contracts: Foundation in [implementation plan](../delivery/implementation-plan.md#foundation--native-foundations), [native reuse](../../apps/ios/FOUNDATIONS.md), scoped LOCAL-02/04/10/15, and affected control/coverage ledgers.
- Baseline: `c666a23ac6134982820c0ef0c95ef484e2678261`, with inherited uncommitted native code/tests and evidence. This plan records existing work retrospectively; it does not claim those earlier edits followed the new slice workflow.

Agent workflow/docs tooling is separate unticketed repository maintenance. It does not expand this product issue or complete a V1 section.

## Slices

| Slice | Working outcome | Focused proof | State | Commit marker | Actual SHA |
| --- | --- | --- | --- | --- | --- |
| S1 | Shared native metadata/fields, tab selection and capture/details/photo source-return behavior, with rendering and UI regression cases | Native unit/Debug + unsigned Release; Standards/Spec source review | Committed | `AQD-Slice: #20/S1` | `eb21a84` |
| S2 | Revalidate the opened bootstrap store before seeding stock Today, preserving existing owner/widget IDs | Native persistence/reopen/bootstrap tests in unit suite; source review | Committed | `AQD-Slice: #20/S2` | `95e789d` |
| S3 | Feature unit scope and explicit final E2E scope; policy and evidence distinguish deferred runtime acceptance | Tooling/workflow tests, actual unit selection, shell validation | Committed | `AQD-Slice: #20/S3` | `6767729` |

## Acceptance and evidence

| Item | Slice | Evidence | Result |
| --- | --- | --- | --- |
| Native source standards and scoped Foundation behavior | S1/S2 | Independent Standards and Spec reviews of all eight changed Swift files against baseline; no new actionable defect | Passed, source only |
| Core/native unit and Debug app build | S1/S2 | `/tmp/aqd-agent-foundation-unit.log`, matching iPhone 17 Pro Max simulator on iOS 27.0, current dirty native source | Passed, 20 Core /72 Swift Testing /12 XCTest; no UI tests |
| Generic unsigned Release | S1/S2 | `/tmp/aqd-agent-foundation-release.log`, current dirty native source | Passed |
| Repository/workflow/agent-doc checks | S3 | `pnpm check`: 49 passed; `pnpm check:agents` checks all current Markdown/skills; final receipt follows | Passed |

## UI proof requirement at workflow authoring

The owner's acceptance-proof clarification supersedes the old unit-only delivery assumption. Before shipping this issue, read its actual ACs, map the affected UI outcomes, generate/extend selected native E2E cases, inspect their real rendered evidence, and publish the proof table/artifacts in its PR. Existing unit/Release receipts and authored UI cases do not establish that new proof gate. These checks were unexecuted during workflow authoring; the authorized shipping run below owns their current results.

The known landscape Notes failure below must be resolved before issue delivery if it invalidates one of its ACs. Its retained #30 regression entry does not waive the issue's own proof requirement.

## Authorized shipping run, October 15

The owner invoked `aqd-ship 20` through protected squash merge and repository release verification. Workflow maintenance was committed first at `866c3db`. Resume the existing branch and create one PR against `main`, fixed base `c5e11c4b89a1b6d408b1d7ccc984047c043c5457`. GitHub ruleset requires Repository tooling, resolved threads, linear history and squash. Codex review and Native iOS CI remain additional delivery gates.

| Slice | Complete outcome | Verification | State |
| --- | --- | --- | --- |
| S4 | Visible multiline Notes editing, Apply/cancel and retained draft across rotation/relaunch | Existing `testDetailsLandscapeAvailabilityNotesApplyDiscardAndRelaunch` and `testMultilineNotesKeepEditingAcrossRotation`, inspected full-screen attachments | Committed at `ca761fd` |
| S5 | Reusable selected-case proof and remotely accessible results for Foundation | Selected native E2E, attachment export/index, PR AC table and artifacts | Committed at `fd3dcd5`; remote artifact gate pending |
| S6 | Require the exact MVP simulator in hosted acceptance proof | Execute the actual workflow selection against matching and fallback-only inventories, then current-head CI/Codex | Committed at `12912e7`, marker `AQD-Slice: #20/S6` |

The real issue has prose Build/Prove clauses rather than numbered ACs. The following labels preserve those clauses as traceable subcases, without claiming complete LOCAL-01/10/15 or later product roots.

| AC / expected outcome | Actual check | Required evidence | Status |
| --- | --- | --- | --- |
| F1: reusable semantic controls and shared states in light/dark and accessibility variants | AQDTests shared component rendering; `testSharedCaptureControlsAtLargestTextKeepKeyboardSafeTargetsAndValidation`; focused appearance journey | Native rendering units; largest-text UI case; dark source-close via real proof runner, inspected [screens/reports](evidence/issue-20/README.md) | Passed locally; publication pending |
| F2: five native destination identities and source-preserving Agent presentation | `testNativeRootTabsExposeDestinationsTargetsAndSelection`, `testAgentFullScreenBackRestoresCloset` | Tab/return assertions and inspected [screens/reports](evidence/issue-20/README.md) | Passed locally; publication pending |
| F3: capture → accepted photo → acknowledged piece → collection → process relaunch | `testPhotosPickerSaveSearchEditAndRelaunch` | Real synthetic Photos/crop/save/read/relaunch assertions and inspected [screens/reports](evidence/issue-20/README.md) | Passed locally; publication pending |
| F4: cancel/failed write/unknown retry/migration preserve data | AQDTests persistence/recovery; `testCaptureSourceClosePreservesDraftAndPhotoIsRequired`; S4 Details tests | Native failure/unknown-retry/migration units plus corrected Details/source-close/recovery cases; [receipts](evidence/issue-20/README.md) | Passed scoped local behavior; publication pending |
| F5: isolated failure/restart/media fixtures and rendered test support | Existing isolated test-store/fixture guards, selected-case runner and exported attachments | CLI filter RED/GREEN; strict proof validator; actual dark subset run/exports. Default eight-case CI artifact still needs its actual run/readback | Local support passed; remote publication pending |
| F6: manual support/API gates and capability budgets remain explicit | Native unit/Debug, unsigned Release; existing capability evaluation gate | Core20/native84/Debug and unsigned Release passed; [input comparison/build receipt](evidence/issue-20/build-receipt.json). No assistance enabled; broad qualification stays #30 | Passed scoped local gate |

Shipping locator: `vn-aj-vngrd/aqd`, head `van/issue-20/native-ui-foundations`; resolve/reuse its PR on resume. Current local toolchain is Xcode 27.0/27A266a with iPhone 17 Pro Max simulator E3686DA1-1D81-4CD9-A876-9797D94C63DF on iOS 27.0. Synthetic media only. Physical-device and full regression remain #30.

### S4 diagnosis and retained runs

Original tests passed 2/2 while the seven-line landscape screenshot exposed only line 1. Changing only the focused Notes anchor from top to bottom showed line 7 and its caret above Apply/keyboard. Independent Standards and Spec reviews confirmed that narrow difference. A new Vision OCR assertion crops the unobscured editor, excluding keyboard suggestions. Its valid original-anchor RED recognizes `Line 1 wardrobe note`, not the expected `Line 7 after rotation`, in `/tmp/aqd-ship20-ocr-display-red.xcresult`. Earlier empty-OCR probes exposed an app-only landscape screenshot canvas defect; they are failed harness experiments, not valid symptom reproductions. The final helper uses full-display capture with explicit image orientation.

`/tmp/aqd-ship20-final.xcresult` on the bottom-anchor source passed 84 native unit tests and 7/8 selected UI tests, zero skips; Core20 passed separately and unsigned generic Release passed. The multiline OCR test passed. The remaining UI failure occurred before Notes focus: the driver alternated full-body 232-point swipes past Availability. Its final target was y469–531 below the visible body. A measured-distance slow drag with endpoint hold retains the same visibility bounds; its three affected clients, including short-note OCR, passed 3/3 with zero failures/skips in `/tmp/aqd-ship20-focused-correction.xcresult`. Both full-display images were inspected: the short note is visible; line 7 and its caret remain above Apply/keyboard. OCR recognizes the exact expected strings. The combined run remains Failed. Only `NativeFlowTests.swift` changed between the recorded combined and correction source snapshots; production/native-unit/Release inputs stayed identical. Five UI cases whose interactions/expectations did not change retain their earlier passes, with current-head CI still required.

### S5 selected execution and publication support

The issue manifest contains eight UI identifiers. `scripts/prove-ios.sh 20` retains real input identity, logs, result bundle, summary and exported attachments. Empty/malformed selections fail before native work. Strict validation refuses missing/failed/skipped/expected-failure cases, unexpected counts and missing case-associated PNGs; rendered correctness still requires inspection. `pnpm check` passed 53 tests after genuine filter RED/GREEN. A declared one-case dark subset ran through the new wrapper: one pass, zero failures/skips; the actual dark form was inspected and original light appearance restored. This subset does not pass the unselected cases.

[Durable evidence](evidence/issue-20/README.md) retains real failed/passing reports, unmodified screenshots, OCR, native input hashes and build receipts. Native source at `ca761fd` matches the tested production inputs. Subsequent changes are selection/publication tooling and documentation. Native PR CI is configured to run the complete eight-case issue selection and publish `native-ios-acceptance` for 30 days. Its actual run/readback, current-head CI/Codex and protected merge/release remain remote gates, never inferred from configuration. Standards found no actionable issue; the Spec review publication-overclaim wording was corrected before commit.

### S6 hosted acceptance destination correction

[PR #31's Codex finding](https://github.com/vn-aj-vngrd/aqd/pull/31#discussion_r4281401537) on `a8ff736` identified a hosted fallback to another iPhone when the required iPhone 17 Pro Max was absent. CI now reuses the existing exact-target selector, retains the iOS18 minimum check and exports no destination on refusal. The actual-workflow regression first failed because another phone was accepted, then passed both fallback refusal and matching-target export. Receipts are `/tmp/aqd-hosted-destination-red.log`, `-green.log` and `-tooling.log`; `pnpm check` passed 54 tests with zero failures/skips. Documentation/whitespace checks passed. Independent Standards and Spec rechecks found no actionable finding.

Native app/test/fixture inputs remain unchanged from `a8ff736` and the local evidence's recorded inputs. Current-head hosted eight-case acceptance, actual artifact access and a new Codex review remain required after pushing this correction. The earlier review does not certify its successor head.

## Deferred final verification

Final #30 retains older-runtime/full-matrix failures and physical qualification. The current iPhone 17 Pro Max/iOS27 focused Notes acceptance now passes after the bottom-anchor correction, including rendered short text and the active seventh line/caret. This does not certify every OS/device/cursor-editing scenario. Detailed earlier failed receipts remain in [verification](../delivery/verification.md#foundation-20-authorized-native-verification--october14).

Physical iPhone 17 Pro Max execution and its installed OS, camera/media quality, file-protection/backup behavior, VoiceOver and performance/capability qualification remain unverified. Broad minimum/other-device launch compatibility is separate from immediate personal-phone acceptance.

### S3 runner compatibility correction

A final actual-runner check found Bash3.2 aborting under `set -u` for the empty full-scope test-selection array. The regression first failed in all scope; unit/e2e passed. Conditional expansion preserves zero arguments. Three external-tool-recorder scenarios now pass, with no native/Photos work. Correction marker: `AQD-Slice: #20/S3-bash`. Actual SHA: `236d06d`. Independent bounded Standards recheck found no actionable finding.

## Historical cleanup review and delivery

- Standards: no actionable finding in existing native diff, source review only.
- Spec: no new source-proven defect/scope creep; known keyboard failure retained for #30.
- PR/latest-head CI/Codex/merge/release: Not run in this cleanup.
- Initial cleanup receipt: `ba67182`. Final runner receipt: `docs(aqd): Record runner correction and final handoff`, with its own SHA resolved from Git. Agent-foundation maintenance is separately committed at `1d3bfc5`.

## Shipping

- PR: https://github.com/vn-aj-vngrd/aqd/pull/31, branch `van/issue-20/native-ui-foundations`; reuse it.
- Local gate: native code `ca761fd`, proof/tooling `fd3dcd5`, exact hosted destination `12912e7`. The S6 documentation receipt persists the correction SHA before selecting the next remote gate head.
- Published proof: use the actual evidence commit for the [tracked report/images](evidence/issue-20/README.md), then link/read back the real Native iOS Actions artifact. Local source paths identify provenance only.
- Remote gates: query current PR head, expected CI, Codex completion and all threads. Snapshot the matching head before protected squash merge; then verify merged-SHA main CI and repository release. GitHub owns these live statuses.

## Resume

- Current action: full `aqd-ship 20` authorized. Workflow `866c3db`, S4 `ca761fd` and S5 `fd3dcd5` are pushed in PR #31 with accessible AC reports and inline evidence. S6 `12912e7` corrects its first Codex finding; earlier S1–S3 receipts remain retained.
- Next exact action: push the reviewed S6 correction, obtain current-head CI/Codex, inspect/publish its real acceptance artifact, then protected squash merge and main/release verification. No new routine authorization is needed.
- Dirty paths: reconcile actual Git status and resolve S6 through its marker before resuming. No external blocker is currently confirmed.
