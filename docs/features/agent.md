# Agent

One capability surface serves full-screen Agent and focused app actions. It answers style, clothing, travel and planning questions using authorized local context and domain actions. General answers stay distinct from personal facts. Unsupported topics get a brief scope note and a next step.

## Purpose

Agent is a closet copilot. One sentence does a closet chore (dress me today, plan my week, pack my trip, log what I wore, tidy my closet) and the result is a reviewable change set. It knows the whole local closet, runs privately on the iPhone, and never changes anything without asking. Chat is only how the owner asks.

## Availability

The model is on-device (Foundation Models) when the device is eligible and ready. Otherwise a reason-specific unavailable screen appears, with a link to Device support, while Closet and Planner stay fully manual. Deterministic tools never pose as conversation. No cloud model, social, research or message tools in V1.

Device support (Settings, AI, Device support) lists every iPhone that runs Apple Intelligence (iPhone 15 Pro and Pro Max, every iPhone 16 including the 16e, the iPhone 17 family including Air and 17e), the languages, free storage, region and iOS 26 requirement, and shows this iPhone's live status with Check again. The list lives in `AppleIntelligenceSupport` in Core; the live answer always comes from the system. Everything outside Agent works on any iPhone running iOS 18.

## Capabilities and authority

| Capability | Authority |
| --- | --- |
| Search and insights | Read-only within authorized records. |
| Capture | Opens Photos or Camera; the user reviews classification and saves. |
| Outfit, theme, plan, wear, piece edit | Drafts only; the user reviews exact targets, revisions and changed fields, then approves. |
| Archive, restore | A tidy review with one tickable row per piece. Applies only the ticked rows. Undo is offered. |
| Local delete or privacy change | A tidy review, then a separate destructive confirmation with the exact impact and "This can’t be undone". No undo. |
| Weather | Only a fresh, matching, user-selected WeatherKit result; never blocks manual work. |

Ownership and revisions are validated when an action runs, not only when the prompt is built. Notes, generated text and imported metadata cannot authorize a tool call. Photos are not model context. Private notes are read only after the owner turns on the Private notes source, which is off by default and stays off for stored settings from before this rule until it is switched on again.

## Trips and questions

A trip request ("plan outfits for 3 days in Boracay") becomes one review with a different outfit for each day, up to 7. The app picks varied available pieces (spread across days, dresses and separates alternating, steered by the day's occasion); the model supplies only the day labels. The owner chooses what saving does: the outfits always, plus an optional theme that groups them and, when dates were given, an optional Planner trip. Each step has its own receipt, so applying again after an interruption resumes without duplicates. If the model answers a clear trip request without preparing the review, the app prepares it from the request.

When something essential is missing the Agent asks one question at a time as tappable answers (the `askUser` tool, or answers read from a reply that ends in one question), with "Something else" to type. Only the latest reply keeps its buttons. The Agent never asks the owner for an ID or code.

## Records, handles and names

The model never sees UUIDs or revisions. Each turn the app numbers the owner's active pieces, outfits, themes and plans with short handles (`p1`, `o3`, `t2`, `pl1`) in name order, and shows records to the model as a handle, a name and a few facts. Tools accept a handle or a name. The app resolves it: exact handle, then exact name (case and punctuation ignored), then a unique loose match on the words of the name plus its color, category and tags. Several matches ask the owner which one as tappable answers; no match is a quiet step in the activity list. The app reads the current revision when it prepares a review, and staleness is checked again at Apply. Handles are for tools: a reply that shows a handle, UUID or revision is a grounding violation.

## Intent, tools and context

Each request is classified once by rules into an intent (chat, show, find, stats, what to wear, suggest, trip, plan days, theme, relabel, edit piece, edit outfit, edit theme, edit plan, tidy, record wear, profile, add piece, out of scope). Adding, removing or swapping a piece in a saved outfit, an outfit in a theme, or setting one day of a plan ("Swap the flats for my sneakers in Office day", "Change Wednesday in This week to Rainy day") is carried out by the app, which sends the complete new list to the review. A follow-up, such as an answer to a question card or "make it dressier", keeps the previous intent. The intent fixes at most three tools, a short instruction snippet and a reply budget (300 tokens, 400 for looks, 500 for plans). Showing and finding records, wear statistics, a planned look, an outfit suggestion, a plain command (rename, mark as laundry, change a color, set an occasion, record wear, edit the profile, make a theme from a kind of outfit), the next few days and a trip of known length are carried out by the app from the owner's words; the model only writes a one-line framing, and if it cannot, the app writes the sentence itself and the cards remain. Anything else, such as trips with dates, goes to the model with at most three tools. A request outside the Agent gets a scope note with no model call. When essential details are missing the app asks, as tappable answers. Outfit picks are constrained to the ids offered, so the model cannot name a piece that does not exist.

One budget splits the on-device window: instructions, tool definitions, room for tool results and the reply come first; then the request, trusted facts, retrieved records and the closet index, and last conversation history. Token counts are measured when the model can count them and estimated otherwise. History is the last four turns word for word plus a short summary of older turns kept on the conversation, never the whole chat. What does not fit is fetched by the lookup tool or dropped, oldest history first.

## Grounding

A finished reply is checked against the owner's records: names in bold, lists or quotes must be real pieces, outfits, themes or plans; a color with a garment must exist together; counts about the closet must match the trusted totals; no handle, UUID or revision may show; and a reply may not say nothing was found while matching cards are shown. A violation regenerates the reply once with the problems as feedback. If it still fails, the reply stays with a note that some items aren't in the closet, and cards are attached only for names that resolve. Violations are kept in the message details. Replies are trimmed of filler openers and closers, lists that repeat the cards, and middle-dot separators.

## Failure states

A failed reply states what happened and offers a way forward: model unavailable or preparing, Apple Intelligence off, request too long, timed out, declined, interrupted, change not prepared, or save unconfirmed. Actions are Retry, Try a shorter request or Edit request (the request returns to the composer), New chat (carries the request), Open Settings, and Continue without closet. Partial text is kept and marked. Proposal cards say exactly what saving will do before the owner opens the review.

## Proposals and execution

A proposal has a stable ID, capability, exact target IDs and revisions, proposed changes, source limits and status. Approval binds to that version; changed targets, content or source revisions require a fresh review. Execution uses an idempotency key (proposed → approved → executing → succeeded, failed or cancelled), runs the same domain operations as app buttons, and shows receipts linking real saved records. Unknown outcomes are reported honestly and retries check prior completion first. Cancel stops generation and unapproved writes. Bulk plan application is all-or-nothing.

## Review, reject and undo

Every change is a review the owner approves or rejects; there is no standing permission. A tidy review (archive, restore, delete) lists the pieces as rows. The owner unticks rows to leave them out, and Apply uses only the ticked rows. Each piece is checked against the revision that was reviewed before the first write, and an archive that fails part-way is rolled back, so a tidy applies whole or not at all. Reject with a reason cancels the review and sends the reason back so the Agent can revise.

A plan review lets the owner leave days out: tap a day on the card or untick it in the review. Left-out days stay as they were (a new plan leaves them unassigned), at least one day always stays in, and the rest still save together or not at all.

A receipt offers Undo for every applied change: archive, restore, availability, a piece edit, a new or edited outfit or theme, a new or edited plan, recorded wear, a profile edit and a whole trip. Undo restores the earlier state, or removes what the change created, under a revision check: it is offered only while every record it touched is unchanged since the apply and nothing else uses a created outfit. A trip is undone as one (plan, then theme, then outfits) or not at all. The receipt records when undo was used. A retry after an unconfirmed save has no earlier state left, so it offers no undo, and deleting a piece is never undoable.

## Trips and questions

A trip request ("plan outfits for 3 days in Boracay") becomes one review with a different outfit for each day, up to 7. The app picks varied available pieces (spread across days, dresses and separates alternating, steered by the day's occasion); the model supplies only the day labels. The owner chooses what saving does: the outfits always, plus an optional theme that groups them and, when dates were given, an optional Planner trip. Each step has its own receipt, so applying again after an interruption resumes without duplicates. If the model answers a clear trip request without preparing the review, the app prepares it from the request.

When something essential is missing the Agent asks one question at a time as tappable answers (the `askUser` tool, or answers read from a reply that ends in one question), with "Something else" to type. Only the latest reply keeps its buttons. The Agent never asks the owner for an ID or code.

## Records, handles and names

The model never sees UUIDs or revisions. Each turn the app numbers the owner's active pieces, outfits, themes and plans with short handles (`p1`, `o3`, `t2`, `pl1`) in name order, and shows records to the model as a handle, a name and a few facts. Tools accept a handle or a name. The app resolves it: exact handle, then exact name (case and punctuation ignored), then a unique loose match on the words of the name plus its color, category and tags. Several matches ask the owner which one as tappable answers; no match is a quiet step in the activity list. The app reads the current revision when it prepares a review, and staleness is checked again at Apply. Handles are for tools: a reply that shows a handle, UUID or revision is a grounding violation.

## Intent, tools and context

Each request is classified once by rules into an intent (chat, show, find, stats, what to wear, suggest, trip, plan days, theme, relabel, edit piece, tidy, record wear, profile, add piece, out of scope). A follow-up, such as an answer to a question card or "make it dressier", keeps the previous intent. The intent fixes at most three tools, a short instruction snippet and a reply budget (300 tokens, 400 for looks, 500 for plans). Showing and finding records, wear statistics, a planned look, an outfit suggestion, a plain command (rename, mark as laundry, change a color, set an occasion, record wear, edit the profile, make a theme from a kind of outfit), the next few days and a trip of known length are carried out by the app from the owner's words; the model only writes a one-line framing, and if it cannot, the app writes the sentence itself and the cards remain. Anything else, such as trips with dates, goes to the model with at most three tools. A request outside the Agent gets a scope note with no model call. When essential details are missing the app asks, as tappable answers. Outfit picks are constrained to the ids offered, so the model cannot name a piece that does not exist.

One budget splits the on-device window: instructions, tool definitions, room for tool results and the reply come first; then the request, trusted facts, retrieved records and the closet index, and last conversation history. Token counts are measured when the model can count them and estimated otherwise. History is the last four turns word for word plus a short summary of older turns kept on the conversation, never the whole chat. What does not fit is fetched by the lookup tool or dropped, oldest history first.

## Grounding

A finished reply is checked against the owner's records: names in bold, lists or quotes must be real pieces, outfits, themes or plans; a color with a garment must exist together; counts about the closet must match the trusted totals; no handle, UUID or revision may show; and a reply may not say nothing was found while matching cards are shown. A violation regenerates the reply once with the problems as feedback. If it still fails, the reply stays with a note that some items aren't in the closet, and cards are attached only for names that resolve. Violations are kept in the message details. Replies are trimmed of filler openers and closers, lists that repeat the cards, and middle-dot separators.

## Failure states

A failed reply states what happened and offers a way forward: model unavailable or preparing, Apple Intelligence off, request too long, timed out, declined, interrupted, change not prepared, or save unconfirmed. Actions are Retry, Try a shorter request or Edit request (the request returns to the composer), New chat (carries the request), Open Settings, and Continue without closet. Partial text is kept and marked. Proposal cards say exactly what saving will do before the owner opens the review.

## Proposals and execution

A proposal has a stable ID, capability, exact target IDs and revisions, proposed changes, source limits and status. Approval binds to that version; changed targets, content or source revisions require a fresh review. Execution uses an idempotency key (proposed → approved → executing → succeeded, failed or cancelled), runs the same domain operations as app buttons, and shows receipts linking real saved records. Unknown outcomes are reported honestly and retries check prior completion first. Cancel stops generation and unapproved writes. Bulk plan application is all-or-nothing.

## Review, reject and undo

Every change is a review the owner approves or rejects; there is no standing permission. A tidy review (archive, restore, delete) lists the pieces as rows. The owner unticks rows to leave them out, and Apply uses only the ticked rows. Each piece is checked against the revision that was reviewed before the first write, and an archive that fails part-way is rolled back, so a tidy applies whole or not at all. Reject with a reason cancels the review and sends the reason back so the Agent can revise.

A receipt offers Undo for an applied archive, restore, availability change or piece edit while the piece is unchanged since the apply; undo restores the earlier state under a revision check and records when it was used. A retry after an unconfirmed save has no earlier state left, so it offers no undo. Deleting a piece and changes to outfits, themes, plans, wear and profile have no undo: they are edited or removed by hand.

## Context and quality

- Context is explicit and bounded: general (no closet), eligible metadata, or selected pieces, outfits and themes. If the closet exceeds the request limit the user picks Selected pieces or Without closet; no arbitrary subset is sent.
- Style answers (goals, occasions, fit, colors, optional body details) are used only with their own permission and a revocable setting. Unknown or declined stays unknown.
- Output is validated for structure and owned active IDs. Complete outfits meet the requested form or explain gaps; theme requests return theme reviews; pinned pieces survive replacement; manual edits survive retry. Long plans are generated in bounded batches and committed only after a full preview. Statistics come from trusted queries with explicit windows.

## Conversation

A message typed while a reply is running can be queued (up to three, text only). Queued messages show above the field, can be removed, and are sent one at a time when the reply finishes; stopping or a failed reply puts them back in the composer. Each lookup step in a reply's activity names the records it read, so the owner can see what an answer was based on.

Durable conversations with history, new and delete, typed drafts kept across interruption, streaming with Stop and hard timeout, same-turn retry, copy as plain text, Markdown or code, safe Markdown rendering (no remote images or HTML), and per-message details. Voice and image intake are enabled only after on-device support is verified; typed input always works.

## Evals

Deterministic evals and invariants run in CI: a proposal tool never changes a store revision, instructions inside notes never produce a change, and an approval applies only to the version reviewed. The live on-device eval (`scripts/eval-agent-live.sh`) gates every release. It runs the golden, held-out, tidy and edits suites three times on the iPhone 17 Pro Max and fails when a pooled rate misses a bar in `AgentEvalGate`: safety (forbidden claims), unrequested review and no-leak at 100%; proposal (a requested review was prepared), tool, intent, honest, no-invented, consistent and completed at 90%; all checks at 80%. An unrequested review is the dangerous direction, so it allows no miss; the model sometimes asks a question instead of preparing a review, which is a lower bar. The model changes with iOS releases, so the suites also run on each OS beta.

## Acceptance

- Unsupported device or model shows the reason and a manual route; cancel writes nothing.
- A stale or already-applied approval never writes twice or on changed revisions.
- Deleting a conversation does not change wardrobe, plans or wear.
- Nothing a tool prepares changes a record before approval; a rejected or cancelled review writes nothing.
- Unticked tidy rows are never changed; a stale piece stops the whole tidy.
- Undo restores only a piece that is unchanged since the apply, and a delete is never offered undo.
- Device support lists every Apple Intelligence iPhone and shows this iPhone's status.
