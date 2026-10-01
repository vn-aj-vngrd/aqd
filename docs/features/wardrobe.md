# W — Wardrobe

## Outcome and entry points

The user has a durable, searchable record of owned clothing, footwear, and accessories. Entry: Closet → Pieces → Add; Profile's Add opens the same capture flow; Agent requests capture through that flow. Owner-only management is separate from public presentation in [Profile](profile-account.md).

First use offers a private empty closet, with optional samples explicitly identified. A short optional style setup asks go-to occasions and preferences; skip is supported. No required avatar, body measurements, item quota, or style quiz blocks the first save. Show the next useful task after saving: add another piece or build an outfit. Suggestions depend on available categories, not a fixed “five items” onboarding threshold.

## Saved inspiration shortcut

Closet → More → Saved inspiration opens the existing private bookmarked-post collection (W30 → S08/S29). The shortcut is available from Pieces, Outfits, Themes and the empty closet. Use a native toolbar Menu popup anchored to More, with a trailing bookmark symbol and a 44-point More target and the accessible label “More closet options”; selection dismisses the menu and pushes the collection. Back restores the originating Closet tab, filters and scroll position. Outside-tap dismissal changes nothing and returns focus to More. Add uses a separate native bottom sheet over the dimmed Closet; its detents adapt to content and accessibility text.

Community hearts remain in Profile → Settings → Liked posts. Hearts on owned outfits remain Closet Favorites. Saved inspiration contains external posts, separate from owned inventory: bookmarking never adds a piece or outfit to the closet. Make my version starts the existing reviewable outfit flow; removing a bookmark updates the same collection from either entry. Guests retain the destination through sign-in; offline, loading, empty, retry and unavailable-post states reuse the collection contract in [Discovery](discovery-publishing.md).

## Item contract

| Information | Rule |
| --- | --- |
| ID and ownership | Stable identity; managed by the app, not editable in the form. |
| Name | Required, trimmed, 1–80 characters. |
| Category | Required: Tops, Bottoms, Dresses, Layers, Shoes, Accessories. |
| Photo | Optional cover image in the first slice. User selects it or captures it; missing image has a category placeholder. |
| Color, brand, size, fit, material, season, tags | Optional, searchable metadata. Empty means unknown; fit is not silently inferred as Regular for new items. |
| Condition and ownership age | Optional descriptive values; approximate ages are not converted into fabricated purchase dates. |
| Prior wear count | User estimate, integer 0–10,000; separate from dated AQD wear records. |
| Availability | Working default: available, unavailable, or laundry. Archive is a separate lifecycle state. |
| Notes | Private free text, excluded from publication and Agent context unless a later explicit consent flow allows it. |
| Dates and provenance | Added/updated time; identify samples and proposed machine metadata separately from user-confirmed information. |

Text defaults: optional single-value metadata up to 80 characters, up to 20 tags of 40 characters each, notes up to 2,000 characters. Preserve legacy text on migration; editing reports an exceeded limit rather than truncating existing data silently.

## Capture and classification

V1 classification is manual. Automatic photo classification/tagging and visual cleanup are [V2 enhancements](../product/v2-backlog.md); the capability behavior below is future guidance, not required launch work.

1. Select Photos, Camera, or manual entry. Choose a cover photo or continue without one.
2. Preserve the draft while loading/preparing media. Preview the image before saving.
3. Provide name/category; expand optional details when needed.
4. If classification is supported, present proposed fields for review. User changes win; uncertain fields remain unknown. If unsupported or failed, manual completion remains available.
5. Save atomically, show the saved item, and expose add-another/build-outfit actions.

Use the existing photo normalization where suitable; read source for exact image limits. Picker cancellation keeps the draft. Denied camera access offers Photos/manual entry. Corrupt/unsupported images show an error without losing metadata. Photo replacement applies only after preparation succeeds. Batch uploads, receipt import, shopping databases, scanning, selfie garment extraction, background cleanup, and multiple photos are later slices, not prerequisites.

## Browse and lifecycle

### First-outfit activation and repeated capture

W27 reviews a selected photo beside the required name/category fields. Optional metadata lives in More details; Change photo uses the same picker. Manual/no-photo capture uses W07. If a supported classifier proposes fields, identify them as proposals and let edits win; loading/failure must not block manual entry or imply image cleanup.

After the first confirmed save, E12 offers Build my first outfit and Open my closet. The former carries the saved piece into W28/W29 and the outfit builder. W28 shows only missing categories for the requested form and links each to the normal capture/editor with the category suggested, not silently committed. Saving or cancelling returns to the same starter task with the pinned piece intact. Do not replay Welcome, preferences or acquisition prompts for each addition. Failed saves retain both metadata and prepared photo and do not advance readiness.

Readiness is derived from current active, available owned records: a top, bottom and shoes, or a dress and shoes. It is not a persisted onboarding completion counter, purchase recommendation or arbitrary minimum item count. An unavailable/archived/deleted piece stops satisfying a slot. The pinned piece and requested form determine relevant gaps; layers/accessories are optional. W29 names the candidate pieces and exposes Suggest an outfit plus Build manually. Missing categories still allow a partial manual look, visibly described as incomplete. Once an outfit exists, default entry moves to saved looks/planning rather than repeating first-outfit setup.

Pieces supports category, availability/archive filters, metadata search, and sort by recently added/name/most or least worn. Search/filter/sort combine; clear restores the collection. Last-worn sorting treats unknown history explicitly. Item detail shows source information and actual/estimated wear counts as defined in [Planning/history](planning-history.md).

Edit updates the same identity. Archive preserves outfits/history and marks affected future plans unavailable. Restore does not erase history. Delete first previews affected outfits, theme membership through those outfits, and future entries. Working default: delete removes item references; empty outfits are removed; affected future entries retain date/occasion but become unassigned and require outfit re-selection, including when a surviving outfit loses a piece; historical wears keep a minimal non-photo snapshot. Public-post lifecycle follows [Publishing](discovery-publishing.md), not an implicit cascade.

## States

Empty closet offers Add. Empty filtered results offer clear filters. Loading is distinct from empty. Save failure retains the draft and leaves persisted data unchanged. Unreadable storage offers recovery and blocks overwrite. Destructive changes require explicit review. Offline/private use does not require social sign-in.

## Acceptance

- W1: Save a manually classified shoe without photo or optional details; reopen it after app restart.
- W2: Cancel/deny/fail photo capture; entered name/category remain and manual save works.
- W3: Edit an imported item without changing its ID; a failed write changes neither the stored nor visible record.
- W4: Search a color and apply category/archive filters; clearing them restores expected results.
- W5: Archive/restore a used piece without losing outfit or wear history.
- W6: Deletion preview and resulting references match the stated lifecycle, including an unassigned future plan.
- W7: Existing prototype wardrobes migrate with IDs, images, notes, and wear history intact; malformed/newer data is not overwritten.
- W8: First save offers the outfit path; capture missing categories without replaying onboarding and preserve the original pinned piece through save/cancel/restart.
- W9: Top/bottom/shoes and dress/shoes wardrobes reach readiness; a single accessory does not. Archive/unavailability removes eligibility. No fixed upload count, photo or account requirement blocks manual composition.
- W10: Selected photo is reviewable and replaceable; manual fallback and user edits survive classification failure. A failed save never shows a receipt or changes readiness.

- W11: Open Saved inspiration from each Closet tab/empty state; return to the same collection position. Bookmark removal is reflected from Profile too; community likes never appear as owned Favorites.

## Dependency boundary

First slice needs local persistence, media picker, item editor, detail, and collection. Assisted tagging and connected backup are separately gated capabilities. Treat this as a complete vertical feature, not merely a clothing-card component.

Closet search has Pieces / Outfits / Themes scope tabs with owner-only results and preserved per-tab query/filter/scroll state. Reuse [Search and feeds](../design/search-and-feeds.md) for loading, empty, read failure, image fallback, stale data and pagination. Local search remains available without a community network connection; an unavailable remote service must not block owned local records.
