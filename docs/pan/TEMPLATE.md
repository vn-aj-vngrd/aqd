# Issue <number>: <exact issue title>

## Scope

- Issue: <canonical GitHub issue URL>
- Branch: <actual branch>
- Authorized endpoint: <local review / draft PR / leave open / full lifecycle>
- Predecessor and evidence: <dependency and its actual delivery state>
- Contracts: <affected feature/design acceptance links and IDs>
- Baseline: <HEAD, relevant dirty paths and ownership, existing failures>

## Slices

Replace the example with the smallest complete journeys required by this issue.

| Slice | Working outcome and boundaries | Acceptance IDs | Focused proof | State | Commit marker | Actual SHA |
| --- | --- | --- | --- | --- | --- | --- |
| S1 | <one executable journey, including recovery> | <scoped IDs> | <test/build or required observation> | Planned | `AQD-Slice: #<number>/S1` | Pending |

## Acceptance and evidence

| AC / subcase and expected outcome | Slice | Scenario / actual test ID | Tested revision, environment and observed result | Local artifacts / published PR evidence | Status |
| --- | --- | --- | --- | --- | --- |
| <issue AC wording and scoped acceptance ID> | S1 | <focused E2E for UI, appropriate check otherwise> | <exact command/run and actual outcome> | <real screenshots/video and report links; publication initially Pending> | Not run |

## Deferred final verification

List genuinely broader integrated/device/OS qualification retained for #30. Include relevant existing failures and reproduction/artifacts. Keep the issue's own UI AC tests and rendered proof in the acceptance table above; a failure invalidating its AC stays blocking here.

## Review and delivery

- Standards: <reviewed revision/diff and findings/fixes>
- Spec: <acceptance coverage and findings/fixes>
- Repository/native checks: <actual results or exact blockers>
- Final receipt commit: <commit subject/marker; resolve its SHA from Git>

## Shipping

- PR locator: <known canonical URL, otherwise repository/head branch; resolve and reuse on resume>
- Stable local gate: <reviewed revision and acceptance-table pointer>
- Published acceptance proof: <PR proof-section locator and artifact access/identity check, or Pending>
- Remote gate evidence: <GitHub workflow/review/thread/release locators; query their current state>

Follow the plan convention's shipping checkpoints. Passing remote status is read from GitHub; polling results alone do not produce commits.

## Resume

- Current slice or ship phase and last completed action:
- Next exact action:
- Remaining dirty paths and ownership:
- Blocker, evidence, repeated no-progress attempts and missing human/access action, if any:
