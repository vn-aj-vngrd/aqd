# Implementation plan by phase

Read when selecting/changing an implementation slice, not for every review/docs task. This cleanup is documentation-only. The owner separately authorized complete private V1 implementation after PR #5 merges; [current status](implementation-status.md) records that gate and resumption sequence. Current checkout has no tracked Swift app/build definition matching historical prototype reports. [Status](implementation-status.md) owns capability; [verification](verification.md) owns actual results.

## V1 — Small local MVP

| Order | Slice | Required exit / owner |
| --- | --- | --- |
| 1 | Local baseline/storage and capture | LOCAL-01–04; [local architecture](../architecture/v1.md), [wardrobe](../features/wardrobe.md), [capture](../design/capture-photo.md). Versioned records/media and safe restart/migration. |
| 2 | Complete outfits and themes | LOCAL-03–04/11; [outfits](../features/outfits-themes.md). Owned selection, independent memberships and failure recovery. |
| 3 | Planner, routines/trips and actual wear | LOCAL-05; [planning/history](../features/planning-history.md), [calendar](../design/planner-calendar.md). Atomic reviewed plans, actual wear and reproducible facts. |
| 4 | Local recovery/privacy | LOCAL-06–08; [local architecture](../architecture/v1.md#persistence-recovery-and-privacy). Validated staged replacement, export/erase, file protection and network audit. |
| 5 | Today, complete Agent, journal/Profile/Settings | TODAY-01–07, LOCAL-09/12/13/14/15, J1–J7; [Today](../features/today.md), [Agent](../features/agent.md), [profile](../features/profile-account.md), affected design contracts. Durable configuration/personal content, reviewed actions, source-aware returns. |
| 6 | Optional basic native WeatherKit | V1-12/LOCAL-16; complete [weather policy](../product/v1-release.md#optional-live-weather-contract), [mechanics](../architecture/v1.md#optional-native-weather-boundary), [UI](../design/weather-context.md). Independent of account/AI; manual offline core complete. |
| 7 | Native acceptance/distribution | LOCAL-10 and every preceding required check; [native iOS](../design/native-ios.md), phase release and distribution gates. |

[V1 release](../product/v1-release.md#local-acceptance) owns the complete launch checklist. Select affected shared/private feature sections for one slice; read complete applicable acceptance for readiness. No server adapters, CloudKit, subscriptions, social tabs or generic future infrastructure merely for V1. Preserve recovered data through safe migration. No account/item quota/quiz/model gate blocks manual first value. Today/Closet/Planner/Agent/Profile/Settings, themes/routines/trips, onboarding and both appearances must be complete before user release.

## V2 — Complete product

| Order | Slice | Dependency / gate |
| --- | --- | --- |
| 1 | Carry forward complete V1 | Preserve private features, records and navigation without reset. |
| 2 | Extend Agent input/tools/context/providers | Reviewed actions; real device/tool quality, source/permission/cost evidence. |
| 3 | Identity/association/sync/media/recovery | Selected backend/policy; explicit upload preview and account isolation. |
| 4 | Public profile/publication/discovery/comments/safety | Curated snapshots, revocation, two-account tests and staffed moderation. |
| 5 | Human Inbox/social-message actions | Participant/request/retention/block/acknowledgment/abuse contracts. |
| 6 | Landing/admin/connected release | Staff MFA/audits, jobs/alerts, backup/restore, security/load/distribution. |
| 7 | All prepared extensions | Prioritize [full V2 backlog](../product/v2-backlog.md) after usage; capability/design/service gates before enabling. |

[V2 core release](../product/v2-release.md) owns connected acceptance; [V2 requirements](../design/v2-requirements.md) owns prepared extension design. Roadmap membership is not authorization to provision or implement.

## Native target / transparency acceptance — docs/Paper only

API/deployment/guard/fallback acceptance belongs to [native iOS](../design/native-ios.md). [Original planning receipt](archive/implementation-plan-2026-10-07.md#native-target--transparency-acceptance--docspaper-only) retains the dated static scope; kit source is not runtime proof.

## Confirmation acceptance — docs/Paper only

Read [risk policy/state map](../design/native-presentations.md#confirmation-states-not-pushed-screens) when changing decisions/exits. Exact target, no-write cancellation, focus/draft restoration, atomic recovery and unknown-result reconciliation are required native acceptance, not optional polish. [Original receipt](archive/implementation-plan-2026-10-07.md#confirmation-acceptance--docspaper-only).

## Today customization acceptance — docs/Paper only

Read [TODAY-01–07](../features/today.md) and [Today UI](../design/today.md) for configuration/personal-content changes. [Original receipt](archive/implementation-plan-2026-10-07.md#today-customization-acceptance--docspaper-only).

## Shared personalization acceptance — docs/Paper only

[PREF-01–07](../design/onboarding-personalization.md) owns entered-questionnaire completion, explicit refusal, privacy/consent and atomic source-aware save/cancel. Bypass is before entry, not question skipping. [Original receipt](archive/implementation-plan-2026-10-07.md#shared-personalization-acceptance--docspaper-only).

## Navigation refinement acceptance — docs/Paper only

Read [V1 journey/returns](../design/v1-flow.md), [V1 interactions](../design/v1-interactions.md), [V2 flow](../design/v2-flow.md) for connected additions, and LOCAL-15/RELEASE-04 for native acceptance. Today is the accessibility destination; historical Home naming is not a current requirement. [Original receipt](archive/implementation-plan-2026-10-07.md#navigation-refinement-acceptance--docspaper-only) preserves scoped legacy fixture exceptions.

## Foundations library ownership — docs/Paper only

[Foundations](../../DESIGN.md#apply-the-foundations) owns library boundaries; registered IDs remain stable. [Original receipt](archive/implementation-plan-2026-10-07.md#foundations-library-ownership--docspaper-only).

## Shared capture/background-removal acceptance — docs/Paper only

[Capture cleanup](../design/capture-photo.md#background-removal-reference-states) owns cancellable identity-checked job/preview/draft-only apply, manual fallback and measured capability acceptance. Identical Paper fixture pixels are not masks. [Original receipt](archive/implementation-plan-2026-10-07.md#shared-capturebackground-removal-acceptance--docspaper-only).

## Optional native weather acceptance — docs/Paper only

Complete [policy/LOCAL-16](../product/v1-release.md#optional-live-weather-contract), then affected UI/mechanics. Budgets/privacy/late-result/forecast/attribution acceptance cannot be shortened away. Current hidden attribution/details-only placement blocks numerical-weather release; older visible-row planning is superseded. [Original receipt](archive/implementation-plan-2026-10-07.md#optional-native-weather-acceptance--docspaper-only).

## Evidence meanings

Specified/design-prepared: requirements/references exist. Source-ready: reproducible baseline. Capability-gated: actual supported device/provider quality. Verified: revision/environment and observed result recorded in verification. Native WeatherKit entitlement/attribution is independent of private manual availability; V2 service gates do not block V1 core.

After separate authorization, deliver one slice under [lifecycle](../agents/lifecycle.md), with focused failure/domain tests and applicable rendered native/accessibility checks. Required implementation acceptance passes or is blocked unless the owner explicitly reduces scope. Documentation completion never waives it.
