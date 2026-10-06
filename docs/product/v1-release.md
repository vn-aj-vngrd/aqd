# AQD V1 release definition

Updated October 5, 2026 with the owner's clarification: **V1 is a complete usable private app on one Apple device, not a thin closet demo.** It has Home, Closet, Planner, Agent, a local Profile, complete Settings/onboarding and light/dark appearance. It delivers the private wardrobe/outfit/planning journey end to end without an app backend. V2 extends that same app and data with connected features and future enhancements. This branch remains documentation/design only.

The October 1 connected V1 is preserved in [V2 core release](v2-release.md); its private requirements are retained here where device-only operation applies. [V2 backlog](v2-backlog.md) preserves everything else. No feature is discarded by the phase split.

## Release promise

On an iPhone, start privately, add owned pieces, create useful outfits/themes, prepare dates/routines/trips and packing, ask Agent for supported wardrobe help, record actual wear and inspect history/insights. Reopen all local records after restart; manage local Profile/preferences and Settings; export/restore/erase your data. These are complete journeys with loading, empty, error, permission, cancellation and success paths.

No account, social participation, network connection or AI-capable hardware blocks manual wardrobe/planning. V1 Agent is a real local destination with history, review, cancel/retry/copy and truthful capability states. Eligible, ready devices use on-device Foundation Models; other devices show reason-specific Agent unavailability, and manual controls remain available. Do not promise every generative question on every device.

iPhone remains the first Apple-device target; additional iPad/Mac/Watch/Android/web clients are future extensions. Retain the existing iOS 18 manual-path target as a planning default, subject to reproducible baseline review. Foundation Models needs a compatible newer OS/device and runtime availability. Free local use is the working default; no subscription/entitlement backend in V1.

## Included complete local scope

| ID | Required behavior | Local boundary |
| --- | --- | --- |
| V1-01 | V2-style Welcome/onboarding, optional replayable tour/returning session; Home with record-derived Today states | Start private without signup, quiz or arbitrary item quota; request media only when adding a piece. Restore drafts/destination; no All/Following. |
| V1-02 | Pieces: photo/camera/manual entry, name/category, optional metadata, search/filter/sort, edit, availability, archive/restore/delete | One cover photo needed for new-piece save, full-source Fit in a portrait preview and optional local crop/rotate/reset; originals and drafts retained. Manual classification plus verified on-device cleanup/editable tagging where supported. Save/media/migration failure preserves drafts and good data. |
| V1-03 | Manual/assisted owned-piece outfits, pin/replace/edit/favorites and independent themes | Multiple theme memberships, empty collections, rename/delete without losing outfits. No publish/share-to-community action. |
| V1-04 | Dedicated Planner root (Week default, Month alternate): dates/agenda, manual two-week plans, three-calendar-month routines, events/trips, conflicts and deduplicated packing | Calendar intent is local; bulk saving is atomic. Assisted generation is bounded/reviewed where supported. No external calendar or live-weather dependency. |
| V1-05 | Actual wear, backdate/correct/undo, historical snapshots and factual insights | Plans/time passage never record wear; recorded/estimated counts and denominators are explicit. No fabricated purchase/cost data. |
| V1-06 | Agent and focused actions: wardrobe questions/insights, outfit/theme/plan drafts and reviewed local edits/wear | Full local conversation/history/cancel/retry/copy/Markdown, verified local voice/image intake with typed fallback, exact preview/revision validation and actual receipts; no social/send/research/cloud tool. |
| V1-07 | Private Profile fit journal and personal preferences | Dated memories: optional one local photo, existing outfit link, private note ≤500 characters; require editable date (default today) and photo or outfit, never date-only. Optional local identity; existing wear insights and Style remain reachable. Not a duplicate closet or implicit wear; no social identity, public counts or uploads. [Journal contract](../features/profile-account.md#v1-private-fit-journal) owns validation/media/lifecycle. |
| V1-08 | Complete local Settings/privacy/help | Appearance System/Light/Dark, selected-device permission guidance, local profile/preferences, data export/restore/erase. No inactive auth/sync/push/billing toggles. |
| V1-09 | Durable local records/media/drafts and safe migrations | Stable IDs, relationships, themes/plans/history/conversations/profile after restart; no cloud sync or automatic recovery. |
| V1-10 | Versioned local archive export, validated reviewed restore and local erase | Full local archive replacement after staging/validation; no merge engine. Exported copies and original Photos assets are outside erase control. |
| V1-11 | Native complete states and appearance | Home/Closet/Planner/Agent/Profile, onboarding and Settings in light/dark; large text, VoiceOver, Reduce Motion/Transparency, keyboard/safe areas, permission/failure recovery and representative performance. |

Read the complete private W/O/P/A contracts with their phase headers and U's [V1 journal contract](../features/profile-account.md#v1-private-fit-journal). S/U/I connected behaviors remain V2; V1 local Profile/Settings follows this definition. Broad photo/speech/current-context features are enabled only when an on-device path is demonstrated; otherwise retain honest typed/metadata/manual paths and the future V2 requirement. Do not route an unavailable capability to a cloud provider silently.

## Welcome, onboarding and tour

Reuse V2's editorial Welcome with Start my closet and Take a quick tour. Onboarding explains optional/manual capture, device-only privacy and export/loss limits. The four-step Home/Closet/Agent/Profile tour is skippable, replayable from Settings and labelled preview-only; it never inserts demo records. Persist completion/resume locally, retain drafts, and return to the correct entry. Existing users do not repeat it when V2 arrives. [V1 flow](../design/v1-flow.md#welcome-onboarding-and-tour-contract) owns exact routes and accessibility.

## Local acceptance

| Check | Required evidence on the implemented build |
| --- | --- |
| LOCAL-01 | Fresh welcome/onboarding → capture → outfit/theme → plan → wear works in airplane mode and after restart; Home/Closet/Planner/Agent/local Profile/Settings are all usable. No social/account entry is reachable. |
| LOCAL-02 | Photo selection/cancellation, camera denial, invalid media and missing-photo validation preserve metadata/draft; block new-piece save without accepted media; copy selected images locally. First-save category guidance preserves the pinned task without replaying onboarding. |
| LOCAL-03 | Search/filter/sort, edits/archive/restore/delete keep stable IDs and exact impact. Deletion invalidates affected future assignments while history remains interpretable. |
| LOCAL-04 | Failed saves/migrations and corrupt/newer stores never overwrite good data or show false success. Drafts survive interruption; retries do not duplicate entities. |
| LOCAL-05 | Local dates/timezones, two-week plans, three-calendar-month routine future-edit choices, conflicts and trip packing are correct; bulk failure preserves the reviewed draft. Plan/date passage is distinct from wear; actual duplicate item-set/day, undo/correction/statistics are reproducible. |
| LOCAL-06 | Export includes versioned records/photos/relationships and local profile/preferences/Agent history with clearly described contents. Staged restore validates schema/media/reference/size integrity and exact replacement; cancellation/invalid/newer/failure preserves the original closet. |
| LOCAL-07 | Privacy copy states device-only storage, backup exclusion, device/app-loss risk and user-selected export destinations. Verify no AQD cloud entitlements/sync/uploads/remote analytics in the core flow. |
| LOCAL-08 | Erase reviews exact local records/media/history/profile/Agent/draft effects, offers export first and clears derived data. Explain that original Photos and exported copies remain outside AQD. |
| LOCAL-09 | Suggestions/actions use owned current IDs, preserve pins/drafts, require version-bound approval and show actual receipts. Test ineligible/disabled/not-ready model, timeout/cancel/invalid/stale output; labelled rules/manual recovery always works. |
| LOCAL-10 | Physical-device/Simulator checks cover supported OS, keyboard/safe areas, media, VoiceOver/large text/RTL, System/Light/Dark, reduced motion/opaque materials and realistic photo-heavy closet/Agent performance. |
| LOCAL-11 | Empty themes/multiple memberships/rename/delete/favorites retain outfits; migration preserves original theme data. Planner and local Profile shortcuts open the same owned records. |
| LOCAL-12 | Local Agent chat/history/new conversation/cancel/retry/copy/Markdown/review/receipt/reopen/delete work; unsupported input/context and unknown completion are honest. No generated text, imported caption or earlier approval authorizes a new write. |
| LOCAL-13 | Local name/photo remain optional; the shared preference flow can be entered from onboarding/Settings/Profile and uses seven numbered steps/progress without skip controls. Every question accepts an explicit answer or No preference/refusal; body measurements/use remain optional. Editing/cancellation/persistence work from the actual source. V2-style Welcome, private onboarding and Back/Next/Finish/Skip/replay tour routes remain correct for new/returning/draft users in both appearances. Tour examples never persist as user data. |
| LOCAL-15 | Same five equal-width icon-only native slots Home · Closet · Planner · Agent · Profile, explicit accessibility names/selected traits and nonoverlapping hit areas ≥44 × 44 pt. Closet segments only Pieces/Outfits/Themes; Planner Week/Month preserves dates. Home/outfit Plan links carry date context; Back restores origin/selection. Fourth-slot Agent full-screen dismissal restores origin/scroll/focus. Planner/private core need no account. Profile's single More icon contains Add fit/Edit profile/Style/Wear insights/Settings, without duplicate root actions. Verify VoiceOver/Dynamic Type/keyboard/safe areas; no V1 Inbox entry. |
| LOCAL-14 | Journal J1–J7: empty state, photo-only/outfit-only/combined saves, invalid empty/long-note drafts, editable stable dates, source/import cancellation/failure, protected edits/delete and restart. Composition-only fits never invent wearer photos. Fit/link changes never increment wear; separate Record wear deduplicates. Export/restore/erase includes journal media/data, outfit deletion retains memories/snapshots and missing media is honest. Verify privacy, VoiceOver, large text, keyboard and both appearances on the implemented build. |

## Data contract

Persist a versioned local database and protected media in the app sandbox. A local closet/profile identifier is not an online account. SwiftData with CloudKit explicitly disabled is a proposal; preserve a suitable recovered existing store rather than rewrite it merely for an API preference. Use stable item/outfit/theme/plan/history/conversation IDs and safe migrations.

Prepare required media before committing references; preserve old images until replacement saves. Archive preserves links; deletion previews outfit/theme/future-plan effects and retains minimal non-photo historical facts. Conversation/profile/preferences and journal memories/notes/date-timezones/outfit snapshots/media/drafts are local data, subject to export/restore/erase controls. Journal outfit deletion retains minimal composition facts without unexpectedly erasing memories; available media is reference-scoped and unavailable media labelled honestly. Journal replacement/deletion cleans only unreferenced AQD-owned media after commit, not outfits/wear records, other memories or original Photos assets. Private notes and images do not enter Agent context unless a separately supported explicit local selection allows it.

AQD-owned stores/photos/drafts/derived data are excluded from automatic device backups by default. Export creates a versioned archive locally and invokes the native document interface only after an explicit action. Explain its sensitive contents and that the destination can be cloud-backed. Restore is a reviewed full replacement with staging/validation and recoverable original data until completion. Device file protection does not establish encryption for an exported archive at its chosen destination.

## Apple-native assistance and complete experience

Use native navigation/tab controls, forms/menus/sheets, PhotosPicker/camera/document pickers, semantic system text and OS appearance/accessibility. Foundation Models supports bounded text/structured drafting using confirmed local metadata, not guaranteed image understanding or current information. Check hardware/OS/enablement/readiness/language/region at runtime; preparing the model can require network before later offline use.

Agent stays visible on every supported iPhone. Eligible/ready devices get local conversation and reviewed proposals; unavailable devices get a reason-specific explanation and direct routes into manual creation/planning. Long plans may use bounded reviewed batches; manual routines/trips are complete regardless of generative quality. Local contextual input can state occasion/preferences or user-entered conditions; no live forecast claim. Speech/image intake requires a verified on-device implementation before enabling, with typed/metadata fallback and clear unavailable states. Do not add model adapters, a generic orchestration platform or external API just to call V1 complete.

## V2 extends V1

V2 adds online identity/account lifecycle, opt-in association/sync/backup/recovery, social profiles/curated closets, All/Following/discovery, publishing/follows/comments/bookmarks, human Inbox/moderation/admin, remote push, external weather/calendar/research and the complete future enhancement roadmap. It retains V1's Home/Closet/Planner/Agent/Profile/Settings, private journeys, records and design foundations. Inbox is a persistent V2-only 44-point root-toolbar entry into I01, not a tab; no Inbox appears in V1; local Profile gains connected/public controls only after opt-in. No V1 data reset or mandatory redesign is part of this transition.

Advanced capture, try-on/shopping, inferred/automatic-learning personalization beyond the explicit shared questionnaire, purchases/cost-per-wear, richer community/chat, subscriptions, additional platforms and measured infrastructure growth remain in [V2](v2-backlog.md), with requirements prepared. Device-local feasibility alone does not approve every future enhancement for the MVP; existing private core journeys are complete and new features can be added after real usage.

## Known limitations and completion

One installation is authoritative. Device loss/app deletion/corruption without a retained export can lose the closet; automatic second-device recovery is not promised. No app backend or recurring backend bill is required, but Apple distribution/support/device costs remain separate. On-device resources/model quality are finite; unsupported generative capabilities never block manual work.

After separate implementation authorization, establish the source baseline and complete every private slice and LOCAL check with build/commit/device evidence. Review actual native appearance/navigation/accessibility and offline recovery. Paper is a prepared UI requirement, never runtime proof. [V1 flow](../design/v1-flow.md), [coverage](../design/v1-coverage.md), [status](../delivery/implementation-status.md) and [verification](../delivery/verification.md) own the handoff.

Agent availability follows the [reason-specific contract](../features/agent.md#agent-availability-and-provider-selection): L19 unsupported, L80 disabled, L81 preparing. LOCAL-12 includes tab visibility and draft/history preservation without a misleading composer. V2 retains an explicit provider option, with no V1 cloud fallback.
