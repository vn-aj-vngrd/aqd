# Profile — private fit journal

October 6, 2026. Owner-approved design/spec expansion, not implemented functionality. [Profile feature](../features/profile-account.md#v1-private-fit-journal) owns record validation, privacy, media lifecycle and acceptance. [Planning/history](../features/planning-history.md) owns actual wear. Paper owns visuals; [verification](../delivery/verification.md) records static versus native evidence.

## Direction and composition

Personal like a photo album, familiar like an Instagram profile grid, restrained like native iOS Photos. Profile shows dated memories rather than duplicating Closet. V1 has no public username, follower counts, hearts, comments, Share or Post action. The only toolbar action is native More, containing Add fit, Edit profile, Style, Wear insights and Settings; no separate Settings, Edit profile or Add fit control remains on the journal root. V2 can publish a selected memory only through explicit review; the default V2 owner Profile uses the same private journal base, while public collections remain a separate explicit extension.

Canonical populated Profile L48 keeps the native root header/navigation and uses the paired Foundations roles. Dark duplicate L57 has been removed from the simplified canvas; native dark appearance remains required.

- A 64-point optional avatar/initial, name at 28/34 medium, one-line 15/21 style summary. More → Edit profile opens L49. Missing identity uses a truthful neutral local identity rather than a social-account prompt; long names wrap at accessibility sizes.
- A compact lock/privacy line, “Private on this iPhone”, at 13/18. It is not an export/recovery guarantee.
- Your fits with an actual saved-memory count; More → Add fit opens L161. Do not show a fabricated count or count wardrobe outfits as memories.
- Chronological three-column thumbnails at the 390-point reference size: 20-point page inset, 114 × 152-point 3:4 image slots, 4-point horizontal gutters, 8-point row gaps, 4-point photographic corners, and 13/18 date labels below. Photo-less entries also say Outfit so a composition is not mistaken for a wearer photo. Thumbnails may crop only the presentation; detail fits the full source and never overwrites it. Missing media is explicitly unavailable.
- No loose Style/Wear insights footer links. A single 44-point native More toolbar control opens an anchored menu with Add fit, Edit profile, Style, Wear insights and Settings; menu dismissal restores focus and journal position. Closet remains a native destination; the old Your wardrobe settings row is not reproduced here. Foundations’ Profile More reference owns the open-state composition.

The content scrolls independently of native navigation. Preserve date/scroll position after viewing or editing a memory. Larger accessibility text moves to two or one column with wrapping date/action labels, not smaller thumbnails or tap targets. Screen readers expose each memory as one target named by date, photo/composition state and available note/outfit; decorative imagery/symbols are not extra focus stops. Use [registered Foundations icons](icon-manifest.json), including the reused edit master; do not draw screen-specific substitutes.

## States and destinations

| State | Reference | Actions and return behavior |
| --- | --- | --- |
| Populated journal | L48 | More → L165 native menu: Add fit → L161; Edit profile → L49; Style → L45; Wear insights → L41; Settings → L13. Memory → L163. Back from child restores journal scroll/focus. |
| Empty journal | L160 | No example photos or invented totals. Explain private memories; More → Add fit → L161. Edit profile/Settings and Style/insights through the same More menu remain available even with no memories or wardrobe. |
| New fit, no content | L161 | Editable Date defaults to today; optional Add photo, Link outfit and private note. Save disabled until valid date plus accepted photo or linked existing outfit. A note alone cannot satisfy content. |
| New fit, ready | L162 | Save fit commits one local memory atomically, then returns to Profile with the new entry focused. Example is photo-only; no outfit/name/category prerequisite. Save failure retains draft and previous accepted media; no fake receipt or count increment. |
| Memory detail | L163 | Full-source Fit photo/composition, saved date and private note. Edit opens the same draft form with existing values; Save updates the same ID and Back retains the prior record. More → native Delete memory option; the visible Edit fit action opens L162 in edit mode. Delete requires scoped confirmation and safe Cancel, then returns to journal without deleting outfit/wear history. |

Photo source selection reuses L159's native Photos/camera sheet with **fit-draft context**, not piece-capture validation. Close/outside tap/swipe keeps the fit draft; selected source dismisses the sheet before presenting picker/camera. Photo replacement applies only after preparation succeeds. Optional editing reuses deterministic local Fit/crop/rotate controls with fit-draft return context. Link outfit opens an owner-only selection of existing outfits, including an honest empty/no-match state; Cancel retains the previous association. A linked outfit's composition snapshot remains interpretable after outfit edits/deletion, per the feature contract. Unlinking/removing the last valid content blocks Save rather than creating an empty memory.

Date uses a native date picker and stable local calendar-date/timezone semantics. A private note is optional, up to 500 user-perceived characters; show a counter in the editor, preserve over-limit input and block Save with a local error. Back/interactive dismissal protects changed drafts. Import/permission/unavailable-media/validation/save failures use retained fields, one native progress indicator when busy and actionable local recovery. Do not import the piece form's mandatory photo/name/category rules.

No journal action records actual wear or updates planning. Any later explicit Record wear action must route through the existing duplicate-safe wear flow. Photo-only memories do not infer garments or an outfit. This is a memory collection, not proof of utilization.

## V2 preparation

Reuse dated memory thumbnails and detail, but keep private journal and curated public collections distinguishable. A later Share memory action creates a separate public draft with the exact selected rendition and deliberate piece/outfit associations required by the publishing contract. Public caption starts independently of the private note; identity, audience, consent and media/safety gates still apply. Cancelling publication leaves the private memory unchanged. Editing/deleting a private memory does not silently update/unpublish a public snapshot; public lifecycle uses explicit review.

U01 now uses the shared L48 journal composition, with one More control and the separate V2 Inbox toolbar entry. U25 demonstrates its menu; U26 preserves the former public-profile composition as an explicit projection reference, not the default private root. Core Add fit and Edit profile reuse L161/L49 in V2 origin mode; U02 remains public identity editing. Style uses W20/UP01, insights P11 and Settings U05. Public collections/share-from-closet/verified public-link sharing are additive, authorized actions, never implicit publication. The V2 privacy line says Private journal · Not posted automatically rather than claiming device-only storage despite future sync. Connected sharing and native routing remain unimplemented.

## Static fixtures and evidence limits

L48 contains six illustrative memory dates, two existing Unsplash reference photographs and four existing canonical outfit compositions. The photographed people are not the user or sample identity Van. These are design fixtures, not actual uploads, wear records, community activity or production-seeded journal entries. Empty L160 contains none of them. Production uses only user-selected photos and actual saved outfit snapshots.

Photo-less fallback renders are stored in `assets/journal/`: afternoon, coffee, evening and work PNGs exported from existing Paper ORA/OY0/OSK/OSP composition references, not newly generated images. They retain the named looks in [asset mapping](../references/assets.md). These static light-ground fixture images are unchanged in dark appearance, like ordinary photo content; native composition rendering uses semantic light/dark image grounds.

Native acceptance remains required for persistence/schema and migration, memory bounds/decoding, interruption/late results/draft recovery, export/restore and backup exclusion, scoped deletion/refcounts, no implicit wear/publication, Dynamic Type/VoiceOver, keyboard-safe Save, smaller devices, dark/Increase Contrast/Reduce Transparency and native sheet/picker/camera behavior. Static Paper screenshots establish only the inspected compositions.
