# Web admin, landing page and operations

Phase scope: V2 connected-product proposal. V1 needs no app backend, staff admin or paid entitlement service; see [V1 architecture](v1.md). Dated prices and recommendations below are historical planning assumptions, not refreshed purchasing quotes.

Updated October 2, 2026. The user confirmed a web admin app for management, analytics, monitoring and controls, plus a public landing page. This document refines the architecture only; hosting, frameworks and providers remain proposals. See [architecture](architecture.md) and editable diagram **03**.

## Three clients, one small backend

| Surface | Responsibility | Proposed deployment |
| --- | --- | --- |
| Native iOS | Private wardrobe, Agent, connected social and Inbox | Existing iOS direction; shared trusted backend commands. |
| Public website | Product story/screenshots, App Store CTA, support, privacy/terms and account-deletion guidance | Static Cloudflare Pages site, independent build and public domain. |
| Staff admin app | User/account management, moderation, product analytics, system health and bounded controls | Separate static web build on Cloudflare Pages; authenticated staff-only routes and dedicated backend endpoints. |

Separate web deployments prevent a marketing release from changing the admin bundle. Domains are placeholders until the brand is selected. Public website availability does not depend on database or admin availability. Start the landing site with reviewed static content deployed through Git; a CMS is unnecessary initially. A waitlist/contact form is optional: if added, use a small validated, rate-limited server endpoint, explicit purpose/retention and real email delivery. Never connect public forms directly to unrestricted tables.

The admin frontend can be a small TypeScript SPA; its framework remains open. Cloudflare Pages serves assets, while narrow Supabase-backed server endpoints execute authenticated operations. If SSR becomes necessary, revisit the hosting/runtime rather than assuming every framework deploys unchanged. The existing Supabase project and worker can serve both iOS and admin; a new database or always-on admin server is not required by this scope.

## Proposed initial admin modules

| Module | Start with | Contract |
| --- | --- | --- |
| Overview | Active users, first piece/outfit, plans/wear, publishes, message activity and service health | Date range, metric definition, data freshness, empty/unavailable states. Missing data is not zero. |
| Accounts/support | Search account IDs, account status, association/sync failure metadata and export/deletion progress | Limited support projection; no blanket private closet or chat browsing. |
| Moderation | Reports, reported public content, resolution reasons, reversible hide/suspend/restore | Enforce rules on app reads/writes; record actor, target and reason. Reported private material requires a specifically scoped access policy. |
| Jobs/operations | Failed/aged jobs, upload processing, export/deletion retries | Retry through existing deduplicated job commands; no direct arbitrary database edits. |
| Controls | Versioned feature flags, temporary pause of publishing/message sends and bounded limits | Allowlisted keys, validation, expected revision, expiry where appropriate, audit and rollback. Server enforces critical controls; client config cannot grant access. |
| Audit | Staff actions and restricted-data access history | Filtered/paginated read; staff cannot edit or erase their action trail. |

These modules are proposed launch priorities, not approval for unrestricted administrative powers. The landing content stays in Git initially; editing it from admin, campaign tools, user impersonation, custom dashboards and arbitrary SQL consoles are deferred. Billing controls remain gated by the separate monetization contract.

## Staff authorization and action flow

Proposed roles are owner/operator, moderator and analyst. One founder can hold multiple roles; enforce permissions per operation from the beginning. Analysts read aggregates, moderators resolve reports, and owners manage bounded configuration/staff grants. A normal AQD account cannot self-promote. Staff membership is server-managed; bootstrap the first owner through an audited operational procedure.

Invite-only staff sign-in → MFA → current staff/session check → authorized projection or command → validate reason, payload, target revision and operation ID → database transaction with mutation and audit entry → durable receipt → refresh the UI. Require fresh authentication for role changes and destructive account operations. Privileged operations must check the current staff grant, so a stale token cannot retain a revoked role. Keep sessions/tokens out of logs and cache headers private for admin responses. CORS and an unlinked admin URL are not authorization.

Supabase supports [MFA with server/database enforcement](https://supabase.com/docs/guides/auth/auth-mfa). Use that capability if this mapping is selected. No service-role key or provider credential belongs in a browser bundle. Privileged functions must explicitly authorize staff even when their server credential bypasses RLS. If using browser bearer sessions, apply a reviewed token-storage/XSS policy; if cookies are chosen, add CSRF protection and secure cookie settings.

For database changes, audit records commit in the same transaction. External actions such as Auth administration or media deletion require a durable operation/job plus requested/completed/failed audit states, because there is no shared transaction with the external provider. Audit stores IDs and safe summaries, not copied secrets or user chat bodies. Retention and audit-access policies must be selected before launch.

## Product analytics versus system monitoring

**Product analytics:** versioned, allowlisted events describe the wardrobe funnel and engagement. Count authoritative saves/publishes/message sends from committed server receipts; distinguish guest/device activity from associated accounts. Device events are bounded and deduplicated, and delivery is best-effort without blocking the user's action. Event ingestion validates names/fields, limits request size/rate and cannot mutate wardrobe records. Start with small PostgreSQL event tables and daily aggregates; schedule incremental aggregation through the existing worker. Retain raw events for a defined limited period. Show aggregation timestamp/timezone and documented active-user/retention definitions. Consent, identity association and guest-event collection remain policy gates. No photos, notes, prompts, chat bodies or precise location in analytics.

**System monitoring:** service/API latency and errors, database health, storage growth, worker heartbeat, oldest pending job, retry/failure rates, sync conflicts and crash reports. On-device Agent completion/fallback metrics stay bounded and content-free. Start with provider dashboards and one selected crash/error/uptime tool rather than building a log platform. Admin shows sanitized summaries and links to detailed provider views; privileged provider credentials stay server-side. Monitoring ingestion/aggregation is separate from public analytics events, so clients cannot forge service health.

Alert delivery is independent of the admin UI and worker being monitored. Assign an operating owner and channel, set workload-based thresholds and test alert delivery, missed worker heartbeats and stale dashboards. Sensitive exports and raw log access require narrower permissions. Add a warehouse, dedicated event queue or analytics service only when aggregate query load, retention or reporting needs justify it.

## Required review and launch checks

- Normal users and signed-out callers cannot invoke admin endpoints; moderator/analyst roles cannot perform owner operations. Staff revocation and missing MFA deny access.
- Every control/moderation action has a durable receipt and protected audit trail; duplicate retries and stale revisions are safe. External-job failures remain visible.
- Reports, user projections and aggregates expose only allowed fields. Private wardrobe and Inbox content cannot be accessed through generic management queries.
- Metrics reconcile with source receipts, show freshness, and handle delayed/duplicate events. Analytics failure does not block core product flows.
- Landing pages are accessible/mobile-ready, load without backend availability, and link to real store/support/legal destinations. Admin releases and public releases are independently reversible.
- Alerts operate without the admin app, and provider failure is shown as unavailable. Backups/restores and production access procedures stay part of release readiness.

Detailed staff permissions, monitoring provider, thresholds, event retention, framework, support access and landing brand/content remain open implementation decisions. Admin scope adds work and telemetry usage to the cost model; it does not make the previous launch estimate a guaranteed all-in total.
