# AQD V2 backlog

October 1, 2026. These are extras outside the [V1 release definition](V1-RELEASE.md), not implementation commitments or a promise that every item ships in V2. Prioritize after real V1 usage, quality and operating-cost evidence. Existing Paper states or exploratory specs do not expand V1.

| Area | Deferred enhancement | Why / prerequisite |
| --- | --- | --- |
| Try-on | Avatar/full-body previews, personal virtual try-on | Explicit user deferral; separate privacy/provider/quality/cost contract. |
| Shopping | Wishlist, catalog, price alerts, affiliate links, marketplace | Explicit user deferral; validate shopping demand and economics after owned-wardrobe value. |
| Capture | Automatic photo tagging, advanced visual analysis, batch/receipt imports, studio cleanup, scanning, selfie extraction, multiple item photos | Manual/photo review completes V1; need capability and media-cost evidence. |
| Personalization | Inferred taste learning, personalized ranking/trending and automatic feedback learning | Start with explicit preferences and chronological real posts. |
| Insights | Cost-per-wear, purchase tracking, advanced analytics | V1 uses reproducible actual wear/labelled estimates; richer data needs a separate contract. |
| Planning | External calendar sync, reminders/push, multi-destination optimization, luggage constraints, collaborative trips, automatic laundry scheduling | Preserve simple manual availability and reviewed dates/packing first. |
| Social | Private-profile follow requests, repost/stories/video/music, nested comment replies, comment editing/mentions and richer reactions | V1 supports curated public profiles, basic discussion and safety. |
| Inbox | Group chats, calls, arbitrary media/private wardrobe attachments/location, typing and public read receipts, social activity tab, delete-for-everyone UI | V1 pair chat/requests/text/public references and acknowledged in-app unread remain required. Retention/deletion policy is still V1. |
| Notifications | Remote social/message push and activity alerts | V1 uses in-app unread and real auth email delivery. Define transport, consent and deep links separately. |
| Agent enhancements | Response comparison/version browsing, server-collected rating/comment feedback, broader web research, photo/private-note context and consented human-chat context | Basic history/cancel/retry/copy/review/receipts and internal evaluation remain V1; no implicit sensitive context upload. |
| Identity | Additional login providers, optional user MFA setup, self-service cross-account merge | V1 Apple/email recommendation, recovery, safe collisions/account isolation and deletion remain required. Operational security remains V1. |
| Monetization | Paid subscriptions, paywalls, entitlements, restore purchases and billing support | Price/value hypotheses are unapproved; free launch is the working default. If charging is approved before launch, complete billing becomes a V1 requirement. |
| Platforms | Android, consumer web wardrobe app | Launch iOS plus public landing/support/legal pages first. |
| Infrastructure expansion | Media-provider migration, extra services/queues/replicas and large-scale optimizations beyond measured need | V1 still requires scalable data/access patterns, actual workload testing, backup/restore and observability. |
| Acquisition | In-app “How did you find AQD?” survey and automated attribution pipelines | Optional post-value design is extra; public launch pages/Facebook presence remain in launch scope. |

Never defer authentication, connected recovery, cross-account isolation, accessibility, moderation/block/report, core loading/error/offline behavior, durable persistence or safe retries under the label “V2.” Provider decisions required to deliver V1 remain V1 blockers.
