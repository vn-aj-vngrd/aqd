# Decisions and unresolved gates

[Product definition](definition.md) owns confirmed structure; [feature specs](../features/README.md) own exact behavior. Distinguish owner decisions from the reviewable defaults below.

## Confirmed by the user

- A web admin app supports management, analytics, monitoring and controls; a public landing page supports launch. Detailed hosting, staff permissions and telemetry policies remain proposed in [web/admin architecture](../architecture/admin-web.md). This refinement remains documentation/design only.

- V1 includes all core product workflows, authentication and account lifecycle working end to end; extras are V2. [Release definition](v1-release.md) owns the checklist and gaps; this request is documentation only.

- V1 completes the wardrobe workflow first; virtual try-on/avatar previews and shopping wishlist/price alerts remain deferred. Refinement authorizes documentation and Paper design, not app implementation.

- Alta-inspired personal closet/styling plus a social-media-driven wardrobe is the combined product target. Digital closet and personal management are core value; individual social participation is optional, while community and Inbox are required V1 product surfaces.
- Home combines a personal dashboard with All and Following feeds. The first tab is labelled Today in the design.
- Navigation is Home, Closet, Agent, Inbox, Profile. Closet owns personal search and Planner; Today links to those capabilities.
- Normal flows support manual work and focused AI actions using the same capabilities as Agent.
- Agent covers style, clothing, weather, travel, and everyday planning, across product features.
- On-device AI remains the preferred V1 runtime; no provider switch is authorized by refinement.
- Inbox contains human chats; Profile handles social presence/account management.
- Calendar planning supports next two weeks, recurring office needs for three months, and travel events.
- Profile/settings separation remains required. The October 1 redesign uses premium photographic content, system typography, a restrained accent, and native Liquid Glass controls; [DESIGN.md](../../DESIGN.md) supersedes earlier monochrome and icon-only styling.

- Launch starts from zero users; 50,000 users is an illustrative scaling scenario, not initial traffic or an operating target.
- iOS launches first; Android remains outside the current release.
- Public launch includes landing/support/legal pages and a Facebook page. Architecture workshop material stays grouped under `docs/architecture/`.

## Working defaults proposed in this specification pass

These are concrete product recommendations, not retrospectively claimed user approvals. They can be revised during review; specifications consistently use them until changed.

| Choice | Default | Owner specification |
| --- | --- | --- |
| First use | Private capture without mandatory style quiz, avatar, or upload quota. | [W](../features/wardrobe.md) |
| First outfit | First-save receipt leads to category readiness and pinned-piece styling; Today adapts to actual pieces/outfits/plans. Manual composition stays available. | [V1 flow](../design/v1-flow.md), [W](../features/wardrobe.md), [O](../features/outfits-themes.md) |
| Item capture | Name/category required, one optional cover photo, optional details; manual classification always works. | [W](../features/wardrobe.md) |
| Lifecycle | Archive preserves references; deletion previews effects; future assignments become unassigned, historical snapshots remain. | [W](../features/wardrobe.md) |
| Themes | Independent collections; multiple memberships; case-insensitive name uniqueness. | [O](../features/outfits-themes.md) |
| Planner | Calendar dates in explicit plan timezone; resolved entries; inclusive ranges; all-or-nothing bulk save. | [P](../features/planning-history.md) |
| Wear | Same item set once per local day; different combinations allowed; prior estimates kept separate from recorded stats. | [P](../features/planning-history.md) |
| Publication | Explicit snapshots and curated public closet, not automatic exposure of future uploads. | [S](../features/discovery-publishing.md) |
| Feeds/follows | Chronological All, followed-creators Following, public profiles/direct follows; private-profile requests deferred. | [S](../features/discovery-publishing.md) |
| Inbox | One-to-one text/public references; first-contact requests when recipient does not follow sender; no activity tab yet. | [I](../features/inbox.md) |
| Agent | Reads/drafts directly; writes use version-bound review, validation, idempotency, and result receipts. | [A](../features/agent.md) |

## Gates before connected/capability-dependent implementation

Required V1 gates must resolve before launch; they are not optional missing features. Automatic photo classification/advanced tagging are V2. Working defaults added by the release definition: Apple plus verified email links, signed-in backup/sync/recovery, free launch pending pricing approval, and no remote push in V1. These are recommendations, not newly claimed user approvals.

| Gate | Decision/evidence needed | Blocks |
| --- | --- | --- |
| Identity/data service | Sign-in methods, ownership, sync conflict/recovery policy, local account association. | Connected U/S/I and production durability. |
| Media/publication | Storage, access/revocation, deletion/retention policy, supported publication media. | Public closets and safe sharing. |
| Moderation | Report/block operation, enforcement, abuse/rate limits, account/content deletion. | Social launch. |
| Messaging | Transport, retention, delete-for-self/everyone, notification policy, encryption claims. | Connected Inbox. |
| AI capability | Supported on-device image analysis, tools/current retrieval, realistic long-plan accuracy and physical-device latency. | Assisted tagging, weather reasoning, multi-month generation. |
| External weather | Permitted provider/retrieval, licensing, date coverage, user-selected location consent. | Production weather assistance. |
| Future virtual try-on | Separate scope approval, selected API/backend, upload consent and retention/deletion policy, supported garments, real-photo quality, latency and cost evidence. See [future exploration](../features/virtual-try-on.md). | Optional personal photo previews; outside the initial product. |

Private capture/manual composition can proceed once implementation is requested; these later gates do not justify inventing service configuration. Planned private attachments, group chats, chat-context access for Agent, external calendar sync, and notifications need their own later feature decisions.

## Architecture and commercial proposals

| Recommendation | Basis |
| --- | --- |
| Supabase Pro initially | Integrated backend and relational model reduce initial delivery/operations work. |
| Supabase Storage initially | Simpler access/lifecycle integration while photo demand is small. |
| Cloudflare Pages | Low-cost static landing/support pages. |
| Consider R2 when warranted | Photo bandwidth economics; allow migration through stable media references. |
| $414 baseline / $600 first-year reserve | Planning assumptions in [Costs](../architecture/costs.md); excludes development, ads, taxes and unpriced business work. |
| Freemium and $4.99/month or $49.99/year hypothesis | Needs user willingness-to-pay and capability validation; see [pricing hypotheses](../architecture/pricing-strategy.md). |
| Optional Instagram, ads and paid staging | Not requested as mandatory launch spending. |

The on-device AI preference and private first use without signup already come from the product specifications. The detailed offline/account-sync proposal has not received a separate answer in this conversation.


## Refined architecture proposal

The editable board now separates deployment, private write/sync sequence and publication/Inbox flows. The proposal adds a shared trusted command contract, commit-safe sync cursors, account-scoped operations, staged media finalization and durable message acknowledgments. A DB job worker handles retryable media/export/deletion work. Remote push remains V2. These are reviewable proposals, not implemented services or newly approved provider choices.

Admin hosting, staff roles/MFA, audit retention, analytics event policy and monitoring/alert provider remain open. See [web/admin design](../architecture/admin-web.md).


## Operating decisions before connected release

- Select services/region, domain/brand and the actual operating budget.
- Set account-scoped sync/recovery and tombstone retention; media limits/variants, cache revocation, deletion and backup retention.
- Set moderation enforcement, rate limits, messaging retention and accurate encryption claims through the service gates above.
- Set staff roles/MFA, audit retention, analytics event policy and monitoring/alert providers; review [web operations](../architecture/admin-web.md).
- Validate Agent quality/latency on physical devices, subscription value and entitlements before payments, and measurable reliability/performance goals before capacity claims.
