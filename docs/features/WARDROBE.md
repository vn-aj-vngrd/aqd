# W — Wardrobe

## Outcome and entry points

The user has a durable, searchable record of owned clothing, footwear, and accessories. Entry: Closet → Pieces → Add; Profile's Add opens the same capture flow; Agent requests capture through that flow. Owner-only management is separate from public presentation in [Profile](PROFILE-ACCOUNT.md).

First use offers a private empty closet, with optional samples explicitly identified. A short optional style setup asks go-to occasions and preferences; skip is supported. No required avatar, body measurements, item quota, or style quiz blocks the first save. Show the next useful task after saving: add another piece or build an outfit. Suggestions depend on available categories, not a fixed “five items” onboarding threshold.

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

1. Select Photos, Camera, or manual entry. Choose a cover photo or continue without one.
2. Preserve the draft while loading/preparing media. Preview the image before saving.
3. Provide name/category; expand optional details when needed.
4. If classification is supported, present proposed fields for review. User changes win; uncertain fields remain unknown. If unsupported or failed, manual completion remains available.
5. Save atomically, show the saved item, and expose add-another/build-outfit actions.

Use the existing photo normalization where suitable; read source for exact image limits. Picker cancellation keeps the draft. Denied camera access offers Photos/manual entry. Corrupt/unsupported images show an error without losing metadata. Photo replacement applies only after preparation succeeds. Batch uploads, receipt import, shopping databases, scanning, selfie garment extraction, background cleanup, and multiple photos are later slices, not prerequisites.

## Browse and lifecycle

Pieces supports category, availability/archive filters, metadata search, and sort by recently added/name/most or least worn. Search/filter/sort combine; clear restores the collection. Last-worn sorting treats unknown history explicitly. Item detail shows source information and actual/estimated wear counts as defined in [Planning/history](PLANNING-HISTORY.md).

Edit updates the same identity. Archive preserves outfits/history and marks affected future plans unavailable. Restore does not erase history. Delete first previews affected outfits, theme membership through those outfits, and future entries. Working default: delete removes item references; empty outfits are removed; affected future entries retain date/occasion but become unassigned and require outfit re-selection, including when a surviving outfit loses a piece; historical wears keep a minimal non-photo snapshot. Public-post lifecycle follows [Publishing](DISCOVERY-PUBLISHING.md), not an implicit cascade.

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

## Dependency boundary

First slice needs local persistence, media picker, item editor, detail, and collection. Assisted tagging and connected backup are separately gated capabilities. Treat this as a complete vertical feature, not merely a clothing-card component.
