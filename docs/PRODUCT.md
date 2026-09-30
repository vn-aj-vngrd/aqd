# AQD product definition

Refined October 1, 2026. This is the intended product, not a statement of shipped functionality. [Implementation status](IMPLEMENTATION.md) records the current prototype. This direction replaces Personal / Community Home and the earlier restriction of assisted creation to Agent alone.

## Purpose

**AQD is a personal digital closet for organizing owned clothing, creating outfits and themes, planning what to wear, and sharing selected wardrobe content.**

The core asset is a durable record of what someone owns and how they use it. The private experience works without posting, following anyone, or using AI. Community provides inspiration from real closets. Agent provides another way to use the same product capabilities.

The product loop is **capture → organize → create → plan → wear → optionally share → discover → recreate**.

## Experience target: personal stylist and social wardrobe

The user-confirmed direction is **an Alta-inspired personal closet/styling experience plus a social-media-driven wardrobe product**. For AQD, the personal experience means easy capture, organized owned pieces, reusable outfits/themes, contextual styling, dated planning, travel packing, and useful wear insights. The social experience means a visual community feed, discoverable creators and public closets, following, sharing, reactions/bookmarks, inspiration recreated with owned pieces, and human chats.

These are connected parts of the product: a look created in Closet can be explicitly published; someone discovers it in Home, visits its creator's Profile, makes their own version, plans it, and optionally starts a chat in Inbox. Agent helps across that journey using the same domain capabilities.

Social participation is optional for each user, but community and Inbox are required parts of the intended V1 product. A private-only milestone is an intermediate delivery, not completion of this combined experience. Building the personal foundation first is dependency order, not a reduction of the social ambition.

“Alta experience” is an experience benchmark based on the supplied reference, not verified feature-for-feature parity. Advanced imports, virtual try-on, shopping, and other deferred capabilities remain separately scoped. AQD retains its monochrome identity, app-first manual controls, five destinations, and preferred on-device AI.

## Navigation and ownership

| Destination | Owns | Entry points |
| --- | --- | --- |
| Home | Community discovery | All / Following feeds; search for users, public closets, outfits, and themes. |
| Closet | Personal wardrobe management | Pieces, Outfits, Themes, Planner; capture, editing, personal search, wear history, stats, and personalization. |
| Agent | Conversational assistance across features | Questions, insights, reviewed creation and changes; centered entry opens full screen with Back and no bottom navigation. |
| Inbox | Human conversations | Chats, message requests, and accessible public wardrobe references. |
| Profile | Social presence and account management | Identity, followers/following, public collections, publication management, and account settings. |

The target is **Home · Closet · Agent · Inbox · Profile**. Search is reached from Home or inside the relevant personal workspace. Add opens a bottom sheet from Closet or Profile. Profile creation uses the same private wardrobe flow; saving does not publish. Account controls belong in Profile.

Home is a community feed, not a personal dashboard. All and Following are its two feed modes. Today's look, upcoming travel, office routines, and personal activity live in Closet and Planner. Closet and Profile refer to the same owned records, with separate private management and reviewed public presentation.

## App-first assistance

Normal screens complete every core private task manually. Focused actions such as “Suggest an outfit” and “Fill this week” use the same capabilities as Agent. The conversation handles questions and more complex requests; it does not create a separate inventory or planning system.

Agent's general scope is style, clothing, weather, travel, and everyday planning. Personal facts come from authorized records, statistics from trusted calculations, and current information from dated sources. Changes are concrete proposals with review, validation, and execution receipts.

On-device AI remains the V1 preference. Supported-device behavior, image analysis, planning quality, and current-information access require separate evidence before being promised. This refinement does not select a new provider or backend.

## Planning and sharing

Users can prepare the next two weeks, assign weekday office outfits for three months, or organize a two-week trip and its packing list. Events provide context; routines describe recurrence; plans hold dated intentions. Scheduling is distinct from actual wear.

Items, outfits, themes, history, and plans start private. Users explicitly select what to publish. A public closet is a curated view, not disclosure of the complete private inventory. Inspiration creates a draft using the viewer's own items. Inbox is human messaging; Agent conversation stays separate.

## Specification map

[Feature specifications](features/README.md) own detailed fields, behavior, states, access rules, and acceptance criteria. [Canonical vocabulary](../CONTEXT.md) owns domain terms. [Delivery scope](V1-SCOPE.md) bounds milestones; [Implementation plan](IMPLEMENTATION-PLAN.md) defines the module order and handoff. [Decisions](OPEN-QUESTIONS.md) separates confirmed choices, working defaults, and service gates.

The [supplied Alta comparison](references/ALTA-NOTES.md) informs discovery and creation patterns. It does not override AQD's core purpose or verify competitor behavior independently.

## Success and boundaries

Private success means a user can find owned pieces, save usable looks, prepare a plan, and correct wear history. Assisted success means valid owned-item proposals that are easy to review and edit. Social success means useful inspiration without exposing private context.

Durable saving, migration, recovery, and account/data lifecycle are release requirements. A local prototype is insufficient evidence of connected recovery. Marketplace, payments, virtual try-on, livestreams, and unrelated creator features are outside the initial product.
