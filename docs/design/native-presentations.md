# Native iOS presentations

Phase scope: shared native/visual rules apply to both phases. Five-destination base navigation applies to both phases. Full-app E/W/P/S/A/I/U routes, online identity and connected states are V2 references. Complete private themes/planning/Agent are retained in V1. V1 uses only its [dedicated local flow](v1-flow.md) and [complete local release](../product/v1-release.md); [V2 requirements](v2-requirements.md) own connected and extension coverage.

Refined October 1, 2026 against [Apple Design Resources](https://developer.apple.com/design/resources/), [Menus](https://developer.apple.com/design/human-interface-guidelines/menus), [Popovers](https://developer.apple.com/design/human-interface-guidelines/popovers/) and [Sheets](https://developer.apple.com/design/human-interface-guidelines/sheets). Use native SwiftUI/UIKit presentation components. Paper illustrates task content and context; the OS owns exact material, corner shape, arrow, detents, animation and accessibility adaptation.

## One exit per screen

Leading header exits use the native glass Back chevron at the leading edge, with the navigation title independently centered, including standalone forms and setup. Back returns to the previous screen/task step, or dismisses a task root to its originating screen, without committing. Preserve parent drafts and pending return intent. Cancel is reserved for trailing search controls and native decisions; Close/Done dismisses a read-only sheet. Never show Back and Cancel for the same outcome, including a second dismissal button in the body. Search has one trailing native Cancel across initial, focused, result, loading, error and offline states; it restores the source scope and scroll.

Standalone forms and nested steps use one leading neutral glass Back button. At a task root, Back restores the originating screen without committing; within a task, it returns one step with the draft retained. Back or interactive dismissal that would lose unsaved edits opens a contextual native Discard changes / Cancel decision. Cancel keeps editing; no silent save. Routine intentional draft choices use an action sheet; uncommon, substantial unrecoverable loss may require an alert. Do not silently save on exit. Do not place a Cancel text pill before the title or add an equivalent toolbar/body exit. Search keeps trailing Cancel; native alerts and action sheets retain their safe Cancel actions.

| Existing flow | Exit contract |
| --- | --- |
| E03 sign-in | Native glass Back restores Welcome or the originating screen and pending return intent; local records are unchanged. No Cancel or duplicate Continue privately exit. |
| E07 public-profile setup, E08/E13 connect closet | Back exits the setup step without committing and preserves local records and pending return intent; E07 leaves the social action pending, and connection cancellation leaves ownership unresolved. No duplicate Continue privately / Not now / Keep it on this iPhone dismissal in the same view. |
| E10 email entry, E04 verification, E11 expired link | Back returns to the previous auth step with the transaction/draft retained. E11's Continue privately can exit the whole auth flow, a different destination from Back. Back at E03 exits to Welcome or the originating screen. |
| E09 camera recovery | Back is the sole exit to capture with its draft; no equivalent Not now. Photos/manual recovery and Open Settings remain distinct actions. |
| W06 photo choice, W07 manual capture, W09 piece editor, W13 builder, W17 suggestion, W19 theme editor | One leading glass Back; preserve the prior saved record and confirm loss of unsaved edits. |
| W27 photo review, W16 replacement, W21 additional details | Back returns to capture/editor with the same draft and selection. Unsaved-capture details use Use these details, applying to the parent draft only; saved-record mode may Save changes after validation. No redundant Cancel or independent piece creation from a draft substep. |
| P03 plan choice, P04 new plan/trip, P09 record wear | One leading glass Back. No calendar or wear mutation on exit. |
| P05 routine details, P08 plan review, P12 conflicts | Back returns to the preceding draft step with proposed entries and conflict choices retained. Back at the planning task root restores the originating screen without committing. |
| S09 publish, I05 compose, U02 edit profile, U15 typed deletion review, Agent review sheets | One leading glass Back. U15 Back returns to settings without deleting; the final native destructive confirmation retains its own safe Cancel. |
| S10 safety destination and pushed details | Back only; remove duplicate body Cancel. Native action sheets/alerts retain their own OS Cancel group. |

Canonical screens, reusable Foundation primitives, phase-owned larger-text references and V2 review copies use the same exit contract. An alert's safe Cancel is a separate decision within the alert, not a duplicate navigation exit behind it.

## Outfit and receipt trailing More

October 7 [scoped evidence](evidence/ui-refinements.json): outfit detail L08/W15 uses a 44-point trailing ellipsis **More** native Menu with Edit outfit, favorite toggle and destructive Delete last in a separate group. Retained L124 is a contextual open STATE over L08, not a pushed options page; generic and V2 phase menu examples share registered22-point command symbols, without disclosure chevrons, popup headers, Close or grabbers. The OS owns menu geometry/material/adaptation. Hide duplicate body Edit; preserve Plan/Wear and V2 explicit Publish review.

Saved receipts L27/A04 keep Open outfit/Plan primaries and move management into More. Edit outfit opens L133 (V1) or W13 saved-record edit mode (V2), with the same outfit ID/expected revision and Save changes; creation mode is unchanged. Back to conversation is included only for an acknowledged Agent-origin operation plus retained authorized conversation/response; omit it for manual saves or unavailable context. A20 response-feedback receipt's More contains only that guarded conversation return; Update feedback remains separate. Pending/unknown A22/A09 never imply success. Feedback remains V2-extension-only.

Dismiss Menu before editor, Agent return or confirmation. Revalidate ownership, revision and return context. Clean Back/dismissal writes nothing and restores focus/scroll; dirty exit protects drafts; failure preserves prior records, unknown completion reconciles the existing operation. V1 Delete uses L140; V2 linked impact retains necessary ZMA-0 publication review before XSH-0, never a stacked Menu/alert or implicit publication. Added open references ZRD-0 (V1 L27), ZTD-0 (V2 A04), ZVD-0 (V2 W15) and ZXE-0 (V2 A20) are four reference roots, not canonical routes or extra confirmations. Native acceptance remains outstanding.

## Confirmation states, not pushed screens

October 6 owner-approved rule applies to both V1 and V2. A confirmation is an overlay on the actual originating screen, not a new navigation destination. Existing confirmation IDs remain useful Paper state references; do not implement them as extra pushed pages. Keep the selected record, draft, scroll and invoking control behind the native presentation. Reference fixtures never hard-code the runtime return route.

| Risk / task | Native presentation | Required behavior |
| --- | --- | --- |
| Critical, uncommon loss: erase the local closet, replace the current store, delete an account, substantial unrecoverable edits or an actual financial commitment | Native alert for the final decision | Concise specific title, necessary impact message, deliberate action and Cancel. Preserve mandatory typed review, authentication, validation and transaction reconciliation in their real preceding task. No outside tap confirms a destructive action. |
| Intentional, bounded choices: delete a theme/outfit/piece/memory/conversation, remove a plan, sign out, block or routine draft discard | Native confirmationDialog/action sheet | Show the owner underneath; destructive command when appropriate, with a separate Cancel group. Retain exactly scoped consequences. Theme removal never deletes outfits/pieces/wear; sign-out is not erase. Native system dismissal, where permitted, equals Cancel. |
| Common undoable action or unchanged dismissal | Direct action + honest Undo, or dismissal | Avoid redundant interruption. Undo must be real, not a promised fallback where recovery is unavailable. |
| Rich import/restore/upload/payment/publication review or required verification/input | Existing native review/form task | Do not collapse necessary input, scope review or validation into a two-button dialog. Use a final overlay only when its risk requires a separate deliberate decision. |
| Unknown save/send completion | Existing reconciliation state | Never turn an unknown result into blind Retry, Discard or an assumed completed mutation. |

Apple recommends action sheets for related choices after an intentional action, including saving/deleting a draft; alerts are reserved for critical information and uncommon irreversible decisions. Keep titles short, include a message only when it adds necessary scope, and use explicit action verbs. The safe action is **Cancel**: bottom group in an action sheet, normally leading in a horizontal alert. Cancel, outside/system dismissal where supported and interruption never commit. Keep action sheets to at most four actions including Cancel. Restore accessibility focus to the trigger; keep the obscured host out of focus while presented.

The critical draft-loss exception requires all of: an explicit exit request, substantial actual changed content, no autosaved/restorable draft or Undo, and no in-flight write or unknown completion. The10-date V1 and12-date V2 fixtures demonstrate qualifying scope, not a universal numeric threshold. Otherwise use routine scoped discard or clean dismissal; reconcile unknown writes before offering loss decisions.

An iPhone action sheet is not a custom draggable mini-form. SwiftUI `confirmationDialog` or UIKit action-sheet presentation adapts to the device/size class; iPad can use an anchored popover. Do not assume all native dialogs swipe away, or that bottom sheets are mobile-only. Critical decisions require an explicit choice. The OS owns scrim, material, sizing, animation, accessibility and supported dismissal; Paper illustrates the state only. Avoid layering a new confirmation over an undismissed command popup.

Primary guidance: [Apple Alerts](https://developer.apple.com/design/human-interface-guidelines/alerts), [Action sheets](https://developer.apple.com/design/human-interface-guidelines/action-sheets) and [SwiftUI confirmationDialog](https://developer.apple.com/documentation/swiftui/view/confirmationdialog(_:ispresented:titlevisibility:actions:message:)). Reviewed the public Apple DocC [Alerts JSON](https://developer.apple.com/tutorials/data/design/human-interface-guidelines/alerts.json) and [Action sheets JSON](https://developer.apple.com/tutorials/data/design/human-interface-guidelines/action-sheets.json) after the JavaScript page fetch was unavailable. This is guidance, not device acceptance.

## Prepared confirmation state map

Both phases now illustrate decisions over their source context. The register covers17 V1 native decisions and21 V2 native decisions, including the retained nested U12 journey copy, plus a direct piece-photo-removal result and any required linked-impact review. Ten existing canonical IDs and that nested copy keep their control identities; new roots are reference-only. Registered screen/state IDs remain380; these drawings add no pushed runtime routes. The full baseline classifications and final state contracts are in [confirmation evidence](evidence/native-confirmations.json). Baseline candidate text/visibility is not current post-conversion evidence.

### V1

| State / Paper node | Actual caller illustrated | Native decision / preserved scope |
| --- | --- | --- |
| L139 `RXW-0` | L34 `L7F-0`, selected Weekend | Action sheet; theme/memberships only, not outfits/pieces/wear |
| L140 `RYS-0` | L08 `JVS-0`, selected outfit | Action sheet; outfit/memberships/future-plan impact, historical and memory snapshots retained |
| L138 `RX0-0` | L21 `K9I-0`, selected piece | Action sheet for linked-plan impact; unlinked routine archive may act directly with real Undo |
| L141 `RZO-0` | L130 `RHZ-0`, selected wear record | Action sheet; exact wear removal and linked-plan correction |
| L143 `S1G-0` | L26 `KU5-0`, selected conversation | Action sheet; this conversation only, saved proposals excluded |
| L156 `SG4-0` | L128 `RG7-0`, selected plan entry | Action sheet; reviewed occurrence/scope only, actual wear and completed past entries retained |
| L106 `QWN-0` | L75 `ODL-0`, dirty capture fixture | Action sheet; caller-scoped draft discard and pending exit, no silent save |
| L97 `QKI-0` | L21 `K9I-0`, Cotton shirt | Action sheet; revalidated piece/outfit/theme-membership/future-plan impact, Photos/history/memories preserved |
| L142 `S0K-0` | L11 `K16-0`, September30 wear | Action sheet; inspect/correct existing wear, never create a duplicate |
| Delete memory `Z01-0` | L163 `T3X-0` | Action sheet; exact memory and only unreferenced AQD media after commit, no wardrobe/wear or Photos deletion |
| Discard fit draft `Z1X-0` | L162 `T2C-0` | Action sheet; current draft only, prior saved memory retained |
| Discard photo edits `Z3U-0` | L77 `OG7-0` | Action sheet; uncommitted crop/rotation only, accepted rendition and piece/fit parent draft retained; clean exit returns directly |
| Remove fit photo `Z6J-0` | L162 `T2C-0` | Action sheet; draft photo removal only, fit eligibility revalidated |
| Discard recording `Z8G-0` | L70 `N5P-0` | Action sheet; stop recording first, typed parent draft retained |
| Major unsaved loss `ZAS-0` | Qualifying cloned L40 draft:10 unsaved date changes, Oct5–16 | Alert only when explicit exit loses substantial multi-date edits with no autosaved/restorable draft or Undo; ordinary L40 remains unchanged and uses routine dismissal policy |
| Restore commit `ZCU-0` | L15 `KIK-0`, validated archive review | Alert after required validation/impact review; replacement is atomic, not merge; rollback on failure |
| Erase commit `ZE7-0` | L16 `KJF-0`, typed ERASE review | Alert after exact local impact and typed gate; original Photos/exported archives excluded |

### V2

| State / Paper node | Actual caller illustrated | Native decision / preserved scope |
| --- | --- | --- |
| U12 `5B1-0`; journey `DAI-1` | U05 `3B1-0` | Action sheet; account session/cache boundary, unuploaded local changes retained, no erase |
| Delete theme `XQI-0` | W18 `2X8-0`, Weekend | Action sheet; private theme/memberships only, eight outfits remain |
| Outfit deletion review `ZMA-0` | W15 `2AY-0`; existing plan/public-snapshot fixtures `2Q3-0` / `39L-0` | Required rich review, not a confirmation; hold an explicit Keep published / Unpublish choice with actual authorized record IDs/revisions |
| Delete outfit `XSH-0` | Retained `ZMA-0` review, illustrated clone `ZNN-0` | Action sheet after actual plan/public-snapshot review; bind exact Keep published snapshot / Unpublish choice, preserve wear/memory snapshots |
| Delete piece final `XUH-0` | W12 `21M-0` | Action sheet after exact-impact/authorized scope review; public choices remain explicit |
| Discard draft `XWH-0` | W13 `26F-0` dirty fixture | Action sheet; actual invoking editor draft only; all forms inherit scoped dismissal, not a fixed W13 return |
| Major unsaved loss `XZQ-0` | Qualifying planning draft:12 dated assignments/edited notes, Oct7–18, Asia/Manila | Alert only for substantial changed content AND unavailable recoverable draft retention AND no in-flight/unknown write; ordinary W13 remains unchanged |
| Block person `Y1U-0` | S06 `R7-0`, selected person | Action sheet; exact stable account ID and safety consequences |
| Unblock person `Y45-0` | U08 `4MW-0`, selected blocked account | Action sheet; actual available identity, no invented person |
| Decline request `Y5M-0` | I04 `34Z-0`, selected request | Action sheet; request retained on pending/failure |
| Unpublish look `Y87-0` | U04 `34Y-0`, own published look | Action sheet; revoke selected public access, never expose/delete private journal implicitly |
| Delete comment `YAI-0` | S22 `8B5-0`, own acknowledged comment | Action sheet; reconcile unknown send first, no unrelated comment deletion |
| Delete Agent conversation `YCT-0` | A05 `34E-0` | Action sheet; selected conversation, saved wardrobe/proposals excluded |
| Undo wear `YEJ-0` | P10 `5B0-0`, selected historical record | Action sheet; exact record/date/item set from caller |
| Discard recording `YI7-0` | A42 `GXL-0` | Action sheet; stop microphone first and retain typed parent draft |
| Erase local closet `YKL-0` | Shared L16 typed-ERASE review, V2-origin U09 | Alert only after validated ERASE and exact device impact; Cancel keeps review input; account/public deletion remains separate |
| Replace closet `YMR-0` | Shared L15 review cloned into V2 | Alert for reviewed replacement only; non-replacing account restore remains a task |
| Delete account final `YO2-0` | U15 `5IZ-0`, validated typed/re-auth review | Alert; reviewed connected/public deletion and retention policy, remote copies cannot be erased |
| Delete fit memory `YSO-0` | Shared private L163 detail | Action sheet; actual V2 private caller return; cleanup only unreferenced AQD-owned media after commit, preserve other memories and original Photos |
| Remove fit photo `YUG-0` | Shared private L162 editor | Action sheet; current photo/draft scope, not saved parent or Photos |
| Remove piece photo `YW9-0` | Current piece draft | Direct action/result reference, not a confirmation; metadata/prior media retained, Save disabled until valid photo, dirty exit protected separately |
| Remove plan entry `ZGW-0` | P02 `2K0-0`, selected entry | Action sheet; occurrence/future/all scope review when applicable |

Every Cancel preserves the actual source record/draft, selection, scroll and invoking focus. A successful destructive operation returns to the surviving owner/list or resumes the pending exit; it must not return to a deleted detail or a hardcoded fixture. Failed operations keep prior data and show actionable status on the true owner. Unknown completion reconciles the same operation identity before any retry. Do not add success alerts for routine saves, a second confirmation for publication/report review, or executable future payment/moderation controls without their lifecycle.

Foundations `4GB-0` retains generic critical-alert `FJ2-1` and action-sheet `ZGG-0` grammar only. Phase examples live in V1/V2; they are not native components copied verbatim into app code. Static review does not prove Dynamic Type, accessibility focus, native dismissal, iPad adaptation, persistence, authentication or service behavior.

## Presentation selection

| Task | Native presentation | Contract |
| --- | --- | --- |
| Closet More (W30) | Toolbar Menu / UIKit menu popup | Short Saved inspiration command anchored to More; system menu row with trailing symbol. Select dismisses the popup before navigation. Outside tap dismisses without changing Closet; preserve tab/filter/scroll and restore trigger focus. No custom overlay/card renderer or forced generic popover. |
| Closet Add (W05) | Native bottom sheet | Show Closet behind the dimmed presentation. Content-height detent for the chooser where supported, large detent for larger text/space needs. Native grabber when resizable; Cancel and swipe/outside dismissal discard no inventory or existing draft. Its Add a piece / Build an outfit / Create a theme destination rows show registered 22-point chevron.forward disclosures in a fixed trailing lane, with flexible labels and full-row targets ≥44 points (54-point base rows retained). Selecting a destination dismisses/transitions through one presentation owner. |
| Small contextual commands | Menu / contextMenu | Own/other-owner actions and destructive roles come from authorized state. No cascade of custom floating cards. A native menu popup is distinct from a generic content popover. |
| Temporary rich inspector or picker | Native popover in a regular/wide size class; native sheet in compact iPhone layouts | Anchor the popover to its source; let the OS place its arrow. Keep the source visible when possible. Do not force a desktop-size popover on a narrow iPhone. |
| Capture/selection (E06, W06, W14, W16) | Native sheet and system Photos/Camera picker where appropriate | Draft survives picker cancellation/denial; chooser scrolls and grows for accessibility. One presentation at a time. |
| Forms and review (S09, S11, W17, W20, P03–P05, P08–P09, P12, I05, U02, U11, U15, A03, A06, A10, A19, A23) | Native sheet with a NavigationStack and content-appropriate detents | Use large/full-height form presentation when keyboard or content requires it. Single-view forms use the glass Back chevron leading, an independently centered title, and Save/Done trailing when applicable. Protect unsaved edits with a native keep/discard confirmation. Keep primary action clear, keyboard-safe and disabled/pending states truthful. A19 remains V2. |
| Safety/request choices (S10, I04) | Native menu, confirmationDialog or sheet according to the content | A short choice uses native commands; report details/review use a sheet. Avoid an unrelated modal stacked on the current popup. |
| Destructive actions (W12, U12 and committing account deletion) | Native action sheet for bounded record choices; critical final alert after any necessary impact/typed review | Apply the risk table above; name target and impact, destructive role and Cancel. Preserve records/drafts on cancellation. The confirmation is a state over its true host, never a pushed full-screen page. |
| Agent focus and conversation states (A01–A02, A30) | Native full-screen presentation with system navigation | Existing Agent exception: Back restores the originating tab/scroll. Clarification belongs to the conversation; no new modal for every reply. |
| Response details (A18) | Native sheet; popover may be used in wide layouts | Read-only metadata, scrollable at larger text, no fabricated timing and no custom overlay stack. |
| Permissions, sharing, text editing, dates | OS permission alert, share sheet, edit menu and date picker | Use the actual system UI; no imitation of a permission dialog or keyboard. E09 describes camera recovery/permission intent. |

App-owned destination choosers, including Closet Add, Add to Planner and the share-source chooser, use the same registered 22-point trailing disclosure lane with a 12-point label/accessory gap. Grow and wrap labels at accessibility sizes; mirror the forward cue in RTL. This applies to navigation into another task, not immediate commands, selected options, toggles, destructive confirmations or OS-owned source pickers. A native Menu retains its command symbols rather than disclosure chevrons.

## Global open-state appearance

Foundations owns generic native-presentation grammar; the phase-owned **Native controls and open menus** reference retains feature-specific examples. These are authored static approximations, not imported Apple kit components. Use actual system components in the app; never reproduce their Paper rectangles as custom presentation code.

An open command menu uses regular native material, neutral semantic labels and trailing SF Symbols. Keep a fixed symbol lane, concise verb labels, native row spacing, and system section separators. Selected picker choices have a leading native checkmark. Put destructive commands last in a separate group with the system destructive role/red; AQD's muted error token describes inline errors, not native destructive chrome. Do not tint the entire menu blue. No custom header, close button, grabber, chevron or pointer on a short command menu. The system owns positioning, width, shadow, corner shape and any pointer. Paper's 264-point popup and 48-point row illustrate hierarchy only; grow for content, localization and accessibility.

Opening preserves the source selection and scroll. Toolbar menus anchor to the invoking button; context menus anchor to the selected item. Outside tap cancels with no mutation. Selection dismisses before navigation, confirmation or editing. Revalidate owner/access/state before executing. Remove unauthorized commands; temporarily unavailable commands use truthful native disabled state. Do not show a pending mutation as completed or permit duplicate execution. Long-press context actions must also be discoverable through the visible More control.

Rich content popovers have a system material container, content hierarchy and native close/done affordance when needed. The same content adapts to a sheet in compact layouts. Unlike a Menu, a content popover can contain a form, inspector or scrollable content. Do not force one generic floating card to serve both roles.

Sheets use system dimming, corners and detents. Simple action choices use a native confirmation dialog (the iPhone action-sheet presentation), with system Cancel grouping. Multi-step forms use a sheet's NavigationStack. Alerts are reserved for short blocking decisions; avoid success alerts for ordinary saves. Use inline retry for recoverable read/save failures and existing receipts for confirmed completion.

Deletion confirmations use destructive Delete plus neutral Cancel; there is no separate blue primary action. The delete-comment component uses native confirmation rows and destructive red, replacing its old brand-tinted glass button stack. Theme deletion, block/discard commands and account/delete entry points share destructive semantics; disabled account deletion stays neutral until validation succeeds. Navigation titles and explanatory text stay neutral. Full review forms may have a red prominent commit action, while native alerts/dialogs keep system-managed actions and layout.

## Shared root navigation

V1/V2 share five equal-width icon-only native slots Home · Closet · Planner · Agent · Profile with explicit accessibility names/selected traits and full hit areas ≥44 × 44 pt. Planner is a dedicated root, Week default/Month alternate; Closet segments only Pieces/Outfits/Themes. Home plan/outfit Plan links carry date context and Back restores origin/selection. Agent's fourth-slot launch presents the native full-screen task; dismissal restores origin/scroll/focus. V1 Profile's single More icon opens Add fit, Edit profile, Style, Wear insights and Settings; no duplicate root actions remain. L165 illustrates the contextual open state. Account setup never gates private core. V1 has no Inbox entry.

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
| 03 Closet · owned outfit/theme | Outfit: Edit outfit, Plan a wear, Delete outfit; theme: More → Add outfits, Edit theme, Delete theme; L164 illustrates V1's open menu; retained L123 uses the same contextual native-menu composition, not a separate command page | Native Menu/contextMenu for secondary commands; edit/plan open existing tasks. Destructive last with confirmation. Favorite uses native toggle-button semantics. Removing theme membership never deletes an outfit. |
| 04 Planning & wear | Date/timezone and outfit choices (P03–P05), review/conflict (P08/P12), Record/correct/undo wear (P09/P10) | Native DatePicker/Picker and sheet navigation. Rich date/inspection content may use adaptive popover. Packing checks are native selectable rows with a checked trait. No extra planning overflow menu required. |
| 05 Agent | Response: Copy, Retry when valid, Details; proposal Review/Edit/Save; failed-message Resend/Edit | Native content Buttons with optional same-command Menu/contextMenu. Details uses adaptive sheet/popover. Proposals use review sheets; no mutation from simply opening/selecting a response. Helpful/Not helpful and version comparison are V2 extensions beyond the shared V1/V2 core actions. |
| V2 roots · Inbox entry | Persistent labelled 44-point toolbar control → existing I01 → conversation; startup/incoming intents preserve origin | Native push navigation; Back restores origin root/scroll/selected tab. Not a tab, no fake unread and no V1 mirror. Keep reachable with Dynamic Type and keyboard-safe layout. |
| 06 Inbox | Existing conversation details → View profile, Report person, Block person; request Accept/Decline/Block | Native Menu for short secondary choices; details remains a navigable destination. Confirmation for block/decline where impact requires it. Native composer/edit menu. Mute and delete-for-everyone are V2-E08/E09 extensions; gate their commands until the transport/lifecycle exists. |
| 07 Profile · owner | Private journal base: one More for Add fit/Edit private profile/Style/Wear insights/Settings; V2 adds explicit public collections/publication/public-link actions | U01/U25 match V1's native management pattern; Inbox remains a separate V2 entry. Shared L161/L49 editors return to U01 without public identity gates. U26/U02 own the separate public projection/editor. Native publication review and verified-URL ShareSheet never expose private fields automatically. Appearance uses native Picker; no replacement Settings popover. |
| 07 Profile · visitor | More → Report person, Block person | Same anchored Menu/safety group as Home; owner-only commands hidden. Full bio uses native About sheet. |
| 07 Settings · private data and privacy/account | Private local archive export/reviewed restore/erase and on-device assistance remain available without an account; connected account export/sync/restore/deletion are separately scoped additions | Shared local editors restore the actual U05/U09 source. Local erase/restore names device-only records/media and never implies account or public-snapshot deletion. Native share for a ready archive, exact-impact review and safe destructive confirmation; account operations retain re-auth/access checks. Pending/failed sync is status, not a switch. |
| 08 Offline review / 09 V2 walkthrough | Copies of the same feature states | Inherit source-page native controls and commands; no separate presentation language. Offline proposal remains separately scoped. |

## All native-capable controls

| Role | Required native primitive | AQD styling boundary |
| --- | --- | --- |
| Back/navigation, toolbar, tab bar | NavigationStack/Toolbar/TabView or UIKit equivalents | Semantic tint and SF Symbols; retain native history, swipe, destination accessibility names and safe areas; tab captions are hidden. |
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

For simple choosers, automatic dismissal changes no data. For editors, retain the draft and show a native Discard changes / Cancel choice when an interactive dismissal would lose edits; Cancel keeps editing. Intentional routine draft choices use an action sheet; critical unexpected unrecoverable loss uses an alert. Never disable swipe dismissal merely to force engagement. When saving is in flight, communicate the actual state and reconcile unknown completion rather than silently dropping input.

Detents must fit content and adapt to Dynamic Type, keyboard, orientation and available height. Content scrolls at the large detent; controls remain in safe areas. Native dismissal, background dimming, Liquid Glass and Reduce Transparency/Increase Contrast remain system-owned. Paper dimensions and corner values are reference geometry, not values to override native presentation chrome.

## Paper review scope

W30 is the Closet More native-menu popup reference. W05 shows Closet beneath its dimmed native chooser. Earlier context/spacing/contrast/alignment checks remain historical evidence. Feature-specific open menus and dark/opaque phone references now live in the owning phase; Foundations contains generic presentation/control grammar only. X07 separates a bottom-docked keyboard reference from search results. All drawings are authored approximations, not imported Apple kit components.

The October6 confirmation pass covers the prepared state map above, source-context clones and generic Foundations alert/action-sheet grammar. Bounded family renders and measured action checks are recorded in [confirmation evidence](evidence/native-confirmations.json); they do not certify every canvas root. Actual native geometry, materials, dismissal, accessibility, persistence and service behavior remain implementation/device checks.

Additional primary references: [Toggles](https://developer.apple.com/design/human-interface-guidelines/toggles), [Context menus](https://developer.apple.com/design/human-interface-guidelines/context-menus), and [SwiftUI modal presentations](https://developer.apple.com/documentation/swiftui/modal-presentations).

## Agent input presentations

A34 is keyboard-focused full-screen entry; A01 is its keyboard-dismissed state. Header More uses native New conversation / Conversations / Manage context commands. A35 anchors the attachment Menu to + (adapting to a sheet); selected-media PhotosPicker, camera and image-only Files picker are OS-owned. A36/A46 use native selection sheets/navigation or an iPad popover. A38/A44 use native review/edit sheets with one safe exit and retained parent draft. A41 invokes the actual permission prompt only after Continue; A42–A45 use a focused recording/transcript task, never an invented OS permission alert. See [Agent input](agent-input.md). New conversation and scope changes do not discard a draft; leaving a recording stops capture and offers safe discard/retention where appropriate.


## Global title and content alignment · October 2, 2026

Center detail/task navigation titles with Back and native sheet/full-screen navigation independently of action count and width. Root screens without Back, including Home, Closet, Planner, Inbox, Profile and standalone search, keep their titles at the leading content inset. Keep equal reserved space on both sides, preserve 44 pt actions, and use native single-line truncation for long/localized titles. Back remains leading and task actions trailing. Root Closet keeps its title leading, with Search/Add/More trailing. Hidden dismiss controls and decorative flex spacers do not reserve action width. Native navigation/toolbar placement owns the runtime layout and Dynamic Type adaptation.

Agent empty-state welcome heading/supporting introduction are centered; suggestion chips align below. Messages, responses, input text, list rows, form labels and ordinary content headings retain leading alignment. Apply the same contract to light/dark/accessibility variants, page-00 masters and snapshot walkthrough copies.


Centered navigation titles share one base type style: 20 pt size, 26 pt line height, medium (500) weight and the shared `--tracking-title` value. Agent uses the same title style as review/detail/task screens. Paper binds size to `--text-20`; native implementation uses one shared scalable system-font role. Root titles retain their separate leading-aligned hierarchy. Do not apply body-size 17 pt to Agent navigation or shrink long titles to fit; use native truncation/adaptation.
