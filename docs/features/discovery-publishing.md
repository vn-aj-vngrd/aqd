# S — Home, discovery, and publishing

## Outcome and navigation

Home has **Today / All / Following**. Today is a private dashboard over existing wardrobe and planning records; All and Following are visual social feeds of real people's published content. The initial All feed is newest accessible public posts; Following restricts to followed creators. Personalized ranking, trending labels, and personal AI outfit inserts are outside this slice. Users can browse discovery while keeping their closet private.

Search from Home covers public creators, closets, items, outfits, and themes with explicit result types. Closet's search remains owner-scoped. Working default: discovery is available as guest; authenticated identity is required to follow, react, bookmark, publish, or message. A disconnected backend shows an unavailable state, not fake community activity.

## Publication contract

### Today activation states

Today reads existing records rather than storing onboarding completion. Empty closet uses S16. Pieces with no saved outfits and missing required categories offer Build my first outfit → W28; reuse the quiet S48 hierarchy with missing-category copy, not a new dashboard. Enough available pieces but no saved outfits use S48 → W17 or W13. Saved outfits without today's plan use S17 → choose an outfit. A planned look uses S15 → reviewed wear recording. Search remains owner-scoped in Today. Never show planned or wear totals without records, repeat first-use guidance after an outfit exists, or force a community/account step before styling.

Verify the transitions after capture, cancellation, archive, outfit save and plan save; manual composition remains available if readiness changes or assistance fails. The [V1 flow review](../design/v1-flow.md) shows canonical screen sequences. These are target states, not implemented behavior.

Private item/outfit/theme records and public posts have separate IDs and lifecycles. A post contains author, type, caption, selected imagery/composition, allowed included-piece metadata, optional theme and source attribution, created date, and optional owner-confirmed worn date. Working default: snapshot publication, not live mirroring.

Preview exact photos and fields. Exclude private notes, prices unless separately enabled later, wear totals, calendar/event data, travel dates, and unrelated items. A public theme includes only explicitly published members. A public closet is a curated accessible item collection, not a switch exposing every private field or future upload. Later uploads stay private until included.

Save/generate/wear do not publish. Draft publication needs user confirmation. Editing a source record does not update the snapshot; updating a post has its own preview. Deleting/archiving a private source shows linked posts and offers unpublish or keep its already published snapshot. Account deletion removes public content according to [Account](profile-account.md).

Unpublish revokes feed/search/profile retrieval and access through bookmarks/chat references. Invalidate AQD cached presentations on known revocation and revalidate access before resolving a reference; revocation governs future retrieval, not copies already exported outside AQD. Working default: bookmarks retain an unavailable reference that the owner can remove; they do not retain a private copy. Already recreated owned outfits remain private and owned by their creator. Reported/blocked content cannot reappear through another entry point. Authorized server reads enforce access; hiding a button is insufficient.

## Feed behavior

Cards show creator, publication type, imagery, a compact caption, and post actions; selected theme and included-piece totals belong in post detail. The three post types are Piece, Outfit and Theme. An owner-confirmed worn date is optional outfit metadata, not a fourth post type. A generated outfit is not labeled worn without a wear confirmation. Creator/content detail preserves feed position on Back.

Working default: public profiles with immediately effective follows; private closets can belong to public social profiles. Follow/unfollow updates Following. A new user sees All; empty Following offers discover/follow actions. Load and pagination failure preserve current posts and expose retry. Likes/bookmarks update with pending state; failure restores truthful state. Retrying does not duplicate reactions or posts.

## Inspiration

From a public outfit, request “Make a version from my closet.” Focused assistance or Agent receives authorized source context and the viewer's relevant owned items. It proposes owned equivalents, identifies missing matches, and retains attribution if the source remains accessible. Review/edit/save follows [Outfits](outfits-themes.md). A bookmark alone never creates an owned outfit or imports the source's pieces.

## Acceptance

- S1: All shows only accessible published posts; Following changes after follow/unfollow and excludes other creators.
- S2: Search never exposes private items, notes, plans, or unpublished themes through any result type.
- S3: Preview/publish one look from a private closet without exposing unrelated records; retry creates one post.
- S4: Source edits do not silently alter a post; explicit update changes only reviewed content.
- S5: Unpublish removes access from feed, profile, search, bookmark, and chat while preserving inspired owned records.
- S6: Like/bookmark failure recovers accurately; paging failure preserves existing feed and scroll position.
- S7: Inspiration selects only current owned items; unsupported/missing matches remain visible drafts.
- S8: Reporting/blocking works across feed, search, profile, inspiration, and messaging entry points.

- S9: Send/page/retry/delete plain-text top-level comments with retained drafts, stable operation IDs and acknowledged counts; empty/loading/failed states remain distinct.
- S10: Only authorized users can create/delete comments; revocation/block/report/moderation removes access across post, counts and discussion without retaining prohibited text.

## Gates

Authenticated ownership, media access/revocation, pagination, abuse controls, moderation, and account lifecycle need selected connected services before launch. Current optional outfit-post code is reusable evidence, not proof of this complete contract.

## Today dashboard

Today summarizes the current user's planned look, next dated plan entries and direct Add piece / Build outfit / Planner actions. It never publishes or copies records into a second dashboard store. Show actual saved names, availability and dates, using each plan's timezone; weather and computed insights appear only with valid source data. Do not invent streaks, utilization, outfit recommendations or upcoming trips to fill space.

First-use default is Today; restore the selected mode and scroll position on return. Switching to All/Following never exposes private dashboard data. Search on Today enters owner-scoped Closet search (W10); the same icon in social modes enters explicitly labelled public discovery (S03). Changing mode does not silently reuse the other scope's query/results.

S15 shows a planned day. Record wear opens P09 for explicit confirmation and duplicate-safe persistence; a plan is never automatically marked worn. S16 shows an empty closet with Add your first piece, plus optional community browsing. S17 shows an existing closet without a planned look, offering Choose an outfit and the manual builder. Hide empty upcoming sections or show one concise Plan your week action. Missing/unavailable assigned pieces show a conflict and Review plan instead of a false ready state.

Load local sections independently, preserving cached data and drafts. Empty is distinct from load failure. Offline users can use available local wardrobe/plans; public-feed connection failures do not replace the Today dashboard. A failed local section has Retry and its relevant workspace link. Summary totals use actual authorized records, not invented analytics. Refresh after a wardrobe/plan/wear change; sign-out/account switching clears or re-scopes private summaries according to account policy.

Acceptance: three Home tabs remain reachable in populated/loading/empty/offline states; mode-specific search never mixes private/public scope; Today reflects a saved plan change; viewing a plan never records wear; first-use and no-plan states remain useful without AI or network services; larger text expands layouts without hiding actions.

## Today wardrobe activity

Today retains the planned look as the primary task. Beneath it, **Your week in wear** shows two calculated values and a seven-day strip. S15 is the initial viewport; S18 is its scrolled continuation with Wear again, upcoming plans and manual quick actions. The strip is history, not a goal, streak, completion score or forecast.

- Use the current locale's calendar week and display its date range. Count distinct saved local record dates in that week through today for “days recorded”; count distinct item IDs across those records for “pieces worn.” Multiple wears on one day still count as one day; repeated pieces count once. Historical record date/timezone remains unchanged when the device travels. Prior wear estimates and future plans never enter these totals.
- Checked days have dated wear records; an outline marks today; future days remain neutral. A past unmarked day means no record, not that nothing was worn. Tapping the summary opens Wear history (P10) for this week. The strip is one accessible summary, not seven undersized buttons; announce full dates and recorded/not recorded/future states, with a textual history alternative.
- No records ever: show the plain secondary Wear history section with “Your recorded outfits will appear here” and Record your first wear, opening manual selection then P09 review. Existing history but none this week: show zero recorded days/pieces with “Nothing recorded this week” and Open history. Empty closet: keep S16 first-piece content and omit metrics. A no-plan day may still have a populated week; S17 illustrates the independent no-history case.
- **Wear again** uses one active, available, owned piece with at least one dated wear record, absent from today's planned/recorded sets. Working selection default: least recently recorded eligible piece, stable item-ID tie-break. Show the exact last-recorded date, never “not worn for” or an inferred inactivity claim. Hide when no eligible piece exists. Build an outfit opens the manual builder (W13) with the piece selected; it neither saves nor records wear. Missing photos use the existing category fallback.
- Load wardrobe and history independently. Keep cached values during refresh and label stale data with its actual update time when needed. Initial loading reserves neutral summary geometry. Failure shows “Wear history couldn’t load,” Retry and Open history; it never becomes zero. Recompute after confirmed record/edit/undo/delete and clear on account switch. No public visibility or new analytics store is implied.

Static examples use three recorded days and eight unique pieces, not production activity. Verify duplicate-day/item aggregation, week boundaries/locales, travel, backdating, undo, archived items, missing images, stale caches and account changes in implementation.

## Creator-controlled photo tags

Every photo post must link at least one creator-owned piece explicitly reviewed for public sharing. A Piece post shares exactly one piece. An Outfit post shares a saved outfit with one or more selected pieces. A Theme post shares one or more selected outfits and at least one distinct piece across them; private themes may remain empty but empty themes cannot be published. A photo alone is not a post type. No inferred clothing recognition or automatic publication satisfies this requirement.

Entry: Share from your closet → Piece / Outfit / Theme → choose owned source → review photos and selected public fields/pieces → Publish. The Piece preview can explicitly publish the selected private piece snapshot as the purpose of that flow. Outfit/Theme previews must explicitly disclose every newly shared piece, rather than silently exposing private inventory. Existing photo-marker editing still chooses already published pieces. Spatial markers are optional and manual; piece associations are required. Missing/deleted/inaccessible required sources block Publish, explain the reason, and preserve photos, caption and selections. Revalidate immediately before publication with duplicate-safe submission.
Each tag stores post/media identity, published piece ID and normalized image coordinates. Store coordinates relative to the original oriented media, not screen pixels; adapt through aspect-fill/crop transforms. Do not silently move a tag to a different photo on replacement: require placement review. Working limits: five tags per image, one tag per piece per image, and no duplicate overlapping targets. Edge collisions show the numbered list alternative. Creator can edit/remove tags in a draft; an already published change requires snapshot preview and confirmation.

The resting image displays a bottom-leading 44-point piece control for accessible linked pieces, whether or not spatial markers exist. It shows the count for that photo; each uploaded photo needs at least one explicitly associated piece. Tapping one linked piece opens its public detail; multiple pieces open the accessible list, with numbered markers when placed. Theme posts also expose their collection name and reviewed outfit/piece totals through a compact collection row. The collection count can exceed the number linked to a particular cover photo. Marker targets are at least 44 points or fall back to the list rather than overlap. VoiceOver exposes the ordered piece list without spatial exploration. Reduce Transparency uses an opaque control surface.
Revalidate each target on opening. Unpublished/deleted/blocked/permission-revoked pieces show “This piece is no longer available” and return to the look; do not expose private names, photos or historical cached details. Recompute count from accessible targets on refresh. Tags never expose private wear history, prices, plans or notes. No spatial markers does not hide linked pieces. If all linked pieces are later revoked, show an unavailable-pieces state without private previews; editing or republishing requires a valid piece again. An inaccessible whole post uses X04. Authoring/loading/failed-save states retain placements and prevent duplicate publication.

## Reactions, saved content and comments

All and Following use the same 44-point heart/comment/bookmark row with 4-point Like–Comment gap and trailing bookmark. Public post detail reuses it. Heart toggles like; active uses heart.fill with selected semantics. Bookmark toggles a private saved reference and uses bookmark.fill. Comment opens discussion; it has a pressed state but is not a persistent selection. Accessible labels express actions (“Unlike post”, “Remove bookmark”, “View comments”). Inline heart-plus-count is one Like toggle; inline comment-plus-count opens Comments. Post detail has a separate 44-point “Liked by…” link that opens reacting profiles; the comment/count control opens Comments. Show real counts, not fixture defaults. Zero likes has an empty people list; zero comments opens the empty composer state.

Like/bookmark are optimistic only while pending is tracked; coalesce rapid taps to the latest intent and reconcile against confirmed server state. Failure restores the confirmed icon/count and offers Retry. Unknown outcome fetches current state before retrying. Do not increment twice, animate a burst, or make bookmarking imply owning the outfit. Removing a bookmark updates Saved inspiration; removing a like updates Liked posts. Guest actions route through sign-in with the intended post/action retained and revalidated afterward.

Profile → Settings provides Liked posts and Saved inspiration. Liked posts is the viewer's private history of accessible liked posts; the per-post Likes list shows accessible reacting profiles. Saved inspiration remains S08 and has an empty state S29. Collections share loading, offline cache, retry, pagination and revoked-reference behavior. Back restores originating feed, active scope and scroll position.

Comments belong to the post, separate from Inbox and Agent. Working default: plain-text top-level comments, oldest first with pagination, maximum 1,000 user-perceived characters; trim blank-only input, retain internal spacing/newlines, and expose a counter near the limit. Empty Send is disabled. On send, insert a temporary pending row with a stable operation ID; on success reconcile once to the server comment/time, clear only the acknowledged draft, and update the count. Failed sends retain editable text and offer retry; retries must not duplicate comments. New remote comments do not pull a reader away from older content. Native keyboard keeps the composer visible.

Own-comment More offers Delete with a native confirmation; success removes only that comment and updates the count. Others' More offers Report and Block through the existing safety flow. Deletion failure leaves the comment with retry; moderation/removal renders “Comment unavailable” without retained prohibited content. No edit/reply/mention/threaded reactions are implied in this slice. Service gates include authorization, rate limits, abuse controls, moderation, idempotent sends and pagination; static designs do not implement them.

Acceptance: both feeds and post detail have identical actions; filled states match confirmed data; tags appear only after explicit creator selection; private/other-owner targets cannot be linked; coordinate placement survives image resizing; image replacement requires tag review; revoked tags never leak private snapshots; comment empty/sending/failed/sent/deleted/report states preserve correct drafts/counts; liked/saved collection destinations and back-navigation work consistently.

Saved inspiration also opens from Closet → More (W30 → S08/S29), using the same private collection and removal state. Back restores the originating Closet tab/filter/scroll state. Liked posts remain in Profile → Settings; owned outfit favorites remain in Closet.

### Compact feed footer

All, Following and reduced-transparency feed variants use the same footer: heart with like count, comment with comment count, flexible spacer, bookmark. Each combined control has at least 44-point bounds; preserve the 4-point gap between groups. Use matching 15/22 regular caption type directly below with a 4-point internal gap. Limit feed captions to two lines with an accessible More action that opens full post detail; keep the full value there. Theme name and total included-piece count no longer occupy a separate feed line. The image piece count reflects explicitly associated accessible pieces, with or without spatial markers; it does not imply all pieces in an entire theme appear in one photo. Do not introduce repost, music or other Instagram features from the visual reference.

Acceptance for the required-piece rule: reject photo-only publication; show Piece, Outfit and Theme previews; reject empty-theme publication while allowing private empty themes; retain draft on missing piece/save failure; require explicit disclosure before publishing private piece snapshots; revalidate ownership/access and every photo association. S02 demonstrates Noah’s Piece post and opens S35. S30–S34 illustrate sharing types, Theme content, missing-piece validation and Piece/Theme review.

Search uses All / People / Pieces / Outfits / Themes with distinct result layouts and one shared state contract. See [Search and feeds](../design/search-and-feeds.md) for initial, typing, loading, empty, failed, offline, pagination and end states, scope isolation, stable anchors and access revalidation. All and Following use the same continuation footer.
