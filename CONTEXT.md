# AQD product language

AQD V1 represents a person's complete private wardrobe, outfits/themes, routines/trips/plans, actual wear and local Agent/Profile on one device. V2 adds the complete connected/social vision. Items/outfits/themes/events/routines/plans/wear/drafts and local Agent apply to V1. Online account, public Profile projections, post/feed/bookmark and human Inbox are V2. V1 Profile is private local personal information/preferences, not an online identity. A V1 local closet ID is not an online account.

## Wardrobe and creation

**Closet**: A user's personal collection of owned wardrobe items.

**Wardrobe item**: The digital record of one owned piece of clothing, footwear, or accessory, with photos and descriptive information.
_Avoid_: Asset when naming the user-facing object; a photo is media attached to an item, not the item itself.

**Outfit**: A saved combination of wardrobe items intended to be worn together. A generated combination becomes an owned outfit only when saved.

**Theme**: A named collection of outfits organized around a style, mood, or occasion. It is reusable and independent of a date or event.

**Draft**: A proposed item, outfit, theme, or plan that has not yet been saved or applied.

**Wear record**: A record of items actually worn, distinct from a future intention or saved outfit.

## Today

**Today**: The private first destination containing a personally arranged stack of in-app AQD cards; it keeps the house navigation symbol.

**Today widget**: One configured in-app card showing existing AQD records, a chosen local note/photo, or explicit local task shortcuts. It is not an operating-system Home Screen widget or an external integration.

**Today configuration**: The person’s ordered collection of widget instances and their chosen presentation/content, with at least one instance. Repeated kinds may serve different purposes; source records remain distinct from the presentation.

## Personal planning

**Planner**: The personal workspace for scheduling outfits and managing clothing needs over time.

**Plan**: A named set of dated outfit intentions, optionally associated with an event or routine.

**Plan entry**: An outfit intended for a specific date and occasion. It may be unassigned, planned, worn, or skipped.

**Event**: A bounded occasion with dates and context, such as a two-week trip or a wedding. It can have an associated outfit plan.

**Routine**: A repeating clothing context, such as weekdays at the office, with a date range and recurrence pattern.

**Local Profile**: Optional personal name/photo and style preferences on this device, with shortcuts to owned collections, wear insights and local Settings. It is not an online account or public projection.

**Onboarding / tour state**: Local completion/skip and resume state; read-only preview content never becomes user wardrobe data.

## Community — V2

**Profile**: A user's social identity and presentation of selected public wardrobe content.

**Account settings**: Controls for identity access, privacy, notifications, and account lifecycle; personal style/planning preferences belong in Closet; separate from Profile's content collections.

**Post**: An explicitly published presentation of a wardrobe item, outfit, theme, or worn look. It is distinct from the private source record.

**All feed**: Home's discovery feed of accessible public posts, including creators the user follows.

**Following feed**: Home's feed restricted to accessible posts by creators the user follows.

**Community bookmark**: A saved reference to another creator's public content. It does not transfer ownership of their wardrobe items.

**Inspired outfit**: A new combination of the current user's owned items informed by someone else's public look.

**Inbox**: The workspace for conversations with other people, distinct from conversations with Agent.

**Chat**: A conversation between users containing their messages and deliberately shared content.

**Message request**: A pending chat from a sender whose conversation has not been accepted by the recipient.

## Assistance

**AQD Agent**: The conversational assistant that reads authorized context and uses the product's wardrobe, creation, planning, capabilities; sharing and online tools are V2 extensions.

**Focused AI action**: Assistance initiated from a normal app task with its context already selected, such as proposing outfits for an event.

**Insight**: An observation derived from wardrobe information with a stated basis, time window, and limits.


**Local archive (V1)**: A user-initiated versioned export of local records/media for manual restore. It is not account backup, automatic sync or a public post.

**Local settings (V1)**: Device data/privacy, System/Light/Dark appearance/help, local Profile/preferences, archive export/restore and local erase; distinct from V2 account settings.
