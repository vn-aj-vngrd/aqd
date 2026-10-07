# Design task router

For UI creation/review/implementation: [foundations](../../DESIGN.md) → [procedure](rules.md) → affected feature and design contract → applicable [DQ criteria](quality-criteria.md). Read specialist references only for the branch below, not the whole catalog. Releases own phase scope; feature specs own behavior. Static design and native acceptance are separate.

| Trigger | Read | Owner |
| --- | --- | --- |
| Locate/classify a screen | [Screen map](screens.md), [iOS manifest](paper-manifest.json) | Canonical IDs/classification and recorded locators, not runtime routes. |
| Change journey/navigation | [V1 flow](v1-flow.md); connected additions [V2 flow](v2-flow.md) | Readable journeys, root/source returns. |
| Change a V1 control/return | [Interactions](v1-interactions.md) | Action/destination/state/return exceptions and recovery coverage. |
| Acceptance/phase coverage audit | [V1 coverage](v1-coverage.md), [V2 coverage](v2-coverage.md), phase release | Requirement-to-reference traceability; IDs remain stable. |
| Shared geometry/state/accessibility | Affected heading in [Components](components.md); public/social/account only → [connected components](components-connected.md) | Reusable contracts, not feature lifecycle authority. |
| Native API/deployment/feasibility | [Native iOS](native-ios.md) | API guards, target, fallback and runtime acceptance. |
| Presentation/exits/confirmation | [Native presentations](native-presentations.md) | Native open states, exits, source restoration, risk policy. |
| Materials/custom shell | [Liquid Glass](liquid-glass.md) | Functional material selection/accessibility, not API deployment policy. |
| Icon change | [Icons](icons.md), [registry](icon-manifest.json) | Registered geometry, roles and aliases. |
| Motion/navigation animation/loading | [Motion](motion.md), affected [assignment](motion-coverage.md) | Shared recipes and motion-specific exceptions. |
| Today configuration/personal content | [Today](today.md), [feature](../features/today.md) | Visual/configuration contract; feature owns data/lifecycle. |
| Profile journal | [Fit journal](profile-fit-journal.md), [profile feature](../features/profile-account.md) | Private composition, draft/return and record behavior. |
| Photo capture/editor/cleanup | [Capture](capture-photo.md), [wardrobe](../features/wardrobe.md) | Media UI/native acceptance and saved-piece behavior. |
| Entry/auth/onboarding | [Entry](entry-identity.md); questionnaire [Personalization](onboarding-personalization.md); choreography [Entry motion](entry-motion.md) | Entry gates vs entered-questionnaire rules vs animation. |
| Agent send/drafts/context/voice | [Input](agent-input.md) | Eligibility, attachments, focus and input lifecycle. |
| Agent response/stream/approval | [Experience](agent-experience.md), [Agent feature](../features/agent.md) | Response rendering/recovery vs trusted action behavior. |
| Planner dates/views | [Calendar](planner-calendar.md), [planning](../features/planning-history.md) | Calendar UI vs date/wear domain behavior. |
| Weather retrieval/display/consent/context | Complete [V1 weather policy](../product/v1-release.md#optional-live-weather-contract) and LOCAL-16, then [weather UI](weather-context.md) or [mechanics](../architecture/v1.md#optional-native-weather-boundary) | Policy vs interaction vs request/storage mechanics. Numerical attribution remains release-blocking. |
| Search/feed continuation | [Search and feeds](search-and-feeds.md) | Scoped query, pagination and recovery. |
| Connected extension design | Selected [V2 requirements](v2-requirements.md), [full backlog](../product/v2-backlog.md) | Prepared extension contracts, not permission to implement. |
| Landing/admin web | [Web](web.md), [web manifest](web-paper-manifest.json) | Web patterns/responsive scope, not native material. |
| Copy/provenance regression | [Copy ledger](v1-copy-review.md), relevant [reference](../references/README.md)/asset README/evidence | Historical exact receipts and source terms; not routine implementation reads. |

## Current versus history

Paper owns visual composition: [iOS](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0) has Foundations/V1/V2; [web](https://app.paper.design/file/01M3W6P0PN9SSQ1J3N6V23A9WK) has landing/admin. Foundations is reusable primitives; product phones/journeys stay phase-owned. Structural clones require synchronization. Manifests own recorded inventories, [current verification](../delivery/verification.md) owns evidence limits. No current runtime baseline is established.

Historical index inventories/repair narratives are preserved in [October 7 snapshot](../delivery/archive/design-index-2026-10-07.md); read only for reconciliation/provenance. Exact repair mappings remain in existing evidence JSON, unchanged. Official 27 kit inspection/import is source evidence; AQD/native 27 runtime is unverified. Numerical weather with hidden attribution/details-only placement remains blocked, and identical cleanup fixture pixels remain non-proof of masks.
