# AQD architecture

Updated October 2, 2026. Proposed architecture for collaboration, not deployed infrastructure or authorization to configure services. See the [system design index](README.md) and [decision register](../product/decisions.md). Product authority: [PRODUCT](../product/definition.md), [open decisions](../product/decisions.md), [design](../../DESIGN.md), and [feature contracts](../features/README.md).

Open the editable [Excalidraw board](aqd-system-design.excalidraw). The board now has four numbered views: **00 deployment**, **01 private writes / Agent / sync**, **02 publication / Inbox**, and **03 web admin / landing / operations**. Device, application-server, database and storage symbols derive from the generic items in the loaded Excalidraw Library; all elements remain editable. The old preview is retained as a historical workshop image, not the current diagram. Paper remains the visual authority for the app; this board describes system responsibilities.

## What we are designing

The private closet works without social participation. The complete V1 includes public discovery and human Inbox. The user confirmed that the first release includes the full V1. Private foundations can be implemented first as dependency order; a private-only milestone does not complete the release. Launch starts from zero users; 50,000 users is an illustrative future scenario, not expected launch traffic. Target destinations: Home, Closet, Agent, Inbox, Profile.

This checkout contains product/design/tooling documents, but the iOS source paths described in docs/delivery/implementation-status.md are absent. Historical prototype notes therefore cannot establish current source behavior. No infrastructure was created in this workshop.

## Small starting architecture

- One native iOS app with shared domain operations behind manual controls and approved Agent proposals.
- Durable local records and separate media files. Optional account association must preview what is backed up; it never publishes records automatically.
- A separate public landing/support/legal site and a restricted web admin app for management, analytics, monitoring and controls. See [web/admin responsibilities](admin-web.md).
- One backend application with logical identity, wardrobe, planning/history, publication/social, Inbox and moderation boundaries. These do not require separate deployed services.
- PostgreSQL for relational records, revisions, operation receipts and initial durable background work.
- Object storage for media with separate private originals and explicitly published derivatives. Store references and access metadata in the database.
- One worker when slow or retryable jobs become necessary. Start with database jobs/outbox; adopt a managed queue when workload or operations justify it.
- Preferred on-device Foundation Models with named deterministic Quick rules fallback. Cloud AI and weather retrieval are separately gated capabilities.

Recommended starting deployment: Supabase Pro for Auth/PostgreSQL/Storage/Realtime and narrow server-side commands, with Cloudflare Pages for static landing and support pages. This is a recommendation used for budgeting, not a confirmed service selection. R2 is a later media option. The logical backend boundary can be implemented with Supabase-backed operations; it does not require a second always-on API server. See [costs](costs.md) and [scalability](scalability.md).


## Concrete responsibility and write boundaries

The app has one domain-command layer for manual actions and approved Agent proposals. Local private commands validate owned references and commit records plus pending operations atomically. Connected commands revalidate identity and permissions on the server; client checks never grant cloud access. Agent output remains a draft until reviewed, and its receipt refers to the same trusted operation used by manual controls.

| Boundary | Starting mapping (proposed) | Contract |
| --- | --- | --- |
| Identity | Supabase Auth | Authenticated session identifies the principal; ownership and participant checks remain separate. No service secret in the app. |
| Authorized reads | Supabase Data API / database functions | Owner-scoped private data, explicitly visible publications, participant-scoped messages; grants and RLS protect exposed tables and views. |
| Domain writes | Narrow database functions; Edge Functions where external coordination is needed | Validate payload and relationships, enforce policy, check revisions and deduplicate operation IDs. Commit records, receipt, change entries and any job atomically. One logical backend, no extra always-on API. |
| Durable records | PostgreSQL | Private wardrobe, planning and wear, explicit public snapshots, social relationships, human conversations, revisions, receipts and jobs. |
| Media | Supabase Storage | Private originals and staging; scoped uploads; ready publication variants. Stable media IDs resolve provider paths and access policy. |
| Background work | DB jobs + one bounded worker execution path | Leased claims, retry limits, idempotent processing, failed-job visibility; media processing, export, deletion and orphan cleanup. Runtime/scheduler selection remains open. |
| Live updates | Supabase Realtime | Hint to refetch durable authorized data. Reconnect resumes from cursors; polling/refetch is the fallback. |
| Public web | Cloudflare Pages | Static product/landing/support/legal pages, App Store links; independent deployment. |
| Staff admin | Separate static web build + narrow server endpoints | Invite-only MFA, current role checks, scoped projections, audited moderation/configuration/job commands. Same backend; no browser service secrets. |
| Analytics / monitoring | PostgreSQL daily aggregates + selected provider tools | Bounded product events separated from service telemetry; sanitized summaries and independent operator alerts. |

Supabase documents [RLS and grants](https://supabase.com/docs/guides/database/postgres/row-level-security), [Storage access controls](https://supabase.com/docs/guides/storage/security/access-control) and [Postgres Changes](https://supabase.com/docs/guides/realtime/postgres-changes). These support the service mapping; the AQD ownership and write contracts above are our design proposal. Do not expose unrestricted writes that bypass the command contract. Privileged jobs need their own explicit scope because service credentials can bypass RLS.

## Sync and recovery contract to settle

- Scope each operation and cache to the associated account. Guest data remains device-local until a reviewed association succeeds; sign-in never publishes it.
- Commit the local change and pending operation together. Each operation carries a stable ID, payload hash and expected entity revision; reuse with a different payload is rejected. Replay returns the existing receipt.
- Assign server changes a cursor that does not skip commits. A plain transaction-time sequence is insufficient when transactions commit out of order; choose a commit-safe cursor implementation before coding. Pull only authorized changes and deletion tombstones, apply them atomically, then advance the local cursor.
- Reject stale outfit membership and bulk-plan writes; preserve the draft for review. Keep optimistic local state marked pending until the server confirms it, or shows a conflict/failure. A stale Agent approval must be reviewed again.
- Keep media upload status separate from record sync. Recovery waits for required media acknowledgment. Clean orphaned uploads through a bounded job; do not promise cross-store atomicity.
- Define receipt/tombstone retention and the maximum supported offline interval together. A cursor older than retention requires full reconciliation, preventing resurrection of deleted records.

## Publication and messaging correctness

Publishing freezes the reviewed fields and source versions, prepares media in private staging, then rechecks ownership and readiness before committing the visible public snapshot. Storage and PostgreSQL do not share a transaction: failed finalization leaves a retryable draft, never a partially visible post. Public media access/URL expiry must support the chosen unpublish policy; a permanently public bucket cannot promise immediate revocation. Private edits require a new publish action.

Inbox sends use a stable client message ID with a unique conversation/sender key and a durable acknowledgment. Participant, block, rate and request checks run in the same trusted transaction as the send. Concurrent first-contact sends must serialize against the request/conversation record so the one-message rule is enforced. Unknown outcomes reconcile by ID; “read” requires the recipient's acknowledged cursor. Shared wardrobe references are checked again when opened. V1 has in-app unread, with remote push deferred.

## Operating requirements for full V1

The confirmed web admin app provides the restricted operating path to review reports, manage accounts, inspect aggregate analytics and job/service health, and adjust bounded controls. Its proposed authorization, auditing and observability contracts are in [ADMIN-WEB](admin-web.md). Deletion first denies account/public access under the chosen policy, then durable jobs process owned records and media; backup retention and remaining conversation history must be disclosed. Define fresh session checks for sensitive actions rather than assuming that deleting an Auth user instantly invalidates every token.

Before release, verify auth delivery and account association, owner/participant access denials, duplicate retries, stale revisions, reconnect/full reconciliation, interrupted uploads, publication revocation, concurrent message requests, export/deletion jobs and a backup restore. Measure list/image/query latency, job age and sync errors without logging photos or message bodies. Agree numeric targets on an actual workload before making a capacity claim.

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

1. **Capture and save:** selected photo → normalized local media → validated local record and restart recovery. Once signed-in backup is enabled, show a separate pending/synced/failed state; local save alone never implies cloud recovery.
2. **Agent creation:** authorized bounded context → structured draft → user edits/review → current revision validation → same save operation as manual creation → receipt. Unknown completion is reconciled by operation ID; stopping generation does not roll back an already committed save.
3. **Publish:** review selected owned pieces and public fields → prepare media derivatives → validate access and readiness → commit publication snapshot. A post becomes visible only when required media and publication checks pass. Private edits do not silently update the public snapshot. Unpublish denies new access; cached copies and already downloaded content cannot be promised erased instantly.
4. **Send message:** check participants/block/request policy → persist one stable message ID → acknowledge as sent → hint to connected participants. V1 unread is in-app; remote push and notification permissions are V2. Realtime is a hint to fetch authorized durable state, not proof of delivery. Shared post references are rechecked when opened.

## Offline and sync proposal — requires a decision

Manual private work remains available offline. Connected social actions require server acknowledgment. For signed-in private backup, keep pending operations locally, send stable operation IDs with expected revisions, and pull changes using a server cursor. Server authorization determines connected ownership; device clocks do not decide winners.

Proposed first conflict policy: reject a stale update, retain the local draft, and let the user reload or review a merge. Avoid silent last-write-wins for outfit memberships and bulk plans. Deletions need tombstones so offline clients cannot resurrect removed records. Sign-out/account switching must isolate cached records and pending operations.

Signed-in sync/reinstall recovery is a V1 release requirement, while the detailed reconciliation policy remains proposed. Before releasing it, settle conflict UI, media upload recovery, local-account association, tombstone retention and backup/export recovery. Persistence implementation is not chosen by this board.

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

The refined board traces deployment, private writes/sync, publication and messaging. Next, review the unresolved policies and select the concrete service mapping; keep those choices marked as proposals until approved.
