# Scalability and media migration

Updated October 1, 2026. Launch begins with zero users. Design efficient access paths now and buy capacity as observed activity grows. User count alone is not a capacity model.

## What drives capacity

Distinguish registered users, monthly active users, simultaneous sessions and requests per second. Measure pieces/photos per user, stored originals/variants, image reads and bytes, feed query latency, message volume, realtime fan-out/concurrency, database growth, job backlog, and sync conflicts.

Start with bounded queries and cursor pagination, indexes matching ownership/date lookups, compressed appropriately sized images, account-scoped caching, idempotent writes and authorization on every connected operation. Do not add microservices, distributed event infrastructure or a separate search platform solely for a hypothetical 50k users.

| Observed issue | First response |
| --- | --- |
| Slow database queries | Inspect query plans/indexes and reduce returned rows/joins; then evaluate compute. |
| Large photo traffic | Serve thumbnails/cache appropriately; compare R2 economics. |
| API/runtime saturation | Profile operations, reduce unnecessary work and scale the selected runtime. |
| Growing job age/retries | Fix failures; increase worker capacity or introduce an external queue when warranted. |
| Realtime cost/fan-out | Narrow subscriptions to relevant conversations/scopes; distinguish updates from persisted messages. |
| Search/feed bottleneck | Optimize actual SQL paths before considering dedicated search or feed fan-out. |

## Illustrative 50,000-MAU scenario

This is an example, not a launch forecast or load-tested configuration. Approximate decimal storage units are used for planning; provider billing units/rounding may differ.

| Assumption / derived usage | Value |
| --- | ---: |
| Monthly active users | 50,000 |
| Photos per user | 100 |
| Average stored photo | 300 KB |
| Photo count | 5 million |
| Stored photos | ~1,500 GB |
| Active days per month | 10 per user |
| Thumbnails viewed per active day | 50 per user |
| Image requests per month | 25 million |
| Average served thumbnail | 150 KB |
| Image bandwidth | ~3,750 GB/month |

Assuming R2 Standard storage, full-month steady storage, all image reads reaching R2 and the free allowances available to this workload:

| Component | Illustrative monthly amount |
| --- | ---: |
| Supabase Pro + Large compute: $25 + $110 − $10 credit | $125 |
| R2 storage: (1,500 − 10) GB × $0.015 | ~$22.35 |
| R2 reads: (25 − 10) million × $0.36 | ~$5.40 |
| **Selected-component subtotal** | **~$152.75** |

This subtotal omits upload/write operations, additional originals/thumbnails, image processing, database disk/egress, realtime overages, staging, email, monitoring, other workers and taxes. Cache hits can reduce origin reads. Large compute is merely a priced example; only load tests establish whether it meets AQD's actual query/message workload.

The earlier $200–$500/month discussion was a provisional planning range for this imagined activity, not a verified total or ceiling. Actual costs can exceed it. Supabase's included 100k auth MAUs is a billing allowance, not a throughput guarantee.

Rates: [Supabase pricing](https://supabase.com/pricing), [R2 pricing](https://developers.cloudflare.com/r2/pricing/). Recheck before selecting capacity.

## Prepare for a storage migration

Store stable media IDs, object keys and storage-location metadata instead of scattering permanent provider URLs through domain records. Keep upload/access logic in one small service. Separate private originals, published copies and thumbnail variants. Do not build an elaborate provider framework.

Migration sequence:

1. Inventory objects and ownership/visibility metadata.
2. Copy objects and verify counts, checksums and metadata.
3. Support old and new locations while testing upload/access behavior.
4. Switch new uploads and reads in stages; handle in-flight uploads.
5. Verify private authorization, signed access, cache behavior, deletion and revocation.
6. Keep old objects for a defined rollback window, then remove them under the approved lifecycle policy.

Private R2 objects need authorization; free egress does not supply access control. Public caching must match revocation policy, and already downloaded copies cannot be promised erased. This migration keeps users, wardrobe records and messages in Supabase. Migrating the entire backend/auth system is a separate, larger project.
