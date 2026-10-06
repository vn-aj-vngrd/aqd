# V1 interaction and state coverage

Updated October 6, 2026. This is the implementation route checklist for [Paper V1](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-2-0). Read it with [V1 flow](v1-flow.md), [quality criteria](quality-criteria.md) and the [manifest](paper-manifest.json). The original L01–L85 journey is extended by L86–L163, including photo source selection and the private fit journal. A rendered phone is a static reference, not an implemented or wired prototype.

## Rules for every control

- A navigation action must resolve to a listed screen or an explicitly named system presentation. A field edits in place; a toggle/selection changes visible state; neither needs a fictional destination.
- Back restores the source, scroll, query and draft. Dirty dismissal uses L106; keeping changes returns to the editor, discarding returns without saving. Search has one Cancel instead of Back.
- Each picker receives an explicit purpose and selection mode. Returning a selection changes the parent draft only. The parent Save commits it. Cancel leaves the previous selection intact.
- Saves share L149 pending, L150 interrupted/unknown completion, L17 failed, and the relevant saved detail/receipt. Never retry an unknown write as a new operation. These are shared state layouts, not extra mandatory navigation steps.
- Menus in section 14 show complete command content in an expanded phone reference. Runtime uses native Menu, sheet or selectable List as appropriate; do not turn every menu into a compulsory full-screen navigation step.
- PhotosPicker, camera, Files import/export, permission alerts, native date controls, keyboard, text-selection menu and Apple Settings remain OS-owned. Drawings in Foundations and the surrounding AQD screens establish content/return behavior; do not recreate Apple's UI or pretend it was device-tested.

## Action-to-destination checklist

| Source / visible action | Destination or state | Return / outcome |
| --- | --- | --- |
| Global Home / Closet / Planner / Agent / Profile | L02 or L23 / L03 / L09 / L24 or L19/L80/L81 / L48 or L160 | Five equal native slots; restore each root's date/selection/scroll. Fourth-slot Agent presents full-screen and dismisses to origin. No V1 Inbox or Settings on Home. |
| Welcome Start my closet / quick tour | L61 / L62 | Immediate navigation; cancel decorative Welcome motion. |
| L61 Personalize my closet / Take the tour / Explore first | L152 / L62 / L02 | Setup can be skipped. Illustrations never create records. |
| Tour Back / Next / Finish / Skip | L62–L66; L02, or source Settings on replay | Preserve preview isolation; no repeated onboarding for each piece. |
| L152–L154 Continue / Save preferences / Skip setup | Next question / L04 / L04 | Save only explicit answers; skip leaves unknown answers unknown. See [personalization](onboarding-personalization.md). |
| L66 Add my first piece / Open Home | L04 / L02 | Do not repeat completed or skipped preference setup. |
| Today Add a piece / Search / View outfit / Record wear | L04 / L92 / L08 with selected outfit / L11 | Correct selected record/date context. |
| Today weekly wear / Closet in use | L12 / L41 with displayed period | Empty history L146; insufficient insights L147. |
| Closet Pieces / Outfits / Themes | L03 / L20 / L32 | Only these three segments; Planner is a separate root with Week default and Month L85 alternate. |
| Closet Add | L118 → L04 / L06 / L134 | Planner Add instead uses L127. |
| Closet Search field or icon | L92, then L86–L91 | Default to the originating Pieces/Outfits/Themes scope; Home defaults to Pieces. |
| Search scopes / clear / Cancel / Retry / result | L86/L87/L88 / L92 / source / L90 / L21, L08 or L34 with result ID | Retain query across scopes; Back from detail restores query/filter/scroll. Deleted result uses L117. |
| Search empty closet / no matches / filters | L93 / L89 / L121 | Add → L04. Clear query and clear filters are distinct operations. |
| Filters Category / Availability / Sort | L131 / L120 / L122, in filter mode | Filter mode includes All; capture mode requires one real category. Reset restores All and default sort. |
| Piece card / Details / Wear history / Style this / Edit piece | L21 / L94 / L12 filtered by piece / L18 pinned to piece / L132 | Respect archived/unavailable state; historical snapshots remain readable. |
| Piece More / Availability / Archive / Delete | L119 / L120 / L138 / L97 | Archive success → source + Undo; Delete success → Closet. Recompute exact affected counts. |
| Archived pieces / Restore | L96 / restored L21 | Restore updates the same piece ID. Empty archive uses the shared empty-list layout without a fake record. |
| L04 Add photo / selected-photo Change | L159 native sheet / L78 | Entire Add photo row opens source options; symbols are decorative. No separate camera action in L04. Sheet dismissal retains draft and restores focus to Add photo. |
| L159 Choose from Photos / Take photo / Close | System PhotosPicker / native camera / L04 | Dismiss source sheet before picker/camera; Close/outside tap/swipe leaves fields/media unchanged. Picker/camera cancel retains draft; preparation preserves accepted media; import error L107; camera denial L108. Native sheet on iPhone, adaptive popover on wide layouts; focus remains within presented controls. |
| Photo Edit / Fit / Portrait / Rotate / Reset / Zoom / Use | L77; in-place edit recipe | Use returns to L75/L76; Cancel retains earlier media. Remove returns to L04 or L79 and disables Save. |
| Capture Category / More details | L131 / L94 → L95 | Details return to capture draft. Plain labels; no Required/Optional suffixes. |
| Capture Save / first-save Build outfit / Open closet | L149 → L05 / L43 or L44 / L03 | Only committed valid photo/name/category advances. L17 keeps the draft. |
| First outfit Add missing category / Build manually / Suggest | L04 with category hint / L06 / L18 | Return to same starter piece; never replay onboarding. |
| Outfit Selected pieces / Edit pieces / pin / replace | L98 / L98 / in-place selected pin / L99 | Selection remains across filters. Empty selection disables the committing action. |
| Outfit Themes / Save / Suggest variation | L126 / L149 → L08 or L27 / L18 with current pieces | Stale references use L116; no implicit save. |
| Outfit detail Pieces / Plan / Wear / Edit / More | L98 read-only / L10 prefilled / L11 / L133 / L124 | Read-only piece list hides selection/commit controls. |
| Outfit Favorite / Delete | Selected heart state / L140 | Favorite updates local state with rollback on failure; deletion retains wear snapshots. |
| Theme Create / card / Add outfits / Edit / More / Delete | L134 / L34 / L135 / L35 / L123 / L139 | Empty collection L145; deleting theme retains outfits. Multi-select L135 commits membership only on parent Save. |
| Planner Week / Month / previous-next / date | L09 / L85 / in-place period / L82 or date agenda | Selected local date persists. Calendar movement never records wear. |
| Planner toolbar + / selected-day Add / empty-date Plan an outfit; plan one day / routine / event-trip | L127 / L83 or L10 / L36 / L155 | Carry selected date and timezone. Populated Week L09/L33 has no duplicate footer creation link; empty-date primary action remains. |
| Plan Date / timezone / outfit / leave unassigned | Native DatePicker / L151 / L157 / unassigned draft state | Date stays a calendar date in the chosen zone. Single-outfit chooser differs from theme multi-select. |
| Agenda entry / edit / record wear / remove | L128 / L10 populated / L11 / L156 | Removing plan never removes actual wear. |
| Routine repeat days / edit scope / review dates | L37 / L129 / L40 | Scope: one, future, whole. Completed past entries remain intact. |
| Trip Edit / outfit plan / packing / review | L155 populated / L40 / L39 / L40 | Destination/activities edit in place; no required live weather. |
| Packing check / review gaps | Checked row state / L40 filtered to gaps | Deduplicate by piece ID; retain checks for surviving items. |
| Review all dates / assigned row / conflict choices / Save | L40 expanded date list / L157 / L42 / L149 → L84 | One atomic plan save; keep-both or replace is explicit. |
| Wear date / pieces / timezone / Record | Native DatePicker / L98 / L151 / L149 → L130 | Duplicate date+piece set uses L142. Retry cannot double-count. |
| History Calendar / row / Correct / Undo / Record | L137 / L130 / L136 / L141 / L11 | Calendar dots mean recorded wear; future plans are excluded. |
| Wear record View recorded pieces | L98 read-only snapshot variant | Show recorded names/categories; deleted media is a neutral category fallback, never another garment. |
| Insights period / piece / source history | Native month selection / L21 / L12 for same period | Empty denominator uses L147. Estimates excluded from period utilization. |
| Agent starter chips | Editable composer draft; Start with a piece → existing local context picker | Tonight’s look / Plan my week and other suggestions fill a retained editable draft; never auto-send. Opaque 44-point capsule targets, no disclosure chevrons or AI badges. |
| Agent typed Send | L29 → L30 → L31 or L25 | Empty text disabled; capability checked first. No external-provider fallback in V1. |
| Agent More / new / conversations / context | L125 / fresh L24 / L26 / L28 | Keep current conversation and recover drafts. |
| Agent + / context mode / selected pieces | L98 in attachment mode / L74 / L98 | Local owned context only; unsupported image intake has no inert control. |
| Agent Stop / retry / failed request / details | L100 / L29 / L101 or L105 / L102 | Preserve original/partial text; no fabricated save receipt. |
| Agent Copy / response More | Brief Copied check / L102 plus native Copy action | Clipboard result only; remote rating/sending stays V2. |
| Agent review outfit / theme / changes / keep current | L07 / L46 / L47 / return unchanged | Save/apply → real receipt/detail. Stale draft L116, failure L17. |
| Conversations row / header Compose / row menu Manage / Delete selected | Existing conversation / fresh L24 / L158 / L143 | Compose is labelled New conversation for accessibility. Row context menu and accessibility actions expose Manage conversations and Delete; Delete opens L143. No footer action or repeated privacy note. Loading uses search/list skeleton pattern; empty L103; read failure L104. |
| Voice microphone / Continue / Finish / transcript / retry | L69 → system permission → L70 → L71 → L72; L73 unavailable | Transcript goes to composer, never sends automatically. Cancel/discard retains earlier typed draft. |
| Unsupported Agent About / Open Closet / Check | L52 / L03 / reevaluate L19/L80/L81/L24 | Keep Agent tab visible. Off-state help points to Apple Settings; preparing never shows fabricated percentage. |
| Profile Edit / Settings / More | L49 / L13 / native anchored Style and Wear insights menu | Name/avatar optional. More uses shared T6P menu reference, not loose footer links; dismissal restores focus/scroll. Style → L45, Wear insights → L41 with recorded-data period; source history → L12. |
| Profile Add fit / memory | L161 / L163 | Empty journal L160 has no fixtures or invented counts; populated L48/L57 use real saved memories. Back restores journal position. |
| Fit Date / Add or Change photo / Link outfit / Private note | Native date controls with explicit timezone / shared L159 source-sheet recipe / existing owner-only outfit chooser in fit-link mode / retained editor | Return to the originating L161/L162 draft, not piece capture. Date-only/note-only cannot save; outfit-only is valid. Cancellation/failure retains date, note, link and accepted media. Notes ≤500 user-perceived characters; over-limit input retained. |
| Fit Save / Back | Atomic local commit → Profile with new memory focused; edit → refreshed L163 / source with dirty-dismissal protection | Valid date plus photo OR existing outfit; no inferred wear, plan changes, upload or publication. Failure/retry preserves draft and one operation identity. |
| Memory Edit fit / Link outfit / More / Delete memory | L162 in edit mode / same editor focused on outfit / native Delete memory menu / scoped native confirmation | Confirm removes only this memory and unreferenced AQD-owned media, not original Photos, outfits, wear or other memories. Cancel restores detail/focus; failure retains memory. See [journal contract](profile-fit-journal.md). |
| Style goals / occasions / direction / comfort | L152–L154 in edit mode; L45 summary | Edit mode saves and returns to Style rather than restarting capture. |
| Settings Appearance / assistance / help / tour | L50 / L52 / L51 / L62 | System/Light/Dark selection persists; tour replay returns to Settings. |
| Help permissions / local data | Apple Settings / L13 | Restore focus on return. No fake in-app OS Settings page. |
| Export Create / Save to Files / retry / cancel | L109 → L110 → native Files export; L111 failure | A ready archive is not proof it was saved externally. Cancel keeps closet and returns to L14. |
| Restore choose file / validate / confirm | Native Files import → L15; L112 invalid, L113 newer | No replacement before validation and explicit confirmation. Cancel leaves current closet intact. |
| Restore commit / completion / failure | L114 → L115 or L148; unreadable recovery L22 | Commit is transactional; recovery restores original store or routes to L22 if unreadable. |
| Erase Export first / type ERASE / confirm | L14 / inline validation / L149 → L02 | Erases local profile, conversations and wardrobe; separately exported archives remain. Failure L17 retains original store. |

## State reuse and boundaries

Each collection and picker has an empty, populated, selected, filtered-no-match, loading and read-failure variant. Reuse L93/L103/L144–L147 for empty composition, L89 for query/filter emptiness, L90 for loading and L91/L104 for failed reads. Replace the scope noun and recovery action; never expose irrelevant scopes in a single-purpose picker. Search is local: airplane mode is not an error and V1 has no remote pagination or community search requirement. Skeletons appear only during a real asynchronous load.

Choice rows, checkmarks, disabled actions, input focus/validation and native keyboard adaptation are shared component states. Screens show representative selections, not default consent. Native Photos/Files/DatePicker cancellation and permission presentations are explicitly delegated to iOS, with AQD recovery screens provided around them. No extra custom screen is required for Copy, Favorite, packing checks, text editing, reset crop, or a successful appearance selection.

L152–L154 illustrate answered preferences. First use starts with no selections; Continue works without an answer. Multi-selection and deselection use the same checkmark component. Save has pending/error protection. Source metadata, IDs, effects and real counts must come from storage, never fixture labels.

## Acceptance gate for implementation

For every row above, open from each listed source, complete once, cancel once, return with Back, then test the applicable empty/error path. Check draft retention, exact record identity, duplicate prevention, keyboard/focus return, largest text, dark appearance and Reduce Motion. Every newly introduced control must update this ledger and the manifest in the same change. Static Paper inspection does not establish native animation, persistence, OS presentation or accessibility correctness.
