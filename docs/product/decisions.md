# Decisions and unresolved gates

Updated October 5, 2026. The current owner request supersedes the earlier full-connected V1 scope. [V1 release](v1-release.md) and [V2 backlog](v2-backlog.md) own phase boundaries. Product refinement authorizes documentation, architecture and Paper designs only.

## Read branches and authority

Scope/authorization changes → applicable confirmation below. Unselected persistence or commercial choices → working-default row. Connected provider/policy selection → service-gate row. Implementation → the row's owner contract, not every dated approval body. Confirmations preserve what was approved; releases own phase acceptance, features own behavior, architecture owns mechanics and research owns source facts. Earlier terminology/receipts are historical where an owner supersedes them.

## Confirmed by the user

- V1 is a small private personal digital closet and outfit-planning MVP running locally on the user's Apple device, with local clothing data and privacy by default.
- Remove all social features from V1. Avoid backend/server infrastructure and recurring backend costs; prefer Apple-native/on-device capabilities, including Apple Intelligence where applicable.
- V1 is a complete usable local app with Today, Closet, Planner, Agent, local Profile, Settings, welcome/onboarding and light/dark modes. Keep applicable private core features local; V2 simply extends V1 after real usage. No features are dropped.
- Move the complete prior product vision into V2, including social/community, sync and its required infrastructure. Prepare design requirements for both phases in Paper.
- Work on a new branch; do not implement features or production code. This supersedes the prior instruction that community, auth, account durability and Inbox were required in V1.
- The retained broader vision includes Today/All/Following, private Pieces/Outfits/Themes, conversational Agent, human Inbox and social Profile; curated publication never exposes all owned data.
- Preserve native premium restraint, centralized design tokens, system typography and Heritage blue. iOS first; no automatic platform expansion.
- Expand V1 Profile into a private on-device dated fit journal, not a duplicate closet. Optional local identity; retain wear insights and Style. Require date (today by default, editable) and photo or existing outfit; optional one local photo and brief private note, no empty date-only save. Outfit-only memories use actual composition, never fake wearer photos. Adding/linking/unlinking fits is distinct from planning and recorded wear and never rewrites counts.
- V2 may explicitly publish a reviewed selected fit rendition/composition. Private notes stay excluded unless the user deliberately enters a public caption; private defaults/save/sync never post automatically. This approves documentation/Paper scope only, not app implementation; native behavior remains unverified.

### Confirmed navigation refinement — October 6, 2026

- Same five equal-width native slots in V1/V2: **Today · Closet · Planner · Agent · Profile**, icons only with explicit destination accessibility names, selected traits and full nonoverlapping hit areas ≥44 × 44 pt. Planner is a dedicated root (Week default, Month alternate), never a Closet segment; Closet has only Pieces/Outfits/Themes.
- Today plan links and outfit Plan actions retain date context; Back restores origin and preserved selection. Agent launches a native full-screen task from the fourth slot or focused assistance, dismissing to origin/scroll/selection with restored accessibility focus.
- V2 Inbox remains human messaging through a persistent labelled 44-point root-toolbar entry → existing I01 → conversations, not a tab. Back restores origin root/scroll/selected tab; startup/incoming intents preserve origin. Real acknowledged unread only. V1 has no mirrored Inbox control.
- Planner/private core are never account-gated. V1 Profile uses one More icon for Add fit/Edit profile/Style/Wear insights/Settings; Theme More holds Add outfits/Edit theme/Delete theme. Remove redundant body management actions and Today/selected-day Add; Planner toolbar + retains date context.
- Keep only light phone references on the current canvas; remove dark duplicate screens while retaining complete matched light/dark color roles in Foundations and native dark appearance acceptance.
- Onboarding and Settings share six preference questions plus review, with unnumbered navigation titles, seven numbered steps and separate Step n of 7/progress; no Skip question/Skip setup controls. Every question accepts an explicit answer or honest No preference/refusal; fit/comfort/colors and self-described height/body shape remain private, with body details optional. Body use starts off, unknown stays unknown, no photo inference or exact-size guarantee, and no automatic cloud/public exposure.
- Scope is documentation/plans and Paper only. Five-slot native baseline, cross-root selection/returns, Inbox toolbar/incoming intents, VoiceOver/Dynamic Type/keyboard/safe areas require later native evidence; no app wiring/build or verification pass is claimed.

### Confirmed optional WeatherKit scope change

The owner approved moving basic live weather from V2 into V1, inherited by V2, using direct native Apple WeatherKit only. This is documentation/Paper authorization, not app implementation, commit, push or service provisioning. Local private storage/no AQD backend/account/social/cloud LLM and a fully offline manual core remain; V1 is not strictly zero-network. Weather is off until chosen and independent of Foundation Models eligibility. Retain C04 and broader requirements as V1 WeatherKit foundation plus V2 advanced providers/research/calendar/alerts/notifications/expanded travel/collaboration.

The complete adopted [V1 weather policy](v1-release.md#optional-live-weather-contract) is authoritative for request/search disclosure, consent, payload exclusions, location permission, draft-only Apply, numerical budgets/cache/freshness, forecast bounds and attribution withholding. Changes to those approved boundaries require an owner decision; update that policy body rather than maintaining another executable copy here. LOCAL-16 remains required and unverified, not device/quality/performance proof.

Apple Developer Program/App ID entitlement enables the native service, not an end-user account/backend. Included capacity is 500,000 calls/month **per membership**, potentially requiring paid capacity; AQD budgets are not Apple quotas. WeatherKit iOS 16+ does not lower the existing AQD manual iOS 18 target. [Research](../references/weatherkit-v1.md) owns source evidence; [weather context](../design/weather-context.md) owns UI states. No reproducible app/build baseline or native verification is claimed.

### Confirmed native target / transparency refinement · October 7, 2026

Docs/Paper-only scope: commit deployment **iOS18.0** for complete manual core, build published stable **SDK27/Xcode27**, latest stable maintenance at implementation. [Primary research](../references/native-ios-materials.md) owns source evidence, not native build proof. Optional Foundation Models26/runtime eligibility, custom glass26 and27 styles do not raise minimum18; physical-device quality and optional weather network/entitlement remain separate gates. Use actual native controls with each running OS's appearance, opaque content and guarded custom material fallback. Critical alerts require explicit Cancel/destructive; routine related choices retain their actual source and26+ inline/implicit-cancel adaptation instead of guaranteed bottom placement. Preserve all confirmation safety scopes/IDs, no-write cancellation and unknown-operation reconciliation.

Five icon-only native tabs are an explicit HIG-label exception; public UIKit nil-title items are a feasibility route to test, not a tested implementation. No fake glass tab bar/private hacks. Foundations adds bounded **Transparency · Native iOS** API/reference boards, no phase scenes/routes. Official27 alert/action-sheet kit masters are now inspected and imported as separate reference assets; current product dialogs use editable kit-source adaptations rather than rasterized phones. Earlier middle/bottom drawings are superseded. This establishes source provenance, not exact27/AQD/SwiftUI runtime fidelity or redistribution licensing. No app implementation or acceptance advancement.

### Confirmed Today customization · October7

The owner approved **Today** as the first destination label/accessibility name, with unchanged house visual. Private header Search becomes native Customize Today (`slider.horizontal.3`); public All/Following and Closet/global Search remain. [Twelve in-app AQD widgets](../features/today.md), including independent local notes/photos, may be added/configured/duplicated/removed/reordered with minimum one and no arbitrary maximum. Stock Today’s look/Your week in wear/Closet in use is the absent-store default, never a silent personalized reset. No external integrations or WidgetKit. Weather is an existing Off/setup/details launcher, not new numerical data or implicit consent. V2 inherits local configuration and may explicitly use its existing connected feed store. Atomic drafts/Done/Undo, minimum/required-content validation, failures/unknown reconciliation, source/media recovery and all accessibility states are required. This authorizes Paper/docs only; no app, ticket, goal, commit or push.

## Working defaults for V1

| Choice | Proposed practical default | Owner contract |
| --- | --- | --- |
| Device | iPhone first; committed deployment18.0 / build stableSDK27, native baseline/build acceptance still required | [V1 release](v1-release.md) |
| Navigation | Today · Closet · Planner · Agent · Profile in both phases; dedicated Planner root, Pieces/Outfits/Themes-only Closet, Settings from Profile/toolbar; V2-only persistent Inbox root-toolbar entry | [V1 flow](../design/v1-flow.md) |
| Capture | Photo/name/category validated before new-piece save; labels omit Required/Optional; one cover photo, editable optional metadata, manual classification with verified local proposals/cleanup | [Wardrobe](../features/wardrobe.md) |
| Storage | Versioned local database and protected media; no account; disable CloudKit; exclude AQD data from automatic backup | [V1 architecture](../architecture/v1.md) |
| Recovery | User-initiated archive export and reviewed full local restore; disclose device/app-loss risk | [V1 release data contract](v1-release.md#data-contract) |
| Outfits/planning | Owned outfits/favorites/themes, dates/routines/trips/packing, actual wear/history/insights; no external service dependency for manual work; optional native WeatherKit context | [V1 release](v1-release.md) |
| Fit journal | One optional photo via shared native Photos/camera source sheet; optional outfit link/note ≤500 user-perceived characters, stable local date/timezone. Protected drafts/imports, scoped confirmed deletion, minimal outfit snapshot after outfit deletion; journal media/data included in explicit export/restore, excluded from automatic backup | [Profile journal](../features/profile-account.md#v1-private-fit-journal) |
| Assistance | Complete local Agent/history and focused reviewed actions with Foundation Models when available; labelled rules/manual fallback | [V1 architecture](../architecture/v1.md) |
| Commercial | Free local MVP; no subscription/billing entitlement infrastructure; WeatherKit developer capability is separate | [Pricing proposals](../architecture/pricing-strategy.md) |

These implementation defaults make the plan concrete without claiming the user chose a specific persistence API or OS/device matrix. Verify them against restored source before implementation; no AQD cloud service is needed; optional WeatherKit and Apple city lookup are the approved direct online exception.

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
| Advanced weather/calendar/push | Inherit confirmed V1 WeatherKit contract; additional source/licensing/coverage/consent, calendar permission/conflicts, APNs lifecycle | Advanced contextual planning and notifications |
| Try-on/shopping | Provider/rights/consent/retention, real-photo quality, cost/latency/retry; catalog/licensing/affiliate terms | Optional previews and commerce |
| Billing/platforms | Purchase/restore/cancellation/entitlement policy, store requirements and native layouts | Paid tiers and additional clients |
| Operations | Provider/region/budget, backups/restore, role/MFA/audit, telemetry, alerts/SLOs and launch workload | Connected production release |

Supabase/PostgreSQL/Storage/Realtime and Cloudflare static hosting remain V2 proposals. Historical cost/pricing snapshots are unapproved and must be refreshed before purchasing. No remote service was configured. V2 core acceptance is preserved in [V2 release](v2-release.md); all extension design requirements are in [V2 design](../design/v2-requirements.md).
