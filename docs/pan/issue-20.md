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

## Current UI proof gate, not executed

The owner's acceptance-proof clarification supersedes the old unit-only delivery assumption. Before shipping this issue, read its actual ACs, map the affected UI outcomes, generate/extend selected native E2E cases, inspect their real rendered evidence, and publish the proof table/artifacts in its PR. Existing unit/Release receipts and authored UI cases do not establish that new proof gate. Mapping, selected execution and PR publication are Not run in this workflow-refinement task.

The known landscape Notes failure below must be resolved before issue delivery if it invalidates one of its ACs. Its retained #30 regression entry does not waive the issue's own proof requirement.

## Deferred final verification

Final #30 retains the known landscape Notes failure: the software keyboard can be offscreen/unhittable and post-typing text/caret visually indiscernible. Preserve the existing real-keyboard and rendered-text assertions. Cause remains unproven; no source-only fix is claimed. Detailed earlier failed and focused-pass receipts remain in [verification](../delivery/verification.md#foundation-20-authorized-native-verification--october14).

Physical iPhone 17 Pro Max execution and its installed OS, camera/media quality, file-protection/backup behavior, VoiceOver and performance/capability qualification remain unverified. Broad minimum/other-device launch compatibility is separate from immediate personal-phone acceptance.

### S3 runner compatibility correction

A final actual-runner check found Bash3.2 aborting under `set -u` for the empty full-scope test-selection array. The regression first failed in all scope; unit/e2e passed. Conditional expansion preserves zero arguments. Three external-tool-recorder scenarios now pass, with no native/Photos work. Correction marker: `AQD-Slice: #20/S3-bash`. Actual SHA: `236d06d`. Independent bounded Standards recheck found no actionable finding.

## Review and delivery

- Standards: no actionable finding in existing native diff, source review only.
- Spec: no new source-proven defect/scope creep; known keyboard failure retained for #30.
- PR/latest-head CI/Codex/merge/release: Not run in this cleanup.
- Initial cleanup receipt: `ba67182`. Final runner receipt: `docs(aqd): Record runner correction and final handoff`, with its own SHA resolved from Git. Agent-foundation maintenance is separately committed at `1d3bfc5`.

## Resume

- Current action: historical local cleanup S1–S3 is committed with native unit/Debug, unsigned Release and repository passes. The newly required focused UI AC proof/publication remains unexecuted; no PR/merge is performed by workflow refinement.
- Next product action after this cleanup: finish Foundation's remaining required feature gates under the current policy, then obtain authorization for the next dependency-ready issue if not already supplied.
- Dirty paths after the final receipt commit: none expected; verify `git status` before resuming.
