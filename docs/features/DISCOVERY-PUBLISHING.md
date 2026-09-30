# S — Home, discovery, and publishing

## Outcome and navigation

Home is a visual social feed of real people's wardrobe content, with **All / Following** and discovery search. The initial All feed is newest accessible public posts; Following restricts to followed creators. Personalized ranking, trending labels, and personal AI outfit inserts are outside this slice. Users can browse discovery while keeping their closet private.

Search from Home covers public creators, closets, items, outfits, and themes with explicit result types. Closet's search remains owner-scoped. Working default: discovery is available as guest; authenticated identity is required to follow, react, bookmark, publish, or message. A disconnected backend shows an unavailable state, not fake community activity.

## Publication contract

Private item/outfit/theme records and public posts have separate IDs and lifecycles. A post contains author, type, caption, selected imagery/composition, allowed included-piece metadata, optional theme and source attribution, created date, and optional owner-confirmed worn date. Working default: snapshot publication, not live mirroring.

Preview exact photos and fields. Exclude private notes, prices unless separately enabled later, wear totals, calendar/event data, travel dates, and unrelated items. A public theme includes only explicitly published members. A public closet is a curated accessible item collection, not a switch exposing every private field or future upload. Later uploads stay private until included.

Save/generate/wear do not publish. Draft publication needs user confirmation. Editing a source record does not update the snapshot; updating a post has its own preview. Deleting/archiving a private source shows linked posts and offers unpublish or keep its already published snapshot. Account deletion removes public content according to [Account](PROFILE-ACCOUNT.md).

Unpublish revokes feed/search/profile retrieval and access through bookmarks/chat references. Invalidate AQD cached presentations on known revocation and revalidate access before resolving a reference; revocation governs future retrieval, not copies already exported outside AQD. Working default: bookmarks retain an unavailable reference that the owner can remove; they do not retain a private copy. Already recreated owned outfits remain private and owned by their creator. Reported/blocked content cannot reappear through another entry point. Authorized server reads enforce access; hiding a button is insufficient.

## Feed behavior

Cards show creator, publication type, imagery, caption, selected theme, and post actions. Posts may be pieces, outfits, themes, or owner-confirmed worn looks. A generated outfit is not labeled worn without a wear confirmation. Creator/content detail preserves feed position on Back.

Working default: public profiles with immediately effective follows; private closets can belong to public social profiles. Follow/unfollow updates Following. A new user sees All; empty Following offers discover/follow actions. Load and pagination failure preserve current posts and expose retry. Likes/bookmarks update with pending state; failure restores truthful state. Retrying does not duplicate reactions or posts.

## Inspiration

From a public outfit, request “Make a version from my closet.” Focused assistance or Agent receives authorized source context and the viewer's relevant owned items. It proposes owned equivalents, identifies missing matches, and retains attribution if the source remains accessible. Review/edit/save follows [Outfits](OUTFITS-THEMES.md). A bookmark alone never creates an owned outfit or imports the source's pieces.

## Acceptance

- S1: All shows only accessible published posts; Following changes after follow/unfollow and excludes other creators.
- S2: Search never exposes private items, notes, plans, or unpublished themes through any result type.
- S3: Preview/publish one look from a private closet without exposing unrelated records; retry creates one post.
- S4: Source edits do not silently alter a post; explicit update changes only reviewed content.
- S5: Unpublish removes access from feed, profile, search, bookmark, and chat while preserving inspired owned records.
- S6: Like/bookmark failure recovers accurately; paging failure preserves existing feed and scroll position.
- S7: Inspiration selects only current owned items; unsupported/missing matches remain visible drafts.
- S8: Reporting/blocking works across feed, search, profile, inspiration, and messaging entry points.

## Gates

Authenticated ownership, media access/revocation, pagination, abuse controls, moderation, and account lifecycle need selected connected services before launch. Current optional outfit-post code is reusable evidence, not proof of this complete contract.
