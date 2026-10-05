# Current verification

## Release evidence

A reproducible Entry & identity app/backend baseline now exists for issue #3. Current scoped evidence is below. Historical prototype results remain separate; full V1, hosted production and distribution remain unverified.

| Boundary | Status | Evidence / next check |
| --- | --- | --- |
| Product and design requirements | Specified | [Feature acceptance](../features/README.md), [V1 release](../product/v1-release.md), and [design handoff](../design/README.md). Requirements and static drawings are not passing runtime tests. |
| Paper inventory | Recorded design reference | [iOS manifest](../design/paper-manifest.json) and [web manifest](../design/web-paper-manifest.json). Reopen Paper for live visual acceptance. |
| Native Entry build / Simulator behavior | Verified for this slice | Swift 6 / Xcode 26.5, iPhone 17 iOS 26.5; public flow, durable writes, recovery and UI journeys. Physical camera/Apple/device checks remain open. |
| Connected services / production | Unverified | Resolve [service gates](../product/decisions.md), then verify identity, sync, publication/revocation, Inbox and operations. |
| Distribution | Unverified | Repository release, TestFlight and App Store delivery have separate gates. |


## Entry & identity — October 5, 2026

Scope: [issue #3](https://github.com/vn-aj-vngrd/aqd/issues/3), branch `van/issue-3/ios-entry-identity`, foundation merge-base `cf923a05001215aa60625b2d1f5bc3252df7e628`. Source and exact setup: [iOS README](../../apps/ios/README.md). Paper's canonical Entry page was read directly through MCP, including JSX, photographs and recovery screens. E01–E13 and E15–E17 are implemented; E14 stays V2. The private Closet/Profile and first-outfit readiness screens are bounded handoffs, not completion of later wardrobe/outfit/social modules.

| Check | Result and boundary |
| --- | --- |
| Native strict Swift 6 build | Passed, Xcode 26.5 with ad-hoc Simulator signing. Supabase Swift 2.55.3 and transitive lockfile pinned. |
| Public flow tests | 19 domain/identity tests passed in the full native run; all 10 identity tests passed after the additional restored-account origin regression: invalid writes, corruption, draft restoration, account isolation, cancellation during account fetches, offline callback retry, explicit association, pin persistence and pin-based readiness. Two auth regressions were first reproduced as failing tests, then fixed. |
| Native UI journeys | Four public journeys plus the accessibility audit passed across focused iPhone 17 and maximum-text SE runs: no-photo first save/relaunch, invalid email/cancel/private Skip, optional unselected preferences, and native Back retaining a capture draft. Test attachments show welcome, capture, saved receipt, sign-in, keyboard validation and preferences. Portable snapshots: [welcome](evidence/entry-identity/welcome.png) and [first piece](evidence/entry-identity/first-piece.png). |
| Real local Supabase | 25 connected local checks passed, including null/empty payload rejection and photo association with Swift UUID casing. Real email delivery/PKCE verification and consumed-code rejection; owner RLS, profile uniqueness, private photo access, exact receipts, replay, collision and atomic rollback. |
| Database lint | Passed strict public/private-schema lint (`--level warning --fail-on warning`); no schema errors. |
| Native SDK email | Passed actual app email submission, Mailpit verification link, state-bound PKCE exchange and native return to profile setup, with no fabricated auth success. |
| Responsive and accessibility | Standard-text journeys passed on iPhone 17 (iOS 26.5) and SE (iOS 18.1); the final SE save/relaunch rerun also passed. [SE welcome](evidence/entry-identity/se-welcome.png) and [first piece](evidence/entry-identity/se-first-piece.png) preserve the final compact composition. Native contrast/touch-description/hit-area audit passed on both devices after actual target/background fixes. Hero shrinks and centers on short screens, and is removed at accessibility sizes; legal links wrap vertically. The four existing SE journeys/audits passed at maximum accessibility text in dark appearance; the added native Back draft journey also passed after correcting the test to use the native Back control, whose accessibility label is the previous screen title. [SE large text](evidence/entry-identity/se-large-text.png) shows the adaptive layout. |
| Review axes | Standards: four findings fixed (stale responses, route-aware exits, neutral secondary controls, restored-account origin). Spec: three findings fixed (cancellation, offline callback retry, readiness determined by the pinned item). Both final diff rechecks found no remaining blockers. |
| CI delivery | New macOS native build/UI and Linux local-Supabase jobs preserve native artifacts. [PR #4](https://github.com/vn-aj-vngrd/aqd/pull/4): all three jobs passed on `d80007a`; the final typography/navigation update requires fresh latest-head CI. Required Codex GitHub review reported an account review quota error, so merge/release await that gate. |

Local evidence bundles are untracked captures under `/private/tmp/aqd-final-verified.xcresult` (24 passed), `/private/tmp/aqd-origin-regression.xcresult` (10 passed) and `/private/tmp/aqd-responsive-se-large.xcresult` (four passed). They do not survive a fresh clone; reproducible commands and GitHub CI artifacts are the portable evidence. Simulator results do not establish physical camera behavior, live Apple provider success, VoiceOver interaction quality, hosted email delivery or App Store acceptance. The owner approved installed iOS 26.5 after Apple’s Xcode 26.5 catalog rejected the iOS 27 runtime; iOS 27 requires a later tooling update.

The final fidelity audit aligned native primary labels to semantic 17-point medium, standard action height to 50 points, and centered detail titles to semantic 20-point medium. A real SE capture-navigation failure was reproduced in `/private/tmp/aqd-design-fonts-se.xcresult`. Native Back now synchronizes through the navigation binding instead of a second asynchronous path observer; forward routes remain domain-driven. Hero card padding scales uniformly, preventing negative frames during zero-size transitions. The four existing SE UI checks passed afterward with no negative-frame warnings; iPhone 17 and maximum-text SE each passed their four existing checks plus the focused native Back regression. Evidence: `/private/tmp/aqd-navigation-se.xcresult`, `/private/tmp/aqd-navigation-17.xcresult`, `/private/tmp/aqd-navigation-se-large.xcresult`, `/private/tmp/aqd-native-back-17.xcresult` and `/private/tmp/aqd-native-back-se-large.xcresult`. The two five-test bundles include the subsequently corrected Back-label test failure; the one-test bundles prove its final pass. Both review axes found no remaining source findings. SE was restored to normal text/light appearance for review after the stress test.

No hosted AQD project was provisioned; existing unrelated projects were preserved. Hosted organization/cost/region, SMTP, Apple credentials/team, launch legal/retention/deletion policy and marketing-image clearance remain owner gates. The development stack is real local Supabase, not a fake successful auth mode. Signing in does not publish a profile or wardrobe; the explicit connect command confirms an immutable local snapshot before ownership changes. General sync, full cloud media restoration and lifecycle deletion remain later slices.

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

## Tagged ancestor recovery review — October 2, 2026

Codex reviewed `b57fc15` and identified tagged A being skipped after successful B advanced the publication cursor. A tagged ancestor now runs existing-tag publication recovery without changing the cursor; untagged ancestors still skip safely. The regression verifies recovered A is eligible while the remote release cursor remains at C; an additional test verifies untagged ancestor skipping. All 38 tooling tests pass locally.

The review also claimed `queue: max` is unsupported. Current [GitHub workflow syntax](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#jobsjob_idconcurrency) explicitly documents the job concurrency queue property and its 100-pending-job bound. The finding is inapplicable; the supported native queue remains. Final-head CI/Codex and merge/release verification remain live gates.
