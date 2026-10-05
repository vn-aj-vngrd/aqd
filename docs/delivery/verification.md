# Current verification

## Release evidence

The current checkout has no tracked iOS app/build baseline. Historical build and simulator results cannot be reproduced from tracked source here. V1 native/local durability/model/accessibility/distribution checks remain unverified. V2 additionally needs live identity/sync/social/security/operating evidence; those connected gates do not block the V1 device-only architecture.

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

## Tagged ancestor recovery review — October 2, 2026

Codex reviewed `b57fc15` and identified tagged A being skipped after successful B advanced the publication cursor. A tagged ancestor now runs existing-tag publication recovery without changing the cursor; untagged ancestors still skip safely. The regression verifies recovered A is eligible while the remote release cursor remains at C; an additional test verifies untagged ancestor skipping. All 38 tooling tests pass locally.

The review also claimed `queue: max` is unsupported. Current [GitHub workflow syntax](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#jobsjob_idconcurrency) explicitly documents the job concurrency queue property and its 100-pending-job bound. The finding is inapplicable; the supported native queue remains. Final-head CI/Codex and merge/release verification remain live gates.

## V1/V2 planning and Paper refactor — October 5, 2026

Branch: van/v1-v2-product-plan, based on cf923a05001215aa60625b2d1f5bc3252df7e628. Scope: product/architecture/design/backlog documentation and live static Paper only. No app source, provider provisioning, production code, backend deployment or distribution was added.

V1 Paper now has 74 local phone references across ten numbered flow sections, with V2-style Welcome, private onboarding, Back/Next/Finish/Skip tour and Settings replay, complete Home/Closet/Agent/local Profile/Settings, private themes/plans/routines/trips/wear, verified-local rich-input requirements and recovery/appearance. V2 retains every original canonical reference and connected review, plus seven expansion requirement boards. The web file labels connected landing/admin V2 and adds a shared phase-boundary board.

Static screenshots reviewed welcome/onboarding/tour, navigation, local Profile/Settings/data recovery, core wardrobe/planning/Agent states, dark variants, keyboard/voice permission/listen/transcribe/review/fallback/context and expansion boards. Paragraph wrapping, native labels, dark icon/control contrast, theme navigation and exact local-data copy were corrected. Paper does not prove native focus, Dynamic Type/VoiceOver, interaction wiring, model quality, local persistence or connected services. Extension requirements are prepared, not all final platform/provider layouts.

The final Welcome refinement replaces the stock/lifestyle collage with twelve original AI-generated unbranded garment cutouts, preserved source/provenance/atlas coordinates, synchronized V1/V2/review heroes and a page-00 gather/form/settle storyboard (0/520/1,200 ms). Dark photographic ground preserves garment visibility; Reduce Motion uses the settled frame. These are static design/motion requirements; no working animation or native performance proof is claimed.

Validation and two-perspective review findings are recorded below. All LOCAL acceptance and connected-service acceptance remain future implementation evidence.

The iOS Paper file has exactly three pages in order: Foundations, V1 and V2, with 28/85/238 artboards (351 total). V1 is grouped into ten flows with 74 local phone references. All 201 original canonical screen IDs and node IDs remain in V2; the full backlog retains all fifteen deferred feature families and their design requirements. Foundations component masters remain unchanged by the page consolidation and navigation repair.

The final static layout pass corrected all 50 phone bottom bars, their 50 viewports/home indicators and 236 tab slots. Each bar now has consistent side/bottom insets and equal-width centered destinations; fourteen obsolete footer wrappers are hidden. The empty V1 Home now uses all four V1 destinations. Reviewed screenshots cover tour Home/Closet, empty Home, Planner, local Profile, dark Home and V2 Planner/Profile. Tour controls finish above the bars. V1 Planner selection also fixes four weekday/date text nodes: selected accent text has 6.00:1 contrast on its soft fill, and unselected secondary text has 4.75:1 contrast on the light background. These measurements concern the static reference colors, not native accessibility acceptance.

Local validation: 38 repository tooling tests passed on Node 24.20.0; all 512 tracked Markdown links/anchors resolve and every documentation page is reachable from the indexes. JSON/Excalidraw parsing, retained acceptance/screen IDs, planning-only file scope and whitespace checks passed. Two-perspective review findings about stale Agent navigation and backlog page labels were resolved. The manifests record current page membership, Welcome provenance/motion and the bottom-navigation review. No native build, interaction, animation performance, local durability, Apple capability or connected-service result is claimed.
