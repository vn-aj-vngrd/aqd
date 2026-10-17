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
- Photo framing is full-source Fit in a portrait preview with optional crop, pan, zoom, 90° rotation and reset. The original is kept app-private and the Photos asset is never altered. **Cut out piece** is a core capture tool, offered on the photo and in its menu. On-device subject detection (Apple Vision) proposes the cutout; the user refines it with Erase and Restore brushes, Trim sides, zoom, undo/redo and a compare-with-original toggle. Done saves a full-resolution transparent PNG, cropped to the piece when Fit to piece is on, and keeps the original for Reset. Nothing leaves the device. Apple Intelligence has no public background-removal API, so Vision is the engine; the editor works fully by hand when detection finds nothing. Listing-quality photos matter, so transparency is the default output.
- Where a classifier is supported it proposes editable fields; user edits win and failure never blocks manual entry.
- Save is atomic. The receipt shows the photo first with Build outfit, Add another piece and Open my closet. Failed saves keep the draft and prepared photo.

## Browse and lifecycle

Pieces support category and availability/archive filters, metadata search and sort by recently added, name, most or least worn. They combine, and clear restores everything. Search is scoped to Pieces, Outfits and Themes, owner-only, offline, with per-tab state kept.

- **Edit** keeps the ID; a failed write changes neither the stored nor the visible record.
- **Archive** keeps outfits and history and marks affected future plans unavailable. Restore never erases history.
- **Delete** first previews affected outfits, theme membership through them and future plan entries. Delete removes piece references, drops emptied outfits and leaves affected future entries dated but unassigned. Historical wears keep a minimal non-photo snapshot.
- **Readiness** for a first outfit is derived, not stored: a top, bottom and shoes, or a dress and shoes, from available pieces. Missing categories offer capture with the category suggested.

## States

Empty closet offers Add. Empty filters offer Clear. Loading differs from empty. Unreadable storage offers recovery and blocks overwrite. Destructive changes need review.

## Acceptance

- A shoe saved with a photo, name and category reopens after restart.
- Cancelling or failing photo capture keeps fields; Save stays disabled until a valid photo exists.
- Search plus filters combine and clear. Archive and restore keep outfit and wear history.
- Delete preview matches the result, including an unassigned future plan.
- Old prototype data migrates with IDs, images, notes and wear intact; newer or malformed data is never overwritten.
