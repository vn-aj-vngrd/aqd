# Implementation plan by phase

Updated October 5, 2026. This branch authorizes documentation/planning/architecture and Paper designs only. Begin product implementation only after a separate user request. First restore or establish a reproducible source/build baseline: the current checkout has no tracked Swift app/build definition matching historical prototype reports.

## Confirmation acceptance — docs/Paper only

Both phases follow [native risk/presentation policy and state mapping](../design/native-presentations.md#confirmation-states-not-pushed-screens). Existing confirmation IDs describe contextual states, not compulsory pushed pages. Use native action sheets for intentional bounded choices and alerts for critical irreversible loss; retain rich review, typed validation and authentication before the final decision. Common undoable actions should not gain redundant prompts.

Native acceptance must prove exact authorized target/impact, Cancel and supported dismissal without mutation, source focus/scroll/draft return, unavailable/in-flight actions, atomic commit/rollback and unknown-completion reconciliation before retry. Test accessibility sizes/localization/RTL, iPad adaptation, keyboard/safe areas and interruptions. Neither Paper state coverage nor repository tooling tests satisfy these runtime gates. No implementation is authorized by this refinement.

## V1 — Small local MVP

| Order | Slice | Exit evidence after implementation is authorized |
| --- | --- | --- |
| 1 | Local baseline/storage and capture | Versioned records/media, photo/name/category validation before save, permission failure/drafts, search/edit/archive and restart/migration; LOCAL-01–04. |
| 2 | Complete outfits and themes | Owned-piece selection, save/edit/favorite/pin/replace, independent themes/memberships, migration/failure recovery; LOCAL-03–04/11. |
| 3 | Planner, routines/trips and actual wear | Manual dates/two-week plans/routines/events/trip packing/conflicts/timezones, atomic review/save and factual history/insights; LOCAL-05. |
| 4 | Local recovery/privacy | Archive export, validated reviewed restore, erase, file protection/backup exclusion and network audit; LOCAL-06–08. |
| 5 | Complete local Agent, private fit journal, Profile and Settings | Local chat/history/review/cancel/retry/copy, optional identity/preferences, [fit journal](../design/profile-fit-journal.md) date plus photo-or-outfit validation, atomic drafts/imports/scoped deletion/export-restore, complete appearance/data settings and reason-specific on-device/manual states; LOCAL-09/12/13/14 and J1–J7. No mandatory cloud dependency or implicit wear/publication. |
| 6 | Native acceptance/distribution | Device/Simulator accessibility, appearance, keyboard/media/performance and end-to-end offline path; LOCAL-10 and all preceding checks. |

Use the existing smallest suitable app boundaries. Do not add server adapters, a distributed command bus, CloudKit, subscriptions, social tabs or generic future infrastructure. Any recovered legacy data needs a safe migration; this plan is not permission to discard it. [V1 release](../product/v1-release.md) owns the complete local baseline; private W/O/P/A contracts apply, while explicit connected/extension behaviors remain V2.

The activation flow is V2-style Welcome → private onboarding / optional replayable tour → photo selection and editable manual details → saved piece → actual missing categories or manual composition → saved outfit → date → actual wear. Settings provides explicit local data control. No fixed item count, quiz/account or AI-capable hardware blocks first value. Home/Closet/Planner/Agent/local Profile/Settings, themes/routines/trips, onboarding and both appearances must be complete before V1 is handed to users.

## V2 — Complete product

| Order | Slice | Dependency / gate |
| --- | --- | --- |
| 1 | Carry forward and extend the complete V1 private foundation | V1 already owns complete private W/O/P/A flows; extend without reset, dropped features or replacement navigation. |
| 2 | Extend Agent inputs/tools and external contextual weather | Shared reviewed actions; real-device/tool quality, source/permission/cost evidence. |
| 3 | Identity, association, sync/media/recovery/account lifecycle | Selected backend/policy; preserve V1 records, explicit upload preview and account isolation. |
| 4 | Profile/publication/discovery/follows/comments/safety | Curated public snapshots, revoked access, two-account tests and staffed moderation. |
| 5 | Human Inbox and reviewed social/message actions | Participant/request/retention/block/send acknowledgment and abuse contracts. |
| 6 | Landing/admin operations and connected release | Staff MFA/audits, jobs/alerts, tested backup/restore, load/service security and distribution. |
| 7 | All prepared V2 extensions | Prioritize [full backlog](../product/v2-backlog.md) after usage; implement named design/service gates before enabling. |

The [V2 core release](../product/v2-release.md) retains complete connected acceptance. V2 extension design requirements are [prepared separately](../design/v2-requirements.md); a future roadmap row is not permission to build or provision it now.

## Shared personalization acceptance — docs/Paper only

Onboarding, Settings → Style and Profile More → Style use one seven-step draft/review/save flow in both phases (six questions plus review), with unnumbered titles, separate Step n of 7 and a progress bar and no Skip question/Skip setup actions. Each question requires an answer or explicit No preference/refusal; sensitive body details remain optional. Goals/occasions/style/fit-comfort/colors guide eligible suggestions; optional height/self-described body shape require purpose-specific use consent, off initially. Declined/unknown values stay unknown; no photo inference, exact-size promise or implicit public/cloud use. Save is atomic, failure retains input, cancellation preserves saved answers and returns to the true source; onboarding success alone continues to capture. Implement and verify PREF-01–PREF-07 in [personalization](../design/onboarding-personalization.md) against a deterministic baseline before widening supported on-device assistance. This design refinement implements no ranking, persistence or model integration.

## Navigation refinement acceptance — docs/Paper only

The approved target is the same five equal-width native slots in both phases: **Home · Closet · Planner · Agent · Profile**, with centered icons only, explicit destination accessibility names/selected traits and full nonoverlapping hit areas ≥44 × 44 pt. Current scope updates diagrams/specifications and Paper references only; it implements no app wiring, migration, service or native build.

After separate implementation authorization, acceptance must cover:

- Establish the native five-slot baseline on compact/large phones; Closet segments only Pieces/Outfits/Themes, dedicated Planner root with Week default and Month alternate. Account setup never gates Planner/private core.
- Cross-root Home plan/outfit Plan links carry date context; Back restores origin/selection/scroll. Fourth-slot Agent launches a native full-screen task and dismissal restores origin and accessibility focus.
- V2 alone retains persistent labelled 44-point Inbox root-toolbar access → existing I01 → conversations. Back restores origin root/scroll/selected tab; startup/incoming intents open Inbox preserving origin. Real acknowledged unread only; no V1 mirror or Inbox tab.
- V1 Profile uses one More toolbar icon → Add fit, Edit profile, Style, Wear insights and Settings. No separate Settings/Edit/Add fit root controls or loose footer links; capabilities remain available. Theme More → Add outfits/Edit theme/Delete theme removes bottom management actions. Menu dismissal restores origin/focus/scroll; editing keeps dirty-draft protections.
- Related Planner choices use one shared surface with stable label/value/disclosure lanes; agenda/trip surfaces and section spacing follow [Planner calendar](../design/planner-calendar.md). Agent starter capsules follow [input](../design/agent-input.md), fill editable drafts and never auto-send. Verify long values, wrapping and keyboard-safe actions.
- VoiceOver/focus, Dynamic Type/localization, keyboard/safe areas and interruption/return behavior on a reproducible native build. Static Paper checks cannot satisfy these gates.

Static Paper inventories and representative visual checks are recorded in [verification](verification.md); native wiring/build/navigation acceptance remains unverified. The nine previously missing V2 root-state/review Inbox controls now share the labelled 44-point canonical entry, including offline roots. Legacy Inbox screenshots use an explicitly documented Home-origin placeholder, not a hard-coded native return.

## Foundations library ownership — docs/Paper only

Foundations is the reusable token/component/icon library, not a fourth app flow. Full-screen product and accessibility examples move into their owning V1/V2 reference areas with stable IDs; canonical routes and implementation scope do not change. The labelled icon catalog and registry distinguish actual phase usage, shared aliases/variants and OS-owned symbols. Native symbol rendering, accessibility and hit testing still require a separately authorized implementation.

## Shared capture/background-removal acceptance — docs/Paper only

Implement only after separate authorization. Follow [capture contract](../design/capture-photo.md#background-removal-reference-states): explicit capability-gated native accepted-photo Menu action, one identity-checked local job, immediate UI Cancel, disabled Use until rendered preview, reversible Original/Removed selection and parent-draft-only apply. Multiple foreground labels preview their union (legitimate pairs valid), never count-only failure or garment-confidence inference. Execution/no-subject/empty/render failure offers Try again/Crop manually/Cancel; unavailable offers Crop manually/Cancel; manual original save remains possible. Prove crop/reset/original recovery, export/restore and Save atomicity; cancellation/replacement/retry/dismiss/save races cannot publish stale results. Validate offline/no photo sent for removal, physical API/device boundaries, latency/memory, enlarged edge inspection, accessibility/appearance/keyboard adaptation and representative consented corpus against manual original baseline. Paper uses identical atlas pixels and establishes no mask-quality or native-runtime pass.

## Evidence meanings

Specified/design-prepared means requirements and Paper references exist. Source-ready needs a reproducible baseline. Capability-gated needs actual device/provider quality. Service-gated applies only to V2 connected work. Verified means build/commit/environment and observed evidence are recorded in [verification](verification.md). A drawing, historical prototype or passing tooling test proves no app behavior.

After authorization, deliver and review one slice at a time under [lifecycle](../agents/lifecycle.md). Use meaningful domain/failure tests, rendered native/accessibility checks, and the applicable phase acceptance. Update [status](implementation-status.md) with actual implementation; do not mark V1 blocked by a deferred V2 provider decision.
