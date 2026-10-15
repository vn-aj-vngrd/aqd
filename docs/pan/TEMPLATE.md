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

| Acceptance item | Slice | Implemented behavior | Check, revision and artifact | Result |
| --- | --- | --- | --- | --- |
| <scoped ID or exact subcase> | S1 | <actual behavior> | <exact command/environment and receipt> | Not run |

## Deferred final verification

List the issue's exact integrated/device/rendered checks retained for #30. Include existing failures and reproduction/artifacts. Keep required feature checks in the acceptance table above.

## Review and delivery

- Standards: <reviewed revision/diff and findings/fixes>
- Spec: <acceptance coverage and findings/fixes>
- Repository/native checks: <actual results or exact blockers>
- PR, latest-head CI/Codex, merge and release: <actual links/SHAs or Not run>
- Final receipt commit: <commit subject/marker; resolve its SHA from Git>

## Resume

- Current slice and last completed action:
- Next exact action:
- Remaining dirty paths and ownership:
- Blocker, evidence, and missing human/access action, if any:
