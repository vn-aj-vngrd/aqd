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
| S1 | Shared native metadata/fields, tab selection and capture/details/photo source-return behavior, with rendering and UI regression cases | Native unit/Debug + unsigned Release; Standards/Spec source review | Committed | `AQD-Slice: #20/S1` | Pending |
| S2 | Revalidate the opened bootstrap store before seeding stock Today, preserving existing owner/widget IDs | Native persistence/reopen/bootstrap tests in unit suite; source review | Planned | `AQD-Slice: #20/S2` | Pending |
| S3 | Feature unit scope and explicit final E2E scope; policy and evidence distinguish deferred runtime acceptance | Tooling/workflow tests, actual unit selection, shell validation | Planned | `AQD-Slice: #20/S3` | Pending |

## Acceptance and evidence

| Item | Slice | Evidence | Result |
| --- | --- | --- | --- |
| Native source standards and scoped Foundation behavior | S1/S2 | Independent Standards and Spec reviews of all eight changed Swift files against baseline; no new actionable defect | Passed, source only |
| Core/native unit and Debug app build | S1/S2 | `/tmp/aqd-agent-foundation-unit.log`, matching iPhone 17 Pro Max simulator on iOS 27.0, current dirty native source | Passed, 20 Core /72 Swift Testing /12 XCTest; no UI tests |
| Generic unsigned Release | S1/S2 | `/tmp/aqd-agent-foundation-release.log`, current dirty native source | Passed |
| Repository/workflow/agent-doc checks | S3 | `pnpm check`: 46 passed; `pnpm check:agents` checks all current Markdown/skills; final receipt follows | Passed, final docs check pending |

## Deferred final verification

Final #30 retains the known landscape Notes failure: the software keyboard can be offscreen/unhittable and post-typing text/caret visually indiscernible. Preserve the existing real-keyboard and rendered-text assertions. Cause remains unproven; no source-only fix is claimed. Detailed earlier failed and focused-pass receipts remain in [verification](../delivery/verification.md#foundation-20-authorized-native-verification--october14).

Physical iPhone 17 Pro Max execution and its installed OS, camera/media quality, file-protection/backup behavior, VoiceOver and performance/capability qualification remain unverified. Broad minimum/other-device launch compatibility is separate from immediate personal-phone acceptance.

## Review and delivery

- Standards: no actionable finding in existing native diff, source review only.
- Spec: no new source-proven defect/scope creep; known keyboard failure retained for #30.
- PR/latest-head CI/Codex/merge/release: Not run in this cleanup.
- Final receipt commit: Pending.

## Resume

- Current action: finish required unit/build/tooling verification and commit the inherited checkpoint in the groups above.
- Next product action after this cleanup: finish Foundation's remaining required feature gates under the current policy, then obtain authorization for the next dependency-ready issue if not already supplied.
- Dirty paths: native slice files, policy/evidence docs, and separately owned agent-foundation maintenance until their commits land.
