# I — Inbox

## Phase boundary

V2 only. V1 has no human messaging, requests, unread state, social notification transport or Inbox destination. See [V1 release](../product/v1-release.md), [V2 backlog](../product/v2-backlog.md) and [V2 design](../design/v2-requirements.md).

## Outcome

People can discuss looks and share accessible wardrobe content. Agent conversations stay in Agent. Entry: persistent labelled 44-point Inbox toolbar control on V2 roots, or Message from a public creator profile. The five base slots remain Home · Closet · Planner · Agent · Profile; Inbox is not a tab. Toolbar entry opens existing I01, then a conversation; Back restores origin root/scroll/selected tab. Startup/incoming Inbox intents open Inbox while retaining the origin (default Home for a fresh session); conversation Back returns through I01. No unread badge is shown without actual acknowledged unread state. V1 has no mirrored entry.

Working first scope: one-to-one text and references to public wardrobe content. Inbox sections are Chats and Requests. Social activity (follows/reactions) is deferred; it is not mixed into messages merely because the supplied Alta reference proposed “activity.” Group chats, calls, arbitrary media uploads, location sharing, and private wardrobe attachments are excluded from the first slice.

## Conversation and delivery

Conversation identity is stable for the participant pair; starting Message again resumes it. Authenticated participants are the only readers. Recommended text limit: 1–2,000 characters after trimming; empty messages cannot send. A message has stable ID, sender, conversation, timestamp, type, and delivery state. Reference messages point to an accessible post rather than copying its private source.

Working contact rule: users who follow the sender receive direct chat; otherwise the first contact becomes a request. Pending requests allow one opening message until accepted; sender sees pending rather than implied delivery/read. Recipient can accept, decline, block, or report. Repeat solicitation limits and rate limits must be defined with backend selection.

Composer retains unsent text. Sending appears pending; server acknowledgment changes it to sent. Retry reuses the message ID; unknown completion checks status before resending. Offline does not pretend a send succeeded. Read/unread derives from acknowledged cursor state. Read receipts/typing indicators are later optional features, not implied by sent status.

Block prevents new contact and removes the relationship from discovery/contact suggestions. Shared references are checked when opened; revoked content displays unavailable. Agent may draft text or a reference message, but recipient/content review precedes send; no default Agent access to human chat history.

## Lifecycle gates

V2 requires real in-app acknowledged unread and reliable connected delivery. Remote push/activity alerts are V2; email authentication still requires delivery. Retention/deletion/abuse decisions are V2 blockers, not optional notification enhancements.

Before connected implementation, decide notification transport/preferences, retention, delete-for-self versus delete-for-everyone, account deletion effects, encryption claims, and abuse limits. Do not claim end-to-end encryption from ordinary authenticated storage. Never populate production Inbox with artificial conversations or counts.

## Acceptance

- I1: Reopening Message with the same creator resumes one conversation.
- I2: A non-follower request cannot bypass acceptance or send repeated opening messages.
- I3: Failed/unknown sends retain text and retry without duplicate messages.
- I4: Only participants can retrieve messages; account switching clears unauthorized cached content.
- I5: Block stops new contact; report can include user-selected relevant evidence under the agreed policy.
- I6: Opening a revoked shared post does not reveal cached private content.
- I7: Agent drafts a message without sending; changed recipient/content requires a new review.
- I8: Empty, offline, request, delivery-error, and unavailable-service states are distinguishable.
- I9: Persistent V2 root-toolbar entry opens I01 before conversations; Back and startup/incoming intent returns restore origin root/scroll/selected tab. Verify 44-point targets, labels, VoiceOver/focus, Dynamic Type and keyboard/safe areas; never fabricate unread or mirror Inbox in V1.

## Dependencies

Connected [Identity](profile-account.md), content access, block/report behavior, and selected messaging services. The root-toolbar entry and return contract may be specified early; messaging functionality cannot be claimed until these gates pass.
