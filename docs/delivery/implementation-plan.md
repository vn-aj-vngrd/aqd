# Implementation plan and handoff

Deliver the complete [V1 release checklist](../product/v1-release.md), including auth/data/safety/launch checks; [V2 extras](../product/v2-backlog.md) are excluded. The source/build baseline must be established first: the current checkout has no tracked Swift source/build definition matching the historical prototype. Service/capability gates for mandatory V1 must close before release.

This is the implementation entry point after product refinement. This documentation pass authorizes specifications only; do not begin app changes until the user requests implementation. Once authorized, deliver one complete slice at a time using the relevant [feature specification](../features/README.md).

## Readiness meanings

- **Specified:** behavior, states, dependencies, and acceptance are written; not proof of implementation.
- **Locally actionable:** the next slice can use current local app infrastructure without an unresolved external service.
- **Service-gated:** connected work depends on a named unresolved identity/storage/messaging decision.
- **Capability-gated:** promised AI/image/retrieval behavior needs evidence on the chosen runtime.
- **Verified:** passing evidence is recorded in docs/delivery/verification.md for the actual implemented slice.

Feature requirements include reviewable working defaults listed in [Decisions](../product/decisions.md). Do not silently convert a proposal into a confirmed user preference or claim a service-gated feature is production-ready.

## Delivery order

| Order | Slice | State | Depends on / completion |
| --- | --- | --- | --- |
| 1 | W: Add/classify/save/find/edit one item, archive/restore, local migration | Specified; source baseline required | W1–W5/W7; preserve existing user data. Deletion impact expansion waits for dependent features. |
| 2 | O: Manual outfit composition and theme collections | Specified; source baseline required | W IDs/lifecycle; O1–O4/O7, migrate current theme strings. |
| 3 | P: Actual wear/history and trusted stats | Specified; source baseline required | W/O; P7–P9 and explicit date/estimate handling. |
| 4 | P: Manual Planner/event/routine/packing | Specified; source baseline and slices 1–3 required | P1–P5; stable entries and all-or-nothing persistence. |
| 5 | A: Shared proposal/review/execution contract; focused outfit/theme actions | Specified; runtime capability-gated | Manual operations above; A1–A5/A7 and real-device limits. |
| 6 | A/P: Assisted dates/routines and context retrieval | Specified; capability-gated | Full manual Planner, proposal contract, dated weather source; P6/A6/A8/A10. |
| 7 | U/S: Connected identity/durability, public profile, publishing, All/Following/search | Specified; service-gated | Selected backend/storage, data lifecycle, access/revocation and moderation; U/S acceptance. |
| 8 | I: Human Inbox | Specified; service-gated | U/S access/blocking and messaging policy; I1–I8. |
| 9 | A: Social actions and reviewed message drafts | Specified; service-gated | Connected S/I contracts and A9; never use mocks as deployment proof. |

Do not build a custom framework or split every screen into a package to match this table. Logical feature boundaries do not mandate physical module extraction. Inspect the current Core/Features/Design/Services structure and extend its smallest suitable boundaries.

## Wardrobe activation

The major UX gap is activation: saving one piece must lead clearly to a usable outfit, rather than ending onboarding in a grid. The first private save establishes trust; the first saved outfit establishes styling value. Welcome → optional photo/manual capture → review → save → actual missing-category guidance → suggest or build manually → pin/replace → review/save → plan → record wear is the V1 path. See the [V1 flow review](../design/v1-flow.md) and its dedicated Paper page.

Capture remains one piece at a time, with only name/category required. Readiness uses active, available owned pieces for top + bottom + shoes or dress + shoes; no fixed upload quota, style quiz, account, or AI runtime gates manual creation. The first saved piece can stay pinned. Today distinguishes an empty closet, missing categories, pieces ready but no saved outfits, saved outfits without a plan, and a planned look. Repeated capture returns to the pending outfit task.

V1 requires manual and supported-device contextual styling, editable replacements, independent themes, planning/routines/travel packing, factual wear history/insights, explicit publishing/discovery and human Inbox. This covers the selected Alta-inspired wardrobe workflow, not every Alta feature. Automatic photo metadata is deferred to V2; studio cleanup, bulk import and an avatar are not implied by basic capture.

## Milestone exits

### Milestone 1: Useful private closet

Complete capture, manual classification, item management, manual outfits, independent themes, actual wear history, and factual stats. Preserve existing data through migrations and handle failed saves without losing drafts.

Exit: a new user can capture a piece, follow missing-category guidance or choose manual composition, save a usable first look, find and edit it after restart, organize it, record wear, and correct history without AI or social participation. Verify W and O acceptance for the delivered scope, including W8–W10 and O8–O9, and P7–P9.

### Milestone 2: Personal planning

Add calendar/agenda planning, dated events, weekday routines, and travel packing. Support two-week plans and office routines spanning three calendar months. Future intentions and actual wear remain distinct.

Exit: a user can save a plan, revise a day or future routine entries, review conflicts, and regenerate its packing list. Bulk saving either persists the reviewed plan completely or preserves the draft without partial changes. Verify P1–P6, disclosing any capability-gated assistance.

### Milestone 3: Shared Agent capabilities

Deliver grounded questions and insights, reviewed outfit/theme drafts, and assisted planning through focused actions and full-screen Agent. Manual operations remain available. Use the selected on-device runtime within demonstrated limits.

Exit: approve a concrete proposal, execute once, and inspect the actual result. Stale targets, cancellation, invalid output, unavailable models, and retries have tested outcomes. Apply A acceptance by capability; physical-device quality and current-information tools have separate release gates.

### Milestone 4: Community and identity

Deliver connected identity/durability, public profiles and curated closets, explicit publication, All / Following feeds, discovery search, follows/reactions/bookmarks, and owned-wardrobe inspiration.

Exit: publish one look without disclosing unrelated inventory, notes, history, or plans; revoke access through profile/feed/search/bookmarks; respect blocking and moderation. Verify U/S acceptance against connected services. Backend, sync, media access, and data lifecycle decisions are prerequisites.

### Milestone 5: Human Inbox

Deliver one-to-one text and public-content references, message requests, reliable delivery/unread states, blocking/reporting, and reviewed Agent message drafts.

Exit: accept a request, send/retry without duplication, and correctly handle revoked references and blocked contact. Verify I acceptance and A9. Messaging retention, delivery, notification, and abuse policies are prerequisites.

## First module after authorization: Wardrobe capture and management

Goal: from an empty/private closet, add one owned item, classify it manually, save it, find it, edit it, and archive/restore it after app restart.

1. Inspect `Garment`, `WardrobeStore`, `ItemEditor`, `ItemDetail`, `ClosetView`, shared UI, and existing tests. Complete when each W requirement maps to current behavior or a named gap.
2. Record the necessary data migration and text validation changes. Complete when an old wardrobe fixture retains IDs, photos, notes, and wears, and failed migration cannot overwrite it.
3. Reuse the picker/form/detail/grid; add only components required by this slice. Complete when W capture and lifecycle paths are connected, including denied/cancelled media and persistence failures.
4. Verify persistence/migration/lifecycle with meaningful core tests; inspect rendered states and affected navigation. Complete when W1–W5/W7 pass and untested device paths are disclosed.
5. Update docs/delivery/implementation-status.md and docs/delivery/verification.md with the exact implemented scope. Complete when the user can review the runnable result and evidence.

Outfit AI, calendar, social feeds, Inbox, receipt imports, and background cleanup are separate slices. Preserve existing functionality when extending the module; this is not authorization to discard the prototype or reset data.

## Feature completion contract

For the authorized slice, account for every requirement and acceptance ID: implemented and verified, deferred with reason/dependency, or blocked by a concrete decision. Distinguish source compilation, synthetic tests, simulator flows, physical-device behavior, connected service tests, and production deployment.

Run appropriate existing build/tests; add tests for meaningful domain changes and failure recovery, not visual constants. UI changes require simulator evidence under [Design rules](../design/rules.md). Failed writes, stale proposals, access denial, offline/loading/empty states, and retry behavior belong to the feature, not a later polish list.

Request missing information only when it blocks the current slice. Continue independent authorized work; do not create remote services or change the AI runtime merely because a later row needs them.
