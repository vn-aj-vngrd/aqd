# Screen map

Phase scope: shared native/visual rules apply to both phases. Five-destination base navigation applies to both phases. Full-app E/W/P/S/A/I/U routes, online identity and connected states are V2 references. Complete private themes/planning/Agent are retained in V1. V1 uses only its [dedicated local flow](v1-flow.md) and [complete local release](../product/v1-release.md); [V2 requirements](v2-requirements.md) own connected and extension coverage.

The retained 201 V2 canonical artboard contracts cover entry, Home, closet, planning, Agent, Inbox, and account management. Paper is the sole visual source; links open the containing page. Maintain this route/state map alongside product decisions. Shared variants below apply to every affected screen even when they do not require a separate artboard. [Native presentations](native-presentations.md) selects Menu, adaptive popover/sheet, confirmation and full-screen task behavior; phone artboards are content references, not custom modal chrome.

Every screen inherits [Global motion](motion.md); [Motion coverage](motion-coverage.md) maps navigation and local state recipes for every ID.

The separate [V1 screen map](v1-flow.md) owns local L01–L81; these E/W/P/S/A/I/U routes belong to the complete V2 design. V2 core scope is mapped in [V2 coverage](v2-coverage.md). E14, U07, A19–A21 and A27–A28 are V2 references; their entry controls are hidden in the connected core until their V2 extension is selected. The complete inventory includes future references, not only launch screens.

## Shared states

- Collections: initial loading, loaded, empty, filtered empty, pagination, offline cached content, retryable error and revoked access. X01–X04 illustrate common patterns.
- Mutations: idle, valid/invalid, saving with duplicate action protection, success receipt, recoverable failure, unknown outcome and reconciliation. Preserve drafts; retry only when safe. X05–X06 and A09 illustrate receipt, error and unknown outcome.
- Forms: keyboard focus, inline validation, disabled primary action, dirty dismissal, cancel, and restored draft. Native sheets and keyboards adapt to safe areas and accessibility text.
- Account gates: private use, signed out, authenticating, expired session and signed in; return to the interrupted intent after authentication.
- Safety: blocked/removed/private content replaces stale previews; report receipt reveals no moderation internals.
- Appearance: light/dark, increased text, Reduce Motion, Reduce Transparency, Increase Contrast and VoiceOver are component requirements. Static Paper variants demonstrate composition, not runtime proof.

## Entry

| ID | Screen | Next screens | Contract and states |
| --- | --- | --- | --- |
| E01 | [Splash](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | E02, W01, S01 | Native launch surface. No imposed delay. Returning users restore authorized destination; fresh install opens E02, unfinished private capture restores draft. Expired auth gates only connected action. |
| E02 | [Welcome](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | E06, E03 | Primary path goes straight to first capture; no preferences, permissions or identity gate. Returning users choose sign-in. No retail storefront imagery or unsupported AI/sync promise. |
| E03 | [Sign in](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | E10, E08, E07, W01, U13 | Apple/email are service-gated working defaults. Back restores Welcome or the originating task with local records retained. Provider cancellation returns here without losing local data. Existing accounts bypass public-profile setup. |
| E04 | [Check your email](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | E08, E07, E10, E11 | Show actual submitted address and real server resend deadline. Link verification has progress and prevents double handling; accept link only for current auth transaction. Back returns to the preceding auth step and preserves local data and return intent; Back at the auth root restores Welcome or the originating screen. |
| E05 | [Style preferences](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | W01, W20 | Off the critical path: offered after first save or from Closet. Do not preselect a personality. Multiple choices allowed; skipping persists. No AI readiness promise. |
| E06 | [Your first piece](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | W06, W07, W04, E12 | Choose photo opens system picker directly; new-piece Save needs an accepted photo, name and category. Manual classification remains available. Camera belongs to capture choices. Selected photo reaches W27 review. First successful atomic save reaches E12; cancellation returns here or closet with draft retained. |
| E07 | [Public profile](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | U01, W01, E08 | Only after authentication and only if a social action needs a new profile. Validate username on blur/server submit; announce available/checking/taken/error. Never show Available before validation. Skip returns to private mode; social intent remains pending. |
| E08 | [Connect your closet](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | W01, E07, E03, E13 | Only when local records exist and ownership is unresolved. Show actual destination identity and exact local counts from source. Atomic association with stable IDs; failure leaves local data unchanged. V2 requires backup/sync; actual provider approval and service checks remain release gates. Existing-account collisions route E13. |
| E09 | [Camera access](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | W06, W07, E06 | Recovery shown only after camera denial, never before the initial system prompt. Photos picker needs no broad library permission. Return from Settings rechecks permission; cancellation retains draft. |
| E10 | [Continue with email](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | E04, E03, U13 | Email keyboard/content type, no autocapitalization; trim and validate email before send. Empty/invalid disables primary with inline guidance. Sending keeps button label/width, prevents duplicate submit; network/rate-limit errors preserve input. No email enumeration. |
| E11 | [Sign-in link expired](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | E04, E10, W01 | Expired/consumed link recovery; distinguish offline verification with retry from unusable links. Display actual email only for current local auth context. Preserve originating task and local records. |
| E12 | [First piece saved](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | W28, W29, W01, E05 | Build my first outfit carries the saved pin to category guidance or readiness; Open my closet stays secondary. Shown only after a real persisted record exists. Replace photo/name/category with saved item data; never invent first-save success. No confetti or forced signup. Dismissed first-use guidance is not repeated. |
| E13 | [Connect closet](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | W01, E03, E08 | Safe conflict fallback while merge policy is unresolved. Do not silently merge, overwrite, duplicate or reassign ownership. Separate local/account scopes; return to originating task only when permitted. |
| E14 | [How you found AQD](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | W01 | V2 reference; excluded from V2 navigation. Optional single-choice acquisition question after first save, never before first value. Persist answer or skip once; do not repeat. No free-text requirement. Continue enables after selection; selected radio has visible inner dot plus label and accessible selected state. Analytics event onboarding_acquisition_answered has source enum friend_family, instagram, tiktok, app_store, search_engine, other, unknown and schema_version 1. No email, username or wardrobe data. Respect analytics preference; pending approved analytics service. Skip stores only dismissal, no invented attribution. |

## Home

| ID | Screen | Next screens | Contract and states |
| --- | --- | --- | --- |
| S01 | [Home](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | S15, S02, S03, S05, S06, S19, S22 | All selected in Today / All / Following. Chronological public snapshots. Preserve scroll position after detail; pending reactions roll back on failure. |
| S02 | [Home](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | S05, S12, S35, S22 | Only followed creators. Same post component and pagination states as All. |
| S03 | [Search](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | S04, S06, S01 | Native toolbar search expands on focus. Community scope; no private inventory in results. |
| S04 | [Search results](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | S05, S06, X03 | Clear query, cancel, no results, query error and pagination preserve search state. |
| S05 | [A light layer](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | S06, A03, S08, S10, S19, S20, S22, S25 | Bookmark does not transfer ownership. Inspiration selects owned equivalents and shows missing matches. |
| S06 | [Camille Reyes](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | S07, S13, S14, I04, S10 | Compact visitor profile includes only explicit public collections. Follow count changes after acknowledgement. |
| S07 | [Camille’s closet](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | S05, S06 | Counts and search only include accessible public pieces; owner notes/history/plans are excluded. |
| S13 | [Camille · Pieces](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | S06, S14, S07 | Populated Pieces selection under the compact shared header; published garments only. Preserve tab selection and collection scroll position. |
| S14 | [Camille · Themes](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | S06, S13, S07 | Published theme cover collages and counts use accessible memberships only. Selecting a theme opens its scoped public collection; unavailable members never expose private data. |
| S15 | [Home · Today](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | S01, S02, W10, W15, P01, P09, W06, W13 | Private dashboard over saved wardrobe/plans and recorded-week summary; scroll continues in S18. First-use Home default; restore last mode thereafter. Record wear requires review and a receipt. Search is owner-scoped. |
| S16 | [Today · First piece](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | W06, W07, S01 | Empty local closet: manual first-piece entry, optional community browsing. No fabricated plan/history totals or signup prerequisite. |
| S17 | [Today · No planned look](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | W02, W13, W06, P01, P10 | Existing saved outfits without a current planned look. Choose a saved outfit or build manually; no implicit AI recommendation or wear record. |
| S48 | [Today · Ready to style](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | W17, W13, W28 | Available categories but no saved outfits: Suggest or Build manually. Missing-category variant links W28 using the same hierarchy. Derived from actual records; no signup or quota. |
| S18 | [Today · Wardrobe activity](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | S15, P10, W13, P01, W06 | Scrolled continuation of Today, not another destination. Recorded-week summary, one eligible Wear again piece, upcoming plans and quick actions. |
| S19 | [Post · Tags visible](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | S20, S21, S22, S25 | Selected heart/bookmark; creator-authored numbered image tags. Tag list is the accessible alternative; Back restores source. |
| S20 | [Pieces in this look](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | S19, S21 | Native push to the numbered accessible tag list. Only accessible, explicitly published creator pieces; revoked targets use X04. |
| S21 | [Blue wool coat](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | S06, S07, S19 | Creator public piece snapshot, never private item detail. Save is a reference, not ownership; revalidate access. |
| S22 | [Comments](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | S23, S24, S10 | Oldest-first comments, earlier-page loader above. Keyboard-aware draft, pending/sent reconciliation, own Delete confirmation or other Report/Block. |
| S23 | [Comments · Empty](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | S22 | No comments yet; focus composer without an automatic keyboard on entry. Blank Send is disabled. |
| S24 | [Comments · Send failed](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | S22 | Failed comment retains editable draft; retry with the same operation identity. Never duplicate the comment or clear a newer draft. |
| S25 | [Likes](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | S06, S19 | Accessible reacting profiles. Zero/loading/pagination/error variants use the social master; preserve originating post. |
| S26 | [Liked posts](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | S05, U05 | Private liked-post collection, distinct from public per-post Likes. Unliking removes the reference; shared empty/retry/unavailable states. |
| S27 | [Tag pieces](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | S28, S09 | Author-only tag placement, move/remove, maximum five per image. Done returns to publication review; cancel retains prior placements. |
| S28 | [Choose published piece](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | S27, U04 | Choose only an owned published piece; private publication is a separate explicit flow and retains the post draft. |
| S29 | [Saved inspiration · Empty](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | S01, S08, U05 | Empty private Saved inspiration; Explore Home opens All. No placeholder saved posts. |
| S30 | [Share from your closet](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | S33, S09, S34, S32 | Share chooser: Piece, Outfit, Theme. Choose an owned source, then review exact public fields and pieces. No photo-only option. |
| S31 | [Theme post](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | S05, S20, S22, S25 | Public Theme example: selected outfits and six disclosed pieces, compact collection row. Open the selected public outfits; hidden members never appear. |
| S32 | [Add a piece to continue](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | S33, W06 | No linked piece: Publish disabled with explanation. Choose or add a piece; return with photo, caption and draft preserved. |
| S33 | [Publish piece](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | S02, S35, S32 | Review Piece publication, one owned piece and its selected public photo/fields. Publish only after final ownership and media checks; pending/error retain draft. |
| S34 | [Publish theme](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | S31, S32 | Review Theme publication: selected outfits and explicitly disclosed piece snapshots. Empty theme cannot publish; future additions remain private. |
| S35 | [Burgundy coat](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | S02, S07 | Noah public Burgundy coat snapshot. Return to Following restores scroll. Save references the public piece and does not import ownership. |
| S36 | [Search · People](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | S06 | People selected: portrait rows, handle and relevant public context. Preserve query and scroll. |
| S37 | [Search · Pieces](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | S21, S35 | Pieces selected: two-column product thumbnails, name and creator. Revalidate public snapshot access. |
| S38 | [Search · Outfits](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | S05 | Outfits selected: cover grid and creator attribution. No private inventory metadata. |
| S39 | [Search · Themes](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | S31 | Themes selected: collection collages, creator and accessible outfit count. |
| S40 | [Search · Loading](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | S04, S37, S41 | Initial query loading: neutral result geometry, native progress, latest query wins. Shared per-tab skeleton shapes. |
| S41 | [Search · Failed](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | S04 | Initial query failure retains query/tab/filters; Retry. Never report failure as empty results. |
| S42 | [Search · Offline](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | S37 | Offline cache explicitly labelled; only cached public results. No cache uses the shared reconnect state. |
| S43 | [Search · Loading more](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | S37 | Next result page loads below existing tiles. Inline Retry on failure; confirmed end replaces progress. |
| S44 | [Home · Multiple posts](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | S05, S35, S31, S45 | Long-content reference: Outfit, Piece and Theme posts in one feed. Shared action row and required-piece links. |
| S45 | [Home · Loading more](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | S44, S46, S47 | Viewport loading more: loaded posts remain above progress, bottom navigation stays clear; append without moving reader. |
| S46 | [Home · Load more failed](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | S45 | Following pagination failure retains loaded posts and cursor; inline Retry does not restart feed. |
| S47 | [Home · End reached](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | S44 | Confirmed end-of-feed state; no perpetual spinner. Refresh/new posts are user-triggered. |
| S08 | [Saved inspiration](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | S05, A03, X04 | Profile Settings or Closet More opens the same private collection. Back restores origin/tab/filter/scroll; removing bookmarks reconciles both entries. Revoked content displays unavailable; existing owned inspired outfits survive. |
| S09 | [Publish look](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | U04, X05 | Exact snapshot review. Repeated submission is idempotent. Saving an outfit never publishes it. |
| S10 | [Report or block](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | S11, U08, S05 | Report selection is reviewed before submission; block confirmation shows exact person. |
| S11 | [Report post](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | X05, S01 | Report receipt, submission failure, retained explanation; service moderation policy required. |
| S12 | [Following](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | S03, S01 | Empty Following differs from empty All, loading, and disconnected service. |
| X01 | [Home](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | S01, X02 | Initial skeleton only; no repeated shimmer under Reduce Motion. Pagination loading retains content. |
| X02 | [Home · Offline](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | S15, S01 | Keep Today reachable for local wardrobe/plans. Separate network failure from service unavailable. Existing feed may stay cached with honest stale state. |
| X03 | [No results](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | S03, W10 | Shared no-results component with owner/community scope provided by feature. |
| X04 | [Content unavailable](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | S01, S08, I02 | Use across bookmarks, chat references, public profiles and search. Revalidate access before opening. |
| X07 | [Search active](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | S04, S03 | Bottom-docked static keyboard layout reference, separate from results. Native Search return key, keyboard-safe scroll viewport and retained focus/query. OS owns actual keyboard geometry/appearance; Paper keycaps are not an imported Apple component. |

## Closet

| ID | Screen | Next screens | Contract and states |
| --- | --- | --- | --- |
| W01 | [Closet](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | W05, W10, W08, W02, W03, P01, W30 | Native Search, Add and More toolbar controls; two-column photography grid. Search scopes to the current owner's closet. |
| W02 | [Closet](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | W15, W13, W17 | Owned favorites are separate from community bookmarks. |
| W03 | [Closet](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | W18, W19 | Themes are independent, reusable, and may be empty; outfits may join multiple themes. |
| W04 | [Closet](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | W06, W07 | Empty inventory. Outfit builder explains that at least one active piece is needed. |
| W05 | [Add to closet](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | W06, W13, W19, W17 | Native bottom sheet from Add over dimmed Closet; content-height/large accessibility detents, native grabber and safe dismissal. Return to the originating destination after cancellation. |
| W06 | [Add a photo](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | E09, W27, W07 | Selected photo reaches W27; manual classification reaches W07 with the same photo requirement. Native picker/camera with loading, cancel, denied permission, large-image and import-error handling. |
| W07 | [New piece](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | W09, W08, X05, X06, E12, W28, W29 | Required validation; whitespace/length limits; saving and recoverable save failure. First-ever successful save reaches E12; later saves return to the item or originating task. |
| W08 | [Cotton shirt](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | W13, W09, P09, W12 | Availability, archive, wear, edit, and linked-publication actions. Missing photo uses category placeholder. |
| W09 | [Piece details](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | W08, W21 | Optional fields can remain unknown. Additional sheet owns condition, age estimate, prior count and notes; never infer purchases. |
| W10 | [Search closet](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | W08, W11, X03 | Native active search; query/filter scope, clear-all, no results, archive mode. Filters retain chooser selection. |
| W22 | [Search closet · Outfits](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | W13, W15 | Owned Outfits search tab. No community results; preserve owner query/filter/scroll state. |
| W23 | [Search closet · Themes](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | W03 | Owned Themes search tab. Collage, name and membership count; includes permitted private empty themes. |
| W24 | [Search closet · No matches](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | W10, W06 | Owner no-match state retains query, offers clear filters and manual add. Do not confuse with read failure. |
| W25 | [Search closet · Loading](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | W10, W26 | Owner query loading uses neutral placeholders and progress; local search does not require community connectivity. |
| W26 | [Search closet · Failed](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | W10 | Owner data-read failure preserves query/filters; Retry without account or data loss. |
| W11 | [Archived pieces](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | W08, W12 | Archive differs from availability/laundry. Existing references disclose archived state. |
| W12 | [Delete piece](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | W01, W08 | Destructive confirmation uses native destructive role. Publish/access cleanup and retry must be truthful. |
| W13 | [Build outfit](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | W14, W16, W15 | Manual composition is complete without AI. Retain name, selected items and pinned pieces across filters. |
| W14 | [Choose pieces](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | W13, W16 | Unavailable or removed selections remain visible with fix/remove; selection is not a save. |
| W15 | [An easy afternoon](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | P03, P09, S09, W13 | Favorite, delete, unavailable piece, and linked-plan update variants. Save, wear, and publish remain distinct. |
| W16 | [Replace a piece](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | W13 | Replacement suggestions are owned active candidates. Nonmatching categories appear only if the user changes scope. |
| W17 | [Suggest an outfit](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | A08, A03, W13 | Focused assistance uses the same proposal capability as Agent; unknown weather stays unknown. |
| W18 | [Weekend](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | W15, W19 | Empty theme offers Add outfits; remove membership never deletes the outfit. |
| W19 | [Edit theme](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | W18, W03 | Unique case-insensitive name; empty membership valid; deletion preserves member outfits. |
| W20 | [Style preferences](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | W01, E05 | Personal styling preferences live in Closet. Unknown attributes are not silently inferred. |
| W21 | [Additional details](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | W09 | Numeric limits, optional unknowns, length errors, keyboard navigation and draft preservation. |
| W27 | [Review piece photo](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | W06, W09, W08, E12, W28, W29, X06 | Portrait 3:4 presentation with full-image Fit by default, Edit photo → W31 and Change photo options; required name/category; More details optional. Classifier proposals editable/optional. Change photo and failure retain the draft; manual uses W07. Return to originating capture task after confirmed save. |
| W28 | [First outfit · Missing pieces](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | W06, W07, W27, W29, W13 | Show requested-form category gaps around pinned saved piece. Capture each through the same flow; re-evaluate on save/cancel. Partial manual composition stays available. No fixed item quota. |
| W29 | [First outfit · Ready](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | W17, W13, W28 | Name actual available pieces; Suggest preserves explicit first-piece pin. Manual remains available; archive/unavailability can return to missing guidance. Readiness does not imply runtime support. |
| W30 | [Closet options](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | S08, S29, E03, W01, W02, W03, W04 | Native iOS Menu popup anchored to More across Closet tabs and empty state; OS-owned material/shape, trailing symbol, outside-tap dismissal and trigger focus restoration. Saved inspiration pushes the existing private collection; guest sign-in preserves intent. Dismiss leaves Closet unchanged; Back restores originating tab/filter/scroll. No community Likes shortcut; owned outfit Favorites stay separate. |
| X06 | [Couldn’t save](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | W07, W13 | Reusable form recovery. Dirty-dismiss confirmation offers keep editing/discard; duplicate retries are safe. |

## Planning

| ID | Screen | Next screens | Contract and states |
| --- | --- | --- | --- |
| P01 | [Planner](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | P02, P03, P04, P06 | Dedicated third root in V1/V2, not a Closet segment; Week default, Month alternate. Home/outfit Plan links carry date context and Back restores origin/selection. Plans are intentions; date passage never records wear. |
| P02 | [October 2026](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | P01, P03 | Month and agenda preserve selected date. Multiple entries per calendar date; explicit plan timezone. |
| P03 | [Plan a look](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | P01, W02 | Date-only semantics. Editing outfit revisions flags future entries; assigning never marks worn. |
| P04 | [New plan](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | P05, P08, A08 | Two weeks or up to three calendar months. Resolved dates, gaps and conflicts are reviewed before save. Trip creation uses destination/activities instead of routine recurrence; V2 section 08 shows the same form variant. |
| P05 | [Office routine](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | P08, P12 | Actual calendar months; inclusive range; routine edits do not overwrite historical entries. |
| P06 | [Seoul, slowly](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | P07, P08 | Trip is event + plan. Dates remain in plan timezone. No weather claim beyond verified forecast coverage. |
| P07 | [Packing list](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | P06, P08 | Deduplicate by item ID; preserve checks for retained pieces after outfit replacements; no invented quantities. |
| P08 | [Review plan](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | P01, P12, X05 | Review whole changeset. Bulk save all-or-nothing; generation or save failure preserves draft and calendar. |
| P09 | [Record wear](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | P10, X05 | Duplicate item-set/day check; backdate/correct/undo revalidates and updates linked plan entries once. |
| P10 | [Wear history](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | P09, P11 | Historical snapshots remain after outfit edits/archive. Undo restores linked entries to planned. |
| P11 | [Wear insights](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | P10 | Trusted calculations and stated denominator/time window. No-data variant says Not enough recorded history. |
| P12 | [Resolve a conflict](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | P08 | Also use for unavailable/laundry pieces and stale outfit revisions, with exact conflict and recovery. |

## Agent

| ID | Screen | Next screens | Contract and states |
| --- | --- | --- | --- |
| A01 | [Agent](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | A11, A24, A06, A07 | Keyboard-dismissed welcome; A34 is default focused entry. Back restores prior tab; runtime label reflects actual capability. |
| A02 | [Agent](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | A03, A06, A18 | Streaming text is not a saved action; source bounds and missing facts are visible. |
| A03 | [Review outfit](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | A22, A23, W13 | Approval binds proposal and source revisions; stale source triggers refreshed review. |
| A04 | [Outfit saved](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | W15, P03, A02 | Receipt only after trusted execution succeeds. Failed/unknown outcomes use A09, never this success screen. |
| A05 | [Conversations](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | A02, A01 | Rename/archive/delete conversation menus; empty and load-failure variants. |
| A06 | [Agent context](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | A01 | Scope and subset are truthful. Sensitive context expansion requires explicit feature consent. |
| A07 | [Assistance unavailable](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | W13, A01 | Unsupported hardware, disabled model, downloading and timeout have precise messages; never call rules AI. |
| A08 | [Preparing a draft](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | P08, A03, A09 | Cancellation stops unapproved work; does not claim rollback after an approved action commits. |
| A09 | [Couldn’t save yet](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | A04, A03, W01 | Unknown execution is checked before retry; same operation ID prevents duplicates. |
| A10 | [Review message](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | I02, A02 | Explicit recipient/content approval. Editing either invalidates previous approval. |

| A11 | [Waiting for response](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | A12, A14, A15, A16 | Waiting before first token; progress and elapsed time measured; Stop always available. No fake answer skeleton. |
| A12 | [Streaming response](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | A13, A14, A15 | Append stable Markdown blocks without shifting reading position. Stop replaces Send; next-message draft retained. Native status indicator respects Reduce Motion; no typewriter effect. |
| A13 | [Response complete](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | A18 | Shared Markdown headings, emphasis and lists; elapsed duration frozen on completion; Copy, Helpful, Not helpful, Retry and details bind exact response version. No save claim. |
| A14 | [Response stopped](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | A11, A18 | Stop confirmed after cancellation acknowledgement. Preserve partial text labelled incomplete. A retry creates a new response version, no duplicate writes. |
| A15 | [Response interrupted](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | A11 | Runtime/stream failure preserves partial text and input. Resume only with supported cursor; otherwise explicit new attempt. Copy includes incomplete marker. |
| A16 | [Taking longer](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | A12, A14, W13 | Slow status is not a fake ETA or progress percentage. Hard timeout ends run and preserves input; manual path does not silently discard work. |
| A17 | [Live task progress](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | A02, A14, A15 | Only event-backed stages and known denominator counts; work counts are not token-based completion estimates. No chain-of-thought disclosure. |
| A18 | [Response details](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | A13 | Localised absolute timestamp and measured monotonic duration. Runtime label from actual provider, never inferred. No raw prompts, secrets, hidden reasoning or model confidence. |
| A19 | [Response feedback](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | A20, A21, A13 | V2 reference; excluded from V2 navigation. Optional reasons/comment, default response sharing off, review exact included content. Thumbs up also supports optional detail; no automatic chat-body upload. Submission locks against double taps. |
| A20 | [Feedback received](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | A13, A19 | V2 reference; excluded from V2 navigation. Show received only after acknowledgement. Associate rating with response ID/version/run ID. Update same feedback record rather than duplicate. |
| A21 | [Feedback not sent](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | A19, A20, A13 | V2 reference; excluded from V2 navigation. Offline/failed submission preserves draft. No automatic later upload without clearly disclosed consent. Idempotent retry; no false thank-you state. |
| A22 | [Saving approved draft](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | A04, A09 | Execution distinct from generation. Disable duplicate approval; retain operation ID. Unknown outcome goes A09 for reconciliation. Stop is not rollback. |
| A23 | [Draft needs review](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | A03, W13 | Stale IDs/source revision invalidate prior approval; refresh creates new review version. Never auto-apply refreshed content. |
| A24 | [Loading conversations](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | A05, A25, A26 | Skeleton only for existing content fetch; no fabricated titles. Retain cached conversations during refresh; announce loading once. |
| A25 | [No conversations](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | A01 | Empty history distinguished from load failure. Starting a new chat preserves prior drafts and does not imply cloud sync. |
| A26 | [Conversation load failed](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | A24, A01 | Show cached data if available; no empty-state masquerade. Deleted/revoked conversation gets explicit unavailable state. |
| A27 | [Copied and rated](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | A18 | V2 reference; excluded from V2 navigation. Copy toast only after clipboard success. Selected helpful trait visible. Pending feedback is distinct from sent; copy failure has retry announcement. |
| A28 | [Alternate response](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | A13, A18, A19 | V2 reference; excluded from V2 navigation. Retry creates sibling version; original preserved. Version navigation has 44 pt targets and disabled edge states. Approvals never transfer between versions. |
| A29 | [Message not sent](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | A11, A01 | Distinguish send failure from stream failure. Stable client message ID prevents duplicate send; original draft remains editable. |
| A30 | [Clarification needed](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | A11 | Ask for missing target/date before tools can mutate. Scope refusal, missing context and no matching pieces use truthful manual alternatives, not fabricated recommendations. |

| A34 | [Agent · Keyboard focused](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | A35, A36, A41, A46, A11 | Default new-chat focus once; multiline Return, native keyboard inset. A01 is keyboard-dismissed welcome. |
| A35 | [Add to your message](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | A38, A36, A53, A40 | Native attachment menu → selected Photos, Camera, image Files or Closet; cancel retains draft. |
| A36 | [Choose closet pieces](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | A37, A47 | Private Pieces / Outfits / Themes, search and retained multiselection. Loading/error/cache/revoked variants inherit shared collection states. |
| A37 | [Agent · Selected attachments](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | A11, A35, A36, A38 | Ready/removable context rail, explicit pin, typed owned revisions; Send is enabled for valid supported input. |
| A38 | [Review attached photo](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | A37, A39, A40, A54, W27 | Selected-image review separates Attach from Add piece; no silent persistence or publication. |
| A39 | [Preparing attachment](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | A37, A40 | Per-attachment preparation with disabled Send and Remove; other selections remain readable. |
| A40 | [Attachment needs attention](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | A39, A38, A37 | Actual unreadable/invalid/oversized/lost-access reason; Retry only when supported, Replace/Remove otherwise. |
| A41 | [Dictation permission](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | A42, A45, A34 | Explanation before native permission request; explicit microphone intent, no capture on autofocus. |
| A42 | [Listening](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | A43, A34 | Measured recording duration/level; Finish or Discard, interrupt stops microphone, no automatic send. |
| A43 | [Transcribing](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | A44, A45, A34 | Transcription distinct from generation, Cancel preserves typed draft; no undisclosed cloud fallback. |
| A44 | [Review voice message](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | A37, A34, A42 | Editable native transcript; Use transcript merges into retained draft, then explicit Send. |
| A45 | [Voice unavailable](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | A41, A42, A43, A34 | Denied mic, unavailable speech, no speech and transcription failure use specific Settings/re-record/retry/typing recovery. |
| A46 | [Context mode](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | A01, A34, A36, A06, A55 | My closet / Selected pieces / Without closet, truthful source bounds; running context remains immutable. |
| A47 | [Closet · No matching pieces](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | A36, W07, A55 | No matches differs from empty/error; retain selected records and offer Clear search or Add piece. |
| A48 | [Stopping response](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | A14, A15 | Stopping pending acknowledgement; Stop stays visible, suppress duplicate taps, retain partial text. |
| A49 | [Response timed out](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | A11, A34, W13 | Terminal timeout preserves request and partial source; fresh attempt never reuses a write approval. |
| A50 | [New response below](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | A12, A13, A14 | Scrolled-up reader stays in place; Jump to latest, Stop and next-message draft remain available. |
| A51 | [Agent · Reduced transparency](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | A34, A35, A36, A41 | Opaque neutral shells/controls, no blur; inherits full Agent behavior. |
| A52 | [Agent · Larger text](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | A34, A35, A36, A41 | Larger text and expanded multiline editor; reflow controls without shrinking touch targets. |
| A53 | [Camera unavailable](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | A38, A35, A34 | Camera denied or absent; precise reason and Photos/Settings/typing alternatives, unchanged draft. |
| A54 | [Photo assistance unavailable](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | A34, W27, A38 | Unsupported image assistance offers description/manual capture/removal; no fake analysis or cloud switch. |
| A55 | [Agent · No closet context](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | W07, A34, A46 | No closet context shows General, useful prompts and Add piece; no ownership claims. |

[Rich input contract](agent-input.md) covers the new composer, media/context/voice and shared permission/readiness/error variants.

Complete behavior and evaluation-feedback contracts: [Agent experience](agent-experience.md).

## Inbox

| ID | Screen | Next screens | Contract and states |
| --- | --- | --- | --- |
| I01 | [Inbox](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | I02, I03, I05 | V2-only persistent labelled 44-point root-toolbar entry, not a tab; I01 precedes conversations. Back restores origin root/scroll/selected tab; startup/incoming intents preserve origin. Real acknowledged unread state only; no speculative typing/read receipts. Empty/offline/unavailable are separate. |
| I02 | [Camille Reyes](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | I06, S05, I07 | Native keyboard-aware composer. Draft retained, send pending until acknowledgement, retry keeps message ID. |
| I03 | [Requests](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | I04, I01 | Pending sender cannot repeatedly send until accepted; service abuse limits required. |
| I04 | [Message request](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | I02, I03, S10 | Accept/decline/block actions preserve truthful pending state on failure. |
| I05 | [New message](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | I02, I04 | Opening Message resumes the stable participant-pair conversation. |
| I06 | [Conversation details](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | S06, S10, I02 | Do not imply end-to-end encryption or delete-for-everyone before the service supports it. |
| I07 | [Camille Reyes](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | I02 | Offline/pending/failed/unknown delivery are distinct; retry never duplicates messages. |
| X08 | [Inbox unavailable](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | I01, W01 | Different from an empty connected Inbox. Never fill unavailable screens with fictional production chats. |

## Profile

| ID | Screen | Next screens | Contract and states |
| --- | --- | --- | --- |
| U01 | [Profile](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | U02, U03, U04, U05 | Owner variant of the compact shared profile; single-line ellipsized bio opens full-description sheet. Published collections only; private inventory totals are not visitor-visible. |
| U02 | [Edit profile](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | U01 | Native photo picker, username conflict; optional 160-character bio with live counter, single-line input, inline over-limit error and retained draft. Save failure preserves edits. |
| U03 | [Connections](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | S06 | Real counts and accessible profiles; blocked users are excluded. |
| U04 | [Published content](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | S09, S05, U06 | Unpublish revokes future AQD retrieval, including bookmarks/chat references; exported copies remain outside AQD. |
| U05 | [Settings](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | U06, U09, U11, U12, U13, U14, W20, S26, S08 | Settings entry belongs to Profile. Grouped native form, keyboard navigation, Dynamic Type. |
| U06 | [Privacy](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | U04, U08, A06, U13 | Public profile with optional social unlisting; private-profile follow requests are deferred. |
| U07 | [Notifications](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | U05 | V2 reference; excluded from V2 navigation. Denied permission and unavailable push service states are explicit. Preferences do not imply transport exists. |
| U08 | [Blocked people](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | U06 | Confirm exact person; block enforcement applies across feed, search, profiles, and Inbox. |
| U09 | [Your data](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | U10, U11, E08 | Format, media access, retention and recovery depend on selected service; avoid unconditional recovery claims. |
| U10 | [Export data](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | X05, U09 | Download uses native share/save UI; no false completed state before artifact exists. |
| U11 | [Delete account](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | U15, U10, U05 | Reauthentication and exact impact are required; do not promise erasure from another person’s device. |
| U12 | [Sign out](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | E03, U05 | Clear tokens and scoped caches; explicit device-only data choice; failure/cancel preserve session. |
| U13 | [Help and legal](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | U05, U09 | Native readable articles and in-app Safari for policies. Support destination and legal copy remain launch inputs. |
| U14 | [Appearance](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | U05 | System is default. No custom glass intensity setting duplicates operating-system preferences. |
| U15 | [Confirm deletion](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | X05, U11 | Destructive button disabled until valid confirmation. Pending/failure/receipt match service result. |
| X05 | [Changes saved](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | W08, U05 | Shared receipt template; replace title/record link with actual operation. Export/deletion use operation-specific completion. |


## V2 lifecycle and assistance additions

| ID | Screen | Next screens | Contract and states |
| --- | --- | --- | --- |
| E15 | [Session expired](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | E03, W01 | Expired session gates connected actions only; restore held intent after sign-in without sending automatically. |
| E16 | [Sign-in unavailable](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | E03, E10, W01 | Provider/network/verification failure preserves email and drafts; retry or choose another supported method. |
| E17 | [Connecting closet](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | U16, U22, E13, W01 | Association pending/unknown/failed states retain local records; check prior completion before retry; account collisions remain separate. |
| U16 | [Backup and sync](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | U18, U17, U22, U09 | Confirmed backup, pending offline edits and refreshing are distinct; exact account/status/time come from records. |
| U17 | [Sync conflict](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | U24, U16 | Conflict summary preserves both revisions; review fields, defer safely; never silently last-write-wins. |
| U18 | [Restore closet](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | U16, U23, E13 | Clean-install/second-device restore scopes records/media to current account; pending progress has no fabricated percentage. |
| U19 | [Export status](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | U10, U09 | Export preparing/ready/expired/failed variants preserve selection; ready requires real artifact; use native Save/Share. |
| U20 | [Deletion pending](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | U21, U13, E03 | Deletion received/executing/failed/unknown variants retain operation ID; hide revoked access and reconcile; no false completion. |
| U21 | [Account deleted](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | E02, U13 | Confirmed account deletion removes access and connected cache; show actual retention policy; guest start creates no account. |
| U22 | [Sync failed](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | U16, W01 | Local saved differs from backed up; failed/unknown upload keeps edit and stable idempotency key. |
| U23 | [Restore failed](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | U18, U16 | Partial restore keeps received records; resume media download without resetting existing drafts. |
| A31 | [Review theme](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | W18, W19, A22, A09 | Theme-only proposal uses owned outfits; preview/edit/save and empty-membership validation; no accidental outfit creation. |
| A32 | [Review changes](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | A23, A22, W08 | Exact target/changed fields reviewed; ownership/source revision revalidated; destructive/public/message actions retain their specific confirmations. |
| A33 | [Weather context](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | W17, A01 | Native place/date selection; no automatic device location. Loaded source/time, loading/failure and outside-coverage variants preserve manual styling. |
| U24 | [Review conflicting edits](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) | U16, U17 | Explicit field/version choice is bound to revisions; newer change refreshes review; Back preserves both versions. |

## Review boundaries

Photographs and personal names are illustrative reference content. Routes here describe intended behavior; Paper is a static design surface. Native implementation, accessibility, persistence, identity, moderation, synchronization, and service behavior must pass [native acceptance](native-ios.md) before release.

### Shared compact social post

S01, S02, D04 and detail share inline heart/comment counters and trailing bookmark. Feed captions use 15/22 regular type, two lines then More; detail shows full caption, optional theme and included-piece total. A photo tag count reflects linked accessible tags only. S09 enters S27 before publication review; tags never publish a private piece implicitly. Page 00 Social actions and piece tags defines selected, pending, rollback, empty, retry, revoked, comment delete/report and saved confirmation states.

Publication entry from an owned Piece/Outfit/Theme opens the corresponding preselected review; general Share opens S30. S02 is a Piece example; S01 an Outfit; S31 a Theme. Every photo requires a linked piece. S09’s optional row applies only to spatial marker placement, not piece inclusion. S20 is a native pushed list; the single-piece photo control opens public detail directly.

Search uses the shared [query and continuation contract](search-and-feeds.md): all public tabs and owner tabs inherit every lifecycle state. All-results groups open their respective selected tab. S03 is blank/recent; X07 focused with native keyboard; X03 no matches. Public-profile search retains that creator scope. No native navigation or data behavior is established by static artboards.

## Shared exit contract

Use the [one-exit map](native-presentations.md#one-exit-per-screen) for presentation ownership and dismissal, including all loading/error variants. The route tables list possible destinations; they do not authorize duplicate Back and Cancel controls for the same outcome.

## Shared piece photo editor

W31 (V2) and L77 (V1) use the same [photo editor](capture-photo.md). W27 → W31 → Use photo returns to W27 without saving a piece; Cancel leaves its previous photo/draft intact. Fit preserves landscape and portrait sources; optional Portrait 3:4 crop, rotate/reset/zoom operate locally. Change options and missing-photo validation are L78/L79 shared states. Missing media retains fields and blocks Save; labels omit Required/Optional. Existing W31 is a new additive editor reference; all original canonical routes remain.
