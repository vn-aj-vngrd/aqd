# Feature specifications

Read the relevant feature before implementing or reviewing that module. [PRODUCT.md](../PRODUCT.md) owns product positioning and navigation; these files own detailed behavior and acceptance. [Implementation plan](../IMPLEMENTATION-PLAN.md) owns delivery order and readiness. [CONTEXT.md](../../CONTEXT.md) owns terms.

| ID | Feature | Read when working on |
| --- | --- | --- |
| W | [Wardrobe](WARDROBE.md) | First use, capture, classification, item lifecycle, inventory search. |
| O | [Outfits and themes](OUTFITS-THEMES.md) | Composition, saved looks, collections, piece replacement. |
| P | [Planning and history](PLANNING-HISTORY.md) | Calendar, events, routines, packing, actual wear, stats. |
| S | [Discovery and publishing](DISCOVERY-PUBLISHING.md) | Home, search, feeds, posts, follows, inspiration, publication access. |
| U | [Profile and account](PROFILE-ACCOUNT.md) | Social identity, public closet, settings, onboarding identity, data lifecycle. |
| I | [Inbox](INBOX.md) | Human chats, requests, delivery, shared references, activity. |
| A | [Agent](AGENT.md) | Focused AI actions, conversation, tools, approval, model limits, evaluations. |

Each acceptance ID is local to its feature and is a target check, not a passing test. Product-owner decisions are distinguished from working defaults in [Decisions](../OPEN-QUESTIONS.md). External-service choices stay unresolved until selected; do not infer a production backend from prototype code.
