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
