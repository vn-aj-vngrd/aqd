# Outfits and themes

Users compose looks from owned pieces and organize them into reusable themes. Entry: Closet → Outfits or Themes, Add → Build an outfit or Create theme, a piece's "Style this", or Agent. No publishing in V1.

## Contracts

- **Outfit:** stable ID, required name (1–80), ordered unique owned piece references, optional mood and occasion, theme memberships, favorite flag, dates. Save needs at least one active owned piece; partial looks are valid and never called complete.
- **Theme:** own ID, name (1–40, case-insensitively unique), optional description, explicit outfit membership. May be empty. An outfit can be in many themes. Rename keeps membership; deleting a theme never deletes outfits.
- Saving twice through retry creates one record. A save failure keeps the draft. Cancelling a dirty draft offers Keep or Discard. A piece archived or removed mid-edit is flagged and offers remove or restore.

## Build outfit

Manual only; no readiness, pin or suggestion step is shown. Follow the [modal pattern](../../DESIGN.md#add-and-edit-modal-pattern).

1. A pinned live canvas shows the chosen pieces; tap one to remove it.
2. A resizable picker (collapsed, peek, medium, large) lists pieces with category chips and search at larger sizes. Unselected pieces come first; selections persist across filters.
3. The name defaults to "<Weekday> look" when empty; edit freely. Theme chips add or change memberships.
4. Save is private and shows the result with Open outfit and Plan this look. It never creates a plan or wear.

Existing suggestion drafts open in this editor; applying a manual selection clears obsolete pins and proposal metadata and revalidates IDs and revisions.

## Create theme

A sheet with a live collage cover from member outfits (generated, not stored), name, optional description and an inline outfit card picker with a selection count. The Themes grid, editor and theme chooser share the same `ThemeCover`. Saving opens the new theme.

## Browse and detail

Outfits browse with search, theme and favorites filters. Themes filter All, With outfits or Empty, and sort Name A–Z, Z–A or Most outfits; ties use name order then ID. A filtered-empty list offers Clear filters; a truly empty one offers Create theme. Reading and filtering never write.

Outfit detail shows the composition, the themes it belongs to (as links), Plan and Record wear, then its pieces as photo rows that open the piece (unavailable references are labelled), and a More menu with Edit, Favorite and a reviewed Delete. Delete names its theme and plan impact and keeps pieces, photos and recorded wear. Theme detail shows the collage cover, a count and its outfits in the same grid as the Outfits tab, with Add outfits in More. Empty lists offer Build an outfit or Create a theme. Owned favorites are separate from community bookmarks.

## Acceptance

- Build, save, reopen and edit an outfit without changing its ID.
- Filter and search the picker while keeping selections and the draft.
- Assign an outfit to two themes, then rename or remove one without deleting the outfit.
- Old single-theme prototype data migrates without losing outfits or membership.
- Failed or retried saves keep edits and create no duplicates.
