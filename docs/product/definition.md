# AQD product definition

[V1 release definition](v1-release.md) is the complete launch checklist, including real authentication, backup/sync/recovery, community and Inbox. [V2 backlog](v2-backlog.md) defers extras. Core workflows must work and pass release checks; a service gate is an unresolved launch dependency, not permission to ship a placeholder.

Refined October 1, 2026. This is the intended product, not a statement of shipped functionality. [Implementation status](../delivery/implementation-status.md) records the current prototype. Home now combines a personal dashboard with All / Following discovery; the dashboard label is Today. The earlier restriction of assisted creation to Agent alone remains superseded.

## Purpose

**AQD is a personal digital closet for organizing owned clothing, creating outfits and themes, planning what to wear, and sharing selected wardrobe content.**

The core asset is a durable record of what someone owns and how they use it. The private experience works without posting, following anyone, or using AI. Community provides inspiration from real closets. Agent provides another way to use the same product capabilities.

The product loop is **capture → organize → create → plan → wear → optionally share → discover → recreate**.

V1 makes the first-outfit handoff explicit: capture/review one piece, show the actual categories needed around it, then suggest or manually build, replace, review and save a look. A first save is a trust milestone; the first usable outfit is the styling milestone. [V1 flow review](../design/v1-flow.md) shows the sequence and conditional auth/Home states. Virtual try-on and shopping wishlist/price alerts remain deferred by user decision.

## Experience target: personal stylist and social wardrobe

The user-confirmed direction is **an Alta-inspired personal closet/styling experience plus a social-media-driven wardrobe product**. For AQD, the personal experience means easy capture, organized owned pieces, reusable outfits/themes, contextual styling, dated planning, travel packing, and useful wear insights. The social experience means a visual community feed, discoverable creators and public closets, following, sharing, reactions/bookmarks, inspiration recreated with owned pieces, and human chats.

These are connected parts of the product: a look created in Closet can be explicitly published; someone discovers it in Home, visits its creator's Profile, makes their own version, plans it, and optionally starts a chat in Inbox. Agent helps across that journey using the same domain capabilities.

Social participation is optional for each user, but community and Inbox are required parts of the intended V1 product. A private-only milestone is an intermediate delivery, not completion of this combined experience. Building the personal foundation first is dependency order, not a reduction of the social ambition.

“Alta experience” is an experience benchmark based on the supplied reference, not verified feature-for-feature parity. Advanced imports, virtual try-on, shopping, and other deferred capabilities remain separately scoped. AQD retains app-first manual controls, five destinations, and preferred on-device AI. The premium native visual direction is owned by [DESIGN.md](../../DESIGN.md).

## Navigation and ownership

| Destination | Owns | Entry points |
| --- | --- | --- |
| Home | Daily dashboard and discovery | Today / All / Following. Today summarizes owned plans and wardrobe; All and Following show public posts. |
| Closet | Personal wardrobe management | Pieces, Outfits, Themes, Planner; capture, editing, personal search, wear history, stats, and personalization. |
| Agent | Conversational assistance across features | Questions, insights, reviewed creation and changes; centered entry opens full screen with Back and no bottom navigation. |
| Inbox | Human conversations | Chats, message requests, and accessible public wardrobe references. |
| Profile | Social presence and account management | Identity, followers/following, public collections, publication management, and account settings. |

The target is **Home · Closet · Agent · Inbox · Profile**. Search is reached from Home or inside the relevant personal workspace. Add opens a bottom sheet from Closet or Profile. Profile creation uses the same private wardrobe flow; saving does not publish. Account controls belong in Profile.

Home has three modes: Today, All and Following. Today is the private dashboard for the current planned look, upcoming plans and wardrobe shortcuts; Closet and Planner remain the editing sources. All and Following retain their public-feed contracts. Today is the first-use default; returning users restore their last Home mode and scroll position. Search from Today is owner-scoped Closet search; search from All/Following is public discovery, with the scope named on entry. Closet and Profile refer to the same owned records, with separate private management and reviewed public presentation.

## App-first assistance

Normal screens complete every core private task manually. Focused actions such as “Suggest an outfit” and “Fill this week” use the same capabilities as Agent. The conversation handles questions and more complex requests; it does not create a separate inventory or planning system.

Agent's general scope is style, clothing, weather, travel, and everyday planning. Personal facts come from authorized records, statistics from trusted calculations, and current information from dated sources. Changes are concrete proposals with review, validation, and execution receipts.

On-device AI remains the V1 preference. Supported-device behavior, image analysis, planning quality, and current-information access require separate evidence before being promised. This refinement does not select a new provider or backend.

## Planning and sharing

Users can prepare the next two weeks, assign weekday office outfits for three months, or organize a two-week trip and its packing list. Events provide context; routines describe recurrence; plans hold dated intentions. Scheduling is distinct from actual wear.

Items, outfits, themes, history, and plans start private. Users explicitly select what to publish: a piece, outfit, or theme. Every shared photo must link at least one owned piece reviewed for public sharing; photo-only posts are not supported. A public closet is a curated view, not disclosure of the complete private inventory. Inspiration creates a draft using the viewer's own items. Inbox is human messaging; Agent conversation stays separate.

## Web and operating surfaces

The launch architecture includes a public landing/support/legal website and a separate restricted web admin app for management, analytics, monitoring and controls. The admin app uses scoped, audited backend operations and does not create a second wardrobe or messaging system. [Web/admin architecture](../architecture/admin-web.md) defines the proposed modules and access boundaries; hosting and detailed operating policies remain open.

## Specification map

[Feature specifications](../features/README.md) own detailed fields, behavior, states, access rules, and acceptance criteria. [Canonical vocabulary](../../CONTEXT.md) owns domain terms. [Delivery scope](../delivery/implementation-plan.md) bounds milestones; [Implementation plan](../delivery/implementation-plan.md) defines the module order and handoff. [Decisions](decisions.md) separates confirmed choices, working defaults, and service gates.

The [Alta reference and comparison](../references/alta-notes.md) informs discovery and creation patterns. It does not override AQD's core purpose or verify competitor behavior independently.

## Success and boundaries

Private success means a user can find owned pieces, save usable looks, prepare a plan, and correct wear history. Assisted success means valid owned-item proposals that are easy to review and edit. Social success means useful inspiration without exposing private context.

Durable saving, migration, recovery, and account/data lifecycle are release requirements. A local prototype is insufficient evidence of connected recovery. Marketplace, payments, virtual try-on, livestreams, and unrelated creator features are outside the initial product.
