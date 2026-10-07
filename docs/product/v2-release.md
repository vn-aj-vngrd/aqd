# AQD V2 core release definition

Reclassified October 5, 2026 from the October 1 connected V1 plan. **V2 core retains the complete connected product**, including the complete V1 private closet/planning/Agent, authentication, account durability, community and human Inbox. [V1](v1-release.md) is the complete device-only baseline that V2 extends. These acceptance targets are preserved, not implemented or verified by this branch.

[V2 backlog](v2-backlog.md) includes this core and every earlier deferred enhancement; [V2 design](../design/v2-requirements.md) prepares extension requirements. The core baseline below is required for connected launch. Extension sequencing is a roadmap decision; do not turn their older exclusion wording into removal from the V2 vision.

## Inherited Today customization

V2 inherits the [complete private Today configuration](../features/today.md): twelve local in-app kinds, independent notes/photos, stable repeated instances, minimum one/no arbitrary maximum, atomic draft/Done/Undo and full source/media/save/restart/accessibility states. Today is first destination label/accessibility name, house unchanged. Private header Customize replaces Search; public All/Following Search remains. Optional Community posts uses the existing authorized feed scope/store only, no new API. No automatic upload/publication or private-photo/Agent context follows from adding a card.

## Release promise

An iPhone user can start privately, capture owned clothing, save a useful outfit, plan a day/routine/trip, record actual wear, and retrieve those records after restart. Signing in enables account-scoped backup/sync/recovery and social participation. They can publish selected content, discover other creators, recreate inspiration with owned pieces, and exchange real human messages. These paths must use actual persisted records and connected services, without fictitious production activity or success receipts.

Launch starts from zero users. 50,000 users remains a future capacity scenario, not a launch audience or evidence of scalability. iOS, public landing/support/privacy pages, a restricted web admin app for management/analytics/monitoring/controls, and the Facebook presence are the launch surfaces; Android and other clients are V2 extensions, outside the initial connected iPhone core. Free launch is the working commercial default until prices/entitlements are approved. Subscriptions are not a prerequisite for this core release.

## Included feature checklist

Every row is mandatory. A service or capability gate means work to resolve before launch, not permission to ship a placeholder tab. The fallback column defines supported behavior on devices without a model or when connectivity fails.

| ID | V2 feature | Required result | Acceptance / fallback |
| --- | --- | --- | --- |
| V2-01 | Entry and Home | Private first use, returning-session restore, Today / All / Following; adaptive empty, missing-category, ready, saved-outfit and planned states | Preserve return intent/drafts. Never require account, photo, quiz or AI for private manual work. |
| V2-02 | Wardrobe | Photos/camera/manual capture, selected-photo review, name/category, optional metadata, add-next loop, search/filter/sort, edit, availability/laundry, archive/restore and deletion impact | W1–W10; first-outfit pin/readiness; storage and permission failures retain drafts. Verified on-device tagging/cleanup follows the V1 capability contract; advanced visual capture remains V2-E01. |
| V2-03 | Outfits and themes | Manual and assisted owned-piece composition, pin/slot replacement, private save/edit/favorites, independent multi-membership themes | O1–O9; missing pieces and partial manual looks are honest; no AI requirement for manual work. |
| V2-04 | Planner and packing | Calendar/agenda, dated plans, two-week planning, three-calendar-month office routines, events/trips, conflicts, review and deduplicated packing | P1–P6; manual and bounded assisted drafts use the same records; bulk changes apply completely or remain drafts. |
| V2-05 | Wear and insights | Explicit actual wear, backdate/correction/undo, history snapshots, most/least worn and recorded utilization | P7–P9; plans/date passage never create wear; reproducible statistics with estimates labelled. |
| V2-06 | Agent and focused actions | Grounded wardrobe questions/insights, outfit/theme/plan drafts, reviewed edits/wear/publication/message drafts using shared domain operations | A1–A16; rich media/closet/voice input and streamed recovery; validate ownership/revisions, approve exact changes, execute once and show real receipts. No default reading of human Inbox. |
| V2-07 | Contextual styling | Occasion, explicit preferences, pinned pieces, date/place; sourced weather for supported dates/locations | Inherit the [V1 native WeatherKit contract](v1-release.md#optional-live-weather-contract), including basic values, consent, budgets and attribution; entitlement/returned date coverage and physical-device behavior still need evidence. Advanced external providers/context remain separately gated; missing weather is disclosed. Unsupported models use labelled rules/manual flows, never invented current facts. |
| V2-08 | Authentication | Apple and verified email sign-in, returning login, session refresh/expiry, cancellation/recovery, sign-out and account switching | AUTH-01–AUTH-08 below. Providers/email method are working defaults requiring an explicit service contract. Auth is not deferred. |
| V2-09 | Account durability and lifecycle | Reviewed local-account association, account-scoped local cache, connected backup/sync/reinstall recovery, useful export and account deletion | U1–U8 and DATA-01–DATA-06; offline private edits reconcile safely. Guest device-only limits disclosed. |
| V2-10 | Profile | Unique username, name/avatar/bio, real public collections/counts, follow/unfollow, settings and resolvable profile links | Visitors see curated accessible public data; existing identities skip setup; no private inventory totals leak. |
| V2-11 | Publishing and discovery | Explicit Piece/Outfit/Theme snapshots, photo-to-owned-piece review, update/unpublish, chronological All/Following, scoped public search, likes/bookmarks and owned-wardrobe recreation | S1–S8; snapshots are independent of private edits; revocation checked across feed/profile/search/bookmarks/chat. |
| V2-12 | Comments | Plain-text top-level discussion, pagination, acknowledged counts, own deletion, report/block | S9–S10; composer/send failure retains draft; nested replies, editing and mentions extend this connected core under V2-E07. |
| V2-13 | Human Inbox | Pair-unique one-to-one text/public references, first-contact requests, accept/decline, pending/sent/failed/unknown delivery and acknowledged unread state | I1–I9; persistent root-toolbar entry → I01, not a tab; two real accounts exchange messages; retries never duplicate; content access checked at open. |
| V2-14 | Safety and support | Report/block across social surfaces, operational moderation queue and responsible operator, rate limits, access enforcement, support/privacy/terms destinations | SAFETY-01–SAFETY-04; deployment policy and operational ownership resolved before public access. |
| V2-15 | Native and operational quality | Accessible controls, keyboard/safe areas, Reduce Motion, performance, crash/error visibility, reliable media/persistence, deployment/restore checks | RELEASE-01–RELEASE-07. Real failures are part of the feature, not V2 polish. |

## Authentication contract

Apple and passwordless verified email links are the recommended V2 methods matching the current entry design. This is a working implementation default, not a claim that providers are configured. Historical password-based prototype notes conflict with that design. Before implementation, select the actual method and reconcile screens, callbacks, email delivery and tests. If password login is retained for existing accounts, password reset becomes a mandatory V2 path; do not strand existing identities. Extra providers and user-facing MFA enrollment are V2 extensions beyond this core baseline.

| Check | Required evidence |
| --- | --- |
| AUTH-01 | Fresh Apple/email account, returning account, cancelled provider and valid auth callback tested against real configured services; callback validates the initiating transaction and restores held intent. |
| AUTH-02 | Email verification, resend cooldown, delayed email, expired/consumed link and repeated callback produce correct states without account-enumeration copy or duplicate users. |
| AUTH-03 | Session persists securely across restart; refresh/expiry/offline/revocation handled; tokens and credentials excluded from logs. |
| AUTH-04 | Auth from publishing/follow/comment/message returns to the exact pending action without silently executing it; cancellation retains private drafts. |
| AUTH-05 | Local association previews destination account and exact records; existing account collision keeps data separate; no silent overwrite/merge or automatic publication. |
| AUTH-06 | Sign-out and A→B switching isolate connected private records, media, history, drafts and chat caches. Re-sign-in restores the authorized account. |
| AUTH-07 | Profile setup only when needed; unique username enforced server-side; edits/failures preserve input and stable user identity. |
| AUTH-08 | Recovery and account deletion work on a physical device, with real email/provider errors, reauthentication and honest pending/completed states. Linking providers cannot transfer ownership by matching an unverified email. |

## Data contract

V2 requires working signed-in durability; selecting a backend is an outstanding delivery dependency. Start with the simplest account-scoped persistence and sync appropriate to this contract. No distributed platform or collaboration engine is required.

| Check | Required evidence |
| --- | --- |
| DATA-01 | Private local save/restart and migration preserve stable item/outfit/theme/plan/history, journal and Today instance/content IDs, configuration/order and media; corrupt/newer storage cannot be overwritten by an empty reset. |
| DATA-02 | Signing in associates only reviewed local records; association interruption/retry has one result. Collisions remain separate until an explicit resolution; no automatic merge. |
| DATA-03 | Backup/sync status distinguishes local saved, pending upload, confirmed backed up and failed. Offline private edits remain usable and retry without duplication. |
| DATA-04 | Restore the signed-in closet on a clean install/second device, including reviewed Today layout/repeated instances, off-layout notes/photos/media and recovery references, private Profile/journal/Agent history, plans, theme memberships and wear history. Excluded local-only state is not claimed recovered. Concurrent edits/deletes have a documented revision/conflict policy; conflicts never silently discard changes or resurrect deletion. |
| DATA-05 | Export produces a usable versioned artifact with the owner's records/media and clear limits; it excludes other people's private messages. Guest device-only risk is disclosed before claiming recoverability. |
| DATA-06 | Reauthenticated deletion removes account/public access immediately under the selected policy, processes owned media/data deletion reliably and explains backup retention and remaining conversation history. Sign-out, app removal and account deletion are distinct actions. |

## Supported assistance

The on-device runtime remains preferred. Supported devices must pass realistic questions, first-outfit/pin/replace, theme and two-week/routine/trip drafting, plus approved execution. Unsupported devices retain labelled deterministic suggestions and every manual private path. Bounded generation may take several batches, but the final plan is reviewed together before save.

V2 also includes basic conversation history, cancel/retry, copy, readable responses, proposal details and truthful progress. Advanced response comparisons and server-collected evaluation feedback are V2. Internal quality evaluation and privacy-safe failure measurement remain V2 engineering requirements. Images/private notes and human chat history are excluded from model context by default. Source captions never authorize tool actions.

Core assisted scope cannot be silently deferred because an on-device trial fails. Record the failure and resolve runtime capability, narrow the supported-device promise explicitly with the product owner, or hold launch. Weather requires a real source, timestamp and coverage; plans outside forecast coverage remain valid without fabricated weather. Broad web research and autonomous external tasks are V2.

## Safety, operations and launch acceptance

| Check | Required evidence |
| --- | --- |
| SAFETY-01 | Negative access tests with owner, other account, guest and blocked user cover private records/media, messages, posts/comments, search and public references. Server enforcement matches client behavior. |
| SAFETY-02 | Users report posts/comments/profiles/messages with selected evidence; a responsible operator receives and resolves reports, removes content and suspends abuse. Test the removal propagation. A simple protected operator workflow suffices. |
| SAFETY-03 | Rate limits for auth, publication/comments, requests/messages and media uploads are defined and exercised; block prevents contact and prohibited resurfacing across entry points. |
| SAFETY-04 | Retention, deletion, support response ownership, age/audience policy and encryption/privacy statements are finalized and match deployed behavior. No unsupported end-to-end encryption claim. |
| RELEASE-01 | Fresh private journey: capture → missing categories → manual/assisted outfit → restart → plan → wear/correct → export, including top/bottom/shoes and dress/shoes. |
| RELEASE-02 | Connected journey: real auth → association → clean-install restore → publish → another account discovers/follows/comments/recreates → request accepted → send/retry → unpublish/block → account deletion. |
| RELEASE-03 | Failure matrix covers denied/cancelled photo, failed save/migration, offline/expired session, failed/unknown sync, stale approval, model timeout, partial media upload, revoked content and failed/unknown message send. No draft loss, duplicates or false success. |
| RELEASE-04 | Physical-device and Simulator checks cover the same five equal-width icon-only native slots Today · Closet · Planner · Agent · Profile (explicit accessibility names/selected traits, full hit areas ≥44 × 44 pt), dedicated Planner Week/Month and cross-root date/Back selection, fourth-slot Agent full-screen return, V2-only persistent 44-point Inbox root-toolbar/I01/incoming-intent origin restoration and actual unread state. Verify keyboard/safe areas, VoiceOver/focus, Dynamic Type, reduced motion/transparency, media permissions and supported/unsupported model states; account setup never gates private core. |
| RELEASE-05 | Deployed environment has access controls, secret handling, scoped logs/crash reporting, backup and tested restore, migration/rollback procedure, support owner and service alerts. |
| RELEASE-06 | TestFlight review exercises real connected workflows and records device/build/environment/evidence. Release has no open critical data-loss, privacy/access, crash or core-flow blocker. Store metadata/privacy disclosures and landing/support/legal links match delivered functionality. |
| RELEASE-07 | Measure a documented launch workload on representative devices/services, including image-heavy lists/search, pagination, sync and concurrent messaging. Set numeric latency/error/capacity targets before load testing; do not infer 50k-user readiness from registered-user count or provider plan limits. |

Notification permissions, push reminders and remote activity alerts are prepared V2 extensions beyond this core baseline. V2 Inbox unread is available in-app, and email auth still requires real delivery. Remove or explain future notification controls; never present a toggle as an active transport. Monetization remains a proposal; no paid entitlement or purchase button ships until billing receives a separate approved contract.

## Paper coverage

[Design coverage](../design/v2-coverage.md) maps every V2 group to canonical screens, walkthrough branches and shared/native states. Paper page 02 · V2 contains the preserved connected review boards 00–20 in section 08, with lifecycle/recovery supplements and explicit V2 separation. This closes static flow-reference gaps; provider policies, app/device behavior and connected acceptance are still unresolved/unverified.

## Gap analysis against current evidence

Historical October 1 gap snapshot, retained for traceability. Current source/runtime/review boundaries belong to [status](../delivery/implementation-status.md) and [verification](../delivery/verification.md); this table is not a current task list. Comments now have [S9/S10](../features/discovery-publishing.md#acceptance); connected execution remains unverified.

This was a documentation/current-checkout assessment, not a fresh audit of a running app. On October 1, `apps/ios` contains build/project scaffolding but no tracked Swift source or project build definition was found. [Implementation status](../delivery/implementation-status.md) and earlier verification describe historical prototype behavior. They cannot establish present buildability or complete release readiness. All checks in this document remain unverified for the V2 release until recorded on the actual delivered build.

| Gap | Evidence / risk | Required closure | Priority |
| --- | --- | --- | --- |
| Current build baseline | Historical implementation descriptions cannot be reproduced from the current source tree | Locate/restore the intended app baseline when implementation is authorized; compile/run it and map source to acceptance IDs. Preserve existing data. | Release blocker |
| Auth inconsistency | Entry design says Apple/email links; historical prototype says email/password | Resolve one supported identity contract, legacy account recovery and callbacks; execute AUTH checks. | Release blocker |
| Durable connected data | Backup/sync/conflict/association/export/deletion policies remain service gates | Select service mapping, define revisions/ownership/retention and pass DATA checks with real accounts. | Release blocker |
| Target navigation/activation | Historical Home/Search and single-theme behavior differs from current Today/Inbox and collection targets | Implement target routes/readiness and theme migration, then test fresh/returning journeys. | Core gap |
| Planning/history | Calendar/routines/trips and corrected snapshot semantics lack current release evidence | Complete manual records first, assisted previews second; pass P checks including timezone/conflicts. | Core gap |
| Agent scope versus proof | Limited historical drafting is not evidence of shared approved execution or long-plan quality | Validate proposal/actions and physical-device quality; disclose supported model/rules states. | Core gap |
| Weather evidence | Basic native Apple WeatherKit selected for V1/V2; entitlement, actual coverage and native behavior unverified; advanced providers undecided | Execute LOCAL-16 and A8/RELEASE checks before live claims; separately resolve advanced-source licensing/coverage. | Core gap |
| Community lifecycle | Prototype posts do not prove all publication types, profiles/follows/search, revoke or block | Deploy actual access/media/moderation paths and pass S checks across two users. | Release blocker |
| Comments acceptance traceability (historical, superseded) | Snapshot predates numbered S9/S10 | Numbering is now present in the feature acceptance; verify connected behavior on an actual build. | Runtime evidence gap |
| Human Inbox | Transport, abuse, retention/deletion and delivery remain gates | Real two-account request/send/retry/read-state and access tests; settle operator policies. | Release blocker |
| Operational readiness | Paper and unit tests cannot prove support, restore, service alerts or App Store readiness | Complete SAFETY/RELEASE evidence, launch pages and store preparation. | Release blocker |
| Scope leakage | Paper includes exploration/feedback/notification states and monetization hypotheses | Treat Paper as design inventory, not a release checklist; gate extension controls until their real capability/service exists; retain every extension in the full V2 backlog. | Scope gap |

## Delivery and completion

1. Establish reproducible source/build baseline and approve identity, data, advanced-weather, moderation and messaging contracts and verify the confirmed V1 WeatherKit contract. Draft these while private modules proceed; no service is silently selected by this document.
2. Complete wardrobe/activation, manual outfits/themes, history and Planner with stable migrations and restart evidence.
3. Complete shared Agent proposals/actions and supported-device quality, including contextual planning.
4. Complete connected auth/durability/profile/publication/discovery/comments/safety and then Inbox. Validate account isolation throughout.
5. Run full real-account/private journeys and failure checks, physical-device/TestFlight review and operational launch checks.

Track each acceptance ID as not started, in progress, blocked, or verified, with build/commit/environment and linked evidence. A row is complete only when its normal, empty/loading, failure/offline and access paths pass at the appropriate layer. Current source compilation, synthetic tests, device results, deployed-service results and production checks remain separate evidence. Release only when all mandatory rows pass; a missing core feature requires an explicit scope revision, not a silent V2 move.

## Web operating surface

The web admin and landing architecture is defined in [ADMIN-WEB](../architecture/admin-web.md). Before connected launch, verify staff MFA/role isolation and revocation, protected action audits, moderation and bounded control enforcement, retryable operations, accurate/fresh aggregate metrics and alerts independent of the admin UI. The public site must provide working App Store/support/legal links and remain independent of backend availability. Detailed tooling and policies remain service gates.
