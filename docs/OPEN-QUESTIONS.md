# Decisions and unresolved gates

[PRODUCT.md](PRODUCT.md) owns confirmed structure; [feature specs](features/README.md) own exact behavior. Distinguish owner decisions from the reviewable defaults below.

## Confirmed by the user

- Alta-inspired personal closet/styling plus a social-media-driven wardrobe is the combined product target. Digital closet and personal management are core value; individual social participation is optional, while community and Inbox are required V1 product surfaces.
- Home is All / Following community feeds with discovery search.
- Navigation is Home, Closet, Agent, Inbox, Profile. Personal search/Planner live in Closet.
- Normal flows support manual work and focused AI actions using the same capabilities as Agent.
- Agent covers style, clothing, weather, travel, and everyday planning, across product features.
- On-device AI remains the preferred V1 runtime; no provider switch is authorized by refinement.
- Inbox contains human chats; Profile handles social presence/account management.
- Calendar planning supports next two weeks, recurring office needs for three months, and travel events.
- Profile/settings separation, monochrome native visual direction, icon-only glass navigation, and active icons remain design requirements.

## Working defaults proposed in this specification pass

These are concrete product recommendations, not retrospectively claimed user approvals. They can be revised during review; specifications consistently use them until changed.

| Choice | Default | Owner specification |
| --- | --- | --- |
| First use | Private capture without mandatory style quiz, avatar, or upload quota. | [W](features/WARDROBE.md) |
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

| Gate | Decision/evidence needed | Blocks |
| --- | --- | --- |
| Identity/data service | Sign-in methods, ownership, sync conflict/recovery policy, local account association. | Connected U/S/I and production durability. |
| Media/publication | Storage, access/revocation, deletion/retention policy, supported publication media. | Public closets and safe sharing. |
| Moderation | Report/block operation, enforcement, abuse/rate limits, account/content deletion. | Social launch. |
| Messaging | Transport, retention, delete-for-self/everyone, notification policy, encryption claims. | Connected Inbox. |
| AI capability | Supported on-device image analysis, tools/current retrieval, realistic long-plan accuracy and physical-device latency. | Assisted tagging, weather reasoning, multi-month generation. |
| External weather | Permitted provider/retrieval, licensing, date coverage, user-selected location consent. | Production weather assistance. |

Private capture/manual composition can proceed once implementation is requested; these later gates do not justify inventing service configuration. Planned private attachments, group chats, chat-context access for Agent, external calendar sync, and notifications need their own later feature decisions.
