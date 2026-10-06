# V2 — Complete product design requirements

October 5, 2026. Requirements prepared for the full [V2 backlog](../product/v2-backlog.md). Visual UI/UX lives in [iOS Paper](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0) and [web Paper](https://app.paper.design/file/01M3W6P0PN9SSQ1J3N6V23A9WK); there is no new local gallery or implemented product UI. V1 is the separate [device-only flow](v1-flow.md).

## Prepared core

Page **02 · V2**, sections **01–07**, retains the complete canonical entry/identity, Home/community, Closet/themes, planning/wear, Agent, Inbox and Profile/account screens. Section **08 · Complete connected journeys** on that same V2 page retains the old connected review strips with phase labels corrected. [Screen map](screens.md), [V2 flow](v2-flow.md) and [coverage](v2-coverage.md) own routes, states and unchanged canonical IDs. Web pages now label landing/admin and operating flows V2; the staff app is absent from V1.

Navigation: Home/Closet/Planner/Agent/Profile in both phases, five equal-width icon-only native slots with destination accessibility names/full hit areas ≥44 × 44 pt. Today is private; All/Following and public search are distinct scopes. Closet segments are only Pieces/Outfits/Themes; dedicated Planner defaults to Week with Month alternate. Home/outfit Plan links carry date context and Back preserves origin/selection; private core is not account-gated. Fourth-slot Agent opens a native full-screen task and dismisses to origin/scroll/selection. V2-only human Inbox is a persistent labelled 44-point root-toolbar entry → existing I01 → conversations, never a tab. Back restores origin root/scroll/selected tab; startup/incoming intents preserve origin and unread requires actual acknowledged state. V1 has no Inbox. Owner Profile U01 retains the private fit journal and U25 management menu, reusing private L49/L161 editors with true-source return. U26/U02 are the separate explicit public projection/editor; private journal/body details never enter that projection automatically. Settings retains local archive/recovery/erase and on-device assistance independently of connected account lifecycle controls. Native menus/sheets/forms remain OS-owned, using the shared tokens/type/photo hierarchy in [DESIGN.md](../../DESIGN.md).

## Expansion requirements prepared in Paper

Section **09 · Future expansion requirements** on page **02 · V2** prepares seven grouped requirement boards. Each board shows entry/preview/result/recovery expectations and privacy/infrastructure handoff. These are UX requirement boards, not a claim that all final native layouts, API behavior, billing, rendering quality or additional platforms have been tested.

| Board | Backlog mapping | Required sequence and states |
| --- | --- | --- |
| EX01 · Capture and try-on | E01–E02 | Scoped photo/camera/file intake → editable proposed metadata/per-piece selection → manual/partial retry; optional person-photo consent → processing → appearance result/retry/delete. No body/fit guarantee. |
| EX02 · Shopping and wishlist | E03 | External catalog → save to wishlist → price freshness/alert consent → external purchase/affiliate disclosure. Distinguish external item from owned piece; loading/empty/unavailable/price change/remove. Marketplace adds seller/payment/fulfillment/support review. |
| EX03 · Personalization, insights and Agent | E04–E05/E10 | Exact selected context and upload consent → grounded recommendation/recorded-data insight → correct/reset/opt out; response comparison/history and explicit rating/comment consent. Missing data, invalid result, source unavailable, revoked consent and deletion included. |
| EX04 · Advanced planning and notifications | E06/E09 | Calendar permission/range → date/conflict preview → reviewed assignment/packing; collaborative participant review; reminder/category opt-in → deep link with current access. Denied permission, unsupported forecast, sync conflict, no delivery and revoked content handled. |
| EX05 · Rich community and Inbox | E07–E08 | Audience/follow/group invitation → content/media/location/rights preview → acknowledged action → report/block/leave/delete. Private/removed/expired content, upload partial failure, duplicate send, requests, consent and recipient access are explicit. Calls/typing/read receipts need actual transport semantics. |
| EX06 · Identity, billing and platforms | E11–E13 | Provider/MFA setup/recovery → explicit merge conflicts; value/paywall → purchase pending/cancelled/failed → restore/expiry/support. Adaptive platform requirements include split view, keyboard/pointer, offline/sync and permissions; no automatic parity claim. |
| EX07 · Operations and acquisition | E14–E15 | Health/cost/freshness → bounded retry/rollout → audit/rollback/outage; optional post-value survey/skip, attribution consent and accurate missing analytics. Roles never imply general access to private closet/chat/Agent histories. |

## Shared design acceptance for every backlog row

Provide a discoverable entry and return path; retain draft/selection and native back/discard behavior. Show what is private/public/local/uploaded before the relevant action. State permissions, selected target/audience/context, source freshness and actual costs/limits when they affect a user decision. No provider/configuration details belong in routine consumer flows unless necessary to understand consent or limitations.

Normal, loading, empty, no-match, denied permission, offline/cache, retryable failure, unknown outcome, stale/conflicting/revoked data, cancellation and success all have a recovery contract. Keep stable operation IDs for retried connected mutations. A receipt follows durable acknowledgment; system notification arrival is not a receipt. User edits win over inferred metadata; remote processing and feedback have explicit retention/delete/opt-out.

Core and extension designs inherit 44-point targets, system semantic text, native keyboard/safe areas, VoiceOver focus, dynamic text/RTL/localization, light/dark, Increase Contrast, Reduce Motion and opaque material. Shared controls handle repeated states rather than duplicating a screen for every HTTP result. New iPad/Mac/Android/web compositions require native/platform-specific acceptance before implementation is called complete.

## Scope and remaining gates

Design requirements are prepared; implementation-ready capability/service policy is not established. [V2 architecture](../architecture/v2.md) and [decisions](../product/decisions.md) own backend/provider/retention/access/weather/cost/billing/messaging decisions. Try-on/visual capture need real-photo tests; speech/tools/current context need actual runtime proof. Marketplace/calls/music and additional clients require separately detailed implementation slices.

Reopen the referenced Paper boards for visual review, then verify native behavior and connected operations on a reproducible build. Paper does not prove authentication, sync, moderation, purchase delivery, accessibility semantics or scale. This branch implements no functionality and provisions no infrastructure.

V2-C03 retains the [Agent availability and explicit provider contract](../features/agent.md#agent-availability-and-provider-selection). The shared L19/L80/L81 reason states apply while no usable selected provider is configured; a supported, explicitly consented V2 cloud provider can enable Agent on ineligible Apple Intelligence hardware. Provider setup/privacy/cost and failure states require final native design before implementation.
