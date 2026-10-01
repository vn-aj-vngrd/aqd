# Decisions and unresolved gates

[PRODUCT.md](PRODUCT.md) owns confirmed structure; [feature specs](features/README.md) own exact behavior. Distinguish owner decisions from the reviewable defaults below.

## Confirmed by the user

- V1 includes all core product workflows, authentication and account lifecycle working end to end; extras are V2. [Release definition](V1-RELEASE.md) owns the checklist and gaps; this request is documentation only.

- V1 completes the wardrobe workflow first; virtual try-on/avatar previews and shopping wishlist/price alerts remain deferred. Refinement authorizes documentation and Paper design, not app implementation.

- Alta-inspired personal closet/styling plus a social-media-driven wardrobe is the combined product target. Digital closet and personal management are core value; individual social participation is optional, while community and Inbox are required V1 product surfaces.
- Home combines a personal dashboard with All and Following feeds. The first tab is labelled Today in the design.
- Navigation is Home, Closet, Agent, Inbox, Profile. Closet owns personal search and Planner; Today links to those capabilities.
- Normal flows support manual work and focused AI actions using the same capabilities as Agent.
- Agent covers style, clothing, weather, travel, and everyday planning, across product features.
- On-device AI remains the preferred V1 runtime; no provider switch is authorized by refinement.
- Inbox contains human chats; Profile handles social presence/account management.
- Calendar planning supports next two weeks, recurring office needs for three months, and travel events.
- Profile/settings separation remains required. The October 1 redesign uses premium photographic content, system typography, a restrained accent, and native Liquid Glass controls; [DESIGN.md](../DESIGN.md) supersedes earlier monochrome and icon-only styling.

## Working defaults proposed in this specification pass

These are concrete product recommendations, not retrospectively claimed user approvals. They can be revised during review; specifications consistently use them until changed.

| Choice | Default | Owner specification |
| --- | --- | --- |
| First use | Private capture without mandatory style quiz, avatar, or upload quota. | [W](features/WARDROBE.md) |
| First outfit | First-save receipt leads to category readiness and pinned-piece styling; Today adapts to actual pieces/outfits/plans. Manual composition stays available. | [V1 flow](design/V1-FLOW.md), [W](features/WARDROBE.md), [O](features/OUTFITS-THEMES.md) |
| Item capture | Name/category required, one optional cover photo, optional details; manual classification always works. | [W](features/WARDROBE.md) |
| Lifecycle | Archive preserves references; deletion previews effects; future assignments become unassigned, historical snapshots remain. | [W](features/WARDROBE.md) |
| Themes | Independent collections; multiple memberships; case-insensitive name uniqueness. | [O](features/OUTFITS-THEMES.md) |
| Planner | Calendar dates in explicit plan timezone; resolved entries; inclusive ranges; all-or-nothing bulk save. | [P](features/PLANNING-HISTORY.md) |
| Wear | Same item set once per local day; different combinations allowed; prior estimates kept separate from recorded stats. | [P](features/PLANNING-HISTORY.md) |
| Publication | Explicit snapshots and curated public closet, not automatic exposure of future uploads. | [S](features/DISCOVERY-PUBLISHING.md) |
| Feeds/follows | Chronological All, followed-creators Following, public profiles/direct follows; private-profile requests deferred. | [S](features/DISCOVERY-PUBLISHING.md) |
| Inbox | One-to-one text/public references; first-contact requests when recipient does not follow sender; no activity tab yet. | [I](features/INBOX.md) |
| Agent | Reads/drafts directly; writes use version-bound review, validation, idempotency, and result receipts. | [A](features/AGENT.md) |

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
| Future virtual try-on | Separate scope approval, selected API/backend, upload consent and retention/deletion policy, supported garments, real-photo quality, latency and cost evidence. See [future exploration](features/VIRTUAL-TRY-ON.md). | Optional personal photo previews; outside the initial product. |

Private capture/manual composition can proceed once implementation is requested; these later gates do not justify inventing service configuration. Planned private attachments, group chats, chat-context access for Agent, external calendar sync, and notifications need their own later feature decisions.
