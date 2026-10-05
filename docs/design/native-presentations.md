# Native iOS presentations

Phase scope: shared native/visual rules apply to both phases. Full-app E/W/P/S/A/I/U routes, five-destination navigation, identity and connected states are V2 references. Complete private themes/planning/Agent are retained in V1. V1 uses only its [dedicated local flow](v1-flow.md) and [complete local release](../product/v1-release.md); [V2 requirements](v2-requirements.md) own connected and extension coverage.

Refined October 1, 2026 against [Apple Design Resources](https://developer.apple.com/design/resources/), [Menus](https://developer.apple.com/design/human-interface-guidelines/menus), [Popovers](https://developer.apple.com/design/human-interface-guidelines/popovers/) and [Sheets](https://developer.apple.com/design/human-interface-guidelines/sheets). Use native SwiftUI/UIKit presentation components. Paper illustrates task content and context; the OS owns exact material, corner shape, arrow, detents, animation and accessibility adaptation.

## One exit per screen

Leading header exits use the native glass Back chevron at the leading edge, with the navigation title independently centered, including standalone forms and setup. Back returns to the previous screen/task step, or dismisses a task root to its originating screen, without committing. Preserve parent drafts and pending return intent. Cancel is reserved for trailing search controls and native decisions; Close/Done dismisses a read-only sheet. Never show Back and Cancel for the same outcome, including a second dismissal button in the body. Search has one trailing native Cancel across initial, focused, result, loading, error and offline states; it restores the source scope and scroll.

Standalone forms and nested steps use one leading neutral glass Back button. At a task root, Back restores the originating screen without committing; within a task, it returns one step with the draft retained. Back or interactive dismissal that would lose unsaved edits opens the native Discard changes / Keep editing confirmation. Do not silently save on exit. Do not place a Cancel text pill before the title or add an equivalent toolbar/body exit. Search keeps trailing Cancel; native alerts and action sheets retain their safe Cancel actions.

| Existing flow | Exit contract |
| --- | --- |
| E03 sign-in | Native glass Back restores Welcome or the originating screen and pending return intent; local records are unchanged. No Cancel or duplicate Continue privately exit. |
| E07 public-profile setup, E08/E13 connect closet | Back exits the setup step without committing and preserves local records and pending return intent; E07 leaves the social action pending, and connection cancellation leaves ownership unresolved. No duplicate Continue privately / Not now / Keep it on this iPhone dismissal in the same view. |
| E10 email entry, E04 verification, E11 expired link | Back returns to the previous auth step with the transaction/draft retained. E11's Continue privately can exit the whole auth flow, a different destination from Back. Back at E03 exits to Welcome or the originating screen. |
| E09 camera recovery | Back returns to capture with its draft. Photos/manual recovery remain separate actions. |
| W06 photo choice, W07 manual capture, W09 piece editor, W13 builder, W17 suggestion, W19 theme editor | One leading glass Back; preserve the prior saved record and confirm loss of unsaved edits. |
| W27 photo review, W16 replacement, W21 additional details | Back returns to capture/editor with the same draft and selection. No redundant Cancel. |
| P03 plan choice, P04 new plan/trip, P09 record wear | One leading glass Back. No calendar or wear mutation on exit. |
| P05 routine details, P08 plan review, P12 conflicts | Back returns to the preceding draft step with proposed entries and conflict choices retained. Back at the planning task root restores the originating screen without committing. |
| S09 publish, I05 compose, U02 edit profile, U15 typed deletion review, Agent review sheets | One leading glass Back. U15 Back returns to settings without deleting; the final native destructive confirmation retains its own safe Cancel. |
| S10 safety destination and pushed details | Back only; remove duplicate body Cancel. Native action sheets/alerts retain their own OS Cancel group. |

Canonical screens, page-00 masters, larger-text references and V2 review copies use the same exit contract. An alert's safe Cancel is a separate decision within the alert, not a duplicate navigation exit behind it.

## Presentation selection

| Task | Native presentation | Contract |
| --- | --- | --- |
| Closet More (W30) | Toolbar Menu / UIKit menu popup | Short Saved inspiration command anchored to More; system menu row with trailing symbol. Select dismisses the popup before navigation. Outside tap dismisses without changing Closet; preserve tab/filter/scroll and restore trigger focus. No custom overlay/card renderer or forced generic popover. |
| Closet Add (W05) | Native bottom sheet | Show Closet behind the dimmed presentation. Content-height detent for the chooser where supported, large detent for larger text/space needs. Native grabber when resizable; Cancel and swipe/outside dismissal discard no inventory or existing draft. Selecting a destination dismisses/transitions through one presentation owner. |
| Small contextual commands | Menu / contextMenu | Own/other-owner actions and destructive roles come from authorized state. No cascade of custom floating cards. A native menu popup is distinct from a generic content popover. |
| Temporary rich inspector or picker | Native popover in a regular/wide size class; native sheet in compact iPhone layouts | Anchor the popover to its source; let the OS place its arrow. Keep the source visible when possible. Do not force a desktop-size popover on a narrow iPhone. |
| Capture/selection (E06, W06, W14, W16) | Native sheet and system Photos/Camera picker where appropriate | Draft survives picker cancellation/denial; chooser scrolls and grows for accessibility. One presentation at a time. |
| Forms and review (S09, S11, W17, W20, P03–P05, P08–P09, P12, I05, U02, U11, U15, A03, A06, A10, A19, A23) | Native sheet with a NavigationStack and content-appropriate detents | Use large/full-height form presentation when keyboard or content requires it. Single-view forms use the glass Back chevron leading, an independently centered title, and Save/Done trailing when applicable. Protect unsaved edits with a native keep/discard confirmation. Keep primary action clear, keyboard-safe and disabled/pending states truthful. A19 remains V2. |
| Safety/request choices (S10, I04) | Native menu, confirmationDialog or sheet according to the content | A short choice uses native commands; report details/review use a sheet. Avoid an unrelated modal stacked on the current popup. |
| Destructive actions (W12, U12 and committing account deletion) | Native confirmationDialog/alert after any necessary impact/typed review sheet | Explicit target and impact, destructive role and safe Cancel. Cancellation preserves records and drafts. Never treat an alert mockup as a custom full-screen dialog implementation. |
| Agent focus and conversation states (A01–A02, A30) | Native full-screen presentation with system navigation | Existing Agent exception: Back restores the originating tab/scroll. Clarification belongs to the conversation; no new modal for every reply. |
| Response details (A18) | Native sheet; popover may be used in wide layouts | Read-only metadata, scrollable at larger text, no fabricated timing and no custom overlay stack. |
| Permissions, sharing, text editing, dates | OS permission alert, share sheet, edit menu and date picker | Use the actual system UI; no imitation of a permission dialog or keyboard. E09 describes camera recovery/permission intent. |

## Global open-state appearance

Page 00 **Components · Native controls and open menus** is the shared visual reference, with page-specific examples. These are authored static approximations, not imported Apple kit components. Use actual system components in the app; never reproduce their Paper rectangles as custom presentation code.

An open command menu uses regular native material, neutral semantic labels and trailing SF Symbols. Keep a fixed symbol lane, concise verb labels, native row spacing, and system section separators. Selected picker choices have a leading native checkmark. Put destructive commands last in a separate group with the system destructive role/red; AQD's muted error token describes inline errors, not native destructive chrome. Do not tint the entire menu blue. No custom header, close button, grabber, chevron or pointer on a short command menu. The system owns positioning, width, shadow, corner shape and any pointer. Paper's 264-point popup and 48-point row illustrate hierarchy only; grow for content, localization and accessibility.

Opening preserves the source selection and scroll. Toolbar menus anchor to the invoking button; context menus anchor to the selected item. Outside tap cancels with no mutation. Selection dismisses before navigation, confirmation or editing. Revalidate owner/access/state before executing. Remove unauthorized commands; temporarily unavailable commands use truthful native disabled state. Do not show a pending mutation as completed or permit duplicate execution. Long-press context actions must also be discoverable through the visible More control.

Rich content popovers have a system material container, content hierarchy and native close/done affordance when needed. The same content adapts to a sheet in compact layouts. Unlike a Menu, a content popover can contain a form, inspector or scrollable content. Do not force one generic floating card to serve both roles.

Sheets use system dimming, corners and detents. Simple action choices use a native confirmation dialog (the iPhone action-sheet presentation), with system Cancel grouping. Multi-step forms use a sheet's NavigationStack. Alerts are reserved for short blocking decisions; avoid success alerts for ordinary saves. Use inline retry for recoverable read/save failures and existing receipts for confirmed completion.

Deletion confirmations use destructive Delete plus neutral Cancel; there is no separate blue primary action. The delete-comment component uses native confirmation rows and destructive red, replacing its old brand-tinted glass button stack. Theme deletion, block/discard commands and account/delete entry points share destructive semantics; disabled account deletion stays neutral until validation succeeds. Navigation titles and explanatory text stay neutral. Full review forms may have a red prominent commit action, while native alerts/dialogs keep system-managed actions and layout.

## Per-page V2 presentation map

This defines native presentations for every V2 page; it adds no new feature scope. Existing direct actions remain visible. A menu is secondary access, not a requirement to hide primary actions.

| Paper page / context | Open content and entry | Native component / result |
| --- | --- | --- |
| 01 Entry & identity | Photo source: Choose photo, Take photo, Cancel (E06/W06); authentication and email entry | Native confirmationDialog for source choices, PhotosPicker/camera and OS permission UI. Native Apple sign-in and email fields. Verification errors stay inline. No new welcome overflow menu. |
| 02 Home · Today | Existing Add / Build / Plan / Record wear actions and owner-scoped search | Existing editor/chooser sheets or navigation. No generic dashboard menu added. |
| 02 Home · other person's post or profile | Report post/person; Block person, last and destructive (S10) | Native Menu/contextMenu; Report opens S11 review, Block opens exact-person confirmation. Heart/bookmark remain inline native toggle buttons. |
| 02 Home · own published content | Existing edit/publication review and Unpublish controls | Owner commands only; native review sheet and destructive confirmation for access revocation. Do not offer moderation actions on one's own content. |
| 03 Closet · root | More → Saved inspiration (W30); Add → Add piece / Build outfit / Create theme / Suggest an outfit (W05) | Anchored native Menu; Add retains richer native bottom-sheet chooser. More identical across Pieces, Outfits, Themes and empty state. |
| 03 Closet · piece | Existing Edit, availability, archive/restore, wear and Delete actions (W08–W12) | Native Buttons/Picker/Menu according to existing layout. Availability is a state selection, not a binary switch. Delete names the piece and reviews linked impact before confirmation. |
| 03 Closet · owned outfit/theme | Outfit: Edit outfit, Plan a wear, Delete outfit; theme: existing edit/membership/delete actions | Native Menu/contextMenu for secondary commands; edit/plan open existing tasks. Destructive last with confirmation. Favorite uses native toggle-button semantics. Removing theme membership never deletes an outfit. |
| 04 Planning & wear | Date/timezone and outfit choices (P03–P05), review/conflict (P08/P12), Record/correct/undo wear (P09/P10) | Native DatePicker/Picker and sheet navigation. Rich date/inspection content may use adaptive popover. Packing checks are native selectable rows with a checked trait. No extra planning overflow menu required. |
| 05 Agent | Response: Copy, Retry when valid, Details; proposal Review/Edit/Save; failed-message Resend/Edit | Native content Buttons with optional same-command Menu/contextMenu. Details uses adaptive sheet/popover. Proposals use review sheets; no mutation from simply opening/selecting a response. Helpful/Not helpful and version comparison are V2 extensions beyond the shared V1/V2 core actions. |
| 06 Inbox | Existing conversation details → View profile, Report person, Block person; request Accept/Decline/Block | Native Menu for short secondary choices; details remains a navigable destination. Confirmation for block/decline where impact requires it. Native composer/edit menu. Mute and delete-for-everyone are V2-E08/E09 extensions; gate their commands until the transport/lifecycle exists. |
| 07 Profile · owner | Edit profile, Share profile, Add, Settings; Appearance System/Light/Dark | Native editor/Add sheets, ShareLink/activity sheet and Settings navigation. Appearance uses native Picker with selected check. No replacement Settings popover. |
| 07 Profile · visitor | More → Report person, Block person | Same anchored Menu/safety group as Home; owner-only commands hidden. Full bio uses native About sheet. |
| 07 Settings · privacy/account | Social listing preference; block management; export, sign out, account deletion and sync/restore reviews | Native Form/Toggle for the real binary preference, native share sheet for a ready export, impact/re-auth review sheets plus exact-target confirmation. Pending/failed sync remains an inline status/destination, not a switch. |
| 08 Offline review / 09 V2 walkthrough | Copies of the same feature states | Inherit source-page native controls and commands; no separate presentation language. Offline proposal remains separately scoped. |

## All native-capable controls

| Role | Required native primitive | AQD styling boundary |
| --- | --- | --- |
| Back/navigation, toolbar, tab bar | NavigationStack/Toolbar/TabView or UIKit equivalents | Semantic tint and SF Symbols; retain native history, swipe, labels and safe areas. |
| Toggle preference | Toggle/UISwitch in native Form row | Ink-blue on tint where supported; native thumb, track, animation and accessibility. No added glass effect or custom switch renderer. Show in discovery concerns social listing; owned records stay private. |
| Heart, bookmark, outfit favorite | Native Button with selected state / toggle semantics | Filled symbol plus selected accessibility value. Not a preference switch. |
| One choice / several choices | Native Picker or selectable List rows | Native checkmarks; preserve draft selection. Use a switch only for a binary preference, not navigation or an asynchronous job. |
| Segments, filters, text entry | Native segmented Picker, Buttons, searchable/TextField/TextEditor | Existing density and input-shell policy; preserve keyboard, text selection, dictation, autofill and edit menus. |
| Dates, photo capture/selection, sharing | DatePicker, PhotosPicker/camera, activity/share sheet | OS-owned UI; AQD supplies allowed range, files and scope. |
| Progress, validation, permission | Native ProgressView, inline associated validation, OS permission alert | Actual state only; no custom imitation of system prompts. |
| Menus, sheets, alerts, popovers | Native Menu/contextMenu, sheet, confirmationDialog, alert, popover | Content/actions and supported tint only; native material and adaptation. |

Use available native APIs for the supported deployment target. Older supported OS versions use their standard native appearance rather than a custom imitation of newer glass. AQD-specific garment grids, photo tags, plan agenda, draft review and conversation content remain custom content inside native navigation/presentation. Native-first does not require turning every content surface into glass.

Global acceptance: open/dismiss/reopen from each trigger; compare own/visitor/guest/offline states; test long localized labels, largest accessibility size, VoiceOver, light/dark, Reduce Transparency and Increase Contrast. Check source anchoring, command order, disabled/selected/destructive semantics, preserved draft/scroll and focus return. Runtime behavior still requires implementation/device verification.

## Shared dismissal and adaptation

Only one task presentation owns focus at a time. Dismiss a command menu before pushing a destination or presenting its editor. Nested steps inside a sheet use the sheet's navigation stack; avoid piling unrelated sheets/popovers on top. System alerts may interrupt only when necessary. Return accessibility focus to the initiating control.

For simple choosers, automatic dismissal changes no data. For editors, retain the draft and show a native keep/discard choice when an interactive dismissal would lose edits. Never disable swipe dismissal merely to force engagement. When saving is in flight, communicate the actual state and reconcile unknown completion rather than silently dropping input.

Detents must fit content and adapt to Dynamic Type, keyboard, orientation and available height. Content scrolls at the large detent; controls remain in safe areas. Native dismissal, background dimming, Liquid Glass and Reduce Transparency/Increase Contrast remain system-owned. Paper dimensions and corner values are reference geometry, not values to override native presentation chrome.

## Paper review scope

W30 is the Closet More native-menu popup reference. W05 now shows Closet beneath its dimmed native bottom sheet. Reviewed both for context, spacing, contrast, alignment and fit. Page 00 now includes a global open-state/control reference with per-page content and dark/opaque variants. X07 now separates a bottom-docked keyboard layout reference from search results. All drawings are authored approximations; the Apple kit components were not imported. This is design/docs only; device behavior, actual detents, dismissal, focus and materials remain implementation checks. No screenshots were saved.

Additional primary references: [Toggles](https://developer.apple.com/design/human-interface-guidelines/toggles), [Context menus](https://developer.apple.com/design/human-interface-guidelines/context-menus), and [SwiftUI modal presentations](https://developer.apple.com/documentation/swiftui/modal-presentations).

## Agent input presentations

A34 is keyboard-focused full-screen entry; A01 is its keyboard-dismissed state. Header More uses native New conversation / Conversations / Manage context commands. A35 anchors the attachment Menu to + (adapting to a sheet); selected-media PhotosPicker, camera and image-only Files picker are OS-owned. A36/A46 use native selection sheets/navigation or an iPad popover. A38/A44 use native review/edit sheets with one safe exit and retained parent draft. A41 invokes the actual permission prompt only after Continue; A42–A45 use a focused recording/transcript task, never an invented OS permission alert. See [Agent input](agent-input.md). New conversation and scope changes do not discard a draft; leaving a recording stops capture and offers safe discard/retention where appropriate.


## Global title and content alignment · October 2, 2026

Center detail/task navigation titles with Back and native sheet/full-screen navigation independently of action count and width. Root screens without Back, including Home, Closet, Planner, Inbox, Profile and standalone search, keep their titles at the leading content inset. Keep equal reserved space on both sides, preserve 44 pt actions, and use native single-line truncation for long/localized titles. Back remains leading and task actions trailing. Root Closet keeps its title leading, with Search/Add/More trailing. Hidden dismiss controls and decorative flex spacers do not reserve action width. Native navigation/toolbar placement owns the runtime layout and Dynamic Type adaptation.

Agent empty-state welcome heading/supporting introduction are centered; suggestion chips align below. Messages, responses, input text, list rows, form labels and ordinary content headings retain leading alignment. Apply the same contract to light/dark/accessibility variants, page-00 masters and snapshot walkthrough copies.


Centered navigation titles share one base type style: 20 pt size, 26 pt line height, medium (500) weight and the shared `--tracking-title` value. Agent uses the same title style as review/detail/task screens. Paper binds size to `--text-20`; native implementation uses one shared scalable system-font role. Root titles retain their separate leading-aligned hierarchy. Do not apply body-size 17 pt to Agent navigation or shrink long titles to fit; use native truncation/adaptation.
