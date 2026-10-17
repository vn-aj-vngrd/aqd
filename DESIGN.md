# Design system

Source of truth for AQD UI. Code is the token source: `apps/ios/AQD/UI/AppTheme.swift`, `AppMetrics.swift`. This document defines intent and rules; when they disagree, fix the code or update this file in the same change.

## Direction

Premium through restraint: clothing photography, precise alignment, quiet opaque surfaces and native interaction. Character comes from content and proportion, not boxes or ornament. Use real clothing photos, never flat garment illustrations. Roots prioritize their task.

Roots: **Today · Closet · Planner · Agent · Profile** as five equal icon-only native tabs with explicit accessibility names. Agent opens full screen and returns to its source.

## Color

Charcoal is the only control, selection and tint color. Gold is a brand mark only (logo Q, welcome art), never UI. App-wide tint is `ink`.

| Role | Light | Dark |
| --- | --- | --- |
| Canvas | `#F7F7F5` | `#1C1C1B` |
| Surface (cards, fields) | `#FFFFFF` | `#2B2B29` |
| Image ground | `#F5F4F1` | `#242422` |
| Ink (text, tint) | `#242321` | `#F3F1EB` |
| Secondary text | `#6A6863` | `#BCB9B1` |
| Divider | `#E4E2DC` | `#4A4842` |
| Control boundary | `#807B72` | `#969187` |
| Primary fill / on primary | `#292826` / `#FFFFFF` | `#F2F0EB` / `#242321` |
| Error, success, warning | `#D4142A`, `#416451`, `#795B2E` | `#FF6472`, `#B8D0BF`, `#DCC7A2` |

Text targets 4.5:1 (3:1 large); meaningful control boundaries 3:1. Color is never the only cue: selection also uses a checkmark, fill or weight. Success means an acknowledged completion, warning means risk needing review, red means destructive or failed.

## Type, space, shape

System font with Dynamic Type. Root title 32 medium; section 22 medium; detail title 20 medium; body and action 17; supporting 15; metadata 13.

Space scale 4, 8, 12, 16, 20, 24, 32, 40, 48. Screen inset 20. Related controls 8–12, groups 16–24. Photos 4 radius; fields 16; grouped surfaces 12; composer 28; pills for buttons and chips. Hit targets are at least 44 pt even when the visual is smaller. At accessibility sizes labels wrap, actions stack and grids become one column.

## Components

Reuse these; a hand-built equivalent is a defect.

| Need | Component |
| --- | --- |
| Primary action (50 pt, solid) / secondary (plain text) | `PrimaryAction`, `SecondaryAction`, in `ActionStack` and `ActionFooter` |
| Confirm in a sheet toolbar | `ToolbarSaveAction`: native prominent capsule, charcoal fill |
| Selectable pill (category, filter) | `AppChip` |
| Compact tappable white control or round icon button | `glassControlSurface(shape)` |
| Text input, picker with label and validation | `LabeledField`, `LabeledControl` |
| Disclosure row, grouped rows | `DisclosureRow`, `SurfaceGroup` |
| Photo source | Empty: direct Take photo and Photos buttons. With a photo: a compact ellipsis menu (`SharedPhotoSourceButton`) plus visible Crop and Cut out buttons. Never use a large card as a menu label: the system glass menu morphs from its anchor and clips. |
| Pick one outfit / several pieces inline | `OutfitSelectionStrip`, `PieceSelectionStrip`, with `selectionIndicator` |
| Theme cover collage | `ThemeCover` |
| Empty, error, progress | `AppEmptyState`, `SemanticFeedback`, `OperationProgress` |
| Confirmations and alerts | `appConfirmation`, `draftDiscardConfirmation`: one shared card, 20 pt padding, text aligned with buttons, no native `.alert` or `.confirmationDialog` |

**Glass.** Compact controls use native interactive regular glass on iOS 26+. Reduce Transparency, Increase Contrast and older systems fall back to a flat white surface with a divider hairline. No hand-drawn shadows. Rows, cards and fields stay flat and opaque; never put glass on glass or on ordinary content.

**Fields.** Opaque, 16 radius, 14 padding, persistent label, no border, blur or shadow; keep focus, invalid, disabled and Increase Contrast states. Labels omit Required and Optional.

## Add and edit modal pattern

Every Add, Create, Plan and Record editor follows this structure.

1. **Hero first.** A live preview of what is being made tops the sheet: photo card, outfit canvas, theme cover or chosen-outfit preview. It uses the image ground with 16 radius, updates as choices change, and its empty state says what to do next.
2. **Choose inline, never push.** Select owned content on the same screen with chips, selection strips or a resizable detent sheet (Build outfit: collapsed, peek, medium, large). A simple choice never pushes a chooser or nests a sheet in a push.
3. **Photo sources are direct.** Empty state shows Take photo and Photos; a compact menu handles replace and remove. No popovers, no large menu anchors.
4. **Compact fields,** name first, optional detail last (a More details row or sheet).
5. **Toolbar confirm.** Close (x) leading, Save trailing. When Save is unavailable, one plain secondary line says what is missing (not red). A dirty close uses the shared discard confirmation.
6. **Save and return.** Save closes the sheet and returns to the list with the new item in view and a success haptic. No receipt screen, and no save that opens another editor or pushes a detail. Related tasks (Style this, Add to theme) are offered where the item lives, not chained after a save.

Build outfit specifics: the canvas stays pinned and fills the space above the picker, ordering garments large (layers, tops, dresses, bottoms) with shoes and accessories in a smaller strip; the picker lists unselected pieces first; a new outfit's name defaults to "<Weekday> look".

## Imagery and copy

Show full-source Fit photos and compositions of actual pieces; preserve proportions. Missing media shows a quiet category symbol and name. Task copy: Add piece, Build outfit, Review changes, Save outfit. Explain privacy at the affected choice. AI output stays a draft until a saved receipt.

- **No dot separators.** Never join metadata with " · ". Use spacing, a trailing-aligned value, separate lines, or commas for VoiceOver labels.

## Accessibility and privacy guardrails

Semantic labels, traits and values on every control; keyboard-safe editing; light and dark; Reduce Motion replaces transitions with fades. No implicit wear, publication, body-use, AI or weather consent, and no private-photo upload. Weather-free private journeys work offline.

## Detail screens and empty states

Piece, outfit and theme details share one structure: a hero (photo card, composition or theme cover), a status or info line, the primary action, then sections (pieces, themes, "In outfits") with thumbnails. Related records link to their own detail. Options live in one trailing More menu with Edit first and destructive actions last. Every empty list offers exactly one next action: Add a piece, Build an outfit, Create a theme, or Clear filters when filters hide content.
