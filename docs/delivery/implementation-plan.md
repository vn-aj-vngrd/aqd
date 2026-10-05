# Implementation plan by phase

Updated October 5, 2026. This branch authorizes documentation/planning/architecture and Paper designs only. Begin product implementation only after a separate user request. First restore or establish a reproducible source/build baseline: the current checkout has no tracked Swift app/build definition matching historical prototype reports.

## V1 — Small local MVP

| Order | Slice | Exit evidence after implementation is authorized |
| --- | --- | --- |
| 1 | Local baseline/storage and capture | Versioned records/media, name/category/no-photo save, permission failure/drafts, search/edit/archive and restart/migration; LOCAL-01–04. |
| 2 | Complete outfits and themes | Owned-piece selection, save/edit/favorite/pin/replace, independent themes/memberships, migration/failure recovery; LOCAL-03–04/11. |
| 3 | Planner, routines/trips and actual wear | Manual dates/two-week plans/routines/events/trip packing/conflicts/timezones, atomic review/save and factual history/insights; LOCAL-05. |
| 4 | Local recovery/privacy | Archive export, validated reviewed restore, erase, file protection/backup exclusion and network audit; LOCAL-06–08. |
| 5 | Complete local Agent, Profile and Settings | Local chat/history/review/cancel/retry/copy, optional profile/preferences, complete appearance/data settings and on-device/rules/manual states; LOCAL-09/12/13. No mandatory cloud dependency. |
| 6 | Native acceptance/distribution | Device/Simulator accessibility, appearance, keyboard/media/performance and end-to-end offline path; LOCAL-10 and all preceding checks. |

Use the existing smallest suitable app boundaries. Do not add server adapters, a distributed command bus, CloudKit, subscriptions, social tabs or generic future infrastructure. Any recovered legacy data needs a safe migration; this plan is not permission to discard it. [V1 release](../product/v1-release.md) owns the complete local baseline; private W/O/P/A contracts apply, while explicit connected/extension behaviors remain V2.

The activation flow is V2-style Welcome → private onboarding / optional replayable tour → optional photo/manual details → saved piece → actual missing categories or manual composition → saved outfit → date → actual wear. Settings provides explicit local data control. No fixed item count, quiz/account or AI-capable hardware blocks first value. Home/Closet/Agent/local Profile/Settings, themes/routines/trips, onboarding and both appearances must be complete before V1 is handed to users.

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

## Evidence meanings

Specified/design-prepared means requirements and Paper references exist. Source-ready needs a reproducible baseline. Capability-gated needs actual device/provider quality. Service-gated applies only to V2 connected work. Verified means build/commit/environment and observed evidence are recorded in [verification](verification.md). A drawing, historical prototype or passing tooling test proves no app behavior.

After authorization, deliver and review one slice at a time under [lifecycle](../agents/lifecycle.md). Use meaningful domain/failure tests, rendered native/accessibility checks, and the applicable phase acceptance. Update [status](implementation-status.md) with actual implementation; do not mark V1 blocked by a deferred V2 provider decision.
