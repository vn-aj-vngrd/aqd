# Motion coverage

Phase scope: shared native/visual rules apply to both phases. Five-destination base navigation applies to both phases. Full-app E/W/P/S/A/I/U routes, online identity and connected states are V2 references. Complete private themes/planning/Agent are retained in V1. V1 uses only its [dedicated local flow](v1-flow.md) and [complete local release](../product/v1-release.md); [V2 requirements](v2-requirements.md) own connected and extension coverage.

Every Paper screen/state inherits [Global motion](motion.md), including interruption, Reduce Motion, accessibility and performance requirements. This table is an implementation contract, not evidence of working animation. Native recipes take precedence; custom recipes apply only to changed local content. Existing presentation ownership in docs/design/screens.md wins when a screen has several entry paths.

| Screen | Navigation | Local motion | Flow constraint |
| --- | --- | --- | --- |
| E01 · Splash | Native launch | None | No delay; restore the authorized destination. |
| E02 · Welcome | N-push | E-arrival | Twelve-piece gather/form/settle sequence; Back returns settled; tap interrupts immediately. V1 L60/L67 inherit this recipe. |
| E03 · Sign in | N-push | C-form, C-load | Native auth/keyboard; keep return intent and draft; no success before verification. |
| E04 · Check your email | N-push | C-form, C-load | Native auth/keyboard; keep return intent and draft; no success before verification. |
| E05 · Style preferences | N-push | C-select, C-form | Native step transition; selections and validation stay local. |
| E06 · Your first piece | N-sheet | C-load, C-form | System media picker/permissions; cancellation retains the manual path. |
| E07 · Public profile | N-push | C-select, C-form | Native step transition; selections and validation stay local. |
| E08 · Connect your closet | N-push | C-form, C-load | Native auth/keyboard; keep return intent and draft; no success before verification. |
| E09 · Camera access | N-sheet | C-load, C-form | System media picker/permissions; cancellation retains the manual path. |
| E10 · Continue with email | N-push | C-form, C-load | Native auth/keyboard; keep return intent and draft; no success before verification. |
| E11 · Sign-in link expired | N-push | C-form, C-load | Native auth/keyboard; keep return intent and draft; no success before verification. |
| E12 · First piece saved | N-push | C-save | Receipt after first persisted piece; continue at user pace. |
| E13 · Connect closet | N-push | C-form, C-load | Native auth/keyboard; keep return intent and draft; no success before verification. |
| E14 · How you found AQD | N-push | C-select, C-form | Native step transition; selections and validation stay local. |
| S01 · Home · All | N-root | C-load, C-select | Stable feed; local reaction feedback; no scrolling cell entrances. |
| S02 · Home · Following | N-root | C-load, C-select | Stable feed; local reaction feedback; no scrolling cell entrances. |
| S03 · Search | N-push | C-select, C-load | Native search and keyboard; latest query wins without results jumping. |
| S04 · Search results | N-push | C-select, C-load | Native search and keyboard; latest query wins without results jumping. |
| S05 · A light layer | N-photo | C-load, C-select | Source-matched media detail where appropriate; normal push fallback. |
| S06 · Camille Reyes | N-push | C-select, C-load | Stable identity; collection selection/follow update locally. |
| S07 · Camille’s closet | N-photo | C-load, C-select | Source-matched media detail where appropriate; normal push fallback. |
| S08 · Saved inspiration | N-photo | C-load, C-select | Source-matched media detail where appropriate; normal push fallback. |
| S09 · Publish look | N-sheet | C-form, C-save | Publish receipt follows confirmed write only. |
| S10 · Report or block | N-sheet | C-form, C-save | Stable safety confirmation; no celebratory effects. |
| S11 · Report post | N-sheet | C-form, C-save | Stable safety confirmation; no celebratory effects. |
| S12 · Following | N-root | C-load | Empty Following stays still; retain selected Home scope. |
| S13 · Camille · Pieces | N-push | C-select, C-load | Stable identity; collection selection/follow update locally. |
| S14 · Camille · Themes | N-push | C-select, C-load | Stable identity; collection selection/follow update locally. |
| S15 · Home · Today | N-root | C-save, C-load | Two scroll positions of one Today view; do not animate between artboards. |
| S16 · Today · First piece | N-root | C-load | No data means a static useful prompt, not perpetual loading. |
| S17 · Today · No planned look | N-root | C-load | No data means a static useful prompt, not perpetual loading. |
| S18 · Today · Wardrobe activity | N-root | C-save, C-load | Two scroll positions of one Today view; do not animate between artboards. |
| X01 · Home | In place | C-load | Stable loading/empty/offline/unavailable state; reveal only when data changes. |
| X02 · You’re offline | In place | C-load | Stable loading/empty/offline/unavailable state; reveal only when data changes. |
| X03 · No results | In place | C-load | Stable loading/empty/offline/unavailable state; reveal only when data changes. |
| X04 · Content unavailable | In place | C-load | Stable loading/empty/offline/unavailable state; reveal only when data changes. |
| X07 · Search active | N-push | C-select, C-load | Native search/keyboard; no competing page transition. |
| W01 · Closet | N-root | C-select, C-change, C-load | Preserve collection and scroll; no full-grid cascade. |
| W02 · Closet | N-root | C-select, C-change, C-load | Preserve collection and scroll; no full-grid cascade. |
| W03 · Closet | N-root | C-select, C-change, C-load | Preserve collection and scroll; no full-grid cascade. |
| W04 · Closet | N-root | C-select, C-change, C-load | Preserve collection and scroll; no full-grid cascade. |
| W05 · Add to closet | N-sheet | C-load | Native capture choices/Photos; preserve draft. |
| W06 · Add a photo | N-sheet | C-load | Native capture choices/Photos; preserve draft. |
| W07 · New piece | N-push | C-form, C-save | Native editing; inline validation and confirmed local save. |
| W08 · Cotton shirt | N-photo | C-load, C-select | Same-record photo source only; offscreen source uses push fallback. |
| W09 · Piece details | N-push | C-form, C-save | Native editing; inline validation and confirmed local save. |
| W10 · Search closet | N-push | C-select, C-load | Native owner-scoped search; no per-keystroke grid animation. |
| W11 · Archived pieces | N-push | C-change, C-save | Restore/archive updates locally after receipt. |
| W12 · Delete piece | N-sheet | C-save | Destructive guard; remove only after confirmed result. |
| W13 · Build outfit | N-push | C-change, C-save | Piece replacements reflow locally; pinned pieces stay anchored. |
| W14 · Choose pieces | N-sheet | C-select, C-change | Selection immediate; apply draft changes on explicit confirmation. |
| W15 · An easy afternoon | N-photo | C-load, C-select | Same-record photo source only; offscreen source uses push fallback. |
| W16 · Replace a piece | N-sheet | C-select, C-change | Selection immediate; apply draft changes on explicit confirmation. |
| W17 · Suggest an outfit | N-sheet | C-stream, C-save | Assisted proposal stays draft until reviewed and saved. |
| W18 · Weekend | N-photo | C-load, C-select | Same-record photo source only; offscreen source uses push fallback. |
| W19 · Edit theme | N-push | C-form, C-save | Native editing; inline validation and confirmed local save. |
| W20 · Style preferences | N-sheet | C-select, C-change | Selection immediate; apply draft changes on explicit confirmation. |
| W21 · Additional details | N-push | C-form, C-save | Native editing; inline validation and confirmed local save. |
| X06 · Couldn’t save | In place | C-form, C-load | Preserve failed draft and readable recovery action. |
| P01 · Planner | N-root | C-select, C-change | Dedicated third root; Week default/Month alternate retain date. Cross-root links preserve origin/selection for Back; native calendar drag follows finger, invalid drop restores slot. |
| P02 · October 2026 | N-push | C-select, C-change | Native calendar; drag follows finger; invalid drop restores slot. |
| P03 · Plan a look | N-sheet | C-form, C-save | Plan steps preserve input; no fake assignment before commit. |
| P04 · New plan | N-sheet | C-form, C-save | Plan steps preserve input; no fake assignment before commit. |
| P05 · Office routine | N-sheet | C-form, C-save | Plan steps preserve input; no fake assignment before commit. |
| P06 · Seoul, slowly | N-push | C-select, C-change | Trip/packing changes stay local; stable checked-item identity. |
| P07 · Packing list | N-push | C-select, C-change | Trip/packing changes stay local; stable checked-item identity. |
| P08 · Review plan | N-sheet | C-form, C-save | Review/conflict resolution stable until confirmed. |
| P09 · Record wear | N-sheet | C-save | Confirmed wear updates count once; undo reverses local change. |
| P10 · Wear history | N-push | C-load, C-change | History/insights update without count-up or chart loops. |
| P11 · Wear insights | N-push | C-load, C-change | History/insights update without count-up or chart loops. |
| P12 · Resolve a conflict | N-sheet | C-form, C-save | Review/conflict resolution stable until confirmed. |
| A01 · Agent | N-sheet | C-form, C-stream | Native full-screen Agent route; restore originating destination on Back. |
| A02 · Agent | N-sheet | C-form, C-stream | Native full-screen Agent route; restore originating destination on Back. |
| A03 · Review outfit | N-sheet | C-form, C-select | Review/context/details/clarification remains readable; native sheet as appropriate. |
| A04 · Outfit saved | In place | C-receipt, C-save | Local acknowledgement; success only for the actual confirmed operation. |
| A05 · Conversations | N-push | C-load, C-change | History retains list position and stable conversation IDs. |
| A06 · Agent context | N-sheet | C-form, C-select | Review/context/details/clarification remains readable; native sheet as appropriate. |
| A07 · Assistance unavailable | In place | C-load, C-form | Static recoverable error; retain draft/partial work; no shake. |
| A08 · Preparing a draft | In place | C-stream, C-load | No token animation; Stop immediate; preserve scroll, partial text and task status. |
| A09 · Couldn’t save yet | In place | C-load, C-form | Static recoverable error; retain draft/partial work; no shake. |
| A10 · Review message | N-sheet | C-form, C-select | Review/context/details/clarification remains readable; native sheet as appropriate. |
| A11 · Waiting for response | In place | C-stream, C-load | No token animation; Stop immediate; preserve scroll, partial text and task status. |
| A12 · Streaming response | In place | C-stream, C-load | No token animation; Stop immediate; preserve scroll, partial text and task status. |
| A13 · Response complete | In place | C-stream, C-load | No token animation; Stop immediate; preserve scroll, partial text and task status. |
| A14 · Response stopped | In place | C-stream, C-load | No token animation; Stop immediate; preserve scroll, partial text and task status. |
| A15 · Response interrupted | In place | C-stream, C-load | No token animation; Stop immediate; preserve scroll, partial text and task status. |
| A16 · Taking longer | In place | C-stream, C-load | No token animation; Stop immediate; preserve scroll, partial text and task status. |
| A17 · Live task progress | In place | C-stream, C-load | No token animation; Stop immediate; preserve scroll, partial text and task status. |
| A18 · Response details | N-sheet | C-form, C-select | Review/context/details/clarification remains readable; native sheet as appropriate. |
| A19 · Response feedback | N-sheet | C-form, C-select | Review/context/details/clarification remains readable; native sheet as appropriate. |
| A20 · Feedback received | In place | C-receipt, C-save | Local acknowledgement; success only for the actual confirmed operation. |
| A21 · Feedback not sent | In place | C-load, C-form | Static recoverable error; retain draft/partial work; no shake. |
| A22 · Saving approved draft | In place | C-stream, C-load | No token animation; Stop immediate; preserve scroll, partial text and task status. |
| A23 · Draft needs review | N-sheet | C-form, C-select | Review/context/details/clarification remains readable; native sheet as appropriate. |
| A24 · Loading conversations | N-push | C-load | Loading differs from empty; no artificial waiting. |
| A25 · No conversations | N-push | C-load | Loading differs from empty; no artificial waiting. |
| A26 · Conversation load failed | In place | C-load, C-form | Static recoverable error; retain draft/partial work; no shake. |
| A27 · Copied and rated | In place | C-receipt, C-save | Local acknowledgement; success only for the actual confirmed operation. |
| A28 · Alternate response | In place | C-stream, C-load | No token animation; Stop immediate; preserve scroll, partial text and task status. |
| A29 · Message not sent | In place | C-load, C-form | Static recoverable error; retain draft/partial work; no shake. |
| A30 · Clarification needed | N-sheet | C-form, C-select | Review/context/details/clarification remains readable; native sheet as appropriate. |
| I01 · Inbox | N-push | C-load, C-change | V2 persistent root-toolbar entry, not a tab; startup/incoming intents preserve origin root/scroll/selected tab for Back. Stable list; real acknowledged unread only, request status changes after confirmation. |
| I02 · Camille Reyes | N-push | C-message, C-load | Anchor reading position; native keyboard; retain failed draft. |
| I03 · Requests | N-root | C-load, C-change | Stable list; request status changes after confirmation. |
| I04 · Message request | N-sheet | C-form, C-message, C-save | Review recipient/request; native dismissal preserves draft. |
| I05 · New message | N-sheet | C-form, C-message, C-save | Review recipient/request; native dismissal preserves draft. |
| I06 · Conversation details | N-push | C-select, C-save | Conversation settings/moderation remain stable during confirmation. |
| I07 · Camille Reyes | N-push | C-select, C-save | Conversation settings/moderation remain stable during confirmation. |
| X08 · Inbox unavailable | In place | C-load | Stable loading/empty/offline/unavailable state; reveal only when data changes. |
| U01 · Profile | N-root | C-select, C-load | Stable profile header; native collection tabs. |
| U02 · Edit profile | N-sheet | C-form, C-save | Photo replaces with crossfade; failed save keeps draft. |
| U03 · Connections | N-push | C-select, C-change, C-save | Local follow/unblock/unpublish updates; rollback on failure. |
| U04 · Published content | N-push | C-select, C-change, C-save | Local follow/unblock/unpublish updates; rollback on failure. |
| U05 · Settings | N-push | C-select, C-form | Native settings/navigation; no additional page reveal. |
| U06 · Privacy | N-push | C-select, C-form | Native settings/navigation; no additional page reveal. |
| U07 · Notifications | N-push | C-select, C-form | Native settings/navigation; no additional page reveal. |
| U08 · Blocked people | N-push | C-select, C-change, C-save | Local follow/unblock/unpublish updates; rollback on failure. |
| U09 · Your data | N-push | C-load, C-save | Export progress reflects actual work; completed file receipt stays visible. |
| U10 · Export data | N-push | C-load, C-save | Export progress reflects actual work; completed file receipt stays visible. |
| U11 · Delete account | N-sheet | C-form, C-save | Stable destructive/account confirmation; clear old private state before reveal. |
| U12 · Sign out | N-sheet | C-form, C-save | Stable destructive/account confirmation; clear old private state before reveal. |
| U13 · Help and legal | N-push | C-select, C-form | Native settings/navigation; no additional page reveal. |
| U14 · Appearance | N-push | C-select, C-form | Native settings/navigation; no additional page reveal. |
| U15 · Confirm deletion | N-sheet | C-form, C-save | Stable destructive/account confirmation; clear old private state before reveal. |
| X05 · Changes saved | In place | C-save | Receipt updates affected content; no forced navigation. |

| S19 · Post · Tags visible | N-push | C-load, C-select | Selected heart/bookmark; creator-authored numbered image tags. Tag list is the accessible alternative; Back restores source. |
| S20 · Pieces in this look | N-push | C-load, C-select | Native push to the numbered accessible tag list. Only accessible, explicitly published creator pieces; revoked targets use X04. |
| S21 · Blue wool coat | N-push | C-load, C-select | Creator public piece snapshot, never private item detail. Save is a reference, not ownership; revalidate access. |
| S22 · Comments | N-push | C-load, C-message, C-form | Oldest-first comments, earlier-page loader above. Keyboard-aware draft, pending/sent reconciliation, own Delete confirmation or other Report/Block. |
| S23 · Comments · Empty | N-push | C-load, C-message, C-form | No comments yet; focus composer without an automatic keyboard on entry. Blank Send is disabled. |
| S24 · Comments · Send failed | N-push | C-load, C-message, C-form | Failed comment retains editable draft; retry with the same operation identity. Never duplicate the comment or clear a newer draft. |
| S25 · Likes | N-push | C-load, C-select | Accessible reacting profiles. Zero/loading/pagination/error variants use the social master; preserve originating post. |
| S26 · Liked posts | N-push | C-load, C-select | Private liked-post collection, distinct from public per-post Likes. Unliking removes the reference; shared empty/retry/unavailable states. |
| S27 · Tag pieces | N-push | C-select, C-form | Author-only tag placement, move/remove, maximum five per image. Done returns to publication review; cancel retains prior placements. |
| S28 · Choose published piece | N-push | C-select, C-form | Choose only an owned published piece; private publication is a separate explicit flow and retains the post draft. |
| S29 · Saved inspiration · Empty | N-push | C-load, C-select | Empty private Saved inspiration; Explore Home opens All. No placeholder saved posts. |

| S30 · Share from your closet | N-push | C-select, C-form, C-load | Share chooser: Piece, Outfit, Theme. Choose an owned source, then review exact public fields and pieces. No photo-only option. |
| S31 · Theme post | N-push | C-select, C-form, C-load | Public Theme example: selected outfits and six disclosed pieces, compact collection row. Open the selected public outfits; hidden members never appear. |
| S32 · Add a piece to continue | N-push | C-select, C-form, C-load | No linked piece: Publish disabled with explanation. Choose or add a piece; return with photo, caption and draft preserved. |
| S33 · Publish piece | N-push | C-select, C-form, C-load | Review Piece publication, one owned piece and its selected public photo/fields. Publish only after final ownership and media checks; pending/error retain draft. |
| S34 · Publish theme | N-push | C-select, C-form, C-load | Review Theme publication: selected outfits and explicitly disclosed piece snapshots. Empty theme cannot publish; future additions remain private. |
| S35 · Burgundy coat | N-push | C-select, C-form, C-load | Noah public Burgundy coat snapshot. Return to Following restores scroll. Save references the public piece and does not import ownership. |

| S36 · Search · People | N-push | C-select, C-load, C-form | People selected: portrait rows, handle and relevant public context. Preserve query and scroll. |
| S37 · Search · Pieces | N-push | C-select, C-load, C-form | Pieces selected: two-column product thumbnails, name and creator. Revalidate public snapshot access. |
| S38 · Search · Outfits | N-push | C-select, C-load, C-form | Outfits selected: cover grid and creator attribution. No private inventory metadata. |
| S39 · Search · Themes | N-push | C-select, C-load, C-form | Themes selected: collection collages, creator and accessible outfit count. |
| S40 · Search · Loading | N-push | C-select, C-load, C-form | Initial query loading: neutral result geometry, native progress, latest query wins. Shared per-tab skeleton shapes. |
| S41 · Search · Failed | N-push | C-select, C-load, C-form | Initial query failure retains query/tab/filters; Retry. Never report failure as empty results. |
| S42 · Search · Offline | N-push | C-select, C-load, C-form | Offline cache explicitly labelled; only cached public results. No cache uses the shared reconnect state. |
| S43 · Search · Loading more | N-push | C-select, C-load, C-form | Next result page loads below existing tiles. Inline Retry on failure; confirmed end replaces progress. |
| W22 · Search closet · Outfits | N-push | C-select, C-load, C-form | Owned Outfits search tab. No community results; preserve owner query/filter/scroll state. |
| W23 · Search closet · Themes | N-push | C-select, C-load, C-form | Owned Themes search tab. Collage, name and membership count; includes permitted private empty themes. |
| W24 · Search closet · No matches | N-push | C-select, C-load, C-form | Owner no-match state retains query, offers clear filters and manual add. Do not confuse with read failure. |
| W25 · Search closet · Loading | N-push | C-select, C-load, C-form | Owner query loading uses neutral placeholders and progress; local search does not require community connectivity. |
| W26 · Search closet · Failed | N-push | C-select, C-load, C-form | Owner data-read failure preserves query/filters; Retry without account or data loss. |
| S44 · Home · Multiple posts | N-root | C-load, C-select | Long-content reference: Outfit, Piece and Theme posts in one feed. Shared action row and required-piece links. |
| S45 · Home · Loading more | N-root | C-load, C-select | Viewport loading more: loaded posts remain above progress, bottom navigation stays clear; append without moving reader. |
| S46 · Home · Load more failed | N-root | C-load, C-select | Following pagination failure retains loaded posts and cursor; inline Retry does not restart feed. |
| S47 · Home · End reached | N-root | C-load, C-select | Confirmed end-of-feed state; no perpetual spinner. Refresh/new posts are user-triggered. |

| W27 · Review piece photo | N-push | C-form, C-load, C-save | Preserve photo/fields; no auto-save after analysis or fake receipt. |
| W28 · First outfit · Missing pieces | N-push | C-change, C-load | Category capture returns to same task; no forced progress animation. |
| W29 · First outfit · Ready | N-push | C-select | Actual availability, not a quota; manual path stays visible. |
| S48 · Today · Ready to style | N-root | C-load | Derived state; preserve Home mode and no repeated first-use arrival. |


## V2 lifecycle additions

| Screen | Navigation | Local motion | Flow constraint |
| --- | --- | --- | --- |
| E15 · Session expired | N-push | C-form, C-load, C-save | Preserve drafts/revisions and announce actual terminal status; no invented percentage or premature receipt. |
| E16 · Sign-in unavailable | N-push | C-form, C-load, C-save | Preserve drafts/revisions and announce actual terminal status; no invented percentage or premature receipt. |
| E17 · Connecting closet | N-push | C-form, C-load, C-save | Preserve drafts/revisions and announce actual terminal status; no invented percentage or premature receipt. |
| U16 · Backup and sync | N-push | C-form, C-load, C-save | Preserve drafts/revisions and announce actual terminal status; no invented percentage or premature receipt. |
| U17 · Sync conflict | N-push | C-form, C-load, C-save | Preserve drafts/revisions and announce actual terminal status; no invented percentage or premature receipt. |
| U18 · Restore closet | N-push | C-form, C-load, C-save | Preserve drafts/revisions and announce actual terminal status; no invented percentage or premature receipt. |
| U19 · Export status | N-push | C-form, C-load, C-save | Preserve drafts/revisions and announce actual terminal status; no invented percentage or premature receipt. |
| U20 · Deletion pending | N-push | C-form, C-load, C-save | Preserve drafts/revisions and announce actual terminal status; no invented percentage or premature receipt. |
| U21 · Account deleted | N-push | C-form, C-load, C-save | Preserve drafts/revisions and announce actual terminal status; no invented percentage or premature receipt. |
| U22 · Sync failed | N-push | C-form, C-load, C-save | Preserve drafts/revisions and announce actual terminal status; no invented percentage or premature receipt. |
| U23 · Restore failed | N-push | C-form, C-load, C-save | Preserve drafts/revisions and announce actual terminal status; no invented percentage or premature receipt. |
| A31 · Review theme | N-push | C-form, C-load, C-save | Preserve drafts/revisions and announce actual terminal status; no invented percentage or premature receipt. |
| A32 · Review changes | N-push | C-form, C-load, C-save | Preserve drafts/revisions and announce actual terminal status; no invented percentage or premature receipt. |
| A33 +108S-0–10FL-0 · Shared V1/V2 WeatherKit states | Native push/search/permission | C-form, C-load, C-select | OS transitions/growing rows/bounded fade; Reduce Motion immediate or opacity-only. Preserve actual source/draft/focus; Settings confirms optional preference, outfit/plan/Agent apply context only. No invented progress or save receipt. See [weather](weather-context.md). |
|10GK-0 · Enabled Home inline weather | Native Home/details push | C-load, C-select | Date/symbol/temperature only, no card/number animation; source/time/Saved announced, day mismatch omits values. Return to same Home; legal system-browser return preserves focus. |
| U24 · Review conflicting edits | N-push | C-form, C-load, C-save | Preserve drafts/revisions and announce actual terminal status; no invented percentage or premature receipt. |

| W30 · Closet options | Native Menu | None | Anchored toolbar presentation; selection dismisses then pushes S08/S29; dismissal preserves Closet state. |

## Appearance variants

D01–D04 inherit their underlying screen recipes. Dark mode changes semantic colors, not timing. Larger text reflows without shrinking controls. Reduced Transparency uses opaque native material and the same navigation model. Reduce Motion is a separate runtime preference: each custom recipe uses its non-spatial alternative.

Reference boards are specifications, not additional navigable screens. New screens must receive a motion assignment in this table and the manifest before design coverage is marked complete.

## Agent input extension · October 2, 2026

| Screen | Navigation | Local motion | Flow constraint |
| --- | --- | --- | --- |
| A34 · Agent · Keyboard focused | Native full-screen | C-stream, C-form | Default new-chat focus once; multiline Return, native keyboard inset. A01 is keyboard-dismissed welcome. |
| A35 · Add to your message | N-sheet | C-form, C-select | Native attachment menu → selected Photos, Camera, image Files or Closet; cancel retains draft. |
| A36 · Choose closet pieces | N-sheet | C-form, C-select | Private Pieces / Outfits / Themes, search and retained multiselection. Loading/error/cache/revoked variants inherit shared collection states. |
| A37 · Agent · Selected attachments | Native full-screen | C-stream, C-form | Ready/removable context rail, explicit pin, typed owned revisions; Send is enabled for valid supported input. |
| A38 · Review attached photo | N-sheet | C-form, C-select | Selected-image review separates Attach from Add piece; no silent persistence or publication. |
| A39 · Preparing attachment | Native full-screen | C-stream, C-form | Per-attachment preparation with disabled Send and Remove; other selections remain readable. |
| A40 · Attachment needs attention | Native full-screen | C-stream, C-form | Actual unreadable/invalid/oversized/lost-access reason; Retry only when supported, Replace/Remove otherwise. |
| A41 · Dictation permission | N-sheet | C-form, C-select | Explanation before native permission request; explicit microphone intent, no capture on autofocus. |
| A42 · Listening | N-sheet | C-form, C-select | Measured recording duration/level; Finish or Discard, interrupt stops microphone, no automatic send. |
| A43 · Transcribing | N-sheet | C-form, C-select | Transcription distinct from generation, Cancel preserves typed draft; no undisclosed cloud fallback. |
| A44 · Review voice message | N-sheet | C-form, C-select | Editable native transcript; Use transcript merges into retained draft, then explicit Send. |
| A45 · Voice unavailable | N-sheet | C-form, C-select | Denied mic, unavailable speech, no speech and transcription failure use specific Settings/re-record/retry/typing recovery. |
| A46 · Context mode | N-sheet | C-form, C-select | My closet / Selected pieces / Without closet, truthful source bounds; running context remains immutable. |
| A47 · Closet · No matching pieces | N-sheet | C-form, C-select | No matches differs from empty/error; retain selected records and offer Clear search or Add piece. |
| A48 · Stopping response | Native full-screen | C-stream, C-form | Stopping pending acknowledgement; Stop stays visible, suppress duplicate taps, retain partial text. |
| A49 · Response timed out | Native full-screen | C-stream, C-form | Terminal timeout preserves request and partial source; fresh attempt never reuses a write approval. |
| A50 · New response below | Native full-screen | C-stream, C-form | Scrolled-up reader stays in place; Jump to latest, Stop and next-message draft remain available. |
| A51 · Agent · Reduced transparency | Native full-screen | C-stream, C-form | Opaque neutral shells/controls, no blur; inherits full Agent behavior. |
| A52 · Agent · Larger text | Native full-screen | C-stream, C-form | Larger text and expanded multiline editor; reflow controls without shrinking touch targets. |
| A53 · Camera unavailable | N-sheet | C-form, C-select | Camera denied or absent; precise reason and Photos/Settings/typing alternatives, unchanged draft. |
| A54 · Photo assistance unavailable | N-sheet | C-form, C-select | Unsupported image assistance offers description/manual capture/removal; no fake analysis or cloud switch. |
| A55 · Agent · No closet context | Native full-screen | C-stream, C-form | No closet context shows General, useful prompts and Add piece; no ownership claims. |

## Shared piece photo states

L75/L76 use C-load/C-form for importing and accepted media; L78 uses native Menu presentation. L77/W31 use N-push and C-select/C-form; preview transformations follow direct user input, with no decorative animation. Cancel/Use photo return to the originating draft; only confirmed record save reaches C-save in L05; L79 stays C-form/C-select with missing-photo feedback and retained fields. Reduce Motion applies state changes immediately.
