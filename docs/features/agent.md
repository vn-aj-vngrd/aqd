# A — Agent and focused assistance

## Phase boundary

V1 has a complete local Agent destination with conversation/history/cancel/retry/copy/Markdown, grounded local queries, outfit/theme/plan drafts and reviewed local actions. On-device/rules/manual availability states are required. Online research/weather/social/message tools and server feedback are V2; photo/speech context needs verified on-device support. See [V1 release](../product/v1-release.md), [V2 backlog](../product/v2-backlog.md) and [V2 design](../design/v2-requirements.md).

## Scope and outcome

One capability surface supports both full-screen Agent and focused app actions. Agent covers style, clothing, weather, travel, and everyday planning, using authorized wardrobe context and domain actions. General answers are distinct from personal facts and verified current information. Unsupported topics get a brief scope explanation and relevant next step.

On-device AI remains the user's preference in both phases. Current Foundation Models code demonstrates limited text-based drafting, not image tagging, comprehensive multi-month planning, or a production tool loop. Unsupported device/model state offers manual work and clearly named deterministic rules; it never labels rules as model output. A cloud-provider change requires an explicit product decision.

## Capability and authority map

| Capability | Inputs and result | Authority |
| --- | --- | --- |
| Search/insight | Authorized item/history filters; referenced results/statistics | Read-only within access scope. |
| Capture | Open user-controlled Photos/Camera; item draft | User selects media; review classification and save. |
| Outfit/theme | Context/pinned items; owned-item combination or collection draft | Review/edit before save. |
| Planner | Dates/routine/event/constraints; dated assignment draft | Review entire changeset, gaps, and conflicts before commit. |
| Item/outfit/theme/plan edit | Exact IDs/revisions and proposed fields | Review changed fields; manual validation applies. |
| Wear | Item set/date/plan entry; proposed wear or correction | Review; enforce history duplicate rules. |
| Publication/privacy/delete | Exact targets, impact, public preview | Explicit review and confirmation. |
| Human message | Recipient/conversation and content/reference draft | Explicit send approval; no default Inbox reading. |
| Weather/current information | Selected location/date and permitted retrieval | State source, timestamp, missing coverage; unsupported retrieval is visible. |

Full ownership/access validation happens when actions execute, not only during prompt construction. User notes, generated text, public captions, and imported metadata cannot authorize a tool call. Photos/private notes are absent from current model context; adding them requires a scoped reviewed feature.

## Proposal and action contract

A proposal has stable ID, capability, exact target IDs/revisions, proposed changes, source/context limits, preview, and status. It is a draft, not a saved entity. Approval binds to that proposal version; editing targets/content or changed source revisions requires refreshed preview/review.

Execution has an idempotency key and states proposed → approved → executing → succeeded/failed/cancelled. Rejected proposals do not execute. On retry, determine prior completion before resending. Changes succeed through the same domain operations as app buttons. Show receipts linking actual saved entities; report partial or unknown outcomes honestly. Bulk plan application follows the all-or-nothing contract in [Planner](planning-history.md).

Cancellation stops generation and prevents unapproved writes. If an approved write has already committed, cancel does not claim rollback; show completion and available undo. New conversation turns do not silently reuse an old approval. Permanent deletion/publication/message sends require visible exact impact or destination.

## Context and output quality

Bound wardrobe slices and tool work; say when only a subset is considered. Search/retrieval selects relevant records rather than dumping unlimited photos/history into a prompt. Personal statistics come from trusted queries with explicit windows/denominators, not guessed arithmetic. Unknown condition, purchase date, location, weather, or personal preference remains unknown.

Validate output structure and owned active IDs. Suggested complete outfits meet their requested form or explain gaps. Theme-only requests return a theme review, not an accidental outfit action. Pinned pieces survive replacement. Manual edits are preserved on retry. Long plans are generated in bounded batches but committed only after a full validated preview.

## Acceptance and evaluation

- A1: Same manually entered and Agent-approved action passes identical domain validation.
- A2: Unsupported model, tool error, timeout, or cancellation preserves records and offers a manual next step.
- A3: A theme-only request opens theme review; outfit IDs are owned/current; pinned IDs remain fixed.
- A4: Ambiguous “delete that” asks which target; injected public text cannot cause a write/send.
- A5: Stale proposal/source revision refreshes review; double approval/retry creates one result.
- A6: Review a two-week plan and cancelled proposal without any calendar mutation.
- A7: Generated “saved” language is not displayed as execution success without a receipt.
- A8: Personal insights are reproducible from the cited scope; weather claims match available dated context.
- A9: Publication/send approval is bound to exact content and destination; Inbox remains unread by default.
- A10: Evaluate physical-device availability/latency and realistic prompts separately from mocked tools and host tests.

Evaluation fixtures cover insufficient closets, unavailable pieces, ambiguous names, corrupt output, stale ownership, denied media permission, unknown weather, long routine conflicts, duplicate operations, malicious captions, and revoked content. Record failures and supported capability limits before widening the feature. Usage, approval/error metrics, and user feedback are useful; default telemetry excludes wardrobe photos, notes, and chat bodies.

## Response lifecycle design

[V1 local release](../product/v1-release.md) and [V2 connected core](../product/v2-release.md) include basic local history, cancel/retry, copy, response rendering, proposal details and real receipts. Advanced response-version comparison and server-collected rating/comment feedback are V2; hide their unavailable entry points at launch. Internal quality evaluation remains mandatory V2 engineering work.

[Agent experience](../design/agent-experience.md) defines streaming, measured progress/timing, cancellation, response versions, copy, feedback for evaluations, privacy consent, history and failure recovery. Paper page 02 · V2, section 05 · Agent is the visual reference and page 00 owns shared components. These design contracts do not authorize a provider switch or enable an unapproved feedback service.

Agent response content supports Markdown, including incremental rendering, safe links and plain-text/source copy, through the shared [Markdown contract](../design/agent-experience.md#markdown-responses). Markdown never authorizes a write or substitutes for a structured proposal/receipt.

## Rich input acceptance · October 2, 2026

The authorized design expansion is specified in [Agent input](../design/agent-input.md). It adds user-selected photo/file/camera intake, typed closet selection and reviewed voice transcription to the design. It does not establish model image/speech capability or authorize cloud processing. Unselected photos, private notes and Inbox remain excluded.

- A11: New blank chat focuses the multiline editor once; history, stream updates and picker cancellation preserve focus/drafts without reopening the keyboard unexpectedly.
- A12: Attach/review/remove user-selected images and owned pieces/outfits/themes; preparation, permission denial, invalid files, no matches, stale selection and retry preserve remaining text/context.
- A13: Explicit recording permission, recording, transcription and editable transcript review work without automatic send; denied/unavailable/no-speech/error/interruption states retain the typed draft.
- A14: Waiting status shimmers only in standard motion; Reduce Motion/VoiceOver use a readable static label. Text actually streams in chunks; no hidden completed answer behind simulated progress.
- A15: Stop acknowledgement, send failure, interrupted generation, timeout and unknown execution have distinct recovery; retry never duplicates a message or an approved write.
- A16: Light/dark, opaque material, accessibility text, safe-area/keyboard, RTL and assistive navigation preserve every input action.

These are implementation acceptance targets; native/runtime evidence remains required.
