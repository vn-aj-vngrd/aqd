# Agent

One capability surface serves full-screen Agent and focused app actions. It answers style, clothing, travel and planning questions using authorized local context and domain actions. General answers stay distinct from personal facts. Unsupported topics get a brief scope note and a next step.

## Availability

The model is on-device (Foundation Models) when the device is eligible and ready. Otherwise a reason-specific unavailable screen appears, while Closet and Planner stay fully manual. Deterministic tools never pose as conversation. No cloud model, social, research or message tools in V1.

## Capabilities and authority

| Capability | Authority |
| --- | --- |
| Search and insights | Read-only within authorized records. |
| Capture | Opens Photos or Camera; the user reviews classification and saves. |
| Outfit, theme, plan, wear, piece edit | Drafts only; the user reviews exact targets, revisions and changed fields, then approves. |
| Local delete or privacy change | Visible exact impact and explicit confirmation. |
| Weather | Only a fresh, matching, user-selected WeatherKit result; never blocks manual work. |

Ownership and revisions are validated when an action runs, not only when the prompt is built. Notes, generated text and imported metadata cannot authorize a tool call. Photos and private notes are not model context.

## Trips and questions

A trip request ("plan outfits for 3 days in Boracay") becomes one review with a different outfit for each day, up to 7. The app picks varied available pieces (spread across days, dresses and separates alternating, steered by the day's occasion); the model supplies only the day labels. The owner chooses what saving does: the outfits always, plus an optional theme that groups them and, when dates were given, an optional Planner trip. Each step has its own receipt, so applying again after an interruption resumes without duplicates. If the model answers a clear trip request without preparing the review, the app prepares it from the request.

When something essential is missing the Agent asks one question at a time as tappable answers (the `askUser` tool, or answers read from a reply that ends in one question), with "Something else" to type. Only the latest reply keeps its buttons. The Agent never asks the owner for an ID or code.

## Records, handles and names

The model never sees UUIDs or revisions. Each turn the app numbers the owner's active pieces, outfits, themes and plans with short handles (`p1`, `o3`, `t2`, `pl1`) in name order, and shows records to the model as a handle, a name and a few facts. Tools accept a handle or a name. The app resolves it: exact handle, then exact name (case and punctuation ignored), then a unique loose match on the words of the name plus its color, category and tags. Several matches ask the owner which one as tappable answers; no match is a quiet step in the activity list. The app reads the current revision when it prepares a review, and staleness is checked again at Apply. Handles are for tools: a reply that shows a handle, UUID or revision is a grounding violation.

## Intent, tools and context

Each request is classified once by rules into an intent (chat, show, find, stats, what to wear, suggest, trip, plan days, theme, relabel, edit piece, record wear, profile, add piece, out of scope). A follow-up, such as an answer to a question card or "make it dressier", keeps the previous intent. The intent fixes at most three tools, a short instruction snippet and a reply budget (300 tokens, 400 for looks, 500 for plans). Showing and finding records, wear statistics, a planned look, an outfit suggestion, a plain command (rename, mark as laundry, change a color, set an occasion, record wear, edit the profile, make a theme from a kind of outfit), the next few days and a trip of known length are carried out by the app from the owner's words; the model only writes a one-line framing, and if it cannot, the app writes the sentence itself and the cards remain. Anything else, such as trips with dates, goes to the model with at most three tools. A request outside the Agent gets a scope note with no model call. When essential details are missing the app asks, as tappable answers. Outfit picks are constrained to the ids offered, so the model cannot name a piece that does not exist.

One budget splits the on-device window: instructions, tool definitions, room for tool results and the reply come first; then the request, trusted facts, retrieved records and the closet index, and last conversation history. Token counts are measured when the model can count them and estimated otherwise. History is the last four turns word for word plus a short summary of older turns kept on the conversation, never the whole chat. What does not fit is fetched by the lookup tool or dropped, oldest history first.

## Grounding

A finished reply is checked against the owner's records: names in bold, lists or quotes must be real pieces, outfits, themes or plans; a color with a garment must exist together; counts about the closet must match the trusted totals; no handle, UUID or revision may show; and a reply may not say nothing was found while matching cards are shown. A violation regenerates the reply once with the problems as feedback. If it still fails, the reply stays with a note that some items aren't in the closet, and cards are attached only for names that resolve. Violations are kept in the message details. Replies are trimmed of filler openers and closers, lists that repeat the cards, and middle-dot separators.

## Failure states

A failed reply states what happened and offers a way forward: model unavailable or preparing, Apple Intelligence off, request too long, timed out, declined, interrupted, change not prepared, or save unconfirmed. Actions are Retry, Try a shorter request or Edit request (the request returns to the composer), New chat (carries the request), Open Settings, and Continue without closet. Partial text is kept and marked. Proposal cards say exactly what saving will do before the owner opens the review.

## Proposals and execution

A proposal has a stable ID, capability, exact target IDs and revisions, proposed changes, source limits and status. Approval binds to that version; changed targets, content or source revisions require a fresh review. Execution uses an idempotency key (proposed → approved → executing → succeeded, failed or cancelled), runs the same domain operations as app buttons, and shows receipts linking real saved records. Unknown outcomes are reported honestly and retries check prior completion first. Cancel stops generation and unapproved writes; a committed write is not rolled back. Bulk plan application is all-or-nothing.

## Context and quality

- Context is explicit and bounded: general (no closet), eligible metadata, or selected pieces, outfits and themes. If the closet exceeds the request limit the user picks Selected pieces or Without closet; no arbitrary subset is sent.
- Style answers (goals, occasions, fit, colors, optional body details) are used only with their own permission and a revocable setting. Unknown or declined stays unknown.
- Output is validated for structure and owned active IDs. Complete outfits meet the requested form or explain gaps; theme requests return theme reviews; pinned pieces survive replacement; manual edits survive retry. Long plans are generated in bounded batches and committed only after a full preview. Statistics come from trusted queries with explicit windows.

## Conversation

Durable conversations with history, new and delete, typed drafts kept across interruption, streaming with Stop and hard timeout, same-turn retry, copy as plain text, Markdown or code, safe Markdown rendering (no remote images or HTML), and per-message details. Voice and image intake are enabled only after on-device support is verified; typed input always works.

## Acceptance

- Unsupported device or model shows the reason and a manual route; cancel writes nothing.
- A stale or already-applied approval never writes twice or on changed revisions.
- Deleting a conversation does not change wardrobe, plans or wear.
