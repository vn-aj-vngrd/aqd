# AQD component contracts

Shared visual definitions live on [Paper page 00](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-1-0). [DESIGN.md](../../DESIGN.md) owns usage and the native target; [screen map](screens.md) owns routes. Feature specs own data rules. These are logical components, not a requirement to create one file per row.

## Foundations and native chrome

| Component | Canonical builder | Native implementation | Contract |
| --- | --- | --- | --- |
| Semantic tokens | `TOKENS`, `DARK_TOKENS` | Asset/semantic colors and system text styles | One place to change colors, type roles, space, radii. Dark mapping is semantic, not inverted photography. |
| Status/safe area | `status` | System-owned | Keep native status, home indicator, keyboard and safe-area insets. Reference status markup is illustrative. |
| Root/detail header | `header` | NavigationStack/UINavigationController | Root title versus compact detail title; native glass Back and toolbar actions, system back label/history and swipe gesture; preserve title at large text. |
| Glass tab bar | `nav` | TabView/UITabBarController | Five named destinations, selection, restored navigation state and accessible selected trait. Agent presentation exception is in DESIGN.md. |
| Toolbar icon button | `icon`, `header` | Button/ToolbarItem or UIBarButtonItem | 44-point target; SF Symbol plus accessibility label; loading/disabled/destructive semantics. Search/Add may group by task. |
| Search | `search` | searchable/UISearchController | Explicit scope, query, clear, cancel, keyboard, loading/results/empty/error, retained selection and scroll state. |
| Primary/secondary action | `button` | Native Button with glass/glassProminent style | Standalone primary uses tinted glassProminent; secondary uses glass. Inline content actions retain native plain style. One primary action; label retained during progress; duplicate submission prevented; disabled reason explained beside decision. |
| Segmented control | `tabs` | Picker segmented/UISegmentedControl | Mutually exclusive view state; selected trait; no form submission side effect. |
| Filter rail | `chips` | Native controls in horizontal scroll | Multiple/filter-specific selection, reset, real result updates, 44-point hit area even if visible capsule is smaller. |
| Menu and sheet | Screen composition + row primitives | Menu, confirmationDialog, sheet | Anchor to trigger; sensible detents; accessible dismiss; dirty edits get keep/discard choice; keyboard never covers action. |

## Reusable content

| Component | Canonical builder | Inputs and output | Required states |
| --- | --- | --- | --- |
| Text roles | `textBlock`, `title`, `muted`, `section` | Semantic role + text | Dynamic Type, wrapping, localization; avoid fixed-height text. |
| Field | `field` | Label/value/validation → draft edit | One regular-glass input shell around native editing; empty, entered, focus, invalid, read-only, keyboard, saving; retain failed edits. |
| List row | `row`, `grouped` | Title/value/accessory → action | Fixed trailing lane; optional supporting text; selected/disabled/destructive roles. Grouped cards show inset separators only between rows, never beneath the last or only row. |
| Selection/toggle row | `checkRow`, `toggleRow` | Label/current value → intent | Color plus check/state; native switch semantics; confirmation for material privacy changes. |
| Piece tile/grid | `garment`, `garmentRow` | Owned/public item image + concise metadata | Missing image, loading/error, available/laundry/archived, chooser selected/pinned; one-column accessibility layout. |
| Outfit composition | `composition` | Resolved selected item references | Photo proportions, missing/archived reference, pin/replace, incomplete manual combination; no invented ownership. |
| Outfit/plan row | `outfitRow` | Image/title/date/status → detail | Planned/worn/skipped/unassigned, stale composition, multiple occasions per day. |
| Creator/profile | `creator`, `avatar`, `portrait` | Public identity + capabilities | Owner versus visitor, no avatar, loading, blocked, unavailable; truthful public counts. |
| Calendar and week | `calendar`, `week` | Explicit timezone/date/entries → selection | Selected/today/assigned distinctions, month boundaries, multiple entries, gaps, accessible agenda alternative. |
| Chat row/message | `chatRow`, `bubble` | Authorized sender/text/time/delivery | Pending, sent, failed, unknown, request, unavailable shared reference; no inferred read receipt. |
| Composer | `composer` | Draft/recipient → reviewed send intent | Empty disabled, keyboard, sending, failed retained draft, length validation. |
| Notice/empty | `note`, `empty` | Feature-specific problem and recovery | Loading vs empty vs offline vs service unavailable vs permission denied; retain useful content. |
| Proposal/receipt | Shared image, row, note, action primitives | Typed proposal/revision/result → review/edit/approve | Draft, stale, executing, succeeded, failed, unknown, cancelled; result links require actual committed identity. |

## Native surfaces represented by contracts

Apple sign-in, Photos/Camera picker, Share sheet, date picker, keyboard, system permission alerts, context menus, destructive confirmations and text-selection/edit menus use standard system controls. Their exact geometry is OS-owned. Reference artboards illustrate entry/return and task copy, not a requirement to reproduce the OS in custom views.

## Shared behavior

The reference builders produce static review markup. They contain no persistence or authorization. Implementation receives feature state and emits user intent; trusted domain operations validate and execute. Extract shared implementation only for actual repeated use. Match states and behavior as well as appearance.

Production acceptance: screen reader name/role/state, 44-point target, accessible text, reduced motion/transparency, native keyboard/Back behavior, sensible focus after sheets, error recovery, and current data-access checks. Test representative long names, empty results, photo failures and slow/offline service behavior.

## Toolbar reuse and Paper synchronization

The page 00 toolbar text and toolbar icon masters own toolbar geometry. Cancel, Done, Save and Skip use the text variant; Cancel uses neutral semantic ink, with blue reserved for primary actions and selected states; icon actions use the icon variant. Full-width sheet/form dismissal uses the secondary button variant because its placement differs.

Dimensions bind to Paper tokens (`--spacing-control-height`, `--spacing-control-text-min`, `--spacing-control-padding`, `--leading-control`). Change token values once to update bound instances. For geometry changes, update the master and affected clones, then inspect representative screens. Clones do not automatically inherit structural changes.

Paper clones are snapshots, not linked component instances. Color and dimension token changes propagate; structural component changes require a synchronization pass. Keep the page 00 masters authoritative and avoid screen-local copies of controls.

## Accessibility rendering contract

Use 44-point minimum interactive bounds for back, toolbar, segment, filter, search-clear, send, calendar and week controls. Checkbox/switch labels activate the entire row. Selected filters use a solid accent fill, on-accent checkmark and medium-weight on-accent label; selected segments use a raised pill and stronger type; Increase Contrast adds a clear outline. Empty composers show disabled Send; disabled action labels remain readable. Standard field/search shells use the glass edge and regular material; native focus/invalid states and Increase Contrast supply a stronger boundary using `--color-control-border`. Reduced Transparency uses an opaque semantic surface; validation also uses text and accessible announcements.

Paper renders SVG color variables inconsistently in glyphs. Checkmarks use token-bound border geometry and Send uses a token-bound upward arrow; both preserve foreground contrast. Native implementation uses SF Symbols with semantic foreground styles. Do not certify a fix from exported markup alone: inspect rendered glyphs on their real background.

| Native element | Spoken name and state | Interaction |
| --- | --- | --- |
| Icon action | Search community / Search closet / Add piece / Send message / Clear search / Back | Button trait; 44-point target; disabled Send until valid text |
| Checkbox row | Full label + selected/not selected | Whole row toggles; one accessibility element |
| Filter / segment | Label + selected state | Maintain focus and announce updated results without rereading the screen |
| Piece tile | Piece name, category, availability | Combine image and caption; avoid duplicate image announcements |
| Field | Persistent label, value, required/optional, validation message | Error linked to field; focus first invalid field; preserve typed content |
| Sheet / alert | Title, impact, primary action, Cancel | Focus enters sheet, Escape/dismiss works, focus returns to trigger |
| Composer | Message recipient, draft, delivery state | Announce send result; retain draft after failure; keyboard-safe controls |

At accessibility text sizes, use one-column piece lists, vertical creator/action layouts, wrapping form labels, an agenda alternative to the month grid, and scrollable content above system insets. Reduced Transparency uses opaque semantic surfaces; Increase Contrast strengthens native boundaries; Reduce Motion removes decorative transition movement. These are native acceptance requirements, not functionality proved by the Paper canvas.


## Page 00 component library

Paper page 00 contains the original controls board plus **States and feedback**, **Presentations and navigation**, **Content and form patterns**, **Icon library and navigation states**, and **Entry and identity**. Reuse those masters rather than inventing independent styling per screen.

| Pattern | Shared definition | State details |
| --- | --- | --- |
| Empty state | `empty`, `actionStack` | 12 pt heading/body gap; 24 pt before actions; 12 pt primary/secondary gap. Secondary actions belong inside the stack. |
| Skeleton | `skeleton` | Content-shaped placeholders, no fake content; reserve final geometry. Static under Reduce Motion. |
| Indeterminate progress | `spinner` | One shared circular spinner, using the Agent status master everywhere; native circular ProgressView/UIActivityIndicatorView with an accessible operation label. No competing CSS border-arc variant or invented percentage. |
| Modal / bottom sheet | `header`, `sheetHandle`, shared content | Native sheet detents, safe areas, scroll, keyboard and dirty-dismiss protection. |
| Confirmation | `alertDialog` | Native alert, explicit consequence, safe Cancel, destructive role and restored focus. |
| Filter rail | `chips` | No wrapping or text truncation. Fixed-size chips, 44 pt minimum, 8 pt gap, subtle shadow. Horizontal overflow; 24 pt noninteractive trailing fade only while more content remains. Mirror for RTL; keep selection visible. |
| Segmented tabs | `tabs` | Neutral translucent rail, regular glass selected pill with subtle highlight/shadow, no hard border in default appearance. Use the OS segmented control; no nested custom glass. Reduce Transparency keeps the same geometry and selection shadow with an opaque surface; Increase Contrast alone adds a stronger outline. |
| Icons | `icon`, `ICONS` | 24-unit grid, 22 pt visual size, 44 pt target. Regular inactive / semibold active; tint and selected container reinforce weight. See ICONS.md. |

Paper previews are static. Scroll, focus, material animation and platform semantics are native acceptance requirements. The local gallery has been retired. Paper color tokens remain live; component structure remains synchronized snapshots.

### Shared loading indicator

The Agent **Status and progress** spinner is the sole indeterminate-loading reference across content loading, saving, search, pagination, sync/restore and Agent work. In Paper it uses the same 16-point circle/arc symbol, divider track and accent arc; native rendering uses one circular system progress component consistently and scales through the platform's accessibility behavior. Keep a fixed indicator lane and the existing operation label. Preserve action width, prevent duplicate submission, and keep retained content/drafts readable. One operation has one spinner, not both an inline and button spinner. Completion uses the existing check/receipt; failure uses error/retry, with no endless spinner.

Skeletons reserve content geometry and do not constitute a second animated busy indicator. Do not add pulsing dots, a custom rotating border, looping shimmer or a decorative progress bar. Determinate progress is allowed only for a real measured fraction. Reduce Motion removes custom rotation/transitions and retains meaningful native progress plus text; never impose a minimum loading duration.

### Destructive action hierarchy

A destructive confirmation has one destructive commit action and a safe neutral Cancel/Keep editing action. Delete can be the task's main action without becoming AQD blue. Use native destructive roles and semantic system red for Delete, Block, Discard and Unpublish commands; navigation titles and impact copy remain neutral. Menu/list commands and secondary delete entries use destructive text on native regular material. A confirmed full-task destructive commit may use the existing red prominent treatment; it never uses the blue primary tint. Native alerts/confirmation dialogs retain system action layout and red destructive labels rather than custom glass button stacks. Disabled destructive commits are neutral/disabled, with no blue fill and no enabled red affordance. Cancellation changes no records; failure retains the target and draft.

Composition previews reserve at least 245 pt so their photo columns fit. `screenLayout` keeps docked message composers outside scrolling content; native implementations use safe-area/keyboard insets.

Entry patterns on page 00 include introduction, action stack, identity choice, pill-shaped native Apple sign-in reference, read-only identity detail, and single-choice acquisition rows. Read-only details have no separator or disclosure accessory. Whole selection rows have at least 44 pt targets and a selected dot in addition to tint. The [entry contract](entry-identity.md) owns sequencing and recovery.

## List and card separators

The list or section container owns separator placement, whether the surface is a rounded card or the plain page background. Use a semantic divider between adjacent related rows only; remove the final row’s bottom border. A standalone row or one-row card has no separator. Do not combine the rounded outer edge with an inset bottom stroke. Preserve row height, touch targets and internal alignment. Apply this rule to page 00 masters, light/dark settings, sheets and identity cards; field outlines and explicit section boundaries are separate components and must not be simulated with a trailing row border.

Segmented-control master: neutral capsule rail, 4 pt inset, 2 pt gap, equal-width segments with 44 pt minimum targets, and a raised selected capsule. Standard selection uses the glass/edge/shadow tokens. Reduce Transparency uses opaque white selection and opaque neutral rail (`#E5E5E7`), preserving geometry and subtle shadow. It does not imply Increase Contrast. Native material behavior remains system-owned.

Welcome editorial and first-piece receiving frame share the same image identity and photographic treatment. Page 00 **Motion · Welcome and first piece** defines the reference keyframes. The restrained photographic overlap uses a small depth shadow; ordinary form cards remain flat. See [entry motion](entry-motion.md) for choreography and [global motion](motion.md) for timing and accessibility behavior.

## Agent response components

Canonical examples live on Paper page 00; full state and privacy contracts are in [Agent experience](agent-experience.md). Reuse these patterns across conversation, focused assistance and appearance variants.

| Component | Inputs | States and contract |
| --- | --- | --- |
| Markdown response body | Versioned Markdown source and stream state | Shared semantic typography, lists/quotes/links/code/tables; safe destinations, partial syntax recovery, selection and plain-text/Markdown copy. See [rendering contract](agent-experience.md#markdown-responses). |
| Response status | Actual phase, start/end clock, runtime | Waiting, streaming, stopping, stopped, complete, interrupted, slow; native indeterminate indicator; frozen terminal duration. |
| Task progress | Event-backed stages/counts | Pending, active, done, failed; stable 24-point indicator lane; no fabricated percentage or reasoning transcript. |
| Response actions | Response ID/version, copy outcome, feedback state | Copy, helpful/not helpful, retry, details; 44-point targets; selected semibold symbol; pending versus received feedback. |
| Agent composer | Draft, attachments/context, voice, runtime, run state | Multiline/autofocus, Attach/context/microphone, readiness/removal, native keyboard, generating with Stop, stopping, retained failure; see Agent input. |
| Version navigation | Current version and count | Previous/next with 44-point targets and disabled boundaries; feedback and approvals stay version-bound. |
| Response details | Recorded time, runtime, context | Read-only metadata has no disclosure chevrons; unavailable timing never becomes zero. |
| Feedback form | Rating, optional reasons/note, explicit content consent | Editing, submitting, received, failed/local draft, changed/cleared; no chat content sent by default. |
| Conversation history | Cached entries and fetch state | Loading skeleton, empty, populated, refreshing, failure, unavailable item; retain usable cached data. |
| Save status | Approved draft version and operation ID | Executing, receipt, stale, failed, unknown; generation cancellation never implies rollback. |

Native shared components should be driven by these states; Paper snapshots are illustrative instances, not linked reusable runtime components.

## Compact profile — owner and visitor

The shared profile header places a 64-point avatar beside the display name and follower/following counts. The navigation title uses the username so the display name is not repeated. Use 12-point vertical gaps, a 15/22 bio, and a two-column action row with an 8-point gap. Follow/Following and Message use 15/20 medium labels, 12-point corners and **44-point minimum controls**; label line height must not duplicate the outer hit-area height. Preserve pending/failure state without changing button width. Counts are 44-point targets and come only from authorized public data.

Pieces / Outfits / Themes retain the shared glass segmented control. All three views keep the same profile shell, selected state and independent scroll position. Pieces use a two-column labelled garment grid; Outfits use photographic/composition covers; Themes use named collection collages with accessible public counts. Only published records and memberships appear. Ordinary cards remain flat. The shared pattern is illustrated on page 00 and S06/S13/S14. At larger Dynamic Type sizes, wrap the name, keep the bio preview to one ellipsized line with full-text disclosure, allow buttons to grow and collapse grids to one column rather than clipping text or reducing touch targets.

## Home dashboard

Home scope is one shared Today / All / Following segmented control, including loading, empty and offline states. It uses the existing 44-point segment targets and native glass/opaque accessibility variants. Today is the personal dashboard label; All and Following retain public-feed semantics. Restore each mode's scroll position. Search is explicitly Closet-scoped from Today and public-discovery-scoped from social modes.

Today summary components reuse typed records: planned-look card (outfit, plan entry, availability, wear state), upcoming-plan row (saved local date/timezone and destination), and compact wardrobe action row (44-point Add piece / Build outfit targets). Never treat viewing or passing a plan date as recording wear. The Record wear action opens the existing review flow. Hide unavailable data, retain useful cached content during refresh, and distinguish no closet, no plan, section load failure and offline social feeds. Show only the signed-in/local owner's authorized data. Page 00 and S15–S17 define the composition; Closet and Planner remain the editing sources.


Profile owner and visitor variants share avatar/name/count lanes, 12-point content gaps, single-line bio, equal-width 44-point actions and collection grids. Owner navigation uses the username with Add/Settings; owner actions are Edit profile/Share. Visitor navigation keeps Back/More and Follow/Message. Root destination remains Profile.

`ProfileBioPreview` displays exactly one 15/22 line, width-constrained with tail ellipsis (never a manually shortened saved value). The containing button has a 44-point target and opens a native About sheet with the full, selectable, wrapping description and Done. VoiceOver receives the full description plus an opens-details hint. Empty bios omit the row for visitors; owners add one through Edit profile. Dynamic Type keeps the single-line preview at the selected system size without shrinking type; full text remains available in the sheet. This constraint applies to profile bios, not chat replies, explanatory error text or accessibility labels.

`ProfileBioEditor` is optional, limited to 160 user-perceived characters (grapheme clusters), with a live count and matching persistence/API validation. Normalize pasted line breaks to spaces for this single-line field; trim outer whitespace on save. Reject an over-limit save with an inline error, preserve the draft and focus the field. Do not truncate pasted text silently. Existing over-limit records remain fully readable; require a valid length only when saving a changed bio. Other profile edits must not silently erase the existing bio. Do not truncate the editor value itself; allow native horizontal scrolling/selection. Names/usernames keep their separate existing limits.

## Photo avatar

Page 00 **Components · People and avatar images** owns the shared fixture photos, circular crops and size examples. Use the same person ID, photo and crop everywhere; never choose a different portrait per screen. See [reference assets](../references/assets.md) for the canonical mapping.

Sizes: 32-point compact metadata, 40-point feed/people rows, 44-point inbox, 64-point profile, 72-point edit/detail, 80-point reference preview. Keep interactive targets at least 44 points independently of image size. No shadow, decorative ring, invented online status or verification badge.

Reserve circular geometry while loading; keep a cached photo during refresh. Missing/failed photos use up to two display-name initials on a neutral surface; missing names use the native person symbol. Reduce Motion disables shimmer. Use a person ID and photo revision for image caching, and render appropriately sized thumbnails. Adjacent identity text provides the accessible name; decorative images are hidden from VoiceOver. Standalone actions use labels such as “Open Camille Reyes’s profile” or “Change profile photo.” Photo editing uses the native picker and preserves the previous image until replacement succeeds.

Paper screen copies share the asset mapping but are not live linked components. Apply crop/source changes to all matching instances; native implementation should use one PhotoAvatar component.

## Today activity modules

The existing page-00 Home dashboard master owns RecordedWeekSummary and WearAgain. Reuse surface/ink/secondary/accent/segment-track tokens, 16-point card padding/corners, 12-point inner gaps, 28/34 numbers and 13/18 metric labels. Keep the seven markers evenly spaced; recorded uses check + tint, today an outline, future neutral. At larger text sizes, stack metric groups and expand vertically; never shrink controls or truncate counts. The entire week summary links to history with at least 44-point bounds.

WearAgain uses the existing 4-point photographic corners, one 100 × 112 preview, a named piece, last-recorded date and a 44-point manual-build action. No image shadow or extra decorative badge. Current-day outfit remains above the summary; WearAgain, upcoming and quick actions follow on scroll. Native navigation remains pinned to the viewport safe area; S15 and S18 represent two scroll positions of one Today view.

No-history, loading, cached, error and ineligible-piece behavior is defined in the [activity contract](../features/discovery-publishing.md#today-wardrobe-activity). A confirmed wear may crossfade the updated summary once using motion.crossfade; no repeated shimmer, count-up or animated goals. Reduce Motion updates immediately.

### Today text hierarchy

Home remains the only large title. Do not repeat “Your wardrobe today” below the Today segment. The date uses 13/18 regular secondary text. Empty/no-plan messages use 20/26 regular, supporting copy 15/22, and an 8-point internal gap. Keep 20 points before the primary action and existing 44-point minimum secondary targets. Populated card headings use 17/24 medium.

Empty wear history is an unboxed secondary section: 15/22 medium “Wear history,” 15/22 supporting text, and a regular-weight action. Populated history retains its data card and numeric hierarchy. This distinction reduces competing emphasis without implying that empty history is an error. Page 00 Home dashboard owns the hierarchy; S15–S17 apply it.

### Filter chip selection

Selected chips use `--color-accent` fill with `--color-on-accent` text/checkmark and 15-point medium labels. Unselected chips use regular native glass, regular secondary labels and the shared glass edge. Keep the checkmark so selection is not color-only. Disabled chips have no selection check or elevation and expose the disabled semantic state; do not reuse disabled styling for selected filters. Dark appearance uses the corresponding night accent/on-accent roles. Geometry, 44-point targets, single-line horizontal scrolling and conditional trailing fade remain unchanged. Page 00 and all 13 existing selected filter instances share this treatment; segmented tabs retain their separate native glass design.

### Post action row

Like and comment use adjacent controls with at least 44-point targets and `--spacing-4` between them. Inline counts belong inside their combined controls. The flexible spacer keeps Save at the trailing edge. Do not add extra icon margins inside the targets. Page 00 Content and form patterns includes the shared row; Home All and Reduced Transparency use the same geometry.

## Global component motion

### First-outfit activation

Paper page 00 **Components · First outfit activation** owns missing-category guidance, readiness actions and capture-review rules. Reuse existing opaque fields, 44-point rows, primary capsule, secondary action, status/nav and photo surfaces. Required capture fields are name/category; optional metadata is disclosed through More details. Readiness labels name actual available pieces; missing categories link to the same capture flow. No artificial progress bar, fixed item quota or account gate. W27–W29 and S48 extend existing patterns; [V1 flow](v1-flow.md) owns routing. N-push/C-form/C-save apply without a new animation system.

All shared components inherit [Global motion](motion.md): native chrome uses N-root/N-push/N-sheet; media detail N-photo; chips/segments C-select; placeholders C-load; collection/outfit edits C-change; mutation receipts C-save; fields C-form; human messages C-message; Agent replies C-stream; copy/feedback C-receipt. No component defines an independent timing scale. Page 00 Foundations · Global motion covers every component family and standard/Reduce Motion behavior.

### Social actions, tags and comments

Page 00 **Components · Social actions and piece tags** owns default/liked/saved/pending/failure action states, creator-selected photo tags, tag list fallback and comment composer states. Reuse the existing 22-point symbols, 44-point targets and 4-point post-action gap. Heart/bookmark use matching filled active symbols and selected semantics; Comment opens a destination and has no sticky active appearance.

Photo tags sit bottom-leading with 12-point inset, native functional material/opaque fallback and an accessible count. Revealed markers are numbered and backed by a list. Use C-select for local toggle feedback, N-push for the pieces list, N-photo or N-push for the public piece, and N-push/C-message for comments. Never use animation to imply publication or successful comment delivery. Exact privacy, validation and lifecycle rules are in the discovery specification.

Post footer captions use 15/22 regular text and a 4-point gap below the action row, consistently across All and Following. Place themes in post detail; linked tag counts stay on the photo. Large text expands layout and wraps accessible controls rather than shrinking hit targets. Long counts use locale-aware compact display with the full number in accessibility labels.

### Required pieces when sharing

Share chooser offers Piece, Outfit and Theme. Every photo requires at least one explicitly linked owned piece in the publication review. Spatial markers remain optional. The photo control opens the single public piece or the piece list, even without markers. Piece preview includes one piece; Outfit preview includes at least one; Theme review includes selected outfits and their disclosed pieces. The Theme card adds one compact collection row without restoring the removed generic theme metadata line to every feed post. Missing source/piece blocks Publish with retained photo/caption and Choose a piece / Add a new piece recovery. Page 00 Social owns this rule; S02 and S30–S35 illustrate it.

### Search, control density and continuation

[Search and feeds](search-and-feeds.md) owns scoped search, control density, linked-piece rows and cursor-pagination recovery. Reuse the page-00 masters.

### V1 account and review states

E15–E17, U16–U24 and A31–A33 reuse status/header/home indicator, body/metadata hierarchy, native rows, primary/secondary action stacks and shared save/error states. Exact account, record/revision, artifact and operation status is supplied by real records. Conflict choice opens U24 without discarding either revision. Export/deletion progress/failed/unknown variants retain the operation; native share, reauthentication, confirmation and place/date pickers remain platform-owned. See [V1 coverage](v1-coverage.md).

V1 response actions are Copy, Retry and Details. Feedback/version-comparison masters remain future references; hide Helpful/Not helpful and comparison entries until V2. Settings omit Notifications and first-save omits the acquisition survey. Inbox omits remote mute controls until notification transport is scoped. No unavailable toggle implies a service exists.

## Liquid Glass across controls

[Liquid Glass](liquid-glass.md) owns native API/material selection and accessibility variants. [Native presentations](native-presentations.md) owns open controls, menus/sheets, adaptation and safe dismissal.

Paper layout: navigation previews reserve phone width; bounded tab insets keep single-line labels above the home indicator. Filter rails remain in normal flow with intrinsic height and section gaps, including cloned sheet backdrops. Inspect clone positioning after duplication.

### Navigation exit ownership

Apply the [per-flow exit map](native-presentations.md#one-exit-per-screen) to canonical screens, masters and V1 copies.

## AI assistance badge

Use the page-00 badge master. [Icon catalog](icons.md#ai-assistance-badge) owns geometry, placement, exclusions and accessibility.

## Agent multimodal input masters

Page 00 **Components · Agent multimodal composer** and **Components · Agent shimmer and state coverage** own shared visual examples. [Agent input](agent-input.md) owns the composer states, media/context selection, voice review, recovery and appearance requirements; [global motion](motion.md) owns timing.

## Navigation title alignment

[Native presentations](native-presentations.md#global-title-and-content-alignment--october-2-2026) owns root/detail title placement, action lanes, typography and accessibility adaptation. Apply that contract to page-00 headers and screen copies.
