# V2 flow review

The [V2 core release](../product/v2-release.md) retains connected auth/data/safety acceptance. [V2 backlog](../product/v2-backlog.md) now includes that core and all previously deferred enhancements; [V2 requirements](v2-requirements.md) prepare their design handoff. This flow page is a walkthrough, not the entire release checklist.

Reclassified October 5, 2026 from the October 1 connected review. Documentation and static design only; no app or backend implementation is authorized by this pass. [Open Paper page 02 · V2, section 08 · Complete connected journeys](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0). Read boards 00–20 from top to bottom, then each strip left to right; labelled conditional screens are branches, not compulsory setup. Screen copies are review snapshots with coherent journey fixtures and the P04 trip-form variant; canonical screens remain in V2 feature sections 01–07.

## Refinement and scope

The major gap was the transition from a saved piece to a useful outfit. V2 now makes it explicit: capture → review → save → missing-category capture or readiness → pin/suggest/manual composition → replace/review/save → plan → actual wear. One saved piece establishes trust; a usable outfit establishes styling value. There is no arbitrary upload count, required quiz, photo or social sign-up.

User decision: V2 must retain V1's shared private design and add connected extensions, not replace the Profile journal or restyle shared core controls. U01 uses L48's private journal base; U25 shows its single More menu and U26 preserves a separate public projection. Shared private identity/fit editors remain independent of public username setup. Settings uses V1 core groups and registered icons, with account/sync/privacy additions. E05/W20/U05 reuse UP01–UP07, the same numbered no-skip preference flow. Complete the wardrobe workflow first; defer virtual try-on/avatar previews and shopping wishlist/price alerts. Community and human Inbox remain required V2 product surfaces. This is coverage of AQD's selected Alta-inspired workflow, not full Alta feature parity or a claim that these features ship today.

## Numbered Paper walkthroughs

V1 is page 01; V2 is page 02. V2 sections 01–07 contain canonical features, section 08 contains this connected walkthrough, and section 09 contains future expansion requirements. Screen/node IDs are retained while page links are updated. Board 00 is the V2 overview and boards 01–16 contain journeys and branch/state examples; 17 maps V2 coverage and launch gates; 18 identifies V2 expansions. Each journey starts at step 00: `01.00`, `01.01`, and so on. The screen ID beside each step (for example E02 or W27) stays stable across feature pages and documentation. Recovery cases use codes for reference, without arrows implying a sequential journey.

| Board | Sequence | Conditional behavior |
| --- | --- | --- |
| 00 · V2 overview | Scope and route overview | Read before the screen strips. |
| 01 · Welcome and capture | E02 → E06 → W06 → W27 → E12 → W28 / W29 | W07 provides manual classification with the same photo requirement before saving. W28 appears only for actual missing categories; its capture loop returns to the same pinned task. Ready closets skip W28. |
| 02 · Optional auth and Home | E03 → E10 → E04 → E08 → E07 → Home | Apple can bypass email. E08 only if local association is unresolved; E07 only if a new social profile is needed. Home illustration is S48; choose the actual record-derived state. Existing accounts skip unnecessary setup. |
| 03 · Suggest, replace and save | S48 → W17 → A03 → W16 → A03 → A04 → W15 | Replacement is optional and returns to the same review. Pin and other slots remain. Receipt follows successful approved execution. A07 gives manual fallback. |
| 04 · Manual outfits and themes | W13 → W14 → W15; optional W18 / W19 | Themes are independent and optional; partial manual looks are identified. No AI runtime requirement. |
| 05 · Plan, wear and history | W15 → P03 → P01 → S15 → P09 → P10 → P11 | Review before plan save. Planner and Today are separate entry points into the same records. Planned does not mean worn; history/stats require actual records. |
| 06 · Trip and packing | P04 trip variant → P08 → P06 → P07 | Trip variant replaces routine recurrence with destination/activities. P12 branches before save when a conflict exists, then returns to review. Deduplicate packing by owned item ID. Weather depends on supported date coverage. |
| 07 · Community and Inbox | W15 → S09 → U04; S01 → S06; I04 → I02 | Separate optional journeys. Auth/profile gates preserve the held action. Exact publication is reviewed. I04 illustrates a received request; outgoing contact uses I05/pending-request policy. |
| 08 · Recovery branches | E09 / W07 / X06 / A07 / E11 / I07 | Independent camera/manual, save, AI, auth and message-retry cases; not a sequential funnel. |
| 09 · Identity and session recovery | E15 / E16 / E17 / E13 / U12 | Branches preserve the originating task. Apple/email methods remain service defaults; no callback sends a held action automatically. |
| 10 · Backup, conflicts and restore | U16 / U22 / U17 / U24 / U18 / U23 | Local saved, backed up and restored are different outcomes. Review conflicts before choosing; retry keeps stable IDs. |
| 11 · Export and account deletion | U09 / U10 / U19 / U11 / U15 / U20 / U21 | Export and deletion are separate tasks. Ready export follows artifact creation; deletion completion follows confirmed access removal. |
| 12 · Wardrobe lifecycle and history | W08 / W09 / W11 / W12 / W19 / P10 | Shared item/outfit/theme editors preserve IDs and drafts. Archive/delete warn about plans/public snapshots; actual wear stays historical. |
| 13 · Office routines and calendar edits | P04 / P05 / P12 / P08 / P02 | Create resolved entries for up to three calendar months. Existing plans require entry/future/whole-routine review; calendar time never records wear. |
| 14 · Discovery, discussion and safety | S30 / S33 / S34 / S03 / S22 / S24 / S10 / S11 | Share is private until preview/confirmation. Search, reactions and comments recheck access; block/report applies across every social entry. |
| 15 · Agent review and contextual actions | A33 / A31 / A32 / A23 / A22 / A09 | Use shared domain operations. Weather beyond coverage is omitted; theme/edits stay drafts; refreshed source revisions require fresh approval. |
| 16 · Inbox requests and safe retry | I01 / I05 / I03 / I07 / I06 / U08 | Only participants read human messages. Requests must be accepted; no default Agent reading. Read receipts and remote push extend the connected core under V2-E08/E09. |
| 17 · Coverage and launch gates | All V2-01–V2-15 groups | Maps feature references and operational tests; not implementation evidence. |
| 18 · V2 expansion scope | Future controls/features | Identifies excluded launch surfaces; core auth/data/safety remain required for connected launch; extensions use their own gates. |

Supplementary strips 09–16 show conditional/independent cases, not one compulsory funnel. The original 98 review copies across 16 strips use zero-based step codes; canonical feature sections remain authoritative. [Full coverage audit](v2-coverage.md) records shared/native states and unresolved service gates.

## Shared roots and V2 Inbox access

Both phases retain five equal-width icon-only native slots Home · Closet · Planner · Agent · Profile, explicit destination accessibility names and full hit areas ≥44 × 44 pt. Closet segments are only Pieces/Outfits/Themes. Dedicated Planner defaults to Week, with Month alternate; Home plan links and outfit Plan actions carry date context, and Back restores origin/selection. Fourth-slot Agent opens a native full-screen task, dismissing to origin/scroll/selection. Account setup never gates Planner/private core.

V2 alone has a persistent labelled 44-point Inbox root-toolbar entry → existing I01 → conversations, not a tab. Back restores origin root/scroll/selected tab; startup/incoming Inbox intents preserve origin. Real acknowledged unread only; V1 has no mirrored entry. Verify native VoiceOver/focus, Dynamic Type, keyboard/safe areas and return behavior after implementation; Paper evidence is pending, not a runtime pass.

## Home state and return rules

| Actual records | Today state | Primary route |
| --- | --- | --- |
| No pieces | S16 · First piece | Same capture/editor; manual eligible. |
| Pieces, no outfits, missing categories | First-outfit guidance using S48 hierarchy | W28; add the relevant category or build a partial look manually. |
| Available top/bottom/shoes or dress/shoes, no outfits | S48 · Ready to style | W17, or W13 manual. |
| Saved outfits, no current plan | S17 · No planned look | Choose a saved outfit, then plan. |
| Current planned outfit | S15 · Today | Review actual wear; Planner edits the intention. |

Eligibility reflects current availability and requested form, including whether a pinned piece can be included. Accessories/layers are optional. Readiness re-evaluates after edits/archive/save; it is not a stored checklist. Returning users restore the last Home mode/scroll position. Auth cancellation preserves the originating task and private drafts. Signing in never publishes inventory.

## Selected workflow coverage and remaining gates

The [Alta reference](../references/alta-notes.md) separates official advertised capabilities from AQD decisions. These rows describe V2 requirements, not implementation completion.

| Workflow | AQD V2 contract | Boundary |
| --- | --- | --- |
| Easy wardrobe capture | One-piece photo/manual capture, visible preview, editable name/category, add-next loop, search/edit/archive | No batch/receipt import, automatic studio cleanup or guaranteed tagging. Optional classification requires capability evidence. |
| First/daily outfit | Category guidance, owned-piece suggestions, occasion/mood/preferences, explicit pin, replacement and manual composition | Validate the supported on-device runtime/rules. Never invent owned pieces. |
| Reusable wardrobe | Saved looks, favorites, independent themes | Saving remains private and durable. |
| Calendar/event/routine | Dated plans, two-week schedules, three-month office routine, review/conflicts | Manual path required; long assisted plans need quality validation. |
| Travel and packing | Destination/dates/activities, reviewed looks, deduplicated packing | No multi-destination optimization or unverified forecast claims. |
| Wear history and insights | Confirmed wear, correction/undo, factual recorded counts | Planned dates and estimated prior wear remain separate; cost-per-wear deferred. |
| Weather/context | Explicit date/location input and sourced weather where supported | Provider, permission, coverage and device/tool validation remain release gates. No fabricated current weather. |
| Inspiration/social | Public discovery/search, creator closets/follows, reactions/bookmarks/comments, owned-wardrobe recreation, exact snapshot publishing | Connected identity, media access/revocation and moderation required. A bookmark is not ownership. |
| Human Inbox | Requests, one-to-one text/public references, draft preservation and safe retry | Transport, retention, abuse controls and delivery evidence required. Agent chat is separate. |
| Virtual try-on | Deferred by user decision | Future scope/provider/privacy/quality/cost review. |
| Shopping wishlist/price alerts | Deferred by user decision | No launch shopping catalog, alerts or affiliate revenue assumption. |

## Review and implementation acceptance

The editable design source remains Paper; static designs do not establish runtime behavior.

- Complete fresh private capture through a first outfit and planned/recorded wear without an account or AI runtime; prove save/restart durability.
- Walk top/bottom/shoes and dress/shoes paths; capture only missing categories, retain the pin and draft on cancel/failure, re-evaluate archived/unavailable pieces.
- Replace an outfit slot and verify the other pieces/context survive; keep manual/partial composition available; retries create one saved record.
- Enter sign-in from Welcome and from a pending publication/message action; skip irrelevant association/profile screens and resume the correct intent. Conflicts keep records separate.
- Plan a date and trip, review conflicts, change an outfit and update packing; record/correct actual wear without altering unrelated future intentions.
- Publish exactly reviewed content; inspect public profiles, unpublish/revoke references and accept/retry human chat without exposing private notes/plans.
- Verify native navigation, 44-point targets, keyboard/safe areas, larger text, VoiceOver, Reduce Motion and unavailable/offline states on devices. Paper is static evidence only.

Field, privacy and lifecycle rules remain in [feature specs](../features/README.md); routes in [SCREENS.md](screens.md); implementation status in [IMPLEMENTATION.md](../delivery/implementation-status.md). This refinement introduces no new backend/provider selection, paid AI path or service deployment.

Closet inspiration route: W01/W02/W03/W04 → More (W30) → Saved inspiration (S08/S29) → post detail or Make my version. Return restores the originating Closet state. The collection is shared with Profile Settings; community Liked posts stay there, and owned Favorites stay in Closet. Canonical menu reference: [V2 section 03 · Closet and creation](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0).

## Exit behavior

Review copies follow the [one-exit map](native-presentations.md#one-exit-per-screen): standalone tasks and nested steps use leading glass Back with drafts preserved, and search has trailing Cancel only. A nested Back returns to its task root; Back at the root dismisses the task to its originating screen without committing. Dirty exits require Keep editing / Discard changes. Cancellation never commits a plan, publication, wear record, profile change or account deletion.

## Agent input and streaming review · October 2, 2026

Board 20 adds twelve static copies numbered 20.00–20.11: A34 → A36 → A37 → A11 → A12 → A13, followed by the optional A41–A44 voice branch and independent A40/A49 recovery examples. The last main step and independent branches have no onward arrows. Selected-context examples preserve the dinner prompt; voice review adds editable text and never sends automatically. Canonical A34–A55 and page-00 input/shimmer masters retain authority. Board 19 remains the consolidated offline review. Native focus, permissions, streaming, transcription and execution remain unverified; see [Agent input](agent-input.md).

### Shared capture refinement

W27 → W31 → W27 adds the same local photo editor prepared for V1 L77. No-photo/selected, full portrait/landscape Fit, crop/rotate/reset, Change menu and missing-photo validation states are shared in [Capture photo](capture-photo.md). V2 extends this with its existing sync, tagging and publication gates; editing alone does not trigger any connected action.
