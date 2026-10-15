# iOS implementation plan

## Delivery contract

The active plan is **ten implementation issues/PRs plus one final E2E and hardening issue**: Foundation first, then one vertical slice for each Paper V1 section **01–09**. This replaces the former seven-slice plan and the old #6–19 ticket routing. Historical receipts remain in the [archive](archive/README.md); they are not a second active backlog. The planning refinement created documentation and tickets only. The owner subsequently authorized Foundation implementation on `van/issue-20/native-ui-foundations`, including committing this plan there. Sections01–09 remain specified follow-up work; native distribution is not authorized.

A vertical slice delivers the section's real UI, domain rules, persistence/media, navigation, failure recovery and tests together. One section may need supporting code in another domain; it is not a screen-only PR followed by separate storage/testing PRs. Use one branch and one PR per issue, with review fixes on that PR. Keep feature behavior in its owning section. The owner-approved October15 verification policy below moves broad E2E, device qualification and final hardening to issue #30.

[Current status](implementation-status.md) owns delivered behavior. Native baseline PR #9 is merged at `c5e11c4`; reuse its app, store, media pipeline and tests. Closed historical tickets do not prove complete V1 acceptance. [V1 release](../product/v1-release.md) still owns every launch requirement; V2 remains in [its release](../product/v2-release.md) and [backlog](../product/v2-backlog.md), outside these ten issues.

## Verification policy · owner-approved October15

Owner update, October16: feature delivery uses Core/native unit tests only. All E2E authoring/execution and integrated UI acceptance are deferred to #30, including feature-focused runs. Preserve existing tests and evidence for that ticket. No simulator is allowed locally or in hosted CI. The expensive native iOS CI workflow is removed; fast repository unit checks and existing protected delivery remain. Native unit checks use the connected, unlocked physical iPhone17ProMax. E2E/proof procedures below apply only to #30. Known product, data-loss and security defects still require fixes; deferred E2E is not a claim of full V1 acceptance.

Keep `./scripts/test-ios.sh` at default unit scope. Do not generate/run E2E or launch simulator/build CI per feature. Issue #30 owns the consolidated physical-device E2E, accessibility, permissions/media, privacy and performance qualification. Existing E2E failures remain historical evidence; fix known feature defects through targeted unit checks.

## Ticket index and build order

The numbers below are **Paper ownership**, not ten app destinations or a requirement to implement in numeric order. Build after Foundation in this dependency-aware order:

**Foundation → 01 → 04 → 03 → 05 → 06 → 08 → 02 → 07 → 09 → final hardening #30.**

Section02's complete Today stack consumes the later data domains, so it finishes after those domains. Sections03/04 share themes and outfits; section04 implements the small real theme-membership flow it needs before section03 completes theme management. Capture already exists in the baseline; complete any capture prerequisites needed by an earlier slice there and reconcile them in section02. Section04's Plan/Record wear actions similarly need real supporting save/review routes, extended—not replaced—by sections05/06. These supporting journeys are part of the earlier issue/PR; a dead button or “coming soon” destination cannot satisfy that issue.

| Ticket | Slice | Canonical V1 states | Direct predecessor |
| --- | --- | --- | --- |
| [#20](https://github.com/vn-aj-vngrd/aqd/issues/20) · Foundation | [Native foundations](#foundation--native-foundations) | Foundations page,26 reference roots | Merged native baseline |
| [#21](https://github.com/vn-aj-vngrd/aqd/issues/21) · 01 | [Welcome, onboarding and tour](#01--welcome-onboarding-and-tour) | 23;01.00–01.22 | Foundation |
| [#22](https://github.com/vn-aj-vngrd/aqd/issues/22) · 02 | [Today, capture and photo editing](#02--today-capture-and-photo-editing) | 21;02.00–02.20, plus TW01–TW20 | 08 |
| [#23](https://github.com/vn-aj-vngrd/aqd/issues/23) · 03 | [Closet, search and themes](#03--closet-search-and-themes) | 31;03.00–03.30, including L134 | 04 |
| [#24](https://github.com/vn-aj-vngrd/aqd/issues/24) · 04 | [Outfit creation and review](#04--outfit-creation-and-review) | 12;04.00–04.11 | 01 |
| [#25](https://github.com/vn-aj-vngrd/aqd/issues/25) · 05 | [Planner, routines and trips](#05--planner-routines-and-trips) | 20;05.00–05.19 | 03 |
| [#26](https://github.com/vn-aj-vngrd/aqd/issues/26) · 06 | [Actual wear, history and insights](#06--actual-wear-history-and-insights) | 10;06.00–06.09 | 05 |
| [#27](https://github.com/vn-aj-vngrd/aqd/issues/27) · 07 | [Agent, conversations and recovery](#07--agent-conversations-and-recovery) | 28;07.00–07.27 | 02 |
| [#28](https://github.com/vn-aj-vngrd/aqd/issues/28) · 08 | [Profile and private fit journal](#08--profile-and-private-fit-journal) | 7;08.00–08.06 | 06 |
| [#29](https://github.com/vn-aj-vngrd/aqd/issues/29) · 09 | [Settings, preferences and local data](#09--settings-preferences-and-local-data) | 17;09.00–09.16 | 07 |

The ten linked issues are open, specified `enhancement`/`ready-for-agent` tickets; dependencies still govern when work starts. A predecessor must be delivered before its dependent starts shared implementation. Keep one writer per shared file; discovery/review may run independently. A section issue is specified in advance, not permission to skip its predecessor.

## Agent procedure and PR exit

1. Read the issue, [lifecycle](../agents/lifecycle.md), current status and the section's contracts below. Inspect the current implementation before changing it. Use the documented lifecycle specification fallback when `triage`, `to-spec` or `to-tickets` skills are unavailable; disclose AI-authored ticket preparation.
2. Enumerate all owned canonical roots, reference states and controls from the [manifest](../design/paper-manifest.json), [implementation ledger](../design/evidence/v1-implementation-coverage.json) and [interaction ledger](../design/v1-interactions.md). Inspect live Paper descendants/assets for that inventory; headers and reference boards are not extra push routes.
3. Implement one end-to-end journey, then all its required branches. Reuse baseline components and shared validators. Add preserving, versioned migrations when records/media owners change; extend the media-reference graph before retaining new shared bytes. Test actual failure/unknown-result reconciliation, cancellation, stale revisions and restart at the affected seam.
4. Map every issue AC to a proof method. Generate/extend focused native E2E cases for UI outcomes, exercising the required source/return, input/save/relaunch and failure/cancel branches. Inspect actual rendered evidence for the claimed UI state and affected design criteria. Keep the broader control/device/accessibility matrix recorded for #30; a build or Paper screenshot cannot establish functional acceptance.
5. Run relevant unit tests, app build, repository checks and the issue's focused UI proof. Publish the AC table, screenshots/video and linked test artifacts in the PR under [acceptance proof](../agents/acceptance-proof.md). Record exact revision, environment, results and artifacts in [verification](verification.md); update status and per-root coverage without changing design-complete flags into runtime passes. Follow [workflow](workflow.md) and protected delivery gates for the issue's single PR when implementation is authorized.

**Feature delivery done:** owned behavior is implemented; relevant unit/build/repository checks and required focused UI proof pass; the PR contains reviewable AC evidence; review findings are resolved; required CI/Codex/protected delivery gates pass. Missing broad E2E/device qualification alone does not block a feature issue. Missing/failed/unpublished proof of its own AC does. Valid unavailable/manual states are required behavior, not proof that the capable path passed.

Cross-domain unit checks extend real populated fixtures as each domain arrives. Record exactly which portions of a shared acceptance ID passed; never certify the whole ID from a subset. Section09 implements the remaining all-domain behavior; #30 closes integrated runtime and release acceptance after features are complete.

## Foundation — Native foundations

**Outcome:** a reusable, tested Apple-native foundation in the existing app, proven by a real capture/save/reopen journey—not a detached design gallery.

**Build:**
- Map Paper Foundations tokens, typography, spacing, icons and component states to existing semantic SwiftUI/native controls. Complete reusable forms, selection, feedback/loading/disabled states, menus, sheets, critical/routine confirmations and source-aware exits as needed by V1.
- Establish the five native destination identities and source-preserving Agent presentation; verify public-API icon-only tab feasibility and baseline/opaque fallbacks. Preserve actual implemented capture behavior; incomplete product roots remain explicitly unaccepted until their section lands.
- Reuse local persistence, stable operation receipts, draft recovery, protected/backup-excluded media, safe schema migration and reference-checked cleanup. Define concrete seams for section-owned records/validators; add domain storage with its consuming section rather than building a generic future service layer.
- Keep minimum manual iOS18 support and the specified stable SDK/native API gates explicit. Add reusable isolated failure/restart/media fixtures and rendered test support. Establish representative media/Agent performance evaluations and capability budgets from the owning contracts before enabling assistance.

**Read:** [DESIGN](../../DESIGN.md), [procedure](../design/rules.md), [components](../design/components.md), [native iOS](../design/native-ios.md), [presentations](../design/native-presentations.md), [materials](../design/liquid-glass.md), [motion](../design/motion.md), [local architecture](../architecture/v1.md), [native setup](../../apps/ios/README.md).

**Prove:** baseline capture → accepted photo → acknowledged piece → collection → process relaunch still works; cancel/failed write/unknown retry/migration preserve data. Render shared states in light/dark and accessibility variants. Record SDK/device/tab-feasibility gaps as blockers, not inferred success. This issue does not claim complete product roots or full LOCAL-01/10/15.

## 01 — Welcome, onboarding and tour

**Outcome:** a fresh user starts privately; a returning user resumes real local state without repeated onboarding or demo data.

**Build:** splash without imposed delay; Welcome/private-start branches; optional pre-entry personalization; the shared seven-step questionnaire with explicit answers/refusals, optional body details and body-use off; review/edit/save-failure states; skippable/replayable preview-only Today/Closet/Agent/Profile tour. Persist resume/completion and reuse the same preference editor for actual Profile/Settings callers. Implement those minimal entry/return routes now; their full root inventories remain owned by08/09.

**Read:** [entry](../design/entry-identity.md), [entry motion](../design/entry-motion.md), [personalization](../design/onboarding-personalization.md), [profile/preferences](../features/profile-account.md), [welcome routes](../design/v1-flow.md#welcome-onboarding-and-tour-contract).

**Prove:** fresh/returning/interrupted sessions; questionnaire bypass before entry versus explicit refusal after entry; save/cancel/failure/restart from each real caller; tour Back/Next/Finish/Skip/replay with no inserted records. PREF-01–07 and scoped LOCAL-04/13/15; archive/erase portions close in09.

## 02 — Today, capture and photo editing

**Outcome:** all twelve configurable Today kinds use real local sources; capture saves privately and first-outfit guidance reaches a usable owned-piece outfit.

**Build:** empty/planned Today plus TW01–TW20 and the twelve-kind catalog `12ZP-0`; configure/add/duplicate/reorder/remove/minimum-one/defaults/Done/Undo; independent loading/empty/unavailable/error sources; retained Note/Photo management and reference-safe deletion; durable layout/content/drafts/media and unknown-save reconciliation. Complete photo source/camera permissions, whole-image Fit/crop/rotate/reset/cancel/options, category/details/additional metadata, photo failures, save states/receipt and category-derived pinned first-outfit readiness. Reuse the already delivered outfits/plans/wear/journal domains.

Own background-removal references `1010-0`, `1025-0`, `103A-0`, `104E-0`, `105C-0`, photo-discard `Z3U-0`, larger-text `22T-0` and welcome/first-piece motion `64C-0`. Demonstrate identity-safe cancellable local processing, editable proposals, original/removed review and manual fallback; identical fixture pixels are not mask quality evidence.

Own the nine WeatherKit references `108S-0` through `10FL-0` plus `10GK-0` via their exact manifest IDs. Implement the shared off/consent/place/date/loading/saved/unavailable/late-result behavior and consumers in Today/Outfit/Planner. Numerical weather stays withheld until entitlement, supplied attribution/legal placement and complete LOCAL-16 pass. Settings and Agent integration are extended in07/09; no extra weather PR.

**Read:** [Today feature](../features/today.md), [Today UI](../design/today.md), [wardrobe](../features/wardrobe.md), [capture](../design/capture-photo.md), complete [weather policy](../product/v1-release.md#optional-live-weather-contract), [weather UI](../design/weather-context.md), [weather mechanics](../architecture/v1.md#optional-native-weather-boundary).

**Prove:** every kind/configuration/control on empty and populated data; duplicates/stable identities/minimum-one; exact retained-content deletion/draft references/Undo/media recovery; capture cancel/permissions/invalid media/stale jobs/save failure/unknown/restart; first-piece → pinned outfit. TODAY-01–07, affected W checks and LOCAL-02/04/16; full archive/erase and weather Settings/Agent closure in09.

## 03 — Closet, search and themes

**Outcome:** the three Closet segments are usable collections with real lifecycle and theme membership, not placeholder lists.

**Build:** Pieces/Outfits/Themes and their empty/populated states; Add to closet; piece detail/options/availability/edit/archive/Undo/archived restore/delete; shared unavailable-record state. Complete scoped local search/start/results/loading/failed/empty/no-match, filters and deterministic sorts including wear-aware options. Create blank theme L134, detail/options/commands/edit/member selection/delete; independent multiple memberships and favorites. Reuse04's saved outfits and minimum membership editor.

**Read:** [wardrobe](../features/wardrobe.md), [outfits/themes](../features/outfits-themes.md), [search](../design/search-and-feeds.md), [interactions](../design/v1-interactions.md).

**Prove:** query/scope/filter/sort and return preservation; same records reachable from all callers; exact deletion/archive impact, cancel/failure/unknown recovery; empty/multiple themes/rename/delete retain outfits. W3–7, O3/4/7 and scoped LOCAL-03/04/11. Re-run future-plan/history/journal impact checks as05/06/08 populate those domains; close the complete IDs in09.

## 04 — Outfit creation and review

**Outcome:** owned pieces become an editable private outfit through manual or supported reviewed suggestions, with an actual save receipt.

**Build:** builder/shared chooser/pin/replace; focused suggestion with labelled rules/manual fallback and actual capability-gated on-device drafting; theme chooser; review/save/receipt/detail/More/edit/favorite/delete/stale-draft states. Own saved-receipt More reference `ZRD-0`. Implement the small real create/select theme membership flow required here;03 extends theme collection management. Implement usable date-prefilled Plan and separate Record wear review/save routes now;05/06 extend their calendars/history. Use shared trusted validators/approval/receipt code, subsequently reused by07. Complete capture prerequisites needed by the builder using the existing pipeline;02 owns its remaining inventory.

**Read:** [outfits/themes](../features/outfits-themes.md), [Agent trusted actions](../features/agent.md), [planning/wear](../features/planning-history.md), [interactions](../design/v1-interactions.md), [capture](../design/capture-photo.md).

**Prove:** owned-current IDs, pins, replacement, theme membership, stale review, failed/unknown save/restart, edit/favorite/delete; actual Plan/Wear writes and source returns. Save alone never plans, records wear or publishes. Applicable O checks and scoped LOCAL-04/09/11; later domain changes revalidate impacts.

## 05 — Planner, routines and trips

**Outcome:** users prepare dates, routines and trips with correct calendar intent, packing and atomic review.

**Build:** dedicated Week/retained Week/Month/date/agenda; selected-date Add/choose outfit/save/entry/remove; shared timezone; routine create/detail/edit scopes; event/trip destination/activities; trip detail/packing; bulk plan review/conflicts. Extend04's real Plan route. Store future/actual status distinctly; no elapsed date creates wear. Establish snapshot and recurrence behavior consumed by06.

**Read:** [planning/history](../features/planning-history.md), [calendar](../design/planner-calendar.md), [weather UI](../design/weather-context.md).

**Prove:** Week↔Month/date navigation and originating date/focus; local timezone/DST boundaries; two-week plans/three-calendar-month routine limits; future-edit choices; atomic conflicts/failure/unknown retry; deduplicated packing; manual offline path. P1–6/P11 and scoped LOCAL-04/05/15; weather consumer checks complete in02/09.

## 06 — Actual wear, history and insights

**Outcome:** wear is explicitly recorded, correctable and distinguishable from plans; insights reproduce recorded facts.

**Build:** record wear/duplicate decision/detail/correction/Undo; history/calendar/empty/insufficient-data/insights. Extend04's wear route and link planned/worn/skipped states without mutating immutable historical facts. Reconcile Closet's wear sorts and same-period report shortcuts; provide the reusable insight destination later reached by08/02.

**Read:** [planning/history](../features/planning-history.md), [interactions](../design/v1-interactions.md), [Today reporting](../features/today.md).

**Prove:** duplicate item-set/day, backdate/date-timezone/correct/Undo; plan and clock never record wear; historical snapshots survive record changes; recorded versus estimated counts and period/denominator facts; failure/retry/restart. P7–10 and scoped LOCAL-03/05. Journal-dependent checks run in08; all-domain closure in09.

## 07 — Agent, conversations and recovery

**Outcome:** Agent is a complete local task with durable conversations, honest availability and reviewed domain actions.

**Build:** full-screen origin return; options/composer/keyboard/context/select-local-context; waiting/streaming/complete/local response/details/stop/interruption/message error; conversation list/empty/failure/manage/delete; theme/local-change approvals and receipts; voice permission/listening/transcribing/review/unavailable. Own discard-recording `Z8G-0`. Reuse delivered domain validators, focused suggestion code and weather task. Preserve source drafts and context consent; generated prose/imported text is never write authority.

Foundation Models/image/voice are enabled only with actual supported-device/on-device capability evidence and representative quality/latency/cost/fallback evaluation. Unsupported/disabled/preparing paths preserve history/drafts and offer functioning manual routes. No V1 cloud model, social publication, human Inbox or messaging tools.

**Read:** [Agent](../features/agent.md), [input](../design/agent-input.md), [experience](../design/agent-experience.md), [native availability](../design/native-ios.md), [weather policy](../product/v1-release.md#optional-live-weather-contract).

**Prove:** durable chat/new/history/delete/Markdown/copy; stop/cancel/retry/unknown completion; permission denial/transcript review; model readiness/timeout/invalid/stale output; explicit context; revision-bound approvals with exactly-once domain receipts; source focus/scroll on Back. Applicable private A checks and LOCAL-09/12/15; archive/erase in09.

## 08 — Profile and private fit journal

**Outcome:** optional local identity and private dated fit memories are usable without publishing or implicitly recording wear.

**Build:** empty/populated Profile and one More menu (Add fit/Edit profile/Style/Wear insights/Settings); no-content/ready/edit memory/detail; optional name/photo including draft clear/remove; dated photo-only/outfit-only/combined journal composition, note validation, retained outfit snapshots, edit/delete and source-aware returns. Reuse shared photo/preferences/date/wear flows. Implement the real minimal Settings entry required here;09 extends its full inventory. Own delete-fit `Z01-0`, discard-fit `Z1X-0` and remove-fit-photo `Z6J-0` references.

**Read:** [local Profile and journal](../features/profile-account.md), [fit UI](../design/profile-fit-journal.md), [capture](../design/capture-photo.md), [personalization](../design/onboarding-personalization.md).

**Prove:** J1–J7 and local identity acceptance: valid/invalid drafts, ≤500-character notes, editable dates, import/cancel/failure, no implicit wear, separate deduplicated Record wear, outfit deletion retaining memories/snapshots, protected media cleanup and restart. Scoped LOCAL-13/14/15 and journal-dependent P10; full export/restore/erase in09.

## 09 — Settings, preferences and local data

**Outcome:** users control appearance/privacy and can export, safely replace or erase the complete local app; every V1 section passes integrated acceptance.

**Build:** Settings/Appearance/help/privacy/local Agent capability/Style; shared questionnaire entry and tour replay; all export preparing/ready/failed states; staged reviewed restore/invalid/newer/committing/complete/failed/recovery; exact global erase with export-first guidance. Reuse08's entry,01's editors and02's weather task. Own restore-commit `ZCU-0`, erase-commit `ZE7-0` and substantial-unsaved-loss reference `ZAS-0` at its actual qualifying callers.

Archives/restore/erase include every implemented domain, Today configuration/retained content/drafts/Undo, journal snapshots/media, identity/preferences, plans/routines/trips, wear/history, conversations/operation recovery and weather preference/cache policy. Review actual size/schema/media/reference integrity; failed/cancelled/newer restore retains the original app. Erase acknowledges records separately from pending reference-safe AQD-only file cleanup; original Photos/exported copies remain outside AQD.

**Read:** [local recovery/privacy](../architecture/v1.md#persistence-recovery-and-privacy), [Profile/Settings](../features/profile-account.md), [native presentations](../design/native-presentations.md), complete [V1 LOCAL acceptance](../product/v1-release.md#local-acceptance), [implementation coverage](../design/v1-implementation-coverage.md).

**Prove:** LOCAL-06–08 and all deferred TODAY-07/J6/PREF recovery portions on all-domain fixtures; same-operation failure/unknown/restart; shared Style/tour/weather source returns. Then run **all LOCAL-01–16 and applicable W/O/P/A/PREF/TODAY/J acceptance**, every canonical state/reference control, integrated airplane-mode/relaunch journeys, cross-domain deletion/membership/shortcut/report checks, supported OS/SDK/device/accessibility/media/performance and optional weather capability/privacy/attribution gates. Preserve explicit blockers until resolved. Under the October15 policy, section09 implements its behavior and unit coverage; the final integrated execution gate belongs to #30 and remains required before release. Native signing/App Store submission remains separately authorized.

## Paper accounting and reference ownership

Read-only Paper MCP inspection for this refinement: file `01M3SM2KBHBZG6MA0Q744Y9NW0`; Foundations page `p-1-0` has26 roots/2,101 nodes; V1 page `p-2-0` has227 roots/13,055 nodes, token hash `fdeb7346`. The complete V1 depth1 tree, not the truncated first100 basic-info list, establishes section names and root inventory. Bounded TW02 subtree inspection confirmed real configuration/More/Add/reorder/defaults/Done controls; it is not a whole-control audit or native parity pass.

The index accounts for **169 canonical states**. Section02 additionally owns20 Today references plus catalog,9 weather and5 background-removal references;04 owns receipt-More;02/07/08/09 own the8 native-decision references listed above. Foundation owns the shared component/accessibility/task-composition references `X71-0`/`X7B-0`;02 owns larger-text/motion. The scope board `JK8-0` and nine section headers remain structural traceability references, not destinations. Together these account for all **227 V1 roots** without adding routes or dropping reference-only behavior. Shared references are re-exercised by every consuming section.

## Historical plan links

### V1 — Small local MVP

Compatibility anchor for earlier verification receipts. The former seven-slice delivery sequence is superseded by the ten tickets above; release acceptance has not been reduced.

### Navigation refinement acceptance — docs/Paper only

Compatibility anchor for historical links. Current navigation/returns belong to [V1 flow](../design/v1-flow.md) and [interactions](../design/v1-interactions.md); the dated receipt remains in the [original plan](archive/implementation-plan-2026-10-07.md#navigation-refinement-acceptance--docspaper-only).
