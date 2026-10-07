# O — Outfits and themes

## Phase boundary

V1 completes local manual/assisted owned-item outfits/favorites/pin/replacement and independent themes/multiple memberships. Public sharing and inspired community creation are V2; no publication control appears in V1. See [V1 release](../product/v1-release.md), [V2 backlog](../product/v2-backlog.md) and [V2 design](../design/v2-requirements.md).

## Outcome

Users compose and retain owned-wardrobe looks and organize them into reusable collections. Entry: Closet → Outfits/Themes; Add → Build an outfit; an item detail's “Style this”; focused assistance or [Agent](agent.md). V2 public display is a separate [publication](discovery-publishing.md).

## Contracts

An outfit has stable ID, owner, required trimmed name (1–80 characters), ordered unique owned item references, optional mood/occasion, theme memberships, favorite state, and dates. Save requires at least one active owned piece; an incomplete manual combination is allowed and is not presented as a complete recommendation. Working suggestion default: top + bottoms + shoes, or dress + shoes, with optional layer/accessories. Record why a draft cannot satisfy the requested form.

A theme has its own ID, owner, name (1–40 characters), optional description, and explicit outfit membership. It may be empty. Working default: outfits can belong to multiple themes; theme names are case-insensitively unique per owner. Renaming preserves membership; deleting a theme does not delete its outfits. “Everyday” is not forced onto every saved outfit.

Migrate existing theme strings into theme records and memberships without renaming outfits. Existing standalone theme names become empty collections if unused. Preserve memberships if later edits remove the last outfit.

## Manual creation

1. Choose owned active items, including a preselected piece when entered from item detail.
2. Preview the composition; select/deselect and replace pieces without losing name/context.
3. Name the look and optionally choose/create themes.
4. Save privately; show its detail and actions to Plan or Record wear. Only V2 adds a separate reviewed publication action.

Filters/search apply to the chooser, not only the closet grid. Selected pieces remain visible when filtered out. Archive/removal during editing surfaces an invalid selection and offers remove/restore. Saving twice through retry creates one outfit for the same save operation. Cancelling dirty edits offers keep/discard. Save failure retains the draft.

## Assisted creation

Focused “Suggest an outfit” supplies chosen pieces, mood, occasion, date/place if available, and explicit preferences. It uses [Agent's proposal contract](agent.md), not a separate persistence path. Users can pin an item; a replacement proposal changes only the selected slot unless asked otherwise. Accepting a replacement preserves pinned items and other draft fields.

A generated theme is a proposed name/description/membership; review each before save. Suggestions never import public-source garments into ownership. Available context and missing pieces are visible. User decisions remain authoritative over proposed tags/style.

## Collection and detail

### First usable outfit

E12 and Today link to the same first-outfit task: W28 when categories are missing, W29/W17 when a complete suggestion is possible, or W13 for manual composition. Carry the first saved piece as an explicit pin; the user can unpin it. Readiness is evaluated against the requested outfit form and current availability, not a fixed inventory size. If no supported form can include the pinned piece, explain the gap and offer a different form, unpin or manual composition.

Review the proposed owned pieces before saving; replacing a slot returns to the same review with name, occasion, pin and other pieces preserved. V1 saved detail offers Pieces, Plan and Record wear, with trailing More → Edit outfit / Favorite / Delete using scoped draft/confirmation safeguards. There is no Share/publication control. V2 additionally offers Share as a separate reviewed-publication action. Saving is private and does not create a calendar entry or actual wear. Runtime failure offers manual composition with the draft intact. Partial manual looks remain valid but are not labelled complete suggestions. No style quiz or theme membership is required for a first outfit.

Browse outfits with search, theme and favorites filters. Detail opens each piece, shows unavailable references, and supports private edit, plan, wear, favorite and reviewed delete. Only V2 additionally supports reviewed publication. Theme detail contains member outfits and add/remove membership. Empty themes offer Add outfits. Favorites on owned outfits are distinct from community bookmarks.

## Acceptance

- O1: Build/save/reopen a manual outfit, then edit it without replacing its ID.
- O2: Select items, filter the chooser, and retain selections/draft text.
- O3: Create an empty theme; assign an outfit to two themes; rename/remove one without deleting the outfit.
- O4: Migrate single-theme prototype data and standalone names without losing outfits or membership.
- O5: A suggested replacement preserves pinned pieces and never introduces unowned IDs.
- O6: AI failure or unsupported devices offer manual creation; cancelling generation creates no saved record.
- O7: Failed/retried saves retain edits and avoid duplicate outfits/themes.
- O8: Create the first usable outfit from the capture/readiness path, preserving the pin through replacement; approve/save once and open the same persisted identity.
- O9: Choose manual composition from missing-category, ready and unavailable-assistance states. Partial looks are identified and remain editable; planning and wear occur only through their own reviewed actions; publication is V2-only and requires its own review.

## Dependencies

[Wardrobe](wardrobe.md) IDs/lifecycle are required. Manual composition precedes assisted composition. Planning and V2-only publishing consume the same saved outfit identity; neither is required for the first manual slice. V1 never exposes a connected publication action.
