# Delivery scope

The authoritative release checklist is [V1 release definition](V1-RELEASE.md); extras are in [V2 backlog](V2-BACKLOG.md). All core features, working authentication, account durability, community and Inbox must be verified before launch. Milestones below remain delivery order.

This bounds the intended product in [PRODUCT.md](PRODUCT.md). Detailed requirements belong to [feature specifications](features/README.md); execution order belongs to [Implementation plan](IMPLEMENTATION-PLAN.md). These milestones are not claims about the current app.

## Combined V1 completion

The target is the personal closet/styling experience plus social discovery, sharing, and human chats defined in [Product](PRODUCT.md). Milestones below are delivery increments. Completing only the private closet or adding a nonfunctional social tab does not satisfy V1. Each included feature must meet its acceptance checks with appropriate device/service evidence; unsupported-device fallbacks remain explicitly disclosed. Mandatory core assistance requires supported-device evidence before release; optional image classification is V2.

## Wardrobe workflow refinement — October 1

The major UX gap is activation: saving one piece must lead clearly to a usable outfit, rather than ending onboarding in a grid. The first private save establishes trust; the first saved outfit establishes styling value. Welcome → optional photo/manual capture → review → save → actual missing-category guidance → suggest or build manually → pin/replace → review/save → plan → record wear is the V1 path. See the [V1 flow review](design/V1-FLOW.md) and its dedicated Paper page.

Capture remains one piece at a time, with only name/category required. Readiness uses active, available owned pieces for top + bottom + shoes or dress + shoes; no fixed upload quota, style quiz, account, or AI runtime gates manual creation. The first saved piece can stay pinned. Today distinguishes an empty closet, missing categories, pieces ready but no saved outfits, saved outfits without a plan, and a planned look. Repeated capture returns to the pending outfit task.

V1 requires manual and supported-device contextual styling, editable replacements, independent themes, planning/routines/travel packing, factual wear history/insights, explicit publishing/discovery and human Inbox. This covers the selected Alta-inspired wardrobe workflow, not every Alta feature. Automatic photo metadata is deferred to V2; studio cleanup, bulk import and an avatar are not implied by basic capture.

## Milestone 1: Useful private closet

Complete capture, manual classification, item management, manual outfits, independent themes, actual wear history, and factual stats. Preserve existing data through migrations and handle failed saves without losing drafts.

Exit: a new user can capture a piece, follow missing-category guidance or choose manual composition, save a usable first look, find and edit it after restart, organize it, record wear, and correct history without AI or social participation. Verify W and O acceptance for the delivered scope, including W8–W10 and O8–O9, and P7–P9.

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

## Deferred to V2

[The V2 backlog](V2-BACKLOG.md) is the explicit list of extras: try-on, shopping, automatic photo tagging/import/cleanup, inferred personalization/ranking, notifications/reminders/calendar sync, richer social/chat, advanced Agent feedback/context, Android and unapproved monetization. Provider/capability gaps for mandatory V1 are blockers to resolve, not deferrals. The broader Paper inventory includes future states; it does not make every designed enhancement a launch requirement.

The current build and its gaps are recorded in [Implementation](IMPLEMENTATION.md); actual validation belongs to [Verification](VERIFICATION.md). Documentation refinement authorizes no implementation or service deployment.
