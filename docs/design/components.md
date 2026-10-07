# AQD component contracts

## Today stack and standalone action fields · current October7

[Today](today.md) owns opaque16-padding/16-corner in-app widgets and native List/Editor configuration; [feature contract](../features/today.md) owns twelve kinds, local personal data, minimum-one and atomic draft/state behavior. No WidgetKit, arbitrary instance maximum, external integration or implicit weather/body/AI consent.

A genuine standalone selection/configuration row has opaque surface/night-surface16 corners,14 padding and52 minimum height; flexible preserved17/15 label/value, semantic-gray value,12 gap and fixed22 disclosure lane. Entire labelled row is a native44-min target. Fields remain borderless with native focus/invalid/disabled/Increase Contrast feedback. Real grouped forms retain a single related-row group, not floating cards; OS Menu/alerts/dialogs/toolbars retain native ownership. Passive metadata, Undo/Retry/help and statistics are not forcibly surfaced. [Action evidence](evidence/action-surfaces.json) records16 style-only repaired rows, not universal coverage. Eight legacy grouped rows in AU8-1/DYR-1 remain a structural handoff, not falsely fixed; excluded Today copy BCQ-1 was not changed by that worker.


Phase scope: shared native/visual rules apply to both phases. Five-destination base navigation applies to both phases. Full-app E/W/P/S/A/I/U routes, online identity and connected states are V2 references. Complete private themes/planning/Agent are retained in V1. V1 uses its [dedicated local flow](v1-flow.md), with existing A33 shared under [optional native weather](weather-context.md), and [complete local release](../product/v1-release.md); [V2 requirements](v2-requirements.md) own connected and extension coverage.

Shared visual definitions live on [Paper page 00](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-1-0). [DESIGN.md](../../DESIGN.md) owns usage and the native target; [screen map](screens.md) owns routes. Feature specs own data rules. These are logical components, not a requirement to create one file per row.

## Foundations and native chrome

Shared confirmation primitives live in Foundations `4GB-0`: critical alert `FJ2-1` and routine action-sheet specimen `ZGG-0` (choice group `ZGJ-0`, destructive row `ZGO-0`, separate Cancel `ZGR-0`). These retained IDs now contain crisp editable official27-kit-derived text/frame geometry: 300-point critical and260-point routine shells,34-point corners and48-point pill actions. Legacy choice wrapper `ZGJ-0` and separate Cancel `ZGR-0` are hidden; original text/action IDs remain. [Vector repair](evidence/native-dialog-vector-repair.json) also restores all38 product-phone hosts and semantic controls while hiding their raster replacements and engineering contracts. Adapted copy/material/font previews are not exact native27 pixels or runtime proof. Native critical alerts require explicit Cancel; source-anchored routine UIKit26+ dialogs may appear inline on iPhone/iPad with implicit no-write cancellation. The new [Transparency · Native iOS catalog](native-ios.md#transparency--native-ios-foundations-reference) maps all AQD native roles to Foundation rows, deployment18 and guarded26/27 enhancements. Product confirmation states clone their actual originating scene in V1/V2; apply the [risk-based native policy](native-presentations.md#confirmation-states-not-pushed-screens). The OS supplies runtime appearance and dismissal; no custom dialog renderer or extra pushed confirmation route.

| Component | Canonical builder | Native implementation | Contract |
| --- | --- | --- | --- |
| Semantic tokens | `TOKENS`, `DARK_TOKENS` | Asset/semantic colors and system text styles | One place to change colors, type roles, space, radii. Dark mapping is semantic, not inverted photography. |
| Status/safe area | `status` | System-owned | Keep native status, home indicator, keyboard and safe-area insets. Reference status markup is illustrative. |
| Root/detail header | `header` | NavigationStack/UINavigationController | Root title versus compact detail title; native glass Back and toolbar actions, system back label/history and swipe gesture; preserve title at large text. |
| Glass tab bar | `nav` | TabView/UITabBarController | Same five named slots in V1/V2: Today · Closet · Planner · Agent · Profile. Equal native widths, centered icons without visible captions, full nonoverlapping hit areas ≥44 × 44 pt, explicit destination accessibility names, selection, restored navigation state and accessible selected trait. Agent presentation exception is in DESIGN.md. Icon-only tabs are also an explicit HIG exception: test public UIKit nil-title items and native adaptation; never recreate a custom glass bar. |
| Toolbar icon button | `icon`, `header` | Button/ToolbarItem or UIBarButtonItem | 44-point target; SF Symbol plus accessibility label; loading/disabled/destructive semantics. Search/Add may group by task. |
| Search | `search` | searchable/UISearchController | Explicit scope, query, clear, cancel, keyboard, loading/results/empty/error, retained selection and scroll state. |
| Primary/secondary action | `button` | Native Button with semantic solid primary / flat secondary styling | Standalone primary uses solid accent fill; secondary content actions use plain regular-weight action-text labels with no background, border, blur or shadow. Flat soft-blue Back/View outfit capsules retain their explicit contracts. Primary buttons have no blur or shadow. Inline content actions retain native plain style. One primary action; label retained during progress; duplicate submission prevented; disabled reason explained beside decision. |
| Segmented control | `tabs` | Picker segmented/UISegmentedControl | Mutually exclusive view state; selected trait; no form submission side effect. |
| Filter rail | `chips` | Native controls in horizontal scroll | Multiple/filter-specific selection, reset, real result updates, 44-point hit area even if visible capsule is smaller. |
| Menu and sheet | Screen composition + row primitives | Menu, confirmationDialog, sheet | Anchor to trigger; sensible detents; accessible dismiss; dirty edits get keep/discard choice; keyboard never covers action. |

Paper phone chrome follows the viewport geometry in [DESIGN.md](../../DESIGN.md#layout-and-shape). Bars and home indicators belong to the phone viewport rather than variable-height content/footer wrappers. Tour overlays leave the navigation visible and keep their actions above it. Inspect root screens, tour backdrops, nested phone previews and both appearances after synchronizing clones; changing only a component master does not repair existing copies. Native screens use system safe areas and retain scroll access behind floating chrome.

Today’s look uses a flat secondary capsule for View outfit, matching tour Back: accent-soft background, action-text label, no border, blur or shadow. Dark appearance uses the corresponding night roles. Retain the existing equal-width action slots and minimum 44-point targets; Record wear remains prominent. This content-card exception applies to the shared Home reference and its V1/V2 copies.

Welcome and onboarding alternatives (Take the tour, Take a quick tour, Open Home and Explore first) use centered plain action-text labels without filled capsules, borders, blur or shadows. Use regular-weight plain secondary labels and 50-point reference targets throughout matching entry flows. Group adjacent primary/secondary actions with a dedicated 12-point-gap action stack, matching Welcome. This applies to entry, piece detail, outfit/planner forms, confirmation and recovery flows in V1/V2 and equivalent admin action stacks. Content sections retain their own spacing; do not let their 16/20/24-point gap space individual buttons. Equivalent V2 Welcome account links use the same target and regular weight. Tour step Back/Next remain their existing capsules, and Settings replay remains a grouped row.

## Compact Home weather context

[Weather context](weather-context.md) owns this shared V1/V2 component. Home uses the locale-formatted short date + native condition symbol + temperature, not a separate card. Keep a ≥44-point details target. The owner removed the Paper Home attribution row; details retain attribution, but details-only placement is unverified and blocks numerical-weather release until Apple's required assets and legal placement are satisfied. Show inline numbers only after opt-in, fresh retrieval and matching Home/selected-place day/timezone; off/unavailable/mismatch leaves date only, stale uses explicit Saved/updated text. The weather city never changes plan/journal day. Details expose selected place/day/timezone, source/freshness and actual available forecast fields. Missing attribution with no valid cached asset suppresses numbers. Paper's unverified SDK-asset slot illustrates placement, not certified Apple branding or service retrieval. Use existing grouped rows/system text and native growing layout; settings/source actions return to the actual caller without saving wardrobe records.

## Reusable content

| Component | Canonical builder | Inputs and output | Required states |
| --- | --- | --- | --- |
| Text roles | `textBlock`, `title`, `muted`, `section` | Semantic role + text | Dynamic Type, wrapping, localization; avoid fixed-height text. |
| Field | `field` | Label/value/validation → draft edit | One opaque, flat surface shell around native editing; empty, entered, focus, invalid, read-only, keyboard, saving; retain failed edits. |
| List row | `row`, `grouped` | Title/value/accessory → action | App-owned destination choosers use registered22-point forward chevrons with12-point label/accessory gaps and whole-row targets; immediate commands, selected options and native Menu rows keep their distinct accessories. Fixed trailing lane; optional supporting text; selected/disabled/destructive roles. Grouped cards show inset separators only between rows, never beneath the last or only row. |
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

Calendar selection updates the background and both weekday/date foregrounds together. A soft selected fill uses accent text; a solid accent fill uses on-accent text. Unselected dates use secondary ink. Never retain on-accent white text after clearing the accent background. Preserve today's separate marker and accessible selected state; apply the corresponding semantic roles in dark appearance.

## Reusable settings group

The **Settings group — reusable master** in page 00 Content and form patterns defines the shared opaque surface for personal Profile, Settings, appearance, privacy, data/account and related preference controls. It extends the existing `grouped`/`row` pattern; do not invent a new card style per screen. Paper structural clones remain snapshots and require synchronization.

Use `--color-surface` (white) on the canvas in light mode and `--color-night-surface` on the night canvas in dark mode. The group has 12-point corners, 14-point horizontal padding, no border/shadow, and zero gap between rows. Rows have a 54-point minimum reference height and 8-point vertical padding; supporting text expands the row. Draw semantic 1-point separators between rows only, inset by the group padding. No separator follows the last or only row. Preserve fixed accessory lanes, full-row hit targets, disclosure/toggle/selection semantics and clear destructive labels.

Keep identity, section titles, explanations and warnings outside the group, with the existing section spacing. Group related controls together; a standalone setting may use a one-row group. Preserve draft, permission, selected, disabled and recovery behavior. Native implementation uses reusable sections/rows with system grouped-list and accessibility behavior; text size/localization may expand or scroll content. Admin Settings reuses the white surface and separator/corner roles with web typography, keyboard focus and its existing controls. This design contract prepares reuse without implementing application components.

## Native surfaces represented by contracts

Apple sign-in, Photos/Camera picker, Share sheet, date picker, keyboard, system permission alerts, context menus, destructive confirmations and text-selection/edit menus use standard system controls. Their exact geometry is OS-owned. Reference artboards illustrate entry/return and task copy, not a requirement to reproduce the OS in custom views.

## App-owned semantic feedback

Foundations `10S3-0` owns five generic variants, not phone screens or a Toast component. Existing saved row `4F2-0` / text `4F3-0` now uses confirmed-success check plus success-soft while retaining15/21 text and identity. [Portable evidence](evidence/feedback-variants.json) records146 reviewed targets, exclusions, synchronized copies and limits.

| Role | Symbol / foreground | Meaning |
| --- | --- | --- |
| Neutral | `info.circle` / secondary | Draft/bookkeeping/privacy assurance; not a save receipt |
| Info | `info.circle` / info | Guidance/cached context; active work keeps shared progress |
| Success | `checkmark.circle` / success | Actual acknowledged completion only |
| Warning | `exclamationmark.triangle` / warning | Recoverable risk, offline capability, conflict or unknown result; reconcile before retry |
| Danger | `exclamationmark.octagon` / error | Actual blocking validation/failure; retained draft and recovery |

This is AQD app-owned Label/status grammar, not a universal iOS severity component. Reuse paired semantic/night tokens; primary message text stays ink. Use an18-point fixed symbol lane,8-point gap and first-line alignment; wrap flexible text without shrinking existing15/21–22,17/24 or13/24 helper roles. Contained notices may use matching opaque soft grounds; inline helpers remain unboxed. One message group gets one symbol, not one per paragraph. Persistent Name/Category labels, action text, native critical titles, progress and pristine instructions are excluded. `JNB-0` remains neutral privacy assurance; cached results are info, offline capability warning, pending/unknown never success.

Native implementation uses SwiftUI `Label` (iOS14, within deployment18), meaningful combined text and decorative-symbol accessibility hiding. Associate validation with its field, focus the first invalid field and announce real transitions once. VoiceOver, Dynamic Type, RTL, Night and native material checks are acceptance targets, not verified Paper behavior. Native alerts/dialogs retain platform title/text/actions; see [icon limits](native-presentations.md#native-ios-alert-icon-policy).

## Shared behavior

The reference builders produce static review markup. They contain no persistence or authorization. Implementation receives feature state and emits user intent; trusted domain operations validate and execute. Extract shared implementation only for actual repeated use. Match states and behavior as well as appearance.

Production acceptance: screen reader name/role/state, 44-point target, accessible text, reduced motion/transparency, native keyboard/Back behavior, sensible focus after sheets, error recovery, and current data-access checks. Test representative long names, empty results, photo failures and slow/offline service behavior.

## Toolbar reuse and Paper synchronization

The page 00 toolbar text and toolbar icon masters own toolbar geometry. Cancel, Done, Save and Skip use the text variant; Cancel uses neutral semantic ink, with blue reserved for primary actions and selected states; icon actions use the icon variant. Full-width sheet/form dismissal uses the secondary button variant because its placement differs.

Dimensions bind to Paper tokens (`--spacing-control-height`, `--spacing-control-text-min`, `--spacing-control-padding`, `--leading-control`). Change token values once to update bound instances. For geometry changes, update the master and affected clones, then inspect representative screens. Clones do not automatically inherit structural changes.

Paper clones are snapshots, not linked component instances. Color and dimension token changes propagate; structural component changes require a synchronization pass. Keep the page 00 masters authoritative and avoid screen-local copies of controls.

## Accessibility rendering contract

Use 44-point minimum interactive bounds for back, toolbar, segment, filter, search-clear, send, calendar and week controls. Checkbox/switch labels activate the entire row. Selected filters use a solid accent fill, on-accent checkmark and medium-weight on-accent label; selected segments use an inset opaque pill and accessible selected state; Increase Contrast adds a clear outline. Empty composers show disabled Send; disabled action labels remain readable. Standard editable field shells use opaque semantic surfaces, 16-point corners and no decorative shadow, blur or border; system search remains native; native focus/invalid states and Increase Contrast supply a stronger boundary using `--color-control-border`. Reduced Transparency uses an opaque semantic surface; validation also uses text and accessible announcements.

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
| Empty state | `empty`, `actionStack` | Unboxed on the canvas: vertically center the intrinsic heading/explanation/action stack within the available body region below headers/search/scope controls and above navigation, composer or footer; keep the contents leading-aligned. Do not center the controls themselves or distribute the stack's children across the region. When text exceeds the region, top-align and scroll rather than clip. Inline notices among real records/messages and native sheet controls retain contextual placement. Use a leading 20/26 heading, 15/21–22 explanation, 8 pt heading/body gap and 12 pt before a full-width 50 pt primary action; secondary actions are plain 50 pt targets 12 pt below it. Preserve meaning and existing artwork; grow/reflow at accessibility sizes. Real result cards, form groups and native sheets retain their own surfaces. |
| Skeleton | `skeleton` | Content-shaped placeholders, no fake content; reserve final geometry. Static under Reduce Motion. |
| Indeterminate progress | `spinner` | One shared circular spinner, using the Agent status master everywhere; native circular ProgressView/UIActivityIndicatorView with an accessible operation label. No competing CSS border-arc variant or invented percentage. |
| Modal / bottom sheet | `header`, `sheetHandle`, shared content | Native sheet detents, safe areas, scroll, keyboard and dirty-dismiss protection. |
| Confirmation | `alertDialog` | Native alert, explicit consequence, safe Cancel, destructive role and restored focus. |
| Filter rail | `chips` | No wrapping or text truncation. 32 pt visible capsules, 14/20 labels, 6 pt vertical / 12–14 pt horizontal padding, 8 pt rail gap, no border, blur or shadow. Native interactive bounds remain at least 44 pt. Horizontal overflow; 24 pt noninteractive trailing fade only while more content remains. Mirror for RTL; keep selection visible. |
| Segmented tabs | `tabs` | 36 pt neutral rail with measured 2 pt top/bottom and side insets, 32 pt segments centered without stretch, 14/20 labels and an opaque selected pill; inactive segments have no fill, border, blur or shadow. Use the OS segmented control; no nested custom glass. Reduce Transparency keeps the same flat geometry and opaque selection; Increase Contrast alone adds a stronger outline. |
| Icons | `icon`, `ICONS` | 24-unit grid, 22 pt visual size, 44 pt target. Regular inactive / semibold active; tint and selected container reinforce weight. See ICONS.md. |

Paper previews are static. Scroll, focus, material animation and platform semantics are native acceptance requirements. The local gallery has been retired. Paper color tokens remain live; component structure remains synchronized snapshots.

### Shared loading indicator

The Agent **Status and progress** spinner is the sole indeterminate-loading reference across content loading, saving, search, pagination, sync/restore and Agent work. In Paper it uses the same 16-point circle/arc symbol, divider track and accent arc; native rendering uses one circular system progress component consistently and scales through the platform's accessibility behavior. Keep a fixed indicator lane and the existing operation label. Preserve action width, prevent duplicate submission, and keep retained content/drafts readable. One operation has one spinner, not both an inline and button spinner. Completion uses the existing check/receipt; failure uses error/retry, with no endless spinner.

Skeletons reserve content geometry and do not constitute a second animated busy indicator. Do not add pulsing dots, a custom rotating border, looping shimmer or a decorative progress bar. Determinate progress is allowed only for a real measured fraction. Reduce Motion removes custom rotation/transitions and retains meaningful native progress plus text; never impose a minimum loading duration.

### Destructive action hierarchy

A destructive confirmation has one deliberate native destructive commit and safe neutral cancellation. Critical alerts require explicit Cancel/Keep editing; routine source-anchored dialogs may use OS-supported implicit outside cancellation without a visible button. Delete can be the task's main action without becoming AQD blue. Use native destructive roles and semantic system red for Delete, Block, Discard and Unpublish commands; navigation titles and impact copy remain neutral. Menu/list commands and secondary delete entries use destructive text on native regular material. A confirmed full-task destructive commit may use the existing red prominent treatment; it never uses the blue primary tint. Native alerts/confirmation dialogs retain system action layout and red destructive labels rather than custom glass button stacks. Disabled destructive commits are neutral/disabled, with no blue fill and no enabled red affordance. Cancellation changes no records; failure retains the target and draft.

Composition previews reserve at least 245 pt so their photo columns fit. `screenLayout` keeps docked message composers outside scrolling content; native implementations use safe-area/keyboard insets.

Entry patterns on page 00 include introduction, action stack, identity choice, pill-shaped native Apple sign-in reference, read-only identity detail, and single-choice acquisition rows. Read-only details have no separator or disclosure accessory. Whole selection rows have at least 44 pt targets and a selected dot in addition to tint. The [entry contract](entry-identity.md) owns sequencing and recovery.

## List and card separators

Refined theme lists, packing/review/conflict rows, Planner choices, wear-history utilities and Agent context controls use flat opaque semantic surfaces with spacing instead of decorative rules. Separate image rows use 12-point gaps; related form/toggle rows share one 12-corner group with fixed lanes and no interior separators. Do not apply the no-rule treatment to OS-owned menu/alert grouping or unrelated Settings references without synchronizing their contract.

Where separators remain appropriate, the list or section container owns separator placement, whether the surface is a rounded card or the plain page background. Use a semantic divider between adjacent related rows only; remove the final row’s bottom border. A standalone row or one-row card has no separator. Do not combine the rounded outer edge with an inset bottom stroke. Preserve row height, touch targets and internal alignment. Apply this rule to page 00 masters, light/dark settings, sheets and identity cards; field outlines and explicit section boundaries are separate components and must not be simulated with a trailing row border.

Segmented-control master: 36 pt neutral capsule rail, 2 pt inset and gap, equal-width 32 pt visible segments, and an opaque selected capsule. Labels use 14/20; selection uses medium weight. Native hit bounds remain at least 44 pt. Default and Reduce Transparency use flat opaque selection without blur or shadow. It does not imply Increase Contrast. Native material behavior remains system-owned.

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

## Private Profile and fit journal

[Private fit journal](profile-fit-journal.md) owns V1 L48/L160–L163/L165 (dark phone L57 retired): compact optional identity, private dated three-column memories, honest empty state, date plus photo-or-outfit draft validation, note ≤500 user-perceived characters and full-source detail. A single 44-point More toolbar control contains Add fit, Edit profile, Style, Wear insights and Settings. Remove the separate Settings/Edit profile/Add fit controls from populated and empty journal roots. The phase-owned T6P reference retains the shared five-command open-menu composition with native row targets; native Menu adapts placement/size and restores focus on dismissal. No followers, public collections, Share or Post in V1. Journal operations never record wear. Later V2 publishing uses a separately reviewed rendition and caption, never the private note by default.

[Planner calendar](planner-calendar.md) owns reusable grouped choice surfaces and agenda cards. [Agent input](agent-input.md) owns opaque starter capsules; suggestions fill an editable draft and never auto-send.

## Compact public profile — V2 owner and visitor

The shared profile header places a 64-point avatar beside the display name and follower/following counts. The navigation title uses the username so the display name is not repeated. Use 12-point vertical gaps, a 15/22 bio, and a two-column action row with an 8-point gap. Follow/Following and Message use 15/20 medium labels, 12-point corners and **44-point minimum controls**; label line height must not duplicate the outer hit-area height. Preserve pending/failure state without changing button width. Counts are 44-point targets and come only from authorized public data.

Pieces / Outfits / Themes retain the shared compact segmented control. All three views keep the same profile shell, selected state and independent scroll position. Pieces use a two-column labelled garment grid; Outfits use photographic/composition covers; Themes use named collection collages with accessible public counts. Only published records and memberships appear. Ordinary cards remain flat. The shared pattern is illustrated on page 00 and S06/S13/S14. At larger Dynamic Type sizes, wrap the name, keep the bio preview to one ellipsized line with full-text disclosure, allow buttons to grow and collapse grids to one column rather than clipping text or reducing touch targets.

## Home dashboard

[Today](today.md) owns the customizable private in-app widget stack and its native Customize Today toolbar control; it has no private header Search. V2 may retain existing All / Following discovery modes with public Search and independent scroll positions. Public scope controls retain compact visuals,44-point hit bounds and opaque accessibility variants; they do not replace the private stack or mix public queries with personal content.

Today widgets reuse typed records: planned look (outfit, plan entry, availability, wear state), upcoming plans (saved local dates/timezones) and quick actions with44-point targets. Never treat viewing or passing a date as recording wear; Record wear opens the existing review. Preserve configured instance identities/order when source data is missing; show source-aware empty/unavailable recovery rather than silently removing widgets. Retain useful cached content during refresh and distinguish no closet, no plan, read failure and offline feeds. Show only authorized data; [Today](today.md) owns composition/configuration while Closet and Planner remain their record-editing sources.


The public owner projection U26 and visitor variants share avatar/name/count lanes, 12-point content gaps, single-line bio and collection grids. Public owner management uses More, not loose Add/Settings/Edit/Share duplicates; visitor navigation keeps Back/More and Follow/Message. Default owner root U01 instead shares V1's private dated journal layout, single More and icon-only Profile navigation, with V2 Inbox/additive connected commands. Public username editing and verified-link sharing remain separate from private identity/fit editing.

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

[Today header](today.md) owns the shared empty/planned/weather/tour hierarchy:32/38 medium title,14/20 regular secondary metadata and an8-point title/date gap, with44-point native Customize targets. Preserve native safe areas and larger section gaps below metadata; other root destinations retain their own title hierarchy.

Do not repeat “Your wardrobe today” beneath the title. Date, condition symbol and temperature remain secondary; metadata uses14/20 regular text. Empty/no-plan messages use 20/26 regular, supporting copy 15/22, and an 8-point internal gap. Keep 20 points before the primary action and existing 44-point minimum secondary targets. Populated card headings use 17/24 medium.

Empty wear history is an unboxed secondary section: 15/22 medium “Wear history,” 15/22 supporting text, and a regular-weight action. Populated history retains its data card and numeric hierarchy. This distinction reduces competing emphasis without implying that empty history is an error. Page 00 Home dashboard owns the hierarchy; S15–S17 apply it.

### Filter chip selection

Selected chips use accent fill, on-accent checkmark and 14/20 medium labels. Unselected chips use a neutral segment-track fill and regular ink labels when secondary would fall below 4.5:1 at the compact text size; disabled states retain their separate semantic treatment. All chips are flat without decorative outlines, blur or shadows. Keep the checkmark and accessible selected state. Use 32-point visible capsules with at least 44-point native hit bounds; grow with Dynamic Type. Horizontal scrolling and conditional trailing fade remain. Segmented tabs share the compact geometry contract above.

### Post action row

Like and comment use adjacent controls with at least 44-point targets and `--spacing-4` between them. Inline counts belong inside their combined controls. The flexible spacer keeps Save at the trailing edge. Do not add extra icon margins inside the targets. Page 00 Content and form patterns includes the shared row; Home All and Reduced Transparency use the same geometry.

## Global component motion

### First-outfit activation

Paper page 00 **Components · First outfit activation** owns missing-category guidance, readiness actions and capture-review rules. Reuse existing opaque fields, 44-point rows, primary capsule, secondary action, status/nav and photo surfaces. Capture requires photo/name/category, with no Required/Optional suffixes; optional metadata is disclosed through More details. Readiness labels name actual available pieces; missing categories link to the same capture flow. No artificial progress bar, fixed item quota or account gate. W27–W29 and S48 extend existing patterns; [V2 flow](v2-flow.md) owns routing. N-push/C-form/C-save apply without a new animation system.

All shared components inherit [Global motion](motion.md): native chrome uses N-root/N-push/N-sheet; media detail N-photo; chips/segments C-select; placeholders C-load; collection/outfit edits C-change; mutation receipts C-save; fields C-form; human messages C-message; Agent replies C-stream; copy/feedback C-receipt. No component defines an independent timing scale. Page 00 Foundations · Global motion covers every component family and standard/Reduce Motion behavior.

### Social actions, tags and comments

Page 00 **Components · Social actions and piece tags** owns default/liked/saved/pending/failure action states, creator-selected photo tags, tag list fallback and comment composer states. Reuse the existing 22-point symbols, 44-point targets and 4-point post-action gap. Heart/bookmark use matching filled active symbols and selected semantics; Comment opens a destination and has no sticky active appearance.

Photo tags sit bottom-leading with 12-point inset, native functional material/opaque fallback and an accessible count. Revealed markers are numbered and backed by a list. Use C-select for local toggle feedback, N-push for the pieces list, N-photo or N-push for the public piece, and N-push/C-message for comments. Never use animation to imply publication or successful comment delivery. Exact privacy, validation and lifecycle rules are in the discovery specification.

Post footer captions use 15/22 regular text and a 4-point gap below the action row, consistently across All and Following. Place themes in post detail; linked tag counts stay on the photo. Large text expands layout and wraps accessible controls rather than shrinking hit targets. Long counts use locale-aware compact display with the full number in accessibility labels.

### Required pieces when sharing

Share chooser offers Piece, Outfit and Theme. Every photo requires at least one explicitly linked owned piece in the publication review. Spatial markers remain optional. The photo control opens the single public piece or the piece list, even without markers. Piece preview includes one piece; Outfit preview includes at least one; Theme review includes selected outfits and their disclosed pieces. The Theme card adds one compact collection row without restoring the removed generic theme metadata line to every feed post. Missing source/piece blocks Publish with retained photo/caption and Choose a piece / Add a new piece recovery. Page 00 Social owns this rule; S02 and S30–S35 illustrate it.

### Search, control density and continuation

[Search and feeds](search-and-feeds.md) owns scoped search, control density, linked-piece rows and cursor-pagination recovery. Reuse the page-00 masters.

### V2 account and review states

E15–E17, U16–U24 and A31–A33 reuse status/header/home indicator, body/metadata hierarchy, native rows, primary/secondary action stacks and shared save/error states. Exact account, record/revision, artifact and operation status is supplied by real records. Conflict choice opens U24 without discarding either revision. Export/deletion progress/failed/unknown variants retain the operation; native share, reauthentication, confirmation and place/date pickers remain platform-owned. See [V2 coverage](v2-coverage.md).

Shared V1/V2 connected-core response actions are Copy, Retry and Details. Helpful/Not helpful and version-comparison masters prepare V2 extensions; show them when their real lifecycle is enabled. V1 omits Notifications and the acquisition survey. V2 connected core gates those controls until V2-E09/E15 transport/collection is enabled. Inbox gates remote mute until its notification transport exists. No unavailable toggle implies a service exists.

## Input consistency and native material

Ordinary editable fields use one opaque semantic surface,16-point corners and14-point padding, without decorative resting border, blur or shadow. Use native plain editing; do not choose SDK27 bordered-field styling merely because it exists. Preserve approved value/label/helper roles and native focus, invalid, disabled and Increase Contrast feedback. Existing50/52-point single-line references exceed44-point target requirements;54-point choice rows are a different role, not a universal text-input minimum. Multiline fields grow; preserve the specialized Height/unit geometry.

Liquid Glass belongs to justified native functional chrome or a floating Agent outer shell, not ordinary form content or a second inner editor shell. Native search/keyboard/alert material remains OS-owned; web/admin retain their separate boundary/focus rules. The [input audit and repairs](evidence/input-component-consistency.json) reviewed ordinary fields/search/Agent/human composers and excluded non-input strokes; it repaired the two stale validation/typed-DELETE examples without indiscriminate border deletion or resizing92 otherwise-valid fields. Native behavior and unnamed future frames remain unverified.

## Liquid Glass across controls

[Liquid Glass](liquid-glass.md) owns native API/material selection and accessibility variants. [Native presentations](native-presentations.md) owns open controls, menus/sheets, adaptation and safe dismissal.

Paper layout: navigation previews reserve phone width; bounded tab insets keep centered icons and full hit targets above the home indicator. Destination names remain available to accessibility without visible captions. Filter rails remain in normal flow with intrinsic height and section gaps, including cloned sheet backdrops. Inspect clone positioning after duplication.

### Navigation exit ownership

Apply the [per-flow exit map](native-presentations.md#one-exit-per-screen) to canonical screens, masters and V2 copies.

## AI assistance badge

Use the page-00 badge master. [Icon catalog](icons.md#ai-assistance-badge) owns geometry, placement, exclusions and accessibility.

## Agent multimodal input masters

Page 00 **Components · Agent multimodal composer** and **Components · Agent shimmer and state coverage** own shared visual examples. [Agent input](agent-input.md) owns the composer states, media/context selection, voice review, recovery and appearance requirements; [global motion](motion.md) owns timing.

## Navigation title alignment

[Native presentations](native-presentations.md#global-title-and-content-alignment--october-2-2026) owns root/detail title placement, action lanes, typography and accessibility adaptation. Apply that contract to page-00 headers and screen copies.

## Piece photo presentation and editor

[Capture photo](capture-photo.md) owns the shared PhotoPreview, PhotoOptions and PhotoEditor states. L04 is the initial empty-photo draft with one full-width 350 × 88-point opaque Add photo row (12-point corners, 20-point padding); no separate camera action or empty portrait well. Its row opens L159's native source sheet, with decorative symbols and an accessible no-photo state. Choose from Photos opens system PhotosPicker; Take photo opens native camera. Close/outside tap/swipe preserves the draft and returns focus to Add photo. Use adaptive popover on wider layouts; no Remove option before selection. L79 reuses the compact L04 selector for missing-photo recovery through L159, with retained fields, inline feedback and disabled Save. V2 capture and connected review copies adopt the same source-sheet-over-draft and selected-photo editor structure; no obsolete empty portrait well is an alternative contract. L75/L76 use a 168 × 224 portrait viewport with whole-image Fit, L77/W31 provide the optional local crop/rotate/reset/zoom editor, L78 shows the native Change menu, and L79 is a missing-photo validation draft with retained fields and disabled Save. Use Photo, Name and Category labels without Required/Optional; every new-piece save needs all three. Do not restore the old horizontal preview/actions layout or three persistent photo actions when a photo is selected. Never stretch or auto-crop landscape media. Reuse opaque semantic surfaces, 4-point photographic corners, plain secondary actions and native target/adaptation rules.

### Demo image identity

Use the canonical [demo wardrobe and composition mapping](../references/assets.md#v1-and-v2-demo-wardrobe--october-6-2026) across V1, V2 and flow copies. Match visible piece labels, colors and included-piece counts to the image. Keep garment proportions, use whole-image Fit for previews, and reserve cropping for the explicit editor. Different named looks need distinct compositions; repeated appearances of the same look retain the same pieces. Empty capture remains empty.


## Three-action task hierarchy

For three content actions, keep the first two in the existing 12-point primary/secondary stack and place the third as a centered plain 50-point footer above native safe areas, matching L61 Explore first. L43 Build manually is a tertiary alternative, not a third adjacent primary. Preserve native scroll access and keyboard/Dynamic Type expansion; use native safe-area layout rather than fixed runtime coordinates. This does not rearrange menus, toolbar commands, picker choices or system destructive dialogs.

## Disclosure rows and header editing

Piece/theme selection and summary disclosures use semantic surface, 12-point corners, 14-point horizontal padding and 54-point minimum height. Keep the trailing chevron in a fixed 22-point lane and allow labels/values to wrap at larger text sizes. Header Edit uses a 22-point `square.and.pencil` symbol in a 44-point circular Back-style control with semantic ink, an explicit accessibility label and the existing edit destination. Content-level Edit actions remain plain text. Home does not expose Settings; Profile owns that route. See [quality criteria](quality-criteria.md) and [Planner calendar](planner-calendar.md).

## Recorded-wear visuals

L41 and P11 share wear-ranking rows with matching piece thumbnails, explicit wear counts and bars starting at zero on one shared scale. The demo uses 6 wears for Straight jeans and 4 for Cotton shirt. Closet utilization is a factual 8/12 progress bar (67% rounded), not a target or score. The displayed period is September 2026. Actual values derive from recorded wear under the planning/history rules, never plans or generated estimates. Empty history shows no-data copy and Record a look, not invented bars; zero active pieces shows no denominator, not a division error. VoiceOver gets counts and the full numerator/denominator; visual bars are redundant. View source history opens the same period, and tapping a ranking row opens that piece with its wear records.
