# Feature specifications by phase

[V1 release](../product/v1-release.md) owns the small local MVP and LOCAL checks. Feature contracts own behavior and retain the complete vision; phase releases own inclusion and acceptance aggregation. For V1 work read the affected shared/private contract and dependencies, not unrelated V2 extension sections. Read connected sections only for connected behavior or migration seams; full-contract acceptance audits must cover all applicable IDs. Do not apply every broad feature acceptance ID to V1. [V2 core release](../product/v2-release.md) owns connected-core acceptance; [V2 backlog](../product/v2-backlog.md) owns all enhancements and [V2 designs](../design/v2-requirements.md) prepare their UX requirements.

| ID | Feature | V1 | V2 |
| --- | --- | --- | --- |
| W | [Wardrobe](wardrobe.md) | Local manual single-photo capture, search/edit/archive/lifecycle | Full capture/visual automation/inspiration/connected data |
| O | [Outfits and themes](outfits-themes.md) | Complete local outfits/favorites/themes and focused assistance | Themes, rich styling and publication |
| P | [Planning and history](planning-history.md) | Complete local plans/routines/trips/packing and wear/history/insights; optional basic native WeatherKit | Inherit basic weather; advanced providers/context, bulk plans, routines/events/trips/packing and richer insights |
| A | [Agent](agent.md) | Complete local Agent/chat/history and reviewed private actions; explicit fresh WeatherKit context, independent weather availability | Full conversation/actions/tools/rich input/history/feedback |
| T | [Today customization](today.md) | Twelve private in-app widgets and personal notes/photos, minimum one, durable drafts/atomic layout | Inherit private configuration; optional existing connected feed scope |
| S | [Discovery and publishing](discovery-publishing.md) | Private Today, optional sourced native WeatherKit context | Feeds/publication/social search/follows/comments/inspiration |
| U | [Profile and account](profile-account.md) | Local Profile/preferences and complete Settings | Profile/auth/association/sync/recovery/account lifecycle |
| I | [Inbox](inbox.md) | Absent | Human chats, requests, delivery/access and richer messaging |
| Future | [Virtual try-on](virtual-try-on.md) | Absent | Capability-gated private appearance previews; no fit prediction |

[V1 flow](../design/v1-flow.md) and [V2 flow](../design/v2-flow.md) map separate Paper journeys. Terms live in [CONTEXT.md](../../CONTEXT.md); [decisions](../product/decisions.md) distinguishes scope from proposals. Acceptance IDs are target checks, never passing test evidence.
