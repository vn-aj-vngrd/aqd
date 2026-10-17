# Wardrobe

A durable, searchable record of owned clothing, footwear and accessories. Entry: Closet → Add (or Agent). Manual capture never needs an account, network or AI.

## Piece

| Field | Rule |
| --- | --- |
| ID, ownership | Stable, app-managed. |
| Name | Required, trimmed, 1–80 characters. |
| Category | Required: Tops, Bottoms, Dresses, Layers, Shoes, Accessories (names editable in Manage categories). |
| Photo | One accepted local cover photo is required to save a new piece. Existing pieces missing media show a category placeholder. |
| Color, brand, size, fit, material, season, tags | Optional and searchable. Empty means unknown; fit is never inferred. Single values ≤80 characters, ≤20 tags of ≤40. |
| Condition, ownership age | Optional; approximate ages never become fabricated dates. |
| Prior wear count | User estimate 0–10,000, separate from dated wear records. |
| Availability | Available, unavailable or laundry. Archive is a separate lifecycle state. |
| Notes | Private, ≤2,000 characters, excluded from Agent context. |
| Provenance | Added and updated times; samples and machine-proposed metadata are marked. |

## Capture

Add piece follows the [modal pattern](../../DESIGN.md#add-and-edit-modal-pattern): photo hero with a native source menu (Photos, Camera, Edit, Remove background, Remove photo), a Name field, category chips, and a More details sheet.

- Save needs photo, name and category. A plain hint names what is missing.
- Cancel, denied or failed photo capture keeps entered fields. Denied camera offers Settings, Photos or Keep draft. A corrupt image shows an error without losing metadata. A replacement photo applies only after preparation succeeds.
- Photo framing is full-source Fit in a portrait preview with optional crop, pan, zoom, 90° rotation and reset. The original is kept app-private and the Photos asset is never altered. **Cut out piece** is a core capture tool. By default (Settings → Photo cutout: Automatic, Ask each time or Off) a new photo is cut out on-device with Apple Vision as soon as it is added, with progress on the photo card. **Cut out** / **Refine** on the card, a piece's menu and Add piece's photo menu open the editor: Erase and Restore brushes, Trim sides, zoom, softness, background (Transparent, White or Soft gray), undo and redo, Original compare, Reset and Use original. Done saves a full-size derived photo (transparent by default) and records "fit to piece" as a crop recipe, so the original is never altered and Reset always works. Refine rebuilds its mask from the saved photo's alpha channel, so no extra data is stored. Plain-language hints flag low resolution (short side under 800 px), a piece touching the photo edge, a small piece, a mostly kept background, or no piece found. An optional **Review after cutting out** setting (off by default) opens the editor right after the automatic result, or after a failed one, so it can be refined before saving; Crop and Cut out stay available on the photo in every mode, so manual control is never lost. Nothing leaves the device. Apple Intelligence has no public background-removal API, so Vision is the engine; the editor works fully by hand when detection finds nothing.
- Where a classifier is supported it proposes editable fields; user edits win and failure never blocks manual entry.
- Save is atomic and one step: the sheet closes and the closet scrolls to the new piece, with a success haptic. There is no receipt screen and nothing chains into Build outfit or Create theme. A receipt left unacknowledged by an earlier interruption is finished quietly the next time Add piece opens; only if that write fails is a plain receipt with Done shown. Failed saves keep the draft and prepared photo.
- The photo card offers Crop and Cut out (Refine once cut out) directly. Photos from Photos or the Camera are accepted up to the device's full resolution; sources above 40 megapixels (a 48 MP capture) are scaled down on decode instead of rejected. Where automatic cutout isn't available the card says so and the manual editor does the job.

## Browse and lifecycle

Pieces are filtered by a Category chip row (All and each category, the same control as the outfit picker) and a Status filter menu (All, Available, Unavailable, Laundry, Archived) whose icon fills while a status filter is active. Pieces also support metadata search and sort by recently added, name, most or least worn. They combine, and clear restores everything. Search is scoped to Pieces, Outfits and Themes, owner-only, offline, with per-tab state kept.

- **Edit** keeps the ID; a failed write changes neither the stored nor the visible record.
- **Archive** keeps outfits and history and marks affected future plans unavailable. Restore never erases history.
- **Delete** first previews affected outfits, theme membership through them and future plan entries. Delete removes piece references, drops emptied outfits and leaves affected future entries dated but unassigned. Historical wears keep a minimal non-photo snapshot.
- **Readiness** for a first outfit is derived, not stored: a top, bottom and shoes, or a dress and shoes, from available pieces. Missing categories offer capture with the category suggested.

## States

Piece detail shows the photo, a tappable availability status, a **Style this** action (available pieces only), an **In outfits** strip and wear history; More has Style this, Edit, Cut out photo, Availability, Archive and Delete. An empty closet offers Add a piece; empty filters offer Clear filters. Loading differs from empty. Unreadable storage offers recovery and blocks overwrite. Destructive changes need review.

## Acceptance

- A shoe saved with a photo, name and category reopens after restart.
- Cancelling or failing photo capture keeps fields; Save stays disabled until a valid photo exists.
- Search plus filters combine and clear. Archive and restore keep outfit and wear history.
- Delete preview matches the result, including an unassigned future plan.
- Old prototype data migrates with IDs, images, notes and wear intact; newer or malformed data is never overwritten.
