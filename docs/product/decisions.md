# Decisions and unresolved gates

Updated October 5, 2026. The current owner request supersedes the earlier full-connected V1 scope. [V1 release](v1-release.md) and [V2 backlog](v2-backlog.md) own phase boundaries. Product refinement authorizes documentation, architecture and Paper designs only.

## Confirmed by the user

- V1 is a small private personal digital closet and outfit-planning MVP running locally on the user's Apple device, with local clothing data and privacy by default.
- Remove all social features from V1. Avoid backend/server infrastructure and recurring backend costs; prefer Apple-native/on-device capabilities, including Apple Intelligence where applicable.
- V1 is a complete usable local app with Home, Closet, Agent, local Profile, Settings, welcome/onboarding and light/dark modes. Keep applicable private core features local; V2 simply extends V1 after real usage. No features are dropped.
- Move the complete prior product vision into V2, including social/community, sync and its required infrastructure. Prepare design requirements for both phases in Paper.
- Work on a new branch; do not implement features or production code. This supersedes the prior instruction that community, auth, account durability and Inbox were required in V1.
- The retained broader vision includes Today/All/Following, private Pieces/Outfits/Themes, conversational Agent, human Inbox and social Profile; curated publication never exposes all owned data.
- Preserve native premium restraint, centralized design tokens, system typography and Heritage blue. iOS first; no automatic platform expansion.

## Working defaults for V1

| Choice | Proposed practical default | Owner contract |
| --- | --- | --- |
| Device | iPhone first; retain existing manual iOS 18 target subject to reproducible build review | [V1 release](v1-release.md) |
| Navigation | Home, Closet, Agent, local Profile; Planner in Closet; complete Settings from Profile/toolbar | [V1 flow](../design/v1-flow.md) |
| Capture | Name/category required, one optional cover photo, editable optional metadata, manual classification with verified local proposals/cleanup | [Wardrobe](../features/wardrobe.md) |
| Storage | Versioned local database and protected media; no account; disable CloudKit; exclude AQD data from automatic backup | [V1 architecture](../architecture/v1.md) |
| Recovery | User-initiated archive export and reviewed full local restore; disclose device/app-loss risk | [V1 release data contract](v1-release.md#data-contract) |
| Outfits/planning | Owned outfits/favorites/themes, dates/routines/trips/packing, actual wear/history/insights; no external service dependency | [V1 release](v1-release.md) |
| Assistance | Complete local Agent/history and focused reviewed actions with Foundation Models when available; labelled rules/manual fallback | [V1 architecture](../architecture/v1.md) |
| Commercial | Free local MVP; no subscription/entitlement infrastructure | [Pricing proposals](../architecture/pricing-strategy.md) |

These implementation defaults make the plan concrete without claiming the user chose a specific persistence API or OS/device matrix. Verify them against restored source before implementation; no cloud service is needed to resolve V1.

## V1 implementation evidence needed

Restore or establish a reproducible iOS baseline; validate schema/migration, media protection and backup exclusion, archive/restore/erase, date handling and native accessibility. Validate Foundation Models availability, owned-ID output quality and latency on real devices. Manual behavior remains releasable when optional model assistance is unavailable; no silent cloud fallback or mandatory AI promise.

## V2 service and policy gates

| Gate | Required decision/evidence | Blocks |
| --- | --- | --- |
| Identity/account | Sign-in methods, callbacks, email delivery, legacy recovery, account isolation/association | Connected accounts and lifecycle |
| Sync/recovery | Server ownership/revisions, commit-safe cursor, conflict UI, offline window/tombstones, recovery and rollout | Account sync and second-device recovery |
| Media/publication | Storage/access, derivatives, staged finalization, revoke/cache policy, deletion and backup retention | Public closets/sharing and cloud photos |
| Community safety | Audience/age policy, block/report, rate limits, operator enforcement, appeals/support | Public discovery/comments and messaging |
| Messaging | Transport, retention, request policy, durable send/read acknowledgments, encryption claims, media scanning | Human Inbox and richer chat |
| AI/context | Supported image/speech/tools, bounded generation, physical-device quality; explicit cloud processing consent if ever chosen | Rich Agent/capture/current context |
| Weather/calendar/push | Source/licensing/coverage, selected-location consent, calendar permission/conflicts, APNs lifecycle | Contextual planning and notifications |
| Try-on/shopping | Provider/rights/consent/retention, real-photo quality, cost/latency/retry; catalog/licensing/affiliate terms | Optional previews and commerce |
| Billing/platforms | Purchase/restore/cancellation/entitlement policy, store requirements and native layouts | Paid tiers and additional clients |
| Operations | Provider/region/budget, backups/restore, role/MFA/audit, telemetry, alerts/SLOs and launch workload | Connected production release |

Supabase/PostgreSQL/Storage/Realtime and Cloudflare static hosting remain V2 proposals. Historical cost/pricing snapshots are unapproved and must be refreshed before purchasing. No remote service was configured. V2 core acceptance is preserved in [V2 release](v2-release.md); all extension design requirements are in [V2 design](../design/v2-requirements.md).
