# Profile and Settings

Profile is a private dated fit journal plus optional local identity. It is not an online account: no sign-in, followers, public counts or uploads.

## Fit journal

- A **fit memory** has a stable ID, an editable calendar date (default today) with timezone, an optional local photo, an optional linked outfit and a private note ≤500 characters. Save needs a photo **or** an outfit.
- Without a photo the linked outfit's real piece composition is shown, never a fabricated wearer photo. Linking stores a minimal outfit snapshot (names, ordered pieces, categories) that survives outfit edits and deletion.
- **Add fit** starts from a source: the Profile **+** menu offers Take photo, Choose from Photos and From an outfit, and the editor opens already on that source. It follows the [modal pattern](../../DESIGN.md#add-and-edit-modal-pattern): a hero photo card (native source menu), an inline outfit strip with a No outfit chip, a note, then a collapsed Date row (date and timezone). Over-limit notes keep their text with inline validation; nothing is truncated silently.
- When an outfit is already planned for the fit's day, one tap on "Planned for this day" links it. One plain line says what a new fit still needs ("Add a photo or choose an outfit to save.").
- With an outfit linked, an off-by-default **Record wear next** toggle opens Record wear after saving. Saving never records wear; the count changes only when the wear is confirmed there. Fits are not shared or exported from the journal.
- The journal groups fits by month, and orders them newest or oldest first. Profile has no search. The Fits, Outfits and Pieces counts open their lists; Wear history is under More.
- Adding, editing or deleting a memory never records wear or changes counts. Only an explicit Record wear does.
- Deleting a memory removes only that memory and unshared photo copies; the outfit, wear history and original Photos stay.
- Profile shows real counts of Fits, Outfits and active Pieces, or an unavailable state on read errors.

## Identity and preferences

- Optional name, photo and caption (default "A little of what I wear."; trimmed, ≤160 characters; an explicit empty caption stays hidden). Tapping the avatar opens Edit profile.
- Edit profile, Wear insights and Add fit are reachable from Profile; More opens Style, Settings and help.
- First run is one path: Welcome has a single Start button, which opens the style questionnaire; saving it offers Show me around (a seven-step, skippable tour that names the button for each action) or Skip the tour. Both end in Closet. Settings can replay the tour at any time.
- Style preferences use one seven-step questionnaire from onboarding, Settings and Profile: goals, occasions, style, fit and comfort, colors and patterns, optional height and body shape, then review. Each step needs an answer or No preference; unknown stays unknown. Next stays tappable: on an unanswered step it explains what is needed inline, with a haptic and a VoiceOver announcement, instead of sitting dimmed. Body use for suggestions is off by default and revocable. These are never public or photo-derived.

## Settings

Appearance (System, Light, Dark), permission guidance, local profile and preferences, Agent and weather controls, local archive export and reviewed restore, and local erase (exported copies and original Photos are outside erase). No inactive account, sync, push or billing toggles.

## Acceptance

- Save a photo-only, outfit-only and photo-plus-outfit memory; date-only cannot save.
- A memory keeps its outfit snapshot after the outfit is deleted and never counts as wear.
- Export, restore and erase work as reviewed, replacing data only after staged validation.
