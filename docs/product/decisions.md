# Decisions and unresolved gates

Updated October 5, 2026. The current owner request supersedes the earlier full-connected V1 scope. [V1 release](v1-release.md) and [V2 backlog](v2-backlog.md) own phase boundaries. Product refinement authorizes documentation, architecture and Paper designs only.

## Confirmed by the user

- V1 is a small private personal digital closet and outfit-planning MVP running locally on the user's Apple device, with local clothing data and privacy by default.
- Remove all social features from V1. Avoid backend/server infrastructure and recurring backend costs; prefer Apple-native/on-device capabilities, including Apple Intelligence where applicable.
- V1 is a complete usable local app with Home, Closet, Planner, Agent, local Profile, Settings, welcome/onboarding and light/dark modes. Keep applicable private core features local; V2 simply extends V1 after real usage. No features are dropped.
- Move the complete prior product vision into V2, including social/community, sync and its required infrastructure. Prepare design requirements for both phases in Paper.
- Work on a new branch; do not implement features or production code. This supersedes the prior instruction that community, auth, account durability and Inbox were required in V1.
- The retained broader vision includes Today/All/Following, private Pieces/Outfits/Themes, conversational Agent, human Inbox and social Profile; curated publication never exposes all owned data.
- Preserve native premium restraint, centralized design tokens, system typography and Heritage blue. iOS first; no automatic platform expansion.
- Expand V1 Profile into a private on-device dated fit journal, not a duplicate closet. Optional local identity; retain wear insights and Style. Require date (today by default, editable) and photo or existing outfit; optional one local photo and brief private note, no empty date-only save. Outfit-only memories use actual composition, never fake wearer photos. Adding/linking/unlinking fits is distinct from planning and recorded wear and never rewrites counts.
- V2 may explicitly publish a reviewed selected fit rendition/composition. Private notes stay excluded unless the user deliberately enters a public caption; private defaults/save/sync never post automatically. This approves documentation/Paper scope only, not app implementation; native behavior remains unverified.

### Confirmed navigation refinement — October 6, 2026

- Same five equal-width native slots in V1/V2: **Home · Closet · Planner · Agent · Profile**, icons only with explicit destination accessibility names, selected traits and full nonoverlapping hit areas ≥44 × 44 pt. Planner is a dedicated root (Week default, Month alternate), never a Closet segment; Closet has only Pieces/Outfits/Themes.
- Home plan links and outfit Plan actions retain date context; Back restores origin and preserved selection. Agent launches a native full-screen task from the fourth slot or focused assistance, dismissing to origin/scroll/selection with restored accessibility focus.
- V2 Inbox remains human messaging through a persistent labelled 44-point root-toolbar entry → existing I01 → conversations, not a tab. Back restores origin root/scroll/selected tab; startup/incoming intents preserve origin. Real acknowledged unread only. V1 has no mirrored Inbox control.
- Planner/private core are never account-gated. V1 Profile uses one More icon for Add fit/Edit profile/Style/Wear insights/Settings; Theme More holds Add outfits/Edit theme/Delete theme. Remove redundant body management actions and Today/selected-day Add; Planner toolbar + retains date context.
- Keep only light phone references on the current canvas; remove dark duplicate screens while retaining complete matched light/dark color roles in Foundations and native dark appearance acceptance.
- Onboarding and Settings share six preference questions plus review, with unnumbered navigation titles, seven numbered steps and separate Step n of 7/progress; no Skip question/Skip setup controls. Every question accepts an explicit answer or honest No preference/refusal; fit/comfort/colors and self-described height/body shape remain private, with body details optional. Body use starts off, unknown stays unknown, no photo inference or exact-size guarantee, and no automatic cloud/public exposure.
- Scope is documentation/plans and Paper only. Five-slot native baseline, cross-root selection/returns, Inbox toolbar/incoming intents, VoiceOver/Dynamic Type/keyboard/safe areas require later native evidence; no app wiring/build or verification pass is claimed.

## Working defaults for V1

| Choice | Proposed practical default | Owner contract |
| --- | --- | --- |
| Device | iPhone first; retain existing manual iOS 18 target subject to reproducible build review | [V1 release](v1-release.md) |
| Navigation | Home · Closet · Planner · Agent · Profile in both phases; dedicated Planner root, Pieces/Outfits/Themes-only Closet, Settings from Profile/toolbar; V2-only persistent Inbox root-toolbar entry | [V1 flow](../design/v1-flow.md) |
| Capture | Photo/name/category validated before new-piece save; labels omit Required/Optional; one cover photo, editable optional metadata, manual classification with verified local proposals/cleanup | [Wardrobe](../features/wardrobe.md) |
| Storage | Versioned local database and protected media; no account; disable CloudKit; exclude AQD data from automatic backup | [V1 architecture](../architecture/v1.md) |
| Recovery | User-initiated archive export and reviewed full local restore; disclose device/app-loss risk | [V1 release data contract](v1-release.md#data-contract) |
| Outfits/planning | Owned outfits/favorites/themes, dates/routines/trips/packing, actual wear/history/insights; no external service dependency | [V1 release](v1-release.md) |
| Fit journal | One optional photo via shared native Photos/camera source sheet; optional outfit link/note ≤500 user-perceived characters, stable local date/timezone. Protected drafts/imports, scoped confirmed deletion, minimal outfit snapshot after outfit deletion; journal media/data included in explicit export/restore, excluded from automatic backup | [Profile journal](../features/profile-account.md#v1-private-fit-journal) |
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
