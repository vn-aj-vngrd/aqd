# Issue 21 acceptance evidence

S0–S4 source is committed through `e5de900123bbbad428639d48130545df7b2be624`. Local native checks used the owner's physical iPhone 17 Pro Max, iOS27.0.1/24A446, Xcode27.0/27A266a. No local simulator was started. UI cases use UUID-isolated stores and do not reset the owner's ordinary closet. Hosted CI and repository release are separate gates recorded on the PR.

## Scoped acceptance

| AC | Observed success and proof |
| --- | --- |
| E1 | Fresh Welcome, private explanation, persisted onboarding/tour/relaunch and real capture pass. [Compiled splash light/dark](launch/README.md), [Welcome](refinements/welcome.png). No artificial splash delay or wardrobe seeding. |
| E2 | Explore first bypass and Welcome tour leave preferences incomplete; returning launch preserves route. Passed EntryFlow fresh/bypass/relaunch case. |
| E3 | Seven explicit-answer/refusal steps, review/edit and two-goal limit pass. Height units/custom Unicode160 limit, keyboard, restart and consent pass. Invalid raw input blocks Save after restart, [invalid Review](refinements/invalid-review.png). |
| E4 | Same editor serves onboarding and actual Profile/Settings; successful/failed/unknown saves, draft cancellation and relaunch pass. [Onboarding receipt](refinements/saved-onboarding.png), [Settings receipt](refinements/saved-settings.png), [Profile receipt](refinements/saved-profile-dark.png), [actual empty Profile](refinements/actual-profile.png), [safe/destructive actions](refinements/discard-preferences.png). Explicit Open my closet persists main without inventing tour completion. |
| E5 | Today→Closet→Agent→Profile preview, Back, interruption, skip, replay, Ready and source returns pass. Examples stay inert and no pieces are inserted. [Today](refinements/tour-today-dark.png), [Closet](refinements/tour-closet-dark.png), [Agent](refinements/tour-agent-dark.png), [Profile](refinements/tour-profile-dark.png), [Ready](refinements/ready-dark.png). |
| E6 | Live23 canonical Paper states and five receipt/discard/logo references inspected; actual native light/dark screenshots inspected. Native X/check controls retain spoken labels and ink color. [Dark confirmation](refinements/discard-dark.png); reusable logo matches splash. Whole V1 and broad accessibility/device hardening remain #30. |

## Actual runs and reuse

[Machine-readable receipt](refinements/receipt.json) contains selected cases, source-input hashes, original image hashes and results. Code hashes from the five-case refresh match committed S4. Xcode project byte serialization differs without a semantic change. The retained image files are unchanged originals, inspected as AQD-only before publication.

- `final-issue-proof`, code `9f6e38a`: **Failed**, 17 passed/1 failed/0 skipped. A system `NotificationShortLookView` covered Done in the invalid-height case. The picker stayed open, so later parent-screen assertions failed. This is retained as a failure, not an18/18 pass.
- `final-affected-proof`, final S4 working inputs later committed as `e5de900`: **Passed**, 5/5, zero failures/skips. Repeats that failed case plus dark confirmation/Profile return, private explanation/capture discard, Settings Keep editing/discard/save/restart and cross-root cleanup. Header taps wait for system banners without reading their contents; screenshot guards require foreground AQD. Assertions remain intact.
- Unaffected application, Core and native-unit inputs/results from the base are explicitly reused. S4 changes two confirmation foreground colors and the UI-test interruption driver, with all affected consumers refreshed. This qualification is not a combined single-run18/18 claim.
- `final-appearance-proof`: **Passed**, 3/3, zero failures/skips. Actual dark rendering was inspected; an earlier dark-labelled run rendered light and is excluded from dark evidence. The guarded DEBUG-only test appearance does not change ordinary/Release appearance.
- Core **33 passed**, native **96 passed**, zero failures/skips, including preserving migration, atomicity, body validation and compiled launch rendering. Final logo/native run: `final-brand-native.xcresult`. S4 changes no Core/persistence/native-unit behavior.
- Unsigned generic iOS Release **BUILD SUCCEEDED** after S4 (`final-correction-release.log`). Exact staged S2 snapshot independently compiles (`s2-release.log`). Repository tooling **57 passed** before the documentation receipt.

XCTest reports an `Invalid frame dimension` runtime warning during invalid-height system-picker interaction. The case's input validation, disabled Save, explicit refusal and restart assertions pass after the banner guard. No negative/dynamic width calculation exists in the affected views; retain this diagnostic for #30's integrated platform investigation rather than claiming a warning-free run.

Only curated AQD images and redacted result metadata are published. Full interrupted physical bundles and any private notification/other-app captures stay excluded. The [plan](../../issue-21.md) retains earlier failures, fixes and slice history. Full fit journal, Settings data management and other app sections remain their own issues; these feature checks do not certify complete V1 or native distribution.

## Codex correction after publication

[S6 correction evidence](s6/README.md) supersedes the height-boundary behavior: genuine5-assertion RED then Core34/native96/focused physical1-of-1/Release pass. Current source inputs and built products are hash-bound there. Other feature results/images retain their original revisions and explicitly scoped reuse.
