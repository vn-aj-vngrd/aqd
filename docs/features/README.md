# Feature specifications

[V1 release definition](../V1-RELEASE.md) owns mandatory release scope and cross-feature acceptance. [V2 backlog](../V2-BACKLOG.md) owns enhancements outside launch; broad feature/design contracts must be read within that boundary.

Read the relevant feature before implementing or reviewing that module. [PRODUCT.md](../PRODUCT.md) owns product positioning and navigation; these files own detailed behavior and acceptance. [Implementation plan](../IMPLEMENTATION-PLAN.md) owns delivery order and readiness. [CONTEXT.md](../../CONTEXT.md) owns terms.

| ID | Feature | Read when working on |
| --- | --- | --- |
| W | [Wardrobe](WARDROBE.md) | First use, capture, classification, item lifecycle, inventory search. |
| O | [Outfits and themes](OUTFITS-THEMES.md) | Composition, saved looks, collections, piece replacement. |
| P | [Planning and history](PLANNING-HISTORY.md) | Calendar, events, routines, packing, actual wear, stats. |
| S | [Discovery and publishing](DISCOVERY-PUBLISHING.md) | Home Today dashboard, scoped search, feeds, posts, follows, inspiration, publication access. |
| U | [Profile and account](PROFILE-ACCOUNT.md) | Social identity, public closet, settings, onboarding identity, data lifecycle. |
| I | [Inbox](INBOX.md) | Human chats, requests, delivery, shared references, activity. |
| A | [Agent](AGENT.md) | Focused AI actions, conversation, tools, approval, model limits, evaluations. |

[V1 flow review](../design/V1-FLOW.md) connects first capture, category readiness, outfit creation, planning/wear and optional social/auth journeys. Try-on and shopping remain deferred.

Each acceptance ID is local to its feature and is a target check, not a passing test. Product-owner decisions are distinguished from working defaults in [Decisions](../OPEN-QUESTIONS.md). External-service choices stay unresolved until selected; do not infer a production backend from prototype code.

## Future exploration

- [Personal virtual try-on](VIRTUAL-TRY-ON.md): optional private full-body photo previews using a potential external API; proposed scope, privacy, cost, and quality gates. Outside the initial product; no implementation or provider selected.
