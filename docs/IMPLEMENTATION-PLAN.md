# Implementation plan and handoff

Deliver the complete [V1 release checklist](V1-RELEASE.md), including auth/data/safety/launch checks; [V2 extras](V2-BACKLOG.md) are excluded. The source/build baseline must be established first: the current checkout has no tracked Swift source/build definition matching the historical prototype. Service/capability gates for mandatory V1 must close before release.

This is the implementation entry point after product refinement. This documentation pass authorizes specifications only; do not begin app changes until the user requests implementation. Once authorized, deliver one complete slice at a time using the relevant [feature specification](features/README.md).

## Readiness meanings

- **Specified:** behavior, states, dependencies, and acceptance are written; not proof of implementation.
- **Locally actionable:** the next slice can use current local app infrastructure without an unresolved external service.
- **Service-gated:** connected work depends on a named unresolved identity/storage/messaging decision.
- **Capability-gated:** promised AI/image/retrieval behavior needs evidence on the chosen runtime.
- **Verified:** passing evidence is recorded in VERIFICATION.md for the actual implemented slice.

Feature requirements include reviewable working defaults listed in [Decisions](OPEN-QUESTIONS.md). Do not silently convert a proposal into a confirmed user preference or claim a service-gated feature is production-ready.

## Delivery order

| Order | Slice | State | Depends on / completion |
| --- | --- | --- | --- |
| 1 | W: Add/classify/save/find/edit one item, archive/restore, local migration | Specified; locally actionable | W1–W5/W7; preserve existing user data. Deletion impact expansion waits for dependent features. |
| 2 | O: Manual outfit composition and theme collections | Specified; locally actionable | W IDs/lifecycle; O1–O4/O7, migrate current theme strings. |
| 3 | P: Actual wear/history and trusted stats | Specified; locally actionable | W/O; P7–P9 and explicit date/estimate handling. |
| 4 | P: Manual Planner/event/routine/packing | Specified; locally actionable after 1–3 | P1–P5; stable entries and all-or-nothing persistence. |
| 5 | A: Shared proposal/review/execution contract; focused outfit/theme actions | Specified; runtime capability-gated | Manual operations above; A1–A5/A7 and real-device limits. |
| 6 | A/P: Assisted dates/routines and context retrieval | Specified; capability-gated | Full manual Planner, proposal contract, dated weather source; P6/A6/A8/A10. |
| 7 | U/S: Connected identity/durability, public profile, publishing, All/Following/search | Specified; service-gated | Selected backend/storage, data lifecycle, access/revocation and moderation; U/S acceptance. |
| 8 | I: Human Inbox | Specified; service-gated | U/S access/blocking and messaging policy; I1–I8. |
| 9 | A: Social actions and reviewed message drafts | Specified; service-gated | Connected S/I contracts and A9; never use mocks as deployment proof. |

Do not build a custom framework or split every screen into a package to match this table. Logical feature boundaries do not mandate physical module extraction. Inspect the current Core/Features/Design/Services structure and extend its smallest suitable boundaries.

## First authorized module: Wardrobe capture and management

Goal: from an empty/private closet, add one owned item, classify it manually, save it, find it, edit it, and archive/restore it after app restart.

1. Inspect `Garment`, `WardrobeStore`, `ItemEditor`, `ItemDetail`, `ClosetView`, shared UI, and existing tests. Complete when each W requirement maps to current behavior or a named gap.
2. Record the necessary data migration and text validation changes. Complete when an old wardrobe fixture retains IDs, photos, notes, and wears, and failed migration cannot overwrite it.
3. Reuse the picker/form/detail/grid; add only components required by this slice. Complete when W capture and lifecycle paths are connected, including denied/cancelled media and persistence failures.
4. Verify persistence/migration/lifecycle with meaningful core tests; inspect rendered states and affected navigation. Complete when W1–W5/W7 pass and untested device paths are disclosed.
5. Update IMPLEMENTATION.md and VERIFICATION.md with the exact implemented scope. Complete when the user can review the runnable result and evidence.

Outfit AI, calendar, social feeds, Inbox, receipt imports, and background cleanup are separate slices. Preserve existing functionality when extending the module; this is not authorization to discard the prototype or reset data.

## Feature completion contract

For the authorized slice, account for every requirement and acceptance ID: implemented and verified, deferred with reason/dependency, or blocked by a concrete decision. Distinguish source compilation, synthetic tests, simulator flows, physical-device behavior, connected service tests, and production deployment.

Run appropriate existing build/tests; add tests for meaningful domain changes and failure recovery, not visual constants. UI changes require simulator evidence under [Design rules](DESIGN-RULES.md). Failed writes, stale proposals, access denial, offline/loading/empty states, and retry behavior belong to the feature, not a later polish list.

Request missing information only when it blocks the current slice. Continue independent authorized work; do not create remote services or change the AI runtime merely because a later row needs them.
