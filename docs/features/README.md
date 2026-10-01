# Feature specifications

[V1 release definition](../product/v1-release.md) owns mandatory release scope and cross-feature acceptance. [V2 backlog](../product/v2-backlog.md) owns enhancements outside launch; broad feature/design contracts must be read within that boundary.

Read the relevant feature before implementing or reviewing that module. [Product definition](../product/definition.md) owns product positioning and navigation; these files own detailed behavior and acceptance. [Implementation plan](../delivery/implementation-plan.md) owns delivery order and readiness. [CONTEXT.md](../../CONTEXT.md) owns terms.

| ID | Feature | Read when working on |
| --- | --- | --- |
| W | [Wardrobe](wardrobe.md) | First use, capture, classification, item lifecycle, inventory search. |
| O | [Outfits and themes](outfits-themes.md) | Composition, saved looks, collections, piece replacement. |
| P | [Planning and history](planning-history.md) | Calendar, events, routines, packing, actual wear, stats. |
| S | [Discovery and publishing](discovery-publishing.md) | Home Today dashboard, scoped search, feeds, posts, follows, inspiration, publication access. |
| U | [Profile and account](profile-account.md) | Social identity, public closet, settings, onboarding identity, data lifecycle. |
| I | [Inbox](inbox.md) | Human chats, requests, delivery, shared references, activity. |
| A | [Agent](agent.md) | Focused AI actions, conversation, tools, approval, model limits, evaluations. |

[V1 flow review](../design/v1-flow.md) connects first capture, category readiness, outfit creation, planning/wear and optional social/auth journeys. Try-on and shopping remain deferred.

Each acceptance ID is local to its feature and is a target check, not a passing test. Product-owner decisions are distinguished from working defaults in [Decisions](../product/decisions.md). External-service choices stay unresolved until selected; do not infer a production backend from prototype code.

## Future exploration

- [Personal virtual try-on](virtual-try-on.md): optional private full-body photo previews using a potential external API; proposed scope, privacy, cost, and quality gates. Outside the initial product; no implementation or provider selected.
