# AQD web design

Phase scope: shared native/visual rules apply to both phases. Five-destination base navigation applies to both phases. Full-app E/W/P/S/A/I/U routes, online identity and connected states are V2 references. Complete private themes/planning/Agent are retained in V1. V1 uses only its [dedicated local flow](v1-flow.md) and [complete local release](../product/v1-release.md); [V2 requirements](v2-requirements.md) own connected and extension coverage.

Recorded October 2, 2026. [Web in Paper](https://app.paper.design/file/01M3W6P0PN9SSQ1J3N6V23A9WK) owns the static web designs. [DESIGN.md](../../DESIGN.md) owns the shared AQD brand and native iOS system. These are designs for two separate apps: a public landing site and a protected operator workspace. No web app code, deployment, identity provider, or mailing service was added.

## Phase boundary

The shared Paper V1/V2 boundary board distinguishes a complete local Apple app from the connected landing/admin product. V1 has no staff workspace, waitlist database or application backend. Static support/privacy/store information can be published independently without an app runtime dependency; detailed connected landing/acquisition and protected operations remain V2 references.

## Design authority and organization

| Paper page | Owns |
| --- | --- |
| [00 · Shared web foundations](https://app.paper.design/file/01M3W6P0PN9SSQ1J3N6V23A9WK/p-1-0) | Shared palette, type, spacing, app boundaries |
| [01 · Web components](https://app.paper.design/file/01M3W6P0PN9SSQ1J3N6V23A9WK/p-2-0) | Actions, keyboard focus, fields, validation, status and feedback |
| [02 · V2 · Landing app](https://app.paper.design/file/01M3W6P0PN9SSQ1J3N6V23A9WK/p-3-0) | Full desktop landing and early-access form |
| [03 · V2 · Admin · Overview & analytics](https://app.paper.design/file/01M3W6P0PN9SSQ1J3N6V23A9WK/p-4-0) | Operational overview and aggregate product activity |
| [04 · V2 · Admin · Safety](https://app.paper.design/file/01M3W6P0PN9SSQ1J3N6V23A9WK/p-5-0) | Reports, bounded evidence, confirmation, accounts/enforcement and audit |
| [05 · V2 · Admin · Operations](https://app.paper.design/file/01M3W6P0PN9SSQ1J3N6V23A9WK/p-6-0) | System health, jobs/retry review and bounded controls |
| [06 · V2 · Admin · Access & settings](https://app.paper.design/file/01M3W6P0PN9SSQ1J3N6V23A9WK/p-7-0) | Operator sign-in, verification, permissions and sessions |
| [07 · V2 · Responsive & states](https://app.paper.design/file/01M3W6P0PN9SSQ1J3N6V23A9WK/p-8-0) | Mobile landing/reports, loading and recovery |
| [08 · V2 · Admin flow](https://app.paper.design/file/01M3W6P0PN9SSQ1J3N6V23A9WK/p-9-0) | Five annotated journeys: access, report decision, account enforcement, operations, analytics/settings |

The [web manifest](web-paper-manifest.json) records 28 artboards across nine pages. It is separate from the iOS manifest. Cloned geometry is a snapshot; shared structural changes require updating all affected instances. Token values in this file are independent of iOS tokens and must be deliberately synchronized when the brand changes.

## Shared visual rules

Use the existing cool neutral canvas `#F5F5F7`, white surface, graphite ink `#292C30`, supporting text `#686C72`, divider `#E2E5E9`, and crisp blue `#006FEE`. Blue identifies primary actions and selection; links and secondary labels use `#005BC4` on `#E6F1FE` soft fills; success, warning, and error retain their existing semantic roles. Ordinary content is unboxed or grouped with separators. Use contained surfaces where they explain a form, evidence group, or notice.

Admin Settings uses the [shared settings group](components.md#reusable-settings-group): white opaque surface on the canvas, 12px corners, 14px horizontal padding and separators between rows only. Operator profile, access and security reuse this group with existing web actions, wrapping metadata and keyboard focus. Keep page identity and explanations outside the group. Native and web share these semantic surface rules while retaining their platform controls.

Paper uses Helvetica Neue, matching the iOS reference. Web implementation should use the existing system sans-serif stack rather than depend on a locally installed font. Display headings use medium weight and tight tracking; body text remains regular. Desktop landing display is 96/96px (early-access display 80/84px), section headings 56/60px, admin titles 26/32px, data and compact UI 14/20px, supporting metadata 13/20px, and longer explanatory copy 14/22px. Landing body remains 17/27px and UI 15/20px. Mobile display is 48/50px.

Actions have at least 44px targets, fields retain visible labels, keyboard focus has a visible blue outline, and errors include text rather than color alone. Keep labels and trailing actions in fixed lanes. Native Liquid Glass geometry is an iOS concern; web uses ordinary accessible controls and restrained rounded surfaces.

## Landing app

Proposed routes: `/`, `/early-access`, and Contact / Privacy / Terms destinations. Legal and support content still need their own authored pages before publication.

The landing story is a considered closet: an editorial hero with the existing Today preview beside its promise → alternating Closet preview → capture/build/plan process → planning and optional Agent → selected sharing → questions → early access. The mobile page carries the same product proof and privacy/manual-use questions. The headline reuses “A wardrobe worth wearing.” The CTA is “Get early access,” because a production download destination was not verified. Once an actual release and store URL are confirmed, replace that CTA consistently rather than claim availability prematurely.

Feature copy follows [Product](../product/definition.md): owned pieces, outfits/themes, planning and wear history, reviewed assistance, and selected public sharing. Manual use is explicit. Virtual try-on, shopping alerts, automatic studio processing, pricing, user counts, testimonials, and unsupported AI/privacy claims are excluded.

The form collects an email for launch updates, explains the purpose, links Privacy, and provides success/validation/recovery patterns. It must preserve input on failure and prevent duplicate submissions. Mailing consent, storage, unsubscribe handling, rate limits, and the delivery service remain implementation decisions.

## Admin app

Proposed routes: `/sign-in`, `/verify`, `/`, `/analytics`, `/reports`, `/reports/:id`, `/accounts`, `/accounts/:id`, `/jobs`, `/health`, `/controls`, `/audit-log`, and `/settings`. Overview prioritizes the operational queue. Reports support status, reason, assignee, and case-ID search; case review separates evidence from decision. Accounts show identity and enforcement history, with a reason-bound restoration review. Audit links actor, action, target, time, reason, and related case. Settings covers operator identity, permissions, and sessions.

The operator design develops the [V2 safety requirement](../product/v2-release.md) and the current [web/admin architecture](../architecture/admin-web.md), including management, analytics, monitoring, and controls. The full navigation preview uses an Owner / operator fixture. Moderator and Analyst navigation/actions must reflect their actual grants, rather than copy every owner destination. Invited email-link entry followed by authenticator verification is a working design default; the provider, MFA factor/recovery policy, and detailed permissions remain proposals. Actual operator policy, sign-in/session behavior, and account enforcement contracts must be specified before implementation. Sample identities, queue totals, metrics, timestamps, messages, and policy reasons are illustrative fixtures.

Evidence is bounded to reported public content and user-selected message evidence. The design does not introduce general access to private closets, unrelated conversations, or Agent histories. Every decision requires a recorded reason; removal/suspension requires target/consequence review and confirmation. Keep-content resolution must also validate and persist the reason. A comment removal is distinct from account suspension.

Disable repeated submission while saving. Record a success receipt only after persistence confirms the result, then update the queue and audit entry. Failure retains the draft reason; conflict or unknown outcome refreshes case state before retry. Actual authorization, removal propagation, concurrency, audit integrity, and retention remain implementation verification requirements.

### Analytics and operations

Analytics shows a selected period, aggregation timestamp/timezone, metric definitions, and a first-piece → outfit → plan → wear funnel. The illustrative active-account definition counts associated accounts with committed product actions; guest activity remains separate. Insufficient retention history shows unavailable rather than zero. Final event/cohort definitions and consent/retention require implementation review; these sample figures do not describe a launch audience.

System health distinguishes available, stale, and unavailable signals. The worker example names the last heartbeat and observation time; the media example has no current provider signal. Provider views are linked for detailed sanitized diagnostics rather than copied into a custom raw-log browser. Alert transport is independent of this interface, as required by the architecture.

Jobs distinguishes failed from waiting operations and reviews the existing request before retry, checking prior completion and preventing duplicates. Controls shows only bounded publishing/message-send changes. The pause example requires a reason, duration, affected-flow review, confirmation, and audit receipt. Actual allowlisted keys/limits, server enforcement, expected revisions, expiry, role/MFA checks, and rollback must be specified before implementation. No arbitrary database edits, impersonation, or landing CMS is introduced.

X01 adds session-expired, access-denied, and unavailable telemetry states alongside queue and form recovery. Restore review drafts only after the same operator regains authorization; do not expose draft/evidence to a different operator or an unauthenticated session. A verification code uses one accessible input with numeric input mode and one-time-code autofill in implementation, rather than six separate focus targets.

## Responsive and motion contracts

At desktop, landing uses broad photographic staging and admin uses a 208px sidebar, 56px location bar and 32px page gutters with aligned tables. At mobile, use 24px gutters, a compact header, stacked landing sections, and labelled report cards instead of squeezing table columns. At the working 768px reflow threshold, collapse navigation and reflow feature/evidence columns; do not scale the entire desktop canvas. Tablet/320px layouts and mobile case-review/menu states still need explicit design/implementation review.

Use a small photographic/product arrival and restrained hover/press feedback. Do not hide essential content behind animation or autoplay decoration. Reduce Motion presents content immediately and preserves feedback. Paper does not verify animation, keyboard interaction, screen-reader behavior, or browser performance.

## Reference and verification scope

Reviewed [Tarsi](https://www.tarsi.cloud/) for direct benefits and product demonstration, [Apple Mac](https://www.apple.com/ph/mac/) for product staging and hierarchy, and [Alta](https://www.altadaily.com/) for closet-led positioning. The existing AQD visual system takes precedence; no competitor copy, logo, or imagery was imported.

Canonical AQD Today and Closet boards were exported and embedded as static previews. Clothing photography reuses the sources in [Reference assets](../references/assets.md); these are composition references, not a cleared production asset library.

Rendered the authored sections and screens to inspect spacing, typography, contrast roles, alignment, and fit. Corrected stage clipping, a rejected account-table container, wide status pills, and a loading state that resembled an active button. Rechecked loaded imagery and early-access footer content. Static design evidence is recorded in [Verification](../delivery/verification.md); no working web flow or runtime accessibility claim is made.

## Compact admin patterns and module flow

October 2 refinement: page 01 **C02 · Admin density & table patterns** owns the compact desktop table contract. Use 38px column headers and 44px data rows, 16px horizontal row padding, 14/20px data text, 22px content-width status pills, 1px semantic dividers and an 8px table edge. Labelled admin buttons use 6px corners and retain 44px targets. Status/actions share a centered lane; fixed column widths are identical in headers and data rows. The large marketing controls remain separate from these admin controls.

The illustrative workspace has twelve open reports, three unassigned, four awaiting first review and eight resolved today. Overview previews six reports; the queue shows all twelve. Accounts shows twelve of 386 fixture accounts, audit ten events and jobs eight of 128 fixture operations. Account rows follow Joined descending; reports follow Received descending. Pagination/filter/search/sort controls are design states, not working browser behavior. No production data was inserted. Account enforcement history and reason-bound commands retain their original access limits.

Overview combines compact operational measures, its queue and a service summary. Analytics adds seven daily first-outfit values (7, 9, 8, 11, 12, 15, 14; total 76), while the existing activation milestones and unavailable retention state remain explicit. Do not invent missing monitoring providers or turn unknown signals into zero/healthy. The audit selection uses a compact reason summary and opens its case for detail; decision/retry forms still expose required review and reason content.

Canonical screens live on module pages. The V2 Flow page uses annotated snapshots exported from the reviewed canonical boards; those previews are not live linked components. Refresh them after a canonical visual change. The underlying module screens remain editable. The flow sequences describe intended authorization/receipt boundaries; they do not prove backend enforcement or an implemented end-to-end flow.

Research: [Linear's March 2026 refresh](https://linear.app/changelog/2026-03-12-ui-refresh) supports consistent headers, calmer navigation and a dimmer sidebar. [Attio navigation](https://attio.com/help/reference/attio-101/introduction-to-navigating-attio) separates the sidebar from the content/action panel and supplies search/commands. [Vercel's navigation update](https://vercel.com/changelog/dashboard-navigation-redesign-rollout) emphasizes consistent context and a hideable/resizable sidebar. [shadcn data tables](https://ui.shadcn.com/docs/components/base/data-table) supplies filtering, sorting, column visibility and pagination patterns. [HeroUI v2 tables](https://v2.heroui.com/docs/components/table) documents compactness, optional wrappers, row actions, sorting, loading/empty states, pagination and virtualization. AQD adopts the visual/interaction principles; no component-library or framework choice was made by this Paper pass.

## Product-first landing refinement · October 2, 2026

Refined L01 desktop, L03 mobile and L02 early access in place. The desktop hero combines a left-aligned 96/96px headline with the existing Today phone and one clothing photograph; one competing lifestyle image was removed. Explicit digital-closet/iPhone positioning and concrete owned-piece, outfit and planning copy replace abstract supporting claims. The first product feature alternates the composition, with Closet leading and explanatory copy trailing. Planning and Agent use unequal 684/492px panels, larger wardrobe images and an illustrative piece-to-look composition. The full-width Heritage-blue invitation supplies one deliberate color moment, with white text and an inverted white action.

Mobile retains 24px gutters, 48/50px display type and 44px actions. It now includes the canonical Closet preview, a piece-to-look illustration, a three-day wardrobe strip and two always-visible manual-use/privacy questions. The early-access page carries the same owned-wardrobe promise. Existing photography remains composition-reference material; the piece-to-look sequence is illustrative, not evidence that Agent generated the photographed outfit.

Studied [Linear](https://linear.app/) for a product-centered story, [Cursor](https://cursor.com/) for clear positioning, [Attio](https://attio.com/) for restrained editorial hierarchy, [Raycast](https://www.raycast.com/) for product demonstrations and [Cal.com](https://cal.com/) for showing the product alongside its promise. These are design interpretations of the references; AQD's light app palette and existing controls remain authoritative. No competitor imagery or text was imported.

This pass provides static product demonstrations. It does not add a live demo, animations, working links or email delivery. Implementation should keep content available without animation, preserve visible focus/labels, and verify responsive behavior and screen-reader navigation in the browser.

## Admin navigation and control consistency · October 2, 2026

The eleven desktop workspace headers use a separate muted 13/20px Workspace ancestor, a 14px chevron and a medium 14/20px current section. Keep the breadcrumb group centered in the 56px location bar; implementation uses a labelled breadcrumb navigation, links for ancestor destinations and `aria-current="page"` on the current destination. Decorative chevrons are hidden from assistive technology.

Admin actions, status selectors, filter controls and search share a fixed 44px height, 6px corners and 14/20px text. Center button content in both axes; use symmetric vertical insets rather than padding that determines the outer height. Filters use a separate 14px downward chevron in an 8px gap. Search uses the same neutral line border as adjacent filters, a 20px icon and leading-aligned text. Accounts now has the same 250px search field treatment as Reports. Editable review forms keep their existing stronger field boundary; focus remains a distinct visible outline. The shared C02 reference contains the breadcrumb and complete queue toolbar. Marketing controls retain their own larger pill pattern.

Applied the contract across 49 existing admin controls, desktop module screens, confirmation/access screens, mobile Reports and admin recovery states. Refreshed all fifteen V2 Flow snapshots from fourteen canonical screens. This is static Paper geometry; accessible input labelling, breadcrumb link semantics, focus/hover/disabled states and keyboard operation require browser implementation verification.

Secondary content actions use the shared plain regular-weight blue label treatment, with no white fill, border or shadow and at least a 44-point target. Fields, filters, navigation and grouped Settings surfaces retain their existing structures; primary actions remain prominent.
