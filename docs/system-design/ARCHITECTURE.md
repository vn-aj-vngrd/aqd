# AQD architecture

Updated October 1, 2026. Proposed architecture for collaboration, not deployed infrastructure or authorization to configure services. See the [system design index](README.md) and [decision register](DECISIONS.md). Product authority: [PRODUCT](../PRODUCT.md), [open decisions](../OPEN-QUESTIONS.md), [design](../../DESIGN.md), and [feature contracts](../features/README.md).

Open the editable [Excalidraw board](aqd-system-design.excalidraw). The preview is the original workshop browser screenshot; its unanswered milestone question predates the decision to include the full V1. It is not implementation evidence. Paper remains the visual authority for the app; this board describes system responsibilities.

## What we are designing

The private closet works without social participation. The complete V1 includes public discovery and human Inbox. The user confirmed that the first release includes the full V1. Private foundations can be implemented first as dependency order; a private-only milestone does not complete the release. Launch starts from zero users; 50,000 users is an illustrative future scenario, not expected launch traffic. Target destinations: Home, Closet, Agent, Inbox, Profile.

This checkout contains product/design/tooling documents, but the iOS source paths described in IMPLEMENTATION.md are absent. Historical prototype notes therefore cannot establish current source behavior. No infrastructure was created in this workshop.

## Small starting architecture

- One native iOS app with shared domain operations behind manual controls and approved Agent proposals.
- Durable local records and separate media files. Optional account association must preview what is backed up; it never publishes records automatically.
- One backend application with logical identity, wardrobe, planning/history, publication/social, Inbox and moderation boundaries. These do not require separate deployed services.
- PostgreSQL for relational records, revisions, operation receipts and initial durable background work.
- Object storage for media with separate private originals and explicitly published derivatives. Store references and access metadata in the database.
- One worker when slow or retryable jobs become necessary. Start with database jobs/outbox; adopt a managed queue when workload or operations justify it.
- Preferred on-device Foundation Models with named deterministic Quick rules fallback. Cloud AI and weather retrieval are separately gated capabilities.

Recommended starting deployment: Supabase Pro for Auth/PostgreSQL/Storage/Realtime and narrow server-side commands, with Cloudflare Pages for static landing and support pages. This is a recommendation used for budgeting, not a confirmed service selection. R2 is a later media option. The logical backend boundary can be implemented with Supabase-backed operations; it does not require a second always-on API server. See [costs](COSTS.md) and [scalability](SCALABILITY.md).

## Screens imply data and access boundaries

| Design surface | System requirement |
| --- | --- |
| Today dashboard | Owner-scoped plans and calculated wear statistics; retain useful cached content. |
| Closet / Planner | Same owned pieces, outfits, themes and dated entries; manual saves and atomic bulk plan changes. |
| All / Following | Only accessible published snapshots; stable cursor pagination and real counts. |
| Public Profile | Curated published memberships; no private totals or automatic exposure of new pieces. |
| Agent review / receipt | Structured versioned proposals; trusted ID, permission and revision validation; idempotent execution. |
| Inbox Chats / Requests | Participant authorization, one first-contact message until acceptance, retry-safe IDs and server acknowledgment. |
| Sign-in / account association | Stable ownership, explicit migration, account-scoped cache and sign-out behavior. |

## Minimum domain records

Private: wardrobe items and media references; outfits and outfit-item memberships; themes and theme-outfit memberships; events/routines/plans/dated entries; wear records and historical item snapshots; preferences.

Connected: users/profiles; public posts, selected public pieces and memberships; follows, reactions, bookmarks and comments; blocks/reports; pair-unique conversations, requests, messages and acknowledged read cursors.

Reliability: entity revisions, idempotency receipts, media processing status, deletion tombstones and durable jobs. Add Agent proposal/history/feedback persistence only as required by the agreed Agent lifecycle; keep it separate from human messages.

Stable identifiers survive account association. Calendar intent uses a local date plus explicit plan timezone. Recording wear is a separate action from reaching the scheduled date. Historical records preserve their original context when current items change.

## Four flows to validate before choosing services

1. **Capture and save:** selected photo → normalized local media → validated local record and restart recovery. If optional backup is enabled, show a separate pending/synced/failed state; local save alone never implies cloud recovery.
2. **Agent creation:** authorized bounded context → structured draft → user edits/review → current revision validation → same save operation as manual creation → receipt. Unknown completion is reconciled by operation ID; stopping generation does not roll back an already committed save.
3. **Publish:** review selected owned pieces and public fields → prepare media derivatives → validate access and readiness → commit publication snapshot. A post becomes visible only when required media and publication checks pass. Private edits do not silently update the public snapshot. Unpublish denies new access; cached copies and already downloaded content cannot be promised erased instantly.
4. **Send message:** check participants/block/request policy → persist one stable message ID → acknowledge as sent → notify in background. Realtime/push is a hint to fetch authorized durable state, not proof of delivery. Shared post references are rechecked when opened.

## Offline and sync proposal — requires a decision

Manual private work remains available offline. Connected social actions require server acknowledgment. For opted-in private backup, keep pending operations locally, send stable operation IDs with expected revisions, and pull changes using a server cursor. Server authorization determines connected ownership; device clocks do not decide winners.

Proposed first conflict policy: reject a stale update, retain the local draft, and let the user reload or review a merge. Avoid silent last-write-wins for outfit memberships and bulk plans. Deletions need tombstones so offline clients cannot resurrect removed records. Sign-out/account switching must isolate cached records and pending operations.

Before promising multi-device sync, settle conflict UI, media upload recovery, local-account association, tombstone retention and backup/export recovery. Persistence implementation is not chosen by this board.

## Background work and growth

Keep ordinary domain saves, follows and message acknowledgments synchronous. Save a follow-up job in the same transaction when a committed change requires processing. Consumers use stable job IDs, bounded retries, leases/timeouts and a visible failed state. Media processing can have its own staged job before publication becomes visible.

The transactional outbox addresses the gap between committing a database change and scheduling its side effect. See [AWS primary guidance](https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/transactional-outbox.html); the pattern does not require choosing AWS.

Start feeds with chronological cursor queries, bounded pages and indexes based on actual ownership/date access paths. See [PostgreSQL index documentation](https://www.postgresql.org/docs/current/indexes.html). Use appropriately sized image variants and controlled caching. Cache policy must match publication revocation; public URLs are not suitable for private originals.

Measure API tail latency/error rates, slow queries, media bytes/storage growth, job age/retries and sync conflicts. Default telemetry excludes photos, notes and chat bodies. Scale API replicas and worker concurrency first. Add a dedicated queue, cache, search system, feed fan-out or service split only for an observed workload or operational need. No vector database or distributed event platform is needed by the confirmed starting requirements.

Traffic, active users, pieces/photos per user, photo sizes, retention, messages/day and operating budget remain unknown; capacity estimates and cost comparisons follow those inputs. Reliability targets also need agreement rather than invented numbers.

## Decisions for our next iteration

1. Confirm actual service selection and sign-in methods. First-release scope is already confirmed: full V1, including social and Inbox.
2. Offline private work with optional sync, or a different account/cloud model? Private first use without signup is the current specification.
3. Identity/backend/storage choice after evaluating these requirements.
4. Sync conflict and recovery policy; media revocation/deletion; messaging retention, encryption claims and moderation operations.
5. Supported on-device Agent capabilities and physical-device quality evidence; weather source and consent if included.

Next board: trace capture → outfit → plan → wear → publish → discover → message, then derive a compact data model and service comparison. Keep unresolved choices marked as proposals until reviewed.
