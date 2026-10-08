# Current verification

## Release evidence

PR #5 was protected-squash merged to `cccdc24` on October 7, 2026 after latest-head Codex clearance and required CI. Exact merged-main [CI37683970487](https://github.com/vn-aj-vngrd/aqd/actions/runs/37683970487) and [Release37684034501](https://github.com/vn-aj-vngrd/aqd/actions/runs/37684034501) passed; published non-draft `v1.0.1`, `origin/main` and publication cursor matched that SHA. Reviewed and merged trees matched. Repository release does not certify the native app.

October 8 native baseline is **uncommitted working-tree evidence** on `van/issue-7/native-v1-baseline` from `cccdc24`, tracked by [#7](https://github.com/vn-aj-vngrd/aqd/issues/7) under full-V1 [#6](https://github.com/vn-aj-vngrd/aqd/issues/6). Xcode26.5 build17F42 / Swift6.3.2 / iOS26.5 iPhone17Pro Simulator `E5DAD2A0-6375-4737-B33D-3A08A4D9FDAA` are the observed environment, not SDK27/device certification. No new Paper inspection is claimed.

| Scope | Result | Evidence / limitation |
| --- | --- | --- |
| Source/build baseline | Build passed; delivery incomplete | Working-tree `apps/ios/AQD.xcodeproj`, shared AQD scheme, AQD app, Core package and tests exist. Unsigned Debug simulator build of the current capture/Closet/native-root UI passed (`/tmp/aqd-ui-build.log`). Source is not yet committed/reviewed; build success is not navigation or full V1 acceptance. |
| Initial piece persistence checkpoint | Focused native pass; expansion rerun pending | Actual SwiftData save/reopen with stable identity/photo, same-operation retry after reopening, and read-only database save failure with prior-record preservation passed3 SwiftTesting tests. Result `/tmp/aqd-native-red-derived/Logs/Test/Test-AQD-2026.10.08_11-56-21-+0800.xcresult`. This predates later draft/metadata/search/edit/delete expansion; latest expanded tests/cleanup need rerun. Store reopening is not a process-kill or physical-device durability test. |
| Initial capture validation/import gate | Focused host pass; expansion rerun pending | `swift test --package-path apps/ios/Core` passed5 tests for photo/name/category/80-character prerequisites and cancelled import preserving prior photo/metadata. Genuine failing expectations were observed before fixes. Subsequent identity-gate/metadata expansion needs fresh full checks. Host tests are not native database/media/runtime evidence. |
| Expanded baseline persistence/photo tests | Scoped native pass | Main rerun passed23 SwiftTesting tests in2 suites, including parameterized8 EXIF orientations, protected original/thumbnail bytes, metadata/draft/search/edit/archive/delete/reopen, invalid/newer/corrupt-store refusal, stable operation conflicts and reference-safe deletion with pending cleanup/reopen retry. Read-only/corrupt fixtures produced expected OS failure diagnostics. `/tmp/aqd-unit-final-derived/Logs/Test/Test-AQD-2026.10.08_19-35-52-+0800.xcresult`. This predates reversible photo-editor changes and needs a latest-source rerun. No all-domain deletion/archive/device claim. |
| Native root/cancel/relaunch UI | Scoped rendered pass |3 public XCTest UI tests passed, zero skips, on iPhone17Pro/iOS26.5. Actual tab labels/selected traits/≥44-point targets; Agent full-screen Back→Closet; source-sheet Close, missing-photo disabled Save, Shoes selection and retained draft after app terminate/relaunch. Parent inspected exported Today/capture screenshots; native tab icons have no visible titles and source-sheet cancellation retains entered values. `/tmp/aqd-native-ui-1.xcresult`, attachments `/tmp/aqd-native-ui-attachments/`. No photo-selection/save/edit E2E or VoiceOver-run proof yet. |
| Latest baseline runner | Scoped pass | `IOS_DERIVED_DATA=/tmp/aqd-baseline-final ./scripts/test-ios.sh` passed20 Core tests/4 suites,30 native tests/3 suites and5 public UI tests, zero skips, at20:40 on October8. Includes real PhotosPicker with synthetic asymmetric pixels, explicit crop/rotation/reset/cancel and draft-only Use, save receipt, Closet query, metadata edit and process relaunch; native tests include immutable originals/recipes/derivatives, stock Today identities after read-only reopen and queued deletion cleanup restart without vanished UI operation state. `/tmp/aqd-baseline-final/Logs/Test/Run-AQD-2026.10.08_20-40-51-+0800.xcresult`. No whole LOCAL/TODAY/PREF/J IDs, SDK27 or device/media-quality result. |
| Crop preview output regression | Genuine UI RED→GREEN | Screenshot review found preview double-centering/offset of an oversized crop image despite a previously passing gesture test. Reused the same rotation pixel renderer and anchored viewport top-left. Added public screenshot landmark comparison against accepted rendition: `/tmp/aqd-crop-preview-red.log` failed for missing fixture landmark; `/tmp/aqd-crop-preview-green.log` passed the actual PhotosPicker/editor/save/search/edit/relaunch case. Synthetic pixels are not garment-quality evidence. The latest preview changes are newer than the full runner above; affected end-to-end case passed. |
| Baseline standards/spec recovery fixes | Native rerun passed; final review pending | Independent reviewers inspected all37 staged files against `cccdc24` and #7; both found competing edit drafts and abandoned private media. Edit→leave→reopen genuinely failed (`/tmp/aqd-edit-reopen-red.log`) before item-specific draft/operation recovery. Durable cleanup now stages source/recipe candidates before writes and with relinquished references, independently preserves live original/recipe owners and retries after reopen. Latest full runner on iPhone16Pro/iOS18.1 passed20 Core,37 native and5 UI tests, zero skips: `/tmp/aqd-review-fixes-green2/Logs/Test/Run-AQD-2026.10.08_21-49-20-+0800.xcresult`. Includes prior-schema piece/draft/media/Today identity preservation, failed staging, shared-source abandoned derivatives, reentry/save and source-associated deletion Cancel. Parent inspected exported decision/relaunch screenshots in `/tmp/aqd-review-fixes-attachments/`. Cleanup runtime RED was not evidenced; its regression tests passed after implementation. Two earlier reruns failed due to blind downward test gesture dismissing the task and noncanonical migration-fixture encoding; both were corrected without weakening assertions. Unsigned Release simulator build also passed `/tmp/aqd-review-release.log`; build is not runtime acceptance. No whole acceptance/device/SDK27 claim; final corrected-diff reviews pending. |
| PR #9 fifth Codex/receipt presentation pass · October9 | Locally corrected/reviewed; latest-head gates pending | Hostedd537 nativeCI37855597740 passed Core20/native55 (including all original-byte bootstrap assertions); Photos UI test failed at identifier lookup, while exported actual screenshot `/tmp/aqd-ci-round4-attachments/ECF894FC-5EDB-4297-B26F-CE70215F3671.png` clearly shows the real picker and seeded thumbnail. Test now selects only a screenshot-confirmed white-circle/four-blue/red/yellow fixture pattern using public coordinates, with accessible-image fallback; no guessed coordinates/media hook/crop0.06 weakening. Standalone actual-PNG positive and blank/recovery-alert negative checks `/tmp/aqd-picker-pattern.swift` passed. Codex crash-gap finding: commit removed draft/op before receipt presentation. Genuine native56 RED `/tmp/aqd-pending-receipt-red.log` six runtime issues → read-only exact recovery GREEN. Frozen schema2 reused: Capture opts into atomic pending draft/proof; explicit receipt Back/Open acknowledges and queues media release/removes link atomically; failed acknowledgment stays visible, corrupt/deleted proof refused, newer records never rewound, historical retry never recreates links. Legacy store-call return acknowledgment remains unchanged. Current full **20 Core/61 native/7 UI**, zero skips: `/tmp/aqd-codex-round5-ios18.log`, `/tmp/aqd-codex-round5-ios26.log`; both exercised verified picker-coordinate branch and process-relaunch→exact edit receipt→Back acknowledgment.61 is actual SwiftTesting method count, not worker75 parameter-instance estimate. Focused `/tmp/aqd-pending-receipt-picker-green-final.log`, Release `/tmp/aqd-codex-round5-release.log`, tooling38 `/tmp/aqd-codex-round5-tooling.log` passed. Recovered receipt screenshot `/tmp/aqd-receipt-round5-attachments/3D14D384-D7E0-4893-9927-4546C5D6CEB7.png` inspected; scrollable content/safe-area action and native Back present. Both independent final-delta Standards/Spec passed. Earlier UI expectation of immediate mutable Edit after unacknowledged process exit was updated to the intentional recovered receipt flow; no new behavioral RED claim for that obsolete assertion. Latest-head hostedCI/Codex/protected delivery pending; full#6/SDK27/physical gates unchanged. |
| PR #9 fourth Codex/hosted preservation pass · October9 | Locally corrected/reviewed; fresh remote gate pending | Native CI37850554602 on `f1531be` passed Core20 and UI7, including settled-preview/archived-edit checks, but native54 failed DB/WAL byte assertions for unmarked invalid-Today fixture6 on hosted26.6. Underlying framework checkpoint versus fixture lifetime causality is not proven. Conservative bootstrap inspection now copies exact DB/WAL into protected, backup-excluded transient storage before any CoreData/ModelContainer inspection; same exact-schema/row checks, 32MiB combined bound, no-follow/nonregular guards and cleanup attempts remain. Original preservation assertions are unchanged. New Codex fixes preserve active draft-save errors through import nil/cancel (genuine55native RED `/tmp/aqd-import-draft-refusal-red.log` → GREEN `/tmp/aqd-import-bootstrap-green.log`), and denied Camera offers public Open Settings while restricted status has truthful separate Photos/Keep recovery. Current full runners **20 Core/55 native/7 UI**, zero skips: `/tmp/aqd-codex-round4-ios18.log`, `/tmp/aqd-codex-round4-ios26.log`; Release `/tmp/aqd-codex-round4-release.log`, tooling38 `/tmp/aqd-codex-round4-tooling.log` passed. Both independent corrected-delta Standards/Spec reviews passed. Camera/Settings hardware transitions, concurrent external checkpoint/copy stress and persistent transient cleanup failure are not demonstrated; no simulator camera or causal claim fabricated. Latest-head remote CI/Codex and protected delivery remain pending; whole V1/SDK27/device acceptance unpassed. |
| PR #9 third Codex pass · October9 | Corrected/reviewed locally; final-head remote gates pending | Hosted native CI37845200785 on `3f018a8` passed Core20/native52 but captured the explicitly stale Preparing preview image before asynchronous rotation completed, causing a landmark mismatch. Actual exported artifacts show old red-top-left preview versus correct red-top-right accepted crop; the test now waits for public Use photo enabled before screenshot, preserving0.06 tolerance and missing-landmark checks. Two new Codex P2s fixed: successful Keep retry clears only draft-persistence failure, retaining unrelated import/save messages; collection refresh identity updates archived details and Restore revisions even when the active array is unchanged. Genuine RED `/tmp/aqd-draft-retry-message-red.log`53native and `/tmp/aqd-archived-detail-red.log` public flow preceded fixes; focused GREEN passed54native/UI1 `/tmp/aqd-codex-round3-focused-green.log`. Current full18.1 `/tmp/aqd-codex-round3-ios18.log` and26.5 `/tmp/aqd-codex-round3-ios26.log` both passed **20 Core/54 native/7 UI**, zero skips; unsigned Release `/tmp/aqd-codex-round3-release.log` and tooling38 `/tmp/aqd-codex-round3-tooling.log` passed. Isolated model initializer avoids ordinary closet access; unrelated-error guard added after implementation, no RED claim. Both independent corrected-delta Standards/Spec reviews passed. Fresh final-head CI/Codex/thread/protected delivery pending; full-V1/SDK27/device acceptance unchanged. |
| PR #9 second Codex pass · October9 | Corrected/reviewed locally; final-head remote gates pending | Native CI37836971423 and repository CI37836971537 passed `97dc74c` (hosted Xcode26.6: Core20/native48/UI6), but that Codex pass found four remaining cases. Current fixes safely finish only exact-current-schema empty/stock-Today bootstrap crash windows using public CoreData compatibility plus read-only inspection, preserve committed owner/widget IDs, and refuse foreign/populated/corrupt unmarked stores. Fit Original creates no unused edit copies; exact known legacy Fit paths are pruned without touching originals, required rotated/cropped recipes or unknown files. Recovery failures now show a native root alert; the malformed-payload fixture is real native data, DEBUG-only and UUID-store isolated. Explicit receipt Open Closet selects Pieces; ordinary Back retains prior scope/query/filters. Genuine runtime RED preceded fixes: bootstrap `/tmp/aqd-bootstrap-red.log`, Fit `/tmp/aqd-fit-storage-red.log`, receipt scope `/tmp/aqd-saved-piece-scope-red.log`, alert `/tmp/aqd-bootstrap-green-alert-red.log`. A safety-fixture mistake and the SDK method rename build error were corrected, not claimed as behavioral RED. Read-only SQLite changes only volatile SHM reader bookkeeping; negative cases assert unchanged authoritative DB/WAL/marker/media. Current full runners passed **20 Core/52 native/7 UI**, zero skips, on18.1 `/tmp/aqd-codex-round2-ios18.log` and26.5 `/tmp/aqd-codex-round2-ios26.log`; Release build passed `/tmp/aqd-codex-round2-release.log`. Exported native recovery-alert screenshot inspected. Both independent corrected-delta Standards/Spec reviews passed. Legacy Fit safety regression added after implementation; no RED claim for it. Latest final-head CI/Codex/thread/protected delivery still pending; no whole-V1/SDK27/device claim. |
| PR #9 Codex/native-CI follow-ups · October9 | Locally corrected/reviewed; fresh remote gates pending | PR head `a33c9f3` first [native CI37830146469](https://github.com/vn-aj-vngrd/aqd/actions/runs/37830146469) passed Core20/native40 but failed crop landmark comparison on hosted Xcode26.6. Captured artifacts proved blue-color bounds were truncated by blurred chrome; actual approved portrait viewport landmark Y matched `.53921/.53944`. The corrected test crops the centered240×320 preview from its wider accessibility wrapper, compares the168×224 accepted viewport, retains the0.06 tolerance/missing-landmark checks and saves individual viewport attachments. Codex's two valid P1s are fixed: Add recovers creation-only drafts without consuming saved-item edits; completed receipts retain exact retry proof but do not own superseded media. Replacement stages old source/recipe candidates atomically; current records/drafts retain shared media/Reset sources. Genuine Add→Edit UI RED `/tmp/aqd-add-new-draft-red.log` preceded the fix. Current full iOS26.5 runner passed20 Core/48 native/6 UI, zero skips (`/tmp/aqd-codex-fixes-ios26.log`); iOS18.1 UI6 passed in `/tmp/aqd-codex-fixes-ios18.log`, then corrected native fixture passed48 in `/tmp/aqd-codex-native-green.log` (the earlier combined log failed a fixture that accepted unowned replacement media before cleanup). Final Release build passed `/tmp/aqd-codex-release-final.log`. Both independent bounded Standards/Spec reviews passed against `a33c9f3`; fresh latest-head remote CI/Codex/thread gates remain pending. No full V1/SDK27/device claim. |
| Final baseline source · October9 | Scoped native/UI/Release and final reviews passed; protected delivery pending | Latest same-source full runners passed20 Core,40 native and6 UI tests on iOS18.1 and26.5, zero skips: `/tmp/aqd-baseline-delete-final/Logs/Test/Run-AQD-2026.10.09_02-59-31-+0800.xcresult` and `/tmp/aqd-baseline-delete-ios26/Logs/Test/Run-AQD-2026.10.09_03-03-58-+0800.xcresult`. Final unsigned Release build passed `/tmp/aqd-baseline-release-final.log`. Full37-file Spec review passed; full Standards review found shared archive/delete operation state, fixed with immutable reviewed snapshot/operation/submitted state and cancellation of unsubmitted reviews. Independent final three-file Standards and Spec reviews passed. Native UI now covers outside-dismiss→archive→Undo→fresh reviewed delete, preserving surviving Closet search/filters; explicit receipt Open Closet clears only the detail path. Earlier new-regression runs failed at receipt return and repeated-query test setup before reaching deletion; no delete-runtime RED is claimed. All prior review findings addressed. Latest-head remote CI/Codex, protected merge and merged-SHA release remain pending; full V1/SDK27/device acceptance remains incomplete. |
| Second review recovery/filter/editor fixes · October9 | Scoped native/UI pass; subsequent final review result above | Both final-diff reviews found retained edits could become stale after archive/restore with no usable discard path; Spec also found availability/recently-added controls missing and dirty framing exits unprotected. Added explicit reviewed draft discard (prior saved record retained), reason-specific stale status, combined availability/category/archive/query and deterministic name/creation-time sorting, and dirty editor Back→Discard edits/Cancel with interactive dismissal blocked while dirty/applying. Native runner passed20 Core and40 native tests (`/tmp/aqd-baseline-round2-final.log`); corrected command-selection query then passed all6 public UI tests, zero skips (`/tmp/aqd-baseline-round2-ui-final.log`, `/tmp/aqd-baseline-round2-final/Logs/Test/Test-AQD-2026.10.09_02-38-14-+0800.xcresult`). Includes actual edit→archive→Undo→stale Save→cancel discard→reviewed discard→fresh successful edit, provisional framing cancellation, and availability/sort empty states. Test failures from insertion-cursor assumptions and ambiguous native command labels were repaired without removing retention assertions. Cleanup/filter runtime RED is not claimed. Repository tooling38/38 passed `/tmp/aqd-baseline-round2-tooling.log`; corrected final-source reviews remain pending. |
| Minimum supported runtime | Scoped simulator pass | Latest-source `IOS_DESTINATION='platform=iOS Simulator,id=8EB845AE-957C-4223-ABD1-5C9512B18AFC' IOS_DERIVED_DATA=/tmp/aqd-ios18-final ./scripts/test-ios.sh` passed20 Core,30 native and5 UI tests on iPhone16Pro/iOS18.1, including preview/accepted pixel-landmark equality. Build SDK remains26.5, not27. `/tmp/aqd-ios18-final/Logs/Test/Run-AQD-2026.10.08_21-16-28-+0800.xcresult`. Repository `pnpm check` passed38 tests; project/plist and shell syntax checks passed. Native GitHub workflow is added but no remote native pass is claimed yet. |
| Native environment instability | Observed, not hidden | One earlier focused run aborted in SwiftUI AttributeGraph during keyboard/menu update on iOS26.5. The minimized active-keyboard category regression and subsequent full runner passed; no deterministic app-level cause or device stability certification is claimed. PhotosPicker26 accessibility requires visible-image-center coordinate taps because exposed grid images have no public XCUI hit point; the actual system picker path is still exercised. |
| Remaining private domains | Incomplete | Other roots explicitly show baseline placeholders. Today configuration/content, outfits/themes, Planner/wear, Agent, Profile/journal/preferences/Settings and complete all-domain recovery are unfinished. Full LOCAL/TODAY/PREF/J acceptance is not passed. |
| Requirements | Specified, not executed | [V1 LOCAL acceptance](../product/v1-release.md#local-acceptance), [features](../features/README.md) and [design contracts](../design/README.md). |
| Latest recorded Paper confirmation checkpoint | Bounded static review | [Vector repair](../design/evidence/native-dialog-vector-repair.json): editable source-derived kit geometry, preserved registered identities; not exact native optics or AQD runtime. [Original receipt](archive/verification-2026-10-02–07.md#october7-editable-confirmation-repair--current). |
| Native kit provenance | Inspected/imported source evidence | [Native repair](../design/evidence/native-dialog-repair.json) distinguishes official 27 kit resources and historical UIKit 26.5 research captures from unverified AQD/SwiftUI/iOS 27 execution. |
| Today / action / input references | Scoped static evidence | [Today](../design/evidence/today-customization.json), [action surfaces](../design/evidence/action-surfaces.json), [input consistency](../design/evidence/input-component-consistency.json). Held/excluded rows remain explicit; no whole-app claim. |
| Retained Today Note/Photo deletion | Contract refinement only | [Recorded PR-review follow-up](archive/verification-2026-10-02–07.md#october7-pr-review-follow-up--retained-personal-content); no new Paper roots or runtime check. |
| Optional local identity clearing | Contract refinement only | Codex review of `86a9b6e` identified missing avatar removal. [Identity contract](../features/profile-account.md#local-identity-editing-v1-shared-private-v2) and V1 interaction coverage now specify draft clear/remove, cancellation, acknowledgment/reconciliation and reference-safe cleanup. No new Paper or runtime evidence; changed head requires fresh review. |
| Agent connected-action phase gates | Contract correction only | Codex review of `7edd153` identified mixed local/public authority rows and unqualified human-send/publication acceptance. [Agent](../features/agent.md#capability-and-authority-map) now separates local privacy/delete from V2-only publication/public privacy and human messaging; proposal text and A9 reinforce absent V1 connected tools/controls, distinct from private conversation turns. Local consent uses existing explicit native flow, never inferred chat approval. Static phase/authority cross-check only; runtime unverified. |
| Outfit detail phase actions | Contract correction only | Codex review of `6c4730e` exposed unqualified publication actions below the shared feature's V1 boundary. [Outfits](../features/outfits-themes.md) now consistently gates Share/publication to V2 and explicitly lists V1 Pieces/Plan/Record wear plus More → Edit/Favorite/Delete, matching the [interaction ledger](../design/v1-interactions.md#action-to-destination-checklist). Save remains private and never creates wear/plan/publication. Static phase/action cross-check only; native execution unverified. |
| Today weather fixture date | Documentation correction only | Codex review of `3037f71` identified a contradictory Wed7 requirement beside retained Mon5 evidence. [V1 flow](../design/v1-flow.md#optional-weather-and-source-returns) now matches the recorded `10GK-0` Mon5/Manila fixture and explicitly separates static date/temperature values from runtime formatting. Cross-checked Today/weather/interactions ownership; no Paper or native execution and no certified attribution. |
| Executable slice exits / native catalog | Contract corrections only | Codex review of `0dda2d2` identified prematurely comprehensive slice exits and an obsolete native-catalog root name. [Plan](implementation-plan.md#v1--small-local-mvp) now distinguishes executable domain-scoped evidence from complete acceptance, places all-domain recovery after Today/Agent/Profile, and reserves full journey/archive/device exits for integration. Native catalog names Today with legacy aliases explicit. Release acceptance is unchanged; no app or runtime pass. |
| Remaining acceptance/native terminology | Contract correction only | Codex review of `77bd38f` exposed coverage/native acceptance sources outside the earlier targeted origin scan. A broader current Markdown sweep now aligns private-root, plan, weather, capture, resume and motion terminology with Today; retained historical/public/component identifiers are explicitly legacy aliases. Source fixtures do not fix Today ordering/counts, private header Search stays absent, and public V2 scopes/Search remain reachable independently of optional Community posts placement. Independent24-file focused review passed; `pnpm check` passed38 tests and359 edited-file local targets resolve, with old-heading backlink/whitespace checks passing. This is documentation evidence only, not native/Paper execution. |
| Current Planner/source terminology | Contract correction only | Codex review of `5813b32` identified Planner's obsolete Home link origin. Product/Planner/release/journey/current-flow sources now say Today, including launch/return/weather-task wording; V2 scopes and internal dated evidence locators remain distinct. Heading backlinks were checked before current headings changed; no new app/Paper/runtime evidence. |
| Current phase-handoff terminology | Contract correction only | Codex review of `3159a8b` identified obsolete Home in the V2 phase inventory. Current backlog/definition/flow/Profile-setting inventories now name Today; V2's canonical Home/community section is explicitly an internal legacy alias, not a visible destination name. Historical evidence stays unchanged; no app/Paper behavior is certified. |
| V2 device view / pre-Today migration | Static copy and contract refinement | Codex review of `3f6b234` identified the remaining obsolete V2 diagram roots/Inbox-tab implication and no explicit legacy Today initialization. The device view now separates five roots from Inbox's toolbar entry. [Versioned migration](../features/today.md#versioned-pre-today-migration) stages supported pre-Today sources, preserves records/media, generates stock instance IDs once, validates migrated results and reconciles retries; corrupt/current/newer gaps never permit reset. V1/V2 restore/association pointers agree; no runtime migration or full-board render is certified. |
| Closet-only private search origin | Contract correction only | Codex review of `dd6b4e5` identified a nonexistent Home origin in the V1 search ledger. Entry/return now belongs only to the originating Closet segment; Today exposes Customize, while public All/Following search remains V2. Remaining current release/native-root title inventories use Today; internal/historical Home locators remain distinct. No app or new Paper evidence. |
| Architecture / specified controls inventory | Static artifact corrections only | Codex review of `ca6d4a0` identified the four-root V1 device-view label, obsolete selected-day Add retention and missing retained-card mappings. Excalidraw now lists all five Today roots; the manifest corrects Planner policy and maps retained-card/local-identity logical controls, caller references and native grammar with null new control-node IDs. These mappings do not certify newly drawn states, native routing or runtime behavior. |
| V1 journal persistence inventory | Contract refinement only | Codex review of `b4008f1` identified implicit journal records in [V1 minimum data](../architecture/v1.md#minimum-data). Minimum/export/restore inventories now name stable memory IDs, calendar dates/timezones, notes, outfit links/snapshots and photo/media relationships, matching J1–J7 without a new feature or implementation claim. |
| Connected Today durability | Contract refinement only | Codex review of `6e731be` identified an obsolete ADR root inventory and missing Today records in the V2 model. [ADR0002](../adr/0002-device-only-v1-and-connected-v2.md) now aligns all five roots without changing the device-only decision. [V2 architecture](../architecture/v2.md#today-association-sync-and-recovery) and DATA acceptance explicitly cover reviewed Today configuration/content/media/recovery state, stable identities, conflicts, deletion and account isolation; no provider approval, provisioning, app or runtime evidence. |
| Tour destination / Today erase review | Copy inspected; erase contract refined | Codex review of `76e087a` identified stale tour Home labels and an incomplete erase checklist. [Manifest copy review](../design/paper-manifest.json) records three live Paper text repairs (tour preview/completion and Restore completion), checked screenshots and unchanged380 identities/inventory. [Interaction coverage](../design/v1-interactions.md) includes all retained Today content/configuration/drafts/Undo, reference-safe cleanup and acknowledged failure/unknown states. `pnpm check` passed38 tests; JSON/canonical-entry comparison and whitespace checks passed. Erase review additions are not new drawn states or native/runtime verification; changed head requires fresh CI/Codex. |
| Latest known PR tooling | Passed, 19 seconds | Recorded handoff for `13011c8`; repository tooling only, not native tests. No new CI result inferred. |
| Integrated native / device / capability acceptance | Incomplete beyond scoped baseline results above | Full-domain navigation/focus/returns, media/model quality, recovery/Undo, permissions, VoiceOver, appearances, SDK27 and physical performance remain required. Scoped simulator navigation, writes/reconciliation and restart tests do not pass complete acceptance. |
| Connected / distribution | Unverified | V2 service/security/operations gates and native distribution are separate from repository checks and static design. |

## Active blockers

- **Numerical weather:** hidden attribution row; details-only compliance unverified. Withhold numbers until Apple-required assets/legal placement pass. [Policy](../product/v1-release.md#optional-live-weather-contract), [UI](../design/weather-context.md), [historical owner override](archive/verification-2026-10-02–07.md#owner-follow-up--remove-home-attribution-row).
- **Native feasibility:** icon-only five-tab public API/HIG exception, deployment/API guards and native 18/26/27 behavior remain acceptance gates under [native iOS](../design/native-ios.md). Kit imports are not runtime tests.
- **Background removal:** identical reference pixels do not prove masks. Physical Vision quality/performance and saved-photo propagation remain unverified; [scoped audit](archive/verification-2026-10-02–07.md#october-7-2026--background-removal-coverage-audit).
- **Delivery:** required latest-head CI/Codex and review-thread gates must pass before an authorized protected SHA-bound squash; post-merge release validation is separate. See [delivery stages](../agents/delivery-stages.md). Pending is not passed.

## Documentation context cleanup · October 7, 2026

Scope: documentation only, based on `13011c8`; no app code, Paper, GitHub, commit/push or merge changes. Validation on Node 24.20.0 / pnpm 10.12.1: `pnpm check` passed 38 repository-tooling tests, 0 failures (7.606 seconds); `git diff --check` passed. A temporary scoped Markdown checker examined 103 Markdown files and 1,248 local links, including 230 heading fragments: zero missing targets/anchors. Seven archived bodies compare equal to HEAD originals after only relative-link rebasing; lifecycle delivery stages 5–8 compare exactly equal. Unrelated personal research and ignored Local.xcconfig hashes are unchanged. Tracked iOS listing still contains no source/build baseline. No native/runtime, live Paper, GitHub CI/Codex or distribution checks ran. Measured general UI-implementation entry load (AGENTS, lifecycle, status, foundations, procedure, DQ and design router; previously also blanket full plan) falls from 98,278 to 45,117 bytes before selecting the affected contract/plan slice. This is an explicitly enumerated load set, not a claim that every task loads the same documents. This task can complete its documentation checks without waiving any required implementation acceptance.

## Historical evidence

The complete previous verification text is frozen in [October 2–7 snapshot](archive/verification-2026-10-02–07.md). Once-current inventories and verdicts there are superseded by the boundaries above, not recertified. [Status snapshot](archive/implementation-status-2026-10-07.md) retains the corresponding chronology. [Archive router](archive/README.md) also links prototype and earlier design history.

New current entries identify scope, revision/environment, observed result and limits. Put chronological detailed receipts in the archive; retain current blockers and scoped evidence here. Historical heading redirects below preserve incoming anchors without loading their bodies.

## Historical checkpoint redirects

## October7 editable confirmation repair — current

[Original dated receipt](archive/verification-2026-10-02–07.md#october7-editable-confirmation-repair--current). Historical scope; current boundaries above apply.

## October7 PR review follow-up — retained personal content

[Original dated receipt](archive/verification-2026-10-02–07.md#october7-pr-review-follow-up--retained-personal-content). Historical scope; current boundaries above apply.

## October7 final Today / native / action reconciliation — historical pre-vector checkpoint

[Original dated receipt](archive/verification-2026-10-02–07.md#october7-final-today--native--action-reconciliation--historical-pre-vector-checkpoint). Historical scope; current boundaries above apply.

## App-owned semantic feedback variants

[Original dated receipt](archive/verification-2026-10-02–07.md#app-owned-semantic-feedback-variants). Historical scope; current boundaries above apply.

## Input component consistency — role-directed global audit

[Original dated receipt](archive/verification-2026-10-02–07.md#input-component-consistency--role-directed-global-audit). Historical scope; current boundaries above apply.

## Owner follow-up — remove Home attribution row

[Original dated receipt](archive/verification-2026-10-02–07.md#owner-follow-up--remove-home-attribution-row). Historical scope; current boundaries above apply.

## October 7, 2026 — Home header consistency

[Original dated receipt](archive/verification-2026-10-02–07.md#october-7-2026--home-header-consistency). Historical scope; current boundaries above apply.

## October 7, 2026 — Transparency · Native iOS Foundations references

[Original dated receipt](archive/verification-2026-10-02–07.md#october-7-2026--transparency--native-ios-foundations-references). Historical scope; current boundaries above apply.

## October 7, 2026 — bounded Weather grid spacing correction

[Original dated receipt](archive/verification-2026-10-02–07.md#october-7-2026--bounded-weather-grid-spacing-correction). Historical scope; current boundaries above apply.

## October 7, 2026 — V1 canvas spacing follow-up

[Original dated receipt](archive/verification-2026-10-02–07.md#october-7-2026--v1-canvas-spacing-follow-up). Historical scope; current boundaries above apply.

## October 7, 2026 — complete V1 canvas organization only

[Original dated receipt](archive/verification-2026-10-02–07.md#october-7-2026--complete-v1-canvas-organization-only). Historical scope; current boundaries above apply.

## October 7, 2026 — optional native WeatherKit documentation/Paper handoff

[Original dated receipt](archive/verification-2026-10-02–07.md#october-7-2026--optional-native-weatherkit-documentationpaper-handoff). Historical scope; current boundaries above apply.

## October 7, 2026 — background-removal coverage audit

[Original dated receipt](archive/verification-2026-10-02–07.md#october-7-2026--background-removal-coverage-audit). Historical scope; current boundaries above apply.

## October 7, 2026 — shared local background removal

[Original dated receipt](archive/verification-2026-10-02–07.md#october-7-2026--shared-local-background-removal). Historical scope; current boundaries above apply.

## October 7, 2026 — scoped Planner, native More, preference Review and Height rows

[Original dated receipt](archive/verification-2026-10-02–07.md#october-7-2026--scoped-planner-native-more-preference-review-and-height-rows). Historical scope; current boundaries above apply.

## October6,2026 — V1 copy and contextual native confirmations

[Original dated receipt](archive/verification-2026-10-02–07.md#october62026--v1-copy-and-contextual-native-confirmations). Historical scope; current boundaries above apply.

## October 6, 2026 — Foundations library and complete icon catalog

[Original dated receipt](archive/verification-2026-10-02–07.md#october-6-2026--foundations-library-and-complete-icon-catalog). Historical scope; current boundaries above apply.

## October 6, 2026 — Foundations/V1/V2 synchronization repairs

[Original dated receipt](archive/verification-2026-10-02–07.md#october-6-2026--foundationsv1v2-synchronization-repairs). Historical scope; current boundaries above apply.

## Documentation maintenance — October 2, 2026

[Original dated receipt](archive/verification-2026-10-02–07.md#documentation-maintenance--october-2-2026). Historical scope; current boundaries above apply.

## Foundation release review fix — October 2, 2026

[Original dated receipt](archive/verification-2026-10-02–07.md#foundation-release-review-fix--october-2-2026). Historical scope; current boundaries above apply.

## Final-head Codex review recovery fixes — October 2, 2026

[Original dated receipt](archive/verification-2026-10-02–07.md#final-head-codex-review-recovery-fixes--october-2-2026). Historical scope; current boundaries above apply.

## Publication queue review fix — October 2, 2026

[Original dated receipt](archive/verification-2026-10-02–07.md#publication-queue-review-fix--october-2-2026). Historical scope; current boundaries above apply.

## Tagged ancestor recovery review — October 2, 2026

[Original dated receipt](archive/verification-2026-10-02–07.md#tagged-ancestor-recovery-review--october-2-2026). Historical scope; current boundaries above apply.

## V1/V2 planning and Paper refactor — October 5, 2026

[Original dated receipt](archive/verification-2026-10-02–07.md#v1v2-planning-and-paper-refactor--october-5-2026). Historical scope; current boundaries above apply.

## V1 onboarding action hierarchy — October 6, 2026

[Original dated receipt](archive/verification-2026-10-02–07.md#v1-onboarding-action-hierarchy--october-6-2026). Historical scope; current boundaries above apply.

## Agent navigation icon — October 6, 2026

[Original dated receipt](archive/verification-2026-10-02–07.md#agent-navigation-icon--october-6-2026). Historical scope; current boundaries above apply.

## Shared Profile and Settings surfaces — October 6, 2026

[Original dated receipt](archive/verification-2026-10-02–07.md#shared-profile-and-settings-surfaces--october-6-2026). Historical scope; current boundaries above apply.

## Today title/date spacing — October 6, 2026

[Original dated receipt](archive/verification-2026-10-02–07.md#today-titledate-spacing--october-6-2026). Historical scope; current boundaries above apply.

## New piece photo actions — October 6, 2026

[Original dated receipt](archive/verification-2026-10-02–07.md#new-piece-photo-actions--october-6-2026). Historical scope; current boundaries above apply.

## Today secondary action — October 6, 2026

[Original dated receipt](archive/verification-2026-10-02–07.md#today-secondary-action--october-6-2026). Historical scope; current boundaries above apply.

## Crisp blue palette — October 6, 2026

[Original dated receipt](archive/verification-2026-10-02–07.md#crisp-blue-palette--october-6-2026). Historical scope; current boundaries above apply.

## Plain onboarding alternatives — October 6, 2026

[Original dated receipt](archive/verification-2026-10-02–07.md#plain-onboarding-alternatives--october-6-2026). Historical scope; current boundaries above apply.

## Entry action spacing and weight — October 6, 2026

[Original dated receipt](archive/verification-2026-10-02–07.md#entry-action-spacing-and-weight--october-6-2026). Historical scope; current boundaries above apply.

## Plain secondary actions across surfaces — October 6, 2026

[Original dated receipt](archive/verification-2026-10-02–07.md#plain-secondary-actions-across-surfaces--october-6-2026). Historical scope; current boundaries above apply.

## October 6, 2026 — Compact controls and form consistency

[Original dated receipt](archive/verification-2026-10-02–07.md#october-6-2026--compact-controls-and-form-consistency). Historical scope; current boundaries above apply.

## October 6, 2026 — Global Welcome action spacing

[Original dated receipt](archive/verification-2026-10-02–07.md#october-6-2026--global-welcome-action-spacing). Historical scope; current boundaries above apply.

## October 6, 2026 — First-piece photo flow

[Original dated receipt](archive/verification-2026-10-02–07.md#october-6-2026--first-piece-photo-flow). Historical scope; current boundaries above apply.

## October 6, 2026 — Photo prerequisite and capture labels

[Original dated receipt](archive/verification-2026-10-02–07.md#october-6-2026--photo-prerequisite-and-capture-labels). Historical scope; current boundaries above apply.

## October 6, 2026 — L61 lighter private-start introduction

[Original dated receipt](archive/verification-2026-10-02–07.md#october-6-2026--l61-lighter-private-start-introduction). Historical scope; current boundaries above apply.

## October 6, 2026 — Agent device availability

[Original dated receipt](archive/verification-2026-10-02–07.md#october-6-2026--agent-device-availability). Historical scope; current boundaries above apply.

## October 6, 2026 — Realistic V1/V2 demo imagery

[Original dated receipt](archive/verification-2026-10-02–07.md#october-6-2026--realistic-v1v2-demo-imagery). Historical scope; current boundaries above apply.

## October 6, 2026 — Criteria-led V1/V2 polish

[Original dated receipt](archive/verification-2026-10-02–07.md#october-6-2026--criteria-led-v1v2-polish). Historical scope; current boundaries above apply.

## October 6, 2026 — Ready-to-begin visual

[Original dated receipt](archive/verification-2026-10-02–07.md#october-6-2026--ready-to-begin-visual). Historical scope; current boundaries above apply.

## October 6, 2026 — Returning Home insight card

[Original dated receipt](archive/verification-2026-10-02–07.md#october-6-2026--returning-home-insight-card). Historical scope; current boundaries above apply.

## October 6, 2026 · V1 destinations and state expansion

[Original dated receipt](archive/verification-2026-10-02–07.md#october-6-2026--v1-destinations-and-state-expansion). Historical scope; current boundaries above apply.

## October 6, 2026 — Photo selector comparison (proposal only)

[Original dated receipt](archive/verification-2026-10-02–07.md#october-6-2026--photo-selector-comparison-proposal-only). Historical scope; current boundaries above apply.

## October 6, 2026 — Private fit journal, Planner root and grouped controls

[Original dated receipt](archive/verification-2026-10-02–07.md#october-6-2026--private-fit-journal-planner-root-and-grouped-controls). Historical scope; current boundaries above apply.

## October 6, 2026 — Numbered Foundations and shared private core

[Original dated receipt](archive/verification-2026-10-02–07.md#october-6-2026--numbered-foundations-and-shared-private-core). Historical scope; current boundaries above apply.

### Conversations footer refinement

[Original receipt](archive/verification-2026-10-02–07.md#conversations-footer-refinement).

### Approved L04 replacement

[Original receipt](archive/verification-2026-10-02–07.md#approved-l04-replacement).

### Single Add photo entry and native source sheet

[Original receipt](archive/verification-2026-10-02–07.md#single-add-photo-entry-and-native-source-sheet).

### Populated Week footer simplification

[Original receipt](archive/verification-2026-10-02–07.md#populated-week-footer-simplification).
