# Delivery scope

This bounds the intended product in [PRODUCT.md](PRODUCT.md). Detailed requirements belong to [feature specifications](features/README.md); execution order belongs to [Implementation plan](IMPLEMENTATION-PLAN.md). These milestones are not claims about the current app.

## Combined V1 completion

The target is the personal closet/styling experience plus social discovery, sharing, and human chats defined in [Product](PRODUCT.md). Milestones below are delivery increments. Completing only the private closet or adding a nonfunctional social tab does not satisfy V1. Each included feature must meet its acceptance checks with appropriate device/service evidence; unsupported or deferred AI capabilities remain explicitly disclosed.

## Milestone 1: Useful private closet

Complete capture, classification, item management, manual outfits, independent themes, actual wear history, and factual stats. Preserve existing data through migrations and handle failed saves without losing drafts.

Exit: a user can add a piece, find and edit it after restart, build a look, organize it, record wear, and correct history without AI or social participation. Verify W and O acceptance for the delivered scope and P7–P9.

## Milestone 2: Personal planning

Add calendar/agenda planning, dated events, weekday routines, and travel packing. Support two-week plans and office routines spanning three calendar months. Future intentions and actual wear remain distinct.

Exit: a user can save a plan, revise a day or future routine entries, review conflicts, and regenerate its packing list. Bulk saving either persists the reviewed plan completely or preserves the draft without partial changes. Verify P1–P6, disclosing any capability-gated assistance.

## Milestone 3: Shared Agent capabilities

Deliver grounded questions and insights, reviewed outfit/theme drafts, and assisted planning through focused actions and full-screen Agent. Manual operations remain available. Use the selected on-device runtime within demonstrated limits.

Exit: approve a concrete proposal, execute once, and inspect the actual result. Stale targets, cancellation, invalid output, unavailable models, and retries have tested outcomes. Apply A acceptance by capability; physical-device quality and current-information tools have separate release gates.

## Milestone 4: Community and identity

Deliver connected identity/durability, public profiles and curated closets, explicit publication, All / Following feeds, discovery search, follows/reactions/bookmarks, and owned-wardrobe inspiration.

Exit: publish one look without disclosing unrelated inventory, notes, history, or plans; revoke access through profile/feed/search/bookmarks; respect blocking and moderation. Verify U/S acceptance against connected services. Backend, sync, media access, and data lifecycle decisions are prerequisites.

## Milestone 5: Human Inbox

Deliver one-to-one text and public-content references, message requests, reliable delivery/unread states, blocking/reporting, and reviewed Agent message drafts.

Exit: accept a request, send/retry without duplication, and correctly handle revoked references and blocked contact. Verify I acceptance and A9. Messaging retention, delivery, notification, and abuse policies are prerequisites.

## Deferred

Personalized feed ranking, inferred taste learning, receipt/batch imports, advanced automatic tagging, laundry automation, external calendar sync, reminders, richer trip collaboration, group chats, calls, and arbitrary chat media require separate scope decisions.

The current build and its gaps are recorded in [Implementation](IMPLEMENTATION.md); actual validation belongs to [Verification](VERIFICATION.md). Documentation refinement authorizes no implementation or service deployment.
