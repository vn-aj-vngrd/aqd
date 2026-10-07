# AQD architecture by phase

Updated October 5, 2026. These are planning contracts, not implemented infrastructure. The owner replaced the earlier connected V1 plan with a local private MVP; that connected architecture is retained as V2.

| Boundary | V1: device-only MVP | V2: complete product |
| --- | --- | --- |
| Client | Native iPhone Home / Closet / Planner / Agent / local Profile, full Settings; dedicated Planner and private fit journal | Same five roots; persistent Inbox root-toolbar entry, explicit connected extensions; additional clients later |
| Authority | Local versioned records and protected media | Local private work plus authenticated backend authority for connected records |
| Identity | Local Profile/preferences; no online account/signup | Account/auth/profile, reviewed local association, session/account isolation |
| Sync | None; explicit local archive export/restore | Account-scoped operations, revisions/cursors/conflicts/tombstones, media sync and restore |
| Assistance | Complete local Agent/history and reviewed private actions; on-device/rules/manual paths | Full Agent, richer context/tools, optional consented cloud features after capability gates |
| Weather/network | Optional direct native Apple WeatherKit + online Apple city lookup; off until chosen, independent of AI, offline manual core | Inherit V1 basics; advanced external providers/context, calendar, alerts and notifications remain gated |
| Social/messages | Absent from navigation, data model and actions | Curated publications, feeds/follows/comments, requests and reliable participant Inbox |
| Infrastructure | No app server/database/storage/queue or telemetry service | One modular backend, PostgreSQL, authorized object storage, realtime hints, jobs/worker and safety operations |
| Costs | No required recurring AQD backend cost; Developer Program/shared WeatherKit allowance and potential paid capacity | Provider, media, email, monitoring, moderation, push and optional AI costs |

Read [V1 architecture](v1.md) for local persistence/privacy/recovery and Apple limitations. Read [V2 architecture](v2.md) for trusted writes, complete connected infrastructure, sync and operational gates. [V2 backlog](../product/v2-backlog.md) owns extensions and [design requirements](../design/v2-requirements.md) maps prepared flows.

The editable [Excalidraw board](aqd-system-design.excalidraw) separates a new **V1 device-only** view from the four retained **V2** workshop views: deployment, private writes/Agent/sync, publication/Inbox, web/admin/operations. The [old PNG preview](aqd-system-design-preview.png) is historical and does not represent current scope. Paper remains the authority for product UI.

[Decisions](../product/decisions.md) distinguishes confirmed scope from provider/persistence proposals. [Implementation status](../delivery/implementation-status.md) and [verification](../delivery/verification.md) own actual evidence. No service was purchased/configured and no feature code was added.
