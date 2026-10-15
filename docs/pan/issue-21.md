# Issue 21: Welcome, onboarding and tour

## Scope

- Issue: https://github.com/vn-aj-vngrd/aqd/issues/21
- Branch: `van/issue-21/welcome-onboarding-tour`
- Authorized endpoint: continue the established full `aqd-ship` lifecycle for this issue, including protected PR/CI/Codex, squash merge and repository release verification.
- Predecessor: #20 delivered by PR #31, squash `8b0688022f1876c85d000e4cc316c493fd35ac57`, repository release v1.1.1. Its PR/main CI and Codex passed.
- Baseline: clean `8b06880`; no inherited issue-21 application changes.
- Contracts: [section 01](../delivery/implementation-plan.md#01--welcome-onboarding-and-tour), [entry](../design/entry-identity.md), [personalization/PREF](../design/onboarding-personalization.md), [entry motion](../design/entry-motion.md), [source returns](../design/v1-flow.md#welcome-onboarding-and-tour-contract), scoped LOCAL-04/13/15.
- Local verification: physical iPhone 17 Pro Max only. Current discovery reports connected/paired, Developer Mode enabled, iOS27.0.1/24A446. The owner confirmed connected/unlocked readiness before the first run. All local simulators were shut down and verified to have zero booted devices. Repeat the readiness prompt if a lock/disconnection interrupts testing.

## Slices

| Slice | Working outcome and boundaries | Acceptance | Focused proof | State | Marker | SHA |
| --- | --- | --- | --- | --- | --- | --- |
| S0 | Local test entry points require the physical phone and preserve the device-ready prompt; hosted CI remains separate | Owner device instruction | Runner RED/GREEN, 57 tooling tests, docs checks; actual physical Core20/native84 passed | Committed | `AQD-Slice: #21/S0` | `64010ba` |
| S1 | Seven-step answers/refusals, review and atomic save work from actual Profile/Settings callers, with durable drafts and correct returns | E3/E4, PREF-01/02/03/07 | Validation/preserving migration/persistence/failure tests and focused physical save/cancel/relaunch | Committed | `AQD-Slice: #21/S1` | `eec38f0` |
| S2 | Fresh Welcome/private-start, questionnaire entry/bypass and preview-only tour persist route/completion, resume and replay | E1/E2/E5, onboarding PREF-02 | Core/native restart tests and focused physical entry/tour journeys | Committed | `AQD-Slice: #21/S2` | `08dc28969af74042a0f71fea848247b9d15f754d` |
| S3 | Optional height/units and transactional self-description picker preserve edits, explicit refusal and body-use consent | E3/E4, scoped PREF-04/05/07 | Unit round trips/graphemes, native failure recovery and physical keyboard/custom-description proof | Committed | `AQD-Slice: #21/S3` | `9f6e38a4ce3f72be28b2027e250778a839da4350` |
| S4 | Guard physical proof from system banners/non-AQD captures and pair confirmation text/fill contrast | E4/E6 | Five affected physical cases, retained base failures, inspected light/dark buttons and source review | Committed | `AQD-Slice: #21/S4` | `e5de900123bbbad428639d48130545df7b2be624` |
| S5 | Persist final feature proof, source/context/design ledgers and delivery receipt | E1–E6 | Actual source-bound outcomes, inspected media, docs/tooling checks and remote gates | Committed | `AQD-Slice: #21/S5` | `adf0385416f74c1dc9b97ce77179836e2d4bef97` |
| S6 | Carry displayed12in into next foot while preserving canonical cm | E3, Codex4284764022 | Core34/native96, physical height1/1, Release | Committed | `AQD-Slice: #21/S6` | `e0d1faab8290e9b80838d290ae2e972fdbffaedc` |
| S7 | Preserve positive display/units for tiny values and conversion underflow | E3, Codex4284964778 | Core35/native96, extended physical height1/1, Release | Verified | `AQD-Slice: #21/S7` | This correction commit |

## Acceptance and evidence

Code inspection sequences the reusable editor through working Profile/Settings callers first, then composes Welcome and tour around it. This keeps the same approved product scope while each slice delivers a complete usable route.

The issue uses prose Build/Prove clauses. E1–E6 below preserve those clauses as traceable groups; PREF/LOCAL scopes retain their original owners.

| AC / expected outcome | Slice | Required scenario/check | Observed result and artifacts | Status |
| --- | --- | --- | --- | --- |
| E1: splash has no imposed delay; fresh/returning/interrupted sessions resume actual local state without repeated onboarding/demo records | S2 | Fresh launch, private-start/explore, persisted relaunch and existing populated store | Fresh/returning/interrupted EntryFlow and real capture pass; compiled launch light/dark inspected. [Final evidence](evidence/issue-21/README.md) | Passed locally; publication pending |
| E2: pre-entry bypass stays outside the questionnaire and does not mark preferences complete | S2 | Welcome/private introduction, Explore first, returning launch | Fresh bypass/returning EntryFlow passes without fabricating preference completion. [Final evidence](evidence/issue-21/README.md) | Passed locally; publication pending |
| E3: seven numbered steps require explicit answers/refusals, keep body details optional/use off, validate review and support editing | S1/S3 | Substantive/mixed/all-declined/incomplete, goals limit, custom shape/over-limit, height units, accessible progress | Core33/native96 and focused body/style cases pass; failed invalid-height case refreshed successfully. [Final evidence](evidence/issue-21/README.md) | Passed locally; publication pending |
| E4: one preference editor serves actual onboarding/Profile/Settings callers; save/cancel/failure/unknown/restart preserve source, draft and prior saved values | S1/S2/S3 | Real callers, retained draft, dirty exit, same-operation retry/reconciliation and confirmed receipt | Onboarding/Profile/Settings save, cancel, failure, unknown acknowledgment and restart cases pass; source-aware receipts inspected. [Final evidence](evidence/issue-21/README.md) | Passed locally; publication pending |
| E5: Today/Closet/Agent/Profile tour supports Back/Next/Finish/Skip/replay, restores caller and inserts no records | S2 | Preview-only journey from Welcome/introduction and Settings, interruption/relaunch, actual record counts | Tour resume/Back/skip/replay/Ready and unchanged real record/draft assertions pass; all four preview images inspected. [Final evidence](evidence/issue-21/README.md) | Passed locally; publication pending |
| E6: owned Paper inventory/control returns, light/dark, native interaction and scoped privacy/capability limits are accounted for | S4 | Live Paper inspection; rendered physical evidence; unit/build/repository checks and independent review | Live Paper23 canonical states plus five owner refinements inspected; actual light/dark device media and source review pass. Broad matrix remains #30. [Final evidence](evidence/issue-21/README.md) | Passed locally; publication pending |

Owned canonical references: L172, L60, L61, L01, L152–154, L166–171, L173–177, L62–66. All 23 live Paper subtrees were fetched from the AQD iOS file on V1, token hash `fdeb7346`; exact JSX for Welcome, private introduction, tour Today and ready-to-begin was inspected for S1. Read remaining full question/picker content when implementing S2/S3. These references are states, not 23 independent destinations. Pending/unknown persistence references L149/L150 are shared recovery behavior.

Temporary-path references in historical S0/S1 receipts below identify the original observed run. Those `/tmp` artifacts disappeared after the later interruption; they are no longer retained. Tracked S1 images/receipt survive. Current durable local outputs are under ignored `build/issue-21/`. Only reviewed AQD-only images may be published; interrupted-run captures of another app remain local and excluded.

### S0 evidence

The old actual runner first failed the new expectations because it accepted a local simulator and forced physical signing off. The corrected runner refuses absent/local simulator destinations before tool discovery, requires the owner's readiness response and local signing, and requires explicit physical UI selections. Local proof and photo-seeding entry points also refuse simulator fallback. Hosting is explicit through `GITHUB_ACTIONS`; existing required CI remains on GitHub's machines.

`/tmp/aqd-issue21-device-runner-red.log` recorded the two genuine failures. `/tmp/aqd-issue21-device-guards-final.log` passes all nine runner scenarios. `/tmp/aqd-issue21-device-tooling-final.log` passes all 57 repository tests, zero failures/skips. `pnpm check:agents` and whitespace checks pass. Standards/Spec inspection of this bounded tooling/docs increment found no actionable defect; it changes no app behavior.

After the owner answered Ready now, the real runner used the discovered physical iOS destination and existing ignored local development signing. `/tmp/aqd-issue21-s0-native.log` records Core20 and native84 passed. `/tmp/aqd-issue21-s0-native.xcresult` and `-summary.json` confirm Passed84/failed0/skipped0 on physical iPhone17ProMax, iOS27.0.1/24A446. The summary tool initially could not write Xcode's report cache inside the sandbox; the same extraction succeeded with the required sandbox access. The native run itself exited0. These are baseline/unit checks, not issue21 UI acceptance. No simulator was started.

Preference export/restore/erase closure belongs to section09. Outfit ranking/model evaluation portions of PREF-05/06 require their real consuming sections and capability evidence before assistance is enabled; this issue creates no model feature or fabricated evaluation pass. Keep stored preference/context permission semantics explicit and verify the currently implemented seams.

### S1 implementation and retained failures

The shared seven-step editor now has real Profile More → Style and Settings → Style callers, explicit answers/refusals, review/edit, atomic save and durable caller/step restoration. Schema V3 adds a private local experience row through the existing preserving migration plan; populated V2 pieces, capture drafts, Today identities and media survive migration/reopen. Existing marked closets bypass future first-run entry; validated unmarked bootstrap windows remain fresh. No model, network call or sample wardrobe insertion is enabled.

The first native test build failed because the new public persistence API was absent (`/tmp/aqd-issue21-s1-native-red.log`). Initial sandboxed Swift-package attempts failed on compiler-cache access, not a behavior assertion; the elevated Core run passes24 tests. The physical native `-b` run passes after implementing the API; `-c` additionally passes the independent-draft mutation and pending-receipt regression checks. Exact final counts and source-qualified UI receipt will be recorded after the remaining checks.

Physical UI proof `-a` exposed an exclusive-access crash during answer selection and a Settings selector mismatch. The exported app diagnostics identify simultaneous access through `StyleEditorModel.draft` and the view's current page. Mutations now operate on an independent value. Proof `-b` reached later steps and exposed an outgoing choice view indexing the new body-details page; its diagnostics record Index out of range. Choice rendering now captures its immutable step. Proof `-c` passes the complete Profile answer/review/edit/save/relaunch case, while Settings selectors still failed because iOS exposes the disclosure as `Style, Edit preferences`. The next run uses that observed native label without changing outcome assertions. Those runs were failed, never accepted evidence; their temporary bundles are now unavailable.

The save receipt stays durable until explicit acknowledgment. A lost/unknown acknowledgment can check the same operation or resume its actual receipt after restart. Confirmed failures preserve both the draft and prior saved preferences. Advanced body units/custom-description UI and onboarding callers still belong to S2/S3; S1 does not claim those ACs.

### S1 qualified local gate

`/tmp/aqd-issue21-s1-native-final.log` and its `.xcresult`/summary pass Core24 and native89 with zero failures/skips on the physical phone. The later UI-only single-Back correction is compiled by the final acceptance run; store/Core/native test inputs are unchanged. `/tmp/aqd-issue21-s1-proof-g` passes every selected S1 case (4/4, zero failures/skips/expected failures) through the strict proof validator. The case manifest is `apps/ios/acceptance/issue-21-s1.txt`. [Four inspected original screenshots and source receipt](evidence/issue-21/s1/README.md) are tracked for later PR publication.

The earlier `-d`/`-final` failures retain native cancellation/transition evidence: iOS omits the popover Cancel row; a measured outside-header dismissal preserves input. Reopening waits for the actual Settings control to become hittable after native cover dismissal. `-f` passes all four cases, and `-g` refreshes all four after removing the duplicate trailing exit to match the documented single-Back pattern. No outcome assertion was removed. Error/reconciliation feedback appears before the review, with Retry/Check reachable in the docked footer.

Bounded Standards/Spec review covers the actual S1 Swift/UI/store/tests, preserving V1/V2 schemas, fault fixtures, source returns, matching Paper review/choice geometry and all four rendered states. Its selection/transition/exit findings are fixed; no unresolved finding remains in this slice. Onboarding, tour, custom description and units remain explicit later scope. Repository checks pass57 tooling tests and the agent-doc check (122 files/1542 local links at that check); whitespace passes. Xcode's project rewrite was verified semantically identical with parsed property lists and restored to avoid unrelated formatting changes. Publication and full independent issue review remain pending.

### Owner screen-completion correction · October15

The owner identified missing/inaccurate Section01 UI and prioritized preparing every screen before further tests. The earlier simplified tour previews are superseded even though their behavioral tests passed. Implement faithful read-only Today/Closet/Agent/Profile scenes, native chrome and positioned coach cards, Ready’s composition/roadmap/actions, the44pt splash wordmark and dark native Back chevrons. Inspect adjacent Profile design/actions only as needed for onboarding. The owner now requests splash → Welcome → onboarding → tour → Ready; acknowledged onboarding preferences therefore open the tour, replacing this issue’s earlier immediate-capture handoff. Explore/tour bypasses still retain honest unanswered preferences. Add’s empty-state trash is removed; an explicit retained-draft discard path remains available when content exists. Complete the remaining body inputs before restarting tests, then refresh affected proof and source/return contracts. Do not ship the earlier partial presentation.

### Section01 prepared-screen inventory

These are implemented source states, pending final rendered/device qualification. Earlier simplified tour screenshots are superseded. Native chrome adapts to the current iOS; brand tokens, imagery, hierarchy and actual source returns follow the approved reference.

| Paper state | Prepared implementation / real behavior | Focused proof owner |
| --- | --- | --- |
| L172 Splash | Compiled native launch storyboard and matching44pt opening surface; no timer | Native launch rendering + fresh-launch E1 |
| L60 Welcome | Twelve cached cutouts, first-arrival/reduced-motion handling, two working branches | Entry E1/E2 |
| L61 Private introduction | Exact illustrative composition, capture guidance, compact privacy note, Personalize/Tour/Explore | Entry E2/E4 |
| L01 Private explanation | Illustrative garment composition, truthful local/device-loss copy, real Add/Closet | Entry E1 |
| L152 Goals | Explicit max-two goals or exclusive No preference | Style E3 |
| L153 Occasions | Explicit multi-choice or exclusive No preference | Style E3 |
| L154 Style | Explicit multi-choice or exclusive No preference | Style E3 |
| L166 Fit & comfort | Explicit fit response and retained comfort text | Style + review-summary regression |
| L167 Body details | Optional cm/ft-in input, shape and purpose-specific use defaultOff | Body E3 |
| L168 Colors & patterns | Four retained preference/avoidance fields or explicit refusal | Style + labelled-summary regression |
| L169 Incomplete Review | Derived six-question count; missing/invalid draft disables Save | Body incomplete-review case |
| L170 Saved Goals | Same shared editor loaded from actual saved Profile/Settings preferences | Style E4 |
| L171 Native shape picker | Pending native selection with explicit Done/Cancel | Body E3/E4 |
| L173 Custom description | Durable inner multiline draft, live grapheme count, Use/Cancel | Body E3/E4 |
| L174 Answered Review | Exact answers, labelled preferences/avoidances and body-use state, atomic Save | Body/Style E3/E4 |
| L175 All-declined Review | Six explicit refusals; no substantive comfort hidden by All declined | Style + summary regression |
| L176 Over-limit description | Full161-character draft retained, associated error and disabled Use | Body over-limit E3 |
| L177 Confirmed save failure | Prior saved values and draft preserved, same-operation Retry | Body/Style/Entry E4 |
| L62 Today tour | Native Today chrome, look/week preview, dimmed background + coach card | Entry E5 |
| L63 Closet tour | Native Closet chrome, segmented/search/grid preview + coach card | Entry E5 |
| L64 Agent tour | Native task header, static prompts + coach card | Entry E5 |
| L65 Profile tour | Native Profile chrome, approved identity/journal images + coach card | Entry E5 |
| L66 Ready | Authored knit/trousers/loafers arrangement, roadmap, Add piece/Open Today and source-preserving Back | Entry E5 |

The real supporting Profile More → Style/Settings routes are implemented and tested separately from the inert Profile tour preview. Full profile/journal records remain section08. No preview controls perform writes. No export control is promised before section09 supplies it.

### S3 input and transaction boundaries

Height edits retain raw text in the durable preference draft, including invalid values, while storage normalizes valid measurements to centimeters and keeps the chosen display units. Switching units must preserve the canonical measurement exactly. Blank is optional; nonpositive, nonfinite or malformed input blocks that step even when a shape is selected.

The native body picker owns a pending selection. Custom description has a separate durable inner draft, live grapheme count and explicit Use/Cancel. Use returns to the pending picker; Done applies only to the preference draft. Picker Cancel preserves the prior preference value. Review Save remains the atomic saved-preference boundary. Editing/clearing never enables body-use consent; explicit refusal clears optional details and consent. Physical focused tests must inspect active-keyboard text/validation/footer and restart/cancel/save behavior.

### S2 evidence refresh after interruption

Before the interruption, physical S2 native checks passed Core27/native92 and the corrected focused proof passed all seven selected cases. Earlier UI attempts exposed incorrect test premises: empty native fields expose a nil value, and background navigation controls may remain in XCTest’s tree while a full-screen cover makes them non-hittable. Tests now verify empty values/disabled Save and actual interaction boundaries, with explicit presented-task Back identifiers. These corrections preserve the intended outcomes; complete VoiceOver qualification remains #30.

After the interruption, all `/tmp/aqd-*` bundles/logs were absent. Those historical runs were observed but their temporary artifacts cannot now be published or re-inspected. S1’s tracked screenshots/receipt remain available. New S2 outputs are retained under ignored `build/issue-21/`; a fresh physical run and inspected screenshots are required before the S2 local gate. The generic unsigned Release build and all27 Core tests passed again. Device discovery initially reported disconnection; the owner reconnected/unlocked the phone and confirmed readiness again before native verification resumed.

### Current complete-screen validation

The owner asked to prepare all Section01 screens before further tests; S2/S3 source was therefore prepared before restarting validation. `screens-native-a` passed Core32/native94 on the physical phone. `complete-screens-a` executed14 selected cases,10 passed and4 failed, zero skips. Three body cases passed exact height-unit/custom Use/Cancel/Done/160-limit, saved Settings relaunch and actual Profile failed-save/discard recovery. Its current tour/Ready scenes were inspected and match native chrome, approved imagery, dimmed preview backgrounds and coach-card placement. This run does not pass the full issue gate.

Failure captures show manual navigation/app switching during the run, including an explicit XCTest authorization interruption. They are excluded from publication because another app appears. No app defect is inferred from a missing control in another app. The owner reconfirmed the phone connected, then explicitly available to leave untouched for the final focused run. State-based waits were added before the actual Style menu item and capture Name field. All outcome assertions remain.

Independent Spec review found two actual review defects: omitted comfort and unlabelled preferred/avoided values, plus an incorrect All declined label with substantive comfort. The targeted Core test genuinely failed6 assertions before the correction and passes afterward. Ready’s Back also genuinely failed its original-Welcome source expectation; persisted `readyTourSource` corrects it. `screens-core-final` passes all33 Core tests. Added UI checks cover those summaries, incomplete Review with invalid raw height across restart, consent clearing, Ready Back and content-draft discard. A native rendering check now mounts the actual compiled launch storyboard in both appearances and verifies the44pt centered wordmark. Final native/rendered/Release results remain pending until observed.

## Deferred final verification

#30 retains broad integrated E2E, minimum/other-device OS coverage, complete VoiceOver/RTL/accessibility, physical media/protection/backup and performance qualification. Current feature UI proof must run on the owner's physical phone and cannot be waived into #30. No simulator may be launched locally to replace unavailable physical proof.

## Review and delivery

- Standards/Spec: independent full-issue Standards review and bounded recheck found no actionable defect. Spec found omitted comfort/unlabelled preferred-versus-avoided values and an inaccurate All declined claim; genuine RED reproduced6 assertions, corrected summary tests and all33 Core tests pass. Final rendered Spec recheck remains pending.
- Current check baseline: predecessor results belong to PR #31, not this feature.
- Current source changes: S0 policy is committed; S1 shared preference/editor/persistence code, tests, docs and qualified physical proof are committed as `eec38f0`; S2 entry/tour/logo is committed as `08dc289`; S3 body inputs/picker is committed as `9f6e38a`.
- Final receipt: persist actual slice SHAs and qualified evidence before the final gate head.

## Shipping

- PR locator: `vn-aj-vngrd/aqd`, head `van/issue-21/welcome-onboarding-tour`; resolve/reuse its single PR.
- Local feature gate: Passed with qualified unchanged-input reuse in [final evidence](evidence/issue-21/README.md). Published PR proof and current-head CI/Codex remain pending.
- GitHub owns actual current-head CI/Codex/thread/merge/release state.

## Resume

- Current phase: S0–S6 committed; S7 positive-height precision correction is verified and ready to commit.
- PR: https://github.com/vn-aj-vngrd/aqd/pull/33. Previous head `e0d1faab8290e9b80838d290ae2e972fdbffaedc`; final correction source bound by [exact hashes](evidence/issue-21/s7/receipt.json).
- Next action: commit/push S7, publish/read back proof, resolve Codex4284964778, request one current-head review, wait for CI/Codex, then protected squash/release. Do not start another issue.
- Local gate: Core35/native96, extended focused height1/1 and final Release pass. Earlier base/refresh/appearance results retain their own identity and qualified reuse.
- External blocker: none confirmed. Physical phone stayed available, and local simulators remain shut down.

### Owner correction: actual screens and native confirmations

Owner reported old-looking automated screens, unfinished actual Profile and a source-anchored discard pointer. The actual Profile was still placeholder text while its tour preview used the approved journal composition. Replace that root with the neutral private identity/header and empty fit area, without fake photos/counts or claiming the future journal implementation. Replace preference/capture discard dialogs with centered native alerts and explicit safe cancellation. Nested editor headers use accessible X/checkmark icons; primary Save/Use actions keep their labels.

The prior `complete-screens-final` run was interrupted when pausing for this correction and is not an accepted full batch. Earlier passes remain historical evidence only. Refresh changed screens from a fresh derived-data directory, inspect a short current-screen proof before the full selection, and record the executable hash. The installed-build procedure is now routed from AGENTS.md to acceptance-proof.md. Do not attribute old screens to test fixtures without verifying the actual rendered destination.

Correction check: fresh generic unsigned Release build passed in `build/issue-21/release-ui-correction` after the Profile/icon/alert edits; log `release-ui-correction.log`. Documentation check passed (124 Markdown files, 1555 local links, 288 fragments); `git diff --check` passed. These are compilation/documentation checks, not installed-device acceptance. The focused refresh selection is `apps/ios/acceptance/issue-21-ui-correction.txt`; physical execution awaits renewed readiness after pausing the prior run.

### Saved receipt refinement and semantic confirmation colors

The first correction proof passed 4/4 physical cases with zero failures/skips in `build/issue-21/ui-correction-proof`; it proves the X/check controls and updated actual Profile. Its gray native alert presentation and previous saved receipt were superseded at the owner’s request, so those images are not current acceptance.

Defined and inspected Paper first: `13A6-0` onboarding saved, `13B8-0` Profile return, `13C6-0` Settings return, `13D4-0` native discard sheet. Fixed the confirmation’s wrapping/background in Paper before completion. Native saved receipts reuse existing EntryIllustration and Welcome action patterns. Take the tour retains the agreed sequence; Open my closet acknowledges the receipt and persists main entry without fabricating tour completion. New native persistence and focused UI tests cover that route. The X/check controls remain accessible, and actual Profile has a neutral identity plus truthful empty fits presentation; its full journal remains section08.

The owner rejected gray alert backgrounds. Final confirmation is a native sheet with standard bordered-prominent capsule buttons: Keep editing in AQD accent blue, Discard draft in danger red, system-owned interaction, scrolling/accessibility expansion and no pointing popover. Prior “centered alert” notes above are historical, superseded by this refinement. Current proof refresh selection is six cases in `issue-21-ui-correction.txt`. Source and artifact qualification remain pending while the refreshed native run executes.

### Final owner wrap-up and logo

Owner requested final slice commits and the splash wordmark as the MVP logo. `AQDWordmark` now shares the exact 44-point regular system font/-1.1 tracking across opening, Welcome and saved receipts. Paper wordmarks were updated first and the icon reference `13EP-0` inspected. Added an opaque 1024px AppIcon using the same system typography and splash colors, generated locally by `scripts/render-ios-wordmark.swift`; iOS owns the icon mask. This is part of S2’s complete entry presentation, not a separate branding project.

Observed before the logo-only final refresh: Core33/native96 passed; receipt refinement cases5/6 passed, with the failed picker capture showing AQD out of foreground. Only inspected AQD-only files are tracked in [refinement evidence](evidence/issue-21/refinements/README.md). Refreshed picker plus cross-root cleanup passed2/2, zero failures/skips (`receipt-refresh-proof`), preserving their assertions and adding an explicit native-picker dismissal wait. Source review rechecked receipt atomicity, contextual returns and semantic confirmation buttons with no actionable findings. Final logo native run passed96 again; the three-case final brand/owned-dark proof is running before commits. Broad #30 remains separate.

S2/S3 sources were prepared together at the owner’s request. Shared files are staged by their actual ownership: S2 entry/tour/saved routes/logo/native confirmations retain S1’s body implementation in the index; S3 replaces that body editor with the verified raw-input/picker transaction. This keeps each commit buildable and reviewable while retaining the final integrated working source. Evidence records identify that integrated source instead of claiming a pre-existing SHA for it.

Final visual correction: the first dark-labelled proof actually rendered light because iOS ignored the launch preference. It is not dark proof. Added a DEBUG-only appearance override guarded by both the UI-testing argument and a valid isolated-store UUID; ordinary/Release runs remain system appearance. `final-appearance-proof` then passed3/3 with actual dark screenshots inspected for the picker, saved receipt and Profile tour. The refreshed light saved screen uses the shared 44pt logo. `receipt-refresh-proof` passed2/2 for the interrupted custom picker and retained cleanup. These are local physical results, not PR/CI publication.

The new resource documentation initially duplicated Tour’s README.md in the flattened Release bundle. Renamed it EntryAssets.md; final Release compilation is refreshed after this packaging correction. No source workaround or missing resource is waived.

S2 exact staged snapshot Release build passed in `build/issue-21/s2-release.log` after separating the shared files from S3. This independently compiles entry/tour/receipt/logo/confirmation code with the existing S1 body editor. Integrated physical checks are recorded separately above; they do not claim to have run against an unstated intermediate commit. S2 is ready for its scoped commit.

S2 committed as `08dc28969af74042a0f71fea848247b9d15f754d` (`feat(onboarding): Complete private entry and guided tour`). S3 now stages only body input validation/persistence, transactional picker and their tests plus the full issue manifest. The existing S2 source remains intact. S3 integrated Core33/native96 and physical body/keyboard/cancel/restart cases above passed; true dark picker and saved return also passed in final-appearance-proof. Hook checks passed57 tooling tests.

S3 committed as `9f6e38a4ce3f72be28b2027e250778a839da4350`. Final integrated unsigned Release build passed (`final-release-refresh.log`), including the app icon and guarded test-appearance hook. Xcode project serialization was compared as parsed property lists and restored to the committed byte form, preserving the two intentional AppIcon build settings. The complete 18-case feature selection now refreshes against this code SHA; broader #30 remains excluded. S4 holds final source/evidence/docs qualification and remote publication.

Final contrast correction, tied to S2/S3: the native discard buttons now explicitly use the existing paired on-accent foreground with their blue/red fills, including dark appearance. The running18-case proof still binds to committed `9f6e38a`, whose app binary was built before this two-label color correction. Refresh the affected dark confirmation and light capture/Keep editing cases afterward; do not relabel the running base proof as testing the correction. The dark body case also checks safe cancellation and retained saved answer at the new confirmation. No rules/storage/entry behavior changed.

Concrete device-interruption cause: final-issue-proof’s invalid-height case logged `BannerNotification`/`NotificationShortLookView` over the header, then a Done tap while that interruption was active. The body picker stayed open and subsequent hidden-body actions had hit point{-1,-1}; this is not a successful consent/save check. Earlier non-AQD failure captures can result from the notification tap, not owner navigation. Add a shared test guard that waits for banners to clear without reading their text and requires foreground AQD before header taps/screenshots. Keep the unchanged behavioral assertions, wait for picker dismissal, and refresh affected cases. The currently running base run remains bound to its original source.

S4 affected proof passed5/5, zero failures/skips in `final-affected-proof`, preserving the invalid-height, refusal/consent, Keep editing, capture discard and cleanup assertions. Inspected actual dark/light confirmation colors and disabled invalid Review. Source Standards recheck found no actionable finding. Base `final-issue-proof` remains17 passed/1 failed due to the documented notification interruption; it is never relabelled Passed. Refresh covers the failed case and all consumers affected by the tiny confirmation-color/shared-driver change. All other application/Core/native-unit inputs and expected outcomes are unchanged and their scoped results are reused explicitly. Final correction Release build passed in `final-correction-release.log`.

S4 committed as `e5de900123bbbad428639d48130545df7b2be624`. S5 replaces superseded saved-screen media with inspected current44pt-logo receipts, all four tour previews, Ready, actual Profile and light/dark discard evidence. [Final acceptance receipt](evidence/issue-21/README.md) owns actual17/1 base and5/5 refresh qualification; it does not relabel the failed batch. Final docs/tooling review and remote publication follow.

Final S5 checks pass57 repository tests and agent docs126Markdown/1597links/288fragments. Independent Spec review found no defect; Standards found a stale centered-alert sentence, now replaced with the current native-sheet contract. AQD was launched normally on the phone after tests with no fixture arguments; ordinary data was preserved.

### S6 Codex height-conversion correction

PR [#33](https://github.com/vn-aj-vngrd/aqd/pull/33), published head `adf0385416f74c1dc9b97ce77179836e2d4bef97`. Codex finding [4284764022](https://github.com/vn-aj-vngrd/aqd/pull/33#discussion_r4284764022) identifies a valid cm value just below a whole-foot boundary formatting as12in, disabling unit switching. Preserve canonical cm and normalize displayed12in into the next foot. Test the existing approved public HeightInput seam first, then refresh affected Core/native/height E2E and Release. This correction belongs to S3; final-head CI/Codex must refresh. Marker `AQD-Slice: #21/S6`, state in progress.

S6 checks: real RED5 assertions, full Core34 green, physical native96 passed, focused height journey1/1 passed with original boundary/Review screenshots inspected. Final Release builds, tooling57 and docs checks pass. Standards/Spec bounded reviews found no actionable defect. [Correction evidence](evidence/issue-21/s6/README.md) retains current exact input/product hashes. Unaffected source/results and media remain explicitly reused at their own revisions. Commit this S3 correction with `AQD-Slice: #21/S6`, refresh PR proof, resolve only the addressed finding, then wait for new-head CI/Codex before protected merge.

### S7 positive-height precision correction

Codex4284964778 on head `e0d1faa` identifies accepted tiny positive cm formatting to zero and blocking unit switching. Correct the formatter's nonzero-value invariant, including positive floating-point conversion underflow, while retaining canonical cm and ordinary display. Existing approved HeightInput public seam supplies RED/GREEN and the focused physical height journey gains the exact decimal regression. Marker `AQD-Slice: #21/S7`, in progress; required current-head remote gates refresh after the correction.

S7 final checks pass Core35/native96, focused physical1/1, Release, tooling57 and agent docs. [Proof](evidence/issue-21/s7/README.md) retains RED20, exact input/product hashes and inspected original screenshot. Extended physical case also refreshes S6 and ordinary height/save behavior. Source Standards/Spec reviews are clear. Commit/push S7, resolve the addressed thread and refresh final-head CI/Codex.
