# V1 complete local design coverage
October 6, 2026. [Paper page 01 · V1](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-2-0) groups the prepared V1 phones into seventeen numbered flow and supporting-state sections. [V1 flow](v1-flow.md) owns step/return behavior. L01–L158 are static designs; shared native state contracts handle repeated variations. Requirements preparation is not runtime completion.

| V1 requirement | Local Paper references | Shared/private contracts and remaining native checks |
| --- | --- | --- |
| V1-01 · Welcome / onboarding / Home | L60–L66, L01–L02, L05, L23, L43–L44 | Shared original twelve-piece Welcome/motion, optional replayable tour, new/returning/draft states; E06 media permission presentation, S15–S18/S48 private hierarchy. Prove preview isolation and correct resume. |
| V1-02 · Pieces | L03–L04, L21, L43, L75–L79 | W06–W12/W21/W27–W29: manual/photo, search/filter/sort/edit/archive/restore/delete and exact impacts. Native menu/form states, loading, no-match, media/save failures remain implementation checks. |
| V1-03 · Outfits / themes | L06–L08, L18–L20, L27, L32/L34–L35/L46 | W13–W19, A03/A31: pin/replace/multi-theme/favorite and empty collection; manual path, stale drafts, private save. |
| V1-04 · Planner / routines / trips | L09–L10, L33, L36–L40/L42, L82–L85 | Dedicated third root (not Closet segment), Week default/Month alternate; Home/outfit links retain date and Back origin/selection. P01–P08/P12: local event/trip form variant, recurrence/future-edit, intentional gaps/conflicts, atomic save and deduplicated packing. No live-weather requirement. |
| V1-05 · Wear / insights | L11–L12/L41 | P09–P11: backdate/correct/undo, historical snapshot and real denominators; plan-versus-wear separation. |
| V1-06 · Local Agent | L24–L31/L46–L47/L19; L07/L18/L27; L68–L74 | A01–A09/A11–A18/A22–A26/A29–A32 private lifecycle; typed input, local context/history/cancel/retry/copy/Markdown and actual receipts. A34–A55 and input masters apply only to verified on-device rich-input paths. External sends/tools/feedback remain V2. |
| V1-07 · Local Profile | L48–L49/L45 | Optional name/photo/preferences and private shortcuts; no public handle/counts/follows. Test skipped/edited state and durability. |
| V1-08 · Settings | L13/L50–L52; tour L62–L65 | Complete appearance/capability/privacy/help/tour replay controls; no inactive account, push, sync or billing toggles. |
| V1-09 · Local durability | L17/L22 and every saved-record state | Restart/draft/media integrity, migrations, protection/backup exclusion and performance are LOCAL checks, not illustrative status labels. |
| V1-10 · Export / restore / erase | L14–L16/L22 | Full sensitive archive, schema/media/reference validation, staged replacement, cancellation and erase effects including Profile/Agent. Chosen export location can be cloud-backed. |
| V1-11 · Native appearance / accessibility | L53–L59/L67 + page-00 masters | Both appearances for all routes; shared large-text/opaque-material/form/menu states. Physical-device VoiceOver, focus/keyboard/RTL/localization, Reduce Motion/Transparency and permissions remain unverified. |

## Shared states are complete requirements
Loading, empty, no-match, invalid data, denied permissions, cancelled input, dirty dismissal, capability unavailable, timeout/stopped/partial reply, stale proposal, failed/unknown save, invalid/newer archive and storage failure have retained-draft or safe recovery behavior. Use the relevant private domain contract and native presentation rather than adding fake success or a disabled social surface.

A14/A15/A16/A29 cancellation/interruption/slow/send-failure designs are shared visual patterns for local Agent; labels must describe the actual local runtime. Remote feedback A19–A21/A27–A28 and social actions A10/A28 remain V2. Model-not-ready and unsupported image/speech states preserve typed/manual paths. No generic Agent platform is required to satisfy the private UI.

## Limits and future extension
The original canonical E/W/P/S/A/I/U inventory and connected review are preserved in [V2 coverage](v2-coverage.md). Reusable private references can serve both phases; canonical pages describe the complete V2 target and never introduce account/social controls into V1 automatically. [V2 requirements](v2-requirements.md) prepares the full expansion backlog.

Paper cannot establish database durability, archive recovery, Foundation Models quality, permission semantics, accessibility, distribution or infrastructure behavior. [Verification](../delivery/verification.md) records actual static checks separately. All LOCAL acceptance requires later authorized implementation; this branch changes no app functionality.

Agent device availability: L19 unsupported hardware, L80 Intelligence disabled and L81 model preparing; tab visibility, reason-specific recovery and retained draft/history follow [Agent](../features/agent.md#agent-availability-and-provider-selection).

## Explicit V1 interaction expansion

L86–L158 provide local Search, private editors/pickers, management choices, confirmations, empty/recovery states, archive progress, unknown-save handling and onboarding preferences. Use the [action-to-destination checklist](v1-interactions.md) for every button/link and shared state. System-owned presentations are named explicitly; V2 public/connected controls are excluded. These references supersede using a V2-only screen as the sole implementation route for these actions.
