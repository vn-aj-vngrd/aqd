# AQD product definition

Updated October 5, 2026. AQD has two product phases. This split supersedes the earlier connected V1 plan. It authorizes documentation and Paper design only; no application functionality or infrastructure is implemented by this planning branch. Product V1/V2 are scope names, independent of repository release tags such as `v1.0.0`.

## V1 — Private personal closet

An iPhone user can catalog owned clothing, create outfits, assign them to dates, and record actual wear, entirely on their device. The first useful result is one privately saved piece followed by a usable outfit. An account, connection, social participation, or AI-capable device never blocks the manual flow.

| Destination | V1 responsibility |
| --- | --- |
| Today | Private customizable in-app widget stack: twelve AQD kinds including own local notes/photos; minimum one, no arbitrary maximum. Stock look/week-in-wear/closet-in-use; complete manual first-use and recovery. No external integrations or All/Following feeds. [Today contract](../features/today.md). |
| Closet | Only Pieces/Outfits/Themes segments, search/capture/lifecycle/favorites and wear/history/insight access. |
| Planner | Dedicated root: dates/routines/trips/packing; Week default, Month alternate. Today plan links and outfit Plan actions preserve date and return context. |
| Agent | Complete local conversation/history, supported on-device wardrobe assistance, focused actions, reviewed edits and truthful receipts/recovery. |
| Profile | Local optional name/photo/preferences and personal collection/history/insight shortcuts. No social identity or followers. |
| Settings, from Profile More | System/Light/Dark appearance, local privacy/help/permissions and export/restore/erase. No online account. |

The clarification requires a complete usable V1, including V2-style Welcome, private onboarding and a skippable replayable tour, returning sessions, all private core journeys and complete appearance/permission/error states. Prefer Apple Foundation Models for supported local assistance, with labelled Quick rules and manual paths. No cloud AI fallback, general research or social action is required. Optional basic native Apple WeatherKit live weather is included, without making weather, AI or network a manual-core dependency; local storage is not a strict zero-network promise. The [V1 weather contract](v1-release.md#optional-live-weather-contract) owns selected-place/date disclosure, off-by-default consent, direct Apple calls, bounded forecasts/cache and attribution. Themes, routines/trips and the local Agent belong to V1; earlier draft omissions of those local core features are superseded.

Records and prepared photos live in the app's local sandbox. There is no AQD server, sign-in, managed CloudKit/iCloud sync, remote analytics, messaging transport or subscription entitlement service. AQD-owned stores/media are excluded from automatic device backup to honor the device-only default. User-initiated archive export is an explicit exception: the selected Files destination may be local or cloud-backed. An imported photo may also originate in the user's iCloud Photos library; AQD only receives the photo they select.

V1 does not promise recovery after device loss or app deletion. Export and tested local restore provide a manual recovery path. Apple Intelligence eligibility, settings, downloaded model readiness, language and region affect suggestions; the core closet remains usable without them. [V1 release](v1-release.md) owns the exact small scope; [V1 architecture](../architecture/v1.md) owns storage and capability boundaries.

## V2 — The complete AQD product

V2 extends the complete local V1 with the broader connected styling and social/community vision; it never replaces or resets V1. The full connected core carries forward V1 themes, planning, routines/travel packing and conversational Agent, inherits V1 basic WeatherKit context, then adds advanced external weather providers/context, identity and account lifecycle, sync/recovery, curated public closets, publishing, discovery, follows, likes/bookmarks/comments, human Inbox and safety operations.

Both versions share **Today · Closet · Planner · Agent · Profile** (first slot retains the house glyph), five equal-width icon-only native slots with explicit destination accessibility names and full hit areas of at least 44 × 44 pt. Today’s retained V2 route also owns the distinct All / Following scopes; Closet owns only private Pieces / Outfits / Themes. Planner is a dedicated root, not account-gated. The fourth Agent slot launches a native full-screen task whose dismissal restores origin/selection/scroll. Profile extends its private journal with curated public presentation after opt-in. V2 human Inbox remains available through a persistent labelled 44-point root-toolbar entry, not a tab: I01 then conversations; Back restores origin root/scroll/selected tab. Startup/incoming intents open Inbox while preserving origin; unread requires real acknowledged state. V1 has no Inbox. Saving private data never publishes it.

V2 also owns all previously deferred enhancements: visual capture, try-on, shopping, richer personalization/insights/planning/social/chat, notifications, billing, other platforms and measured infrastructure growth. [V2 backlog](v2-backlog.md) records the full vision, prepared design requirements, dependencies and limitations. [V2 core release](v2-release.md) retains the detailed connected acceptance baseline. Extensions need their named capability, consent, policy and service gates; inclusion in the vision is not a promise that every extension launches together.

V2 starts with one modular backend, relational data, authorized media, sync, durable jobs and moderation/admin operations. Providers, region, prices and service policies remain proposals until selected. [V2 architecture](../architecture/v2.md) records the complete boundary; neither a free provider tier nor Apple CloudKit removes the need to operate a connected social product.

## Shared principles

Onboarding and Settings share one optional private preference questionnaire for goals, occasions, style, fit/comfort, colors/patterns and self-described height/body shape. The entered questionnaire has seven numbered steps/progress and no skip controls; every question accepts an explicit No preference or refusal. Users may edit/clear answers and need not share body details; body-use permission starts off. These inputs personalize eligible deterministic suggestions and supported on-device drafts, not a promised exact clothing size or inferred body assessment. See [personalization](../design/onboarding-personalization.md).

Owned pieces are the source of truth. Drafts are editable; reviewed actions use trusted validation and actual save receipts. Planned clothing is distinct from actual wear. Unknown information stays unknown. Private notes, history and plans never become public implicitly. Manual operations remain available when assistance fails.

Keep the restrained Apple-native design system in [DESIGN.md](../../DESIGN.md). [Paper](../design/README.md) owns UI visuals for both phases; specifications own behavior, and [verification](../delivery/verification.md) owns actual evidence. The current checkout still needs a reproducible iOS source/build baseline before any implementation.
