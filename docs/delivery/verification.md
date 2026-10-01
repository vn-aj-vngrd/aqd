# Current verification

## Release evidence

The current checkout has no tracked iOS app/build baseline. Historical build and simulator results cannot be reproduced from tracked source here. All full-V1 device, live-service, security, accessibility and distribution checks remain unverified.

| Boundary | Status | Evidence / next check |
| --- | --- | --- |
| Product and design requirements | Specified | [Feature acceptance](../features/README.md), [V1 release](../product/v1-release.md), and [design handoff](../design/README.md). Requirements and static drawings are not passing runtime tests. |
| Paper inventory | Recorded design reference | [iOS manifest](../design/paper-manifest.json) and [web manifest](../design/web-paper-manifest.json). Reopen Paper for live visual acceptance. |
| Native build / device behavior | Unverified for current source | Establish a reproducible source/build baseline; verify navigation, keyboard, accessibility, camera and model behavior. |
| Connected services / production | Unverified | Resolve [service gates](../product/decisions.md), then verify identity, sync, publication/revocation, Inbox and operations. |
| Distribution | Unverified | Repository release, TestFlight and App Store delivery have separate gates. |

## Documentation maintenance — October 2, 2026

Grouped documentation by responsibility, consolidated duplicate scope/decisions/assets, and separated historical prototype and Paper review records from current evidence. Validated against the working tree based on `08ded4b`; existing staged design/product refinements were preserved. This work changes documentation and documentation-path diagnostics only.

| Check | Result | Evidence / limits |
| --- | --- | --- |
| Local documentation links and heading anchors | Passed | 378 tracked local references resolve; every Markdown page is reachable from the documentation/agent indexes. Historical local screenshots are labeled untracked paths rather than portable evidence links. |
| Migration integrity | Passed | All 56 mapped destinations exist; feature acceptance IDs, historical verification headings and external asset sources remain present. |
| Paper manifest contracts | Passed | 212 recorded Markdown references resolve; both JSON manifests parse. Artboard data was retained. |
| Repository tooling | Passed | `node --test scripts/*.test.mjs`: 30 tests passed using installed Node v26.4.0. The repository targets Node 24; this is evidence for the local runtime used. |
| Package-manager entry point | Passed during commit | The initial pinned-runtime download failed; the commit hook subsequently ran `pnpm check` with pnpm 10.12.1 successfully (30 tests). Installed Node remains v26.4.0, outside the repository's Node 24 target. |
| Whitespace | Passed | `git diff HEAD --check` on the final working tree. |

No native build, live Paper review, connected-service test or deployment was performed for this documentation cleanup.

## Historical evidence

- [Prototype verification](archive/prototype-verification.md): original build/test/simulator reports and their limits.
- [Design review log](archive/design-review-log.md): dated static Paper review history, including superseded refinements.
- [Prototype implementation](archive/prototype-implementation.md): prior behavior and migration context.
- [Prototype backend setup](archive/prototype-backend-setup.md): historical configuration procedure, not approval to provision a backend.

New verification entries must identify the scope, actual result, source revision/environment and remaining limitations. Keep detailed chronological captures in the archive; summarize current release evidence here.

## Foundation release review fix — October 2, 2026

Codex's earlier PR review identified successful commit A being skipped when newer main commit B failed CI. Added a serialized, fast-forward-only `release` publication cursor, selected by semantic-release, so only successful main CI commits enter publication. Final verification checks both the exact-HEAD version tag and its published non-draft GitHub release.

Passed locally: 33 tooling tests, including real Git fixtures for successful A/newer failing B, same-SHA retry, newer successful C, tag refresh, delayed A, mismatched checkout and divergent history. Standards/spec review checked the final release logic against issue #1; the standards review's missing-GitHub-release finding was fixed. Final-head CI/Codex review and post-merge main CI/release remain required live gates. No native/service deployment was added.

## Final-head Codex review recovery fixes — October 2, 2026

Codex reviewed `efeefff` and found two follow-ups. Publication now retries a missing GitHub release from its existing exact-HEAD version tag, or publishes a draft left by a partial upload, without deleting/recreating tags. Tests cover a tag surviving semantic-release failure, API creation failure/retry, idempotent success, missing tags and draft publication failure/retry. All 37 tooling tests pass locally.

Converted 57 archived local screenshot links to labeled untracked capture paths. Re-ran the local-link/heading/reachability check against `git ls-files`, rather than filesystem existence: all 378 portable references pass. Historical captures are not evidence available in a fresh clone. Fresh final-head CI/Codex review and live merge/release verification remain required.

## Publication queue review fix — October 2, 2026

Codex reviewed `14412af` and identified failed CI workflow runs replacing pending successful releases through workflow-level concurrency. Moved concurrency to the trusted-success-guarded release job and selected GitHub's `queue: max`; failed/skipped workflows no longer occupy the publication group, and eligible pending releases queue instead of replacing each other. The workflow contract test verifies no top-level release concurrency, the job-level queue, no cancellation, and trusted-success conditions. All 37 tooling tests pass; final-head CI/Codex and post-merge publication remain live gates.
