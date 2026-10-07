# Agent response experience

Phase scope: shared native/visual rules apply to both phases. Five-destination base navigation applies to both phases. Full-app E/W/P/S/A/I/U routes, online identity and connected states are V2 references. Complete private themes/planning/Agent are retained in V1. V1 uses its [dedicated local flow](v1-flow.md), with A33 shared under the [optional native weather contract](weather-context.md), and [complete local release](../product/v1-release.md); [V2 requirements](v2-requirements.md) own connected and extension coverage.

Release boundary: [V1](../product/v1-release.md) and the V2 connected core both require local/private history, response rendering, cancel/retry/copy and proposal/receipt details. Response-version comparison and server-collected evaluation feedback below are [V2](../product/v2-backlog.md) design targets, not launch controls.

[Paper page 02 · V2, section 05 · Agent](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0) owns the screen designs; phase-owned references retain response lifecycle/composer examples, while [Foundations](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-1-0) owns the reusable controls, icons and generic states. This contract supplements [Agent capabilities](../features/agent.md). Designs and sample timings are illustrative, not runtime or service validation.

## Conversation lifecycle

The page-00 Status and progress spinner also owns the app-wide indeterminate loading reference. Content loading, save/search/pagination and account work reuse this same circular indicator; no feature introduces its own spinner silhouette. Native progress and accessibility behavior remain platform-owned. See [shared loading indicator](components.md#shared-loading-indicator).

A11 prepares a response, A12 streams it, and A13 completes it. A14 preserves a stopped response, A15 preserves an interrupted response, and A16 explains slow work. A17 exposes real task progress. A29 distinguishes a message that never reached the runtime from a reply that failed midway. A30 asks for missing information before acting. With no matching pieces, explain the constraint and offer Add piece or the manual builder. For an unsupported request, name the supported closet task without pretending a tool ran. If context capacity is reached, offer a new conversation with a user-reviewed summary; never silently omit a material instruction.

[Agent input](agent-input.md#one-native-glass-composer) owns Send eligibility, including supported attachment-only input and runtime availability; response lifecycle consumes that validated send intent. During generation, Stop replaces Send in the same 44-point target. Keep an editable next-message draft; do not send it implicitly. Stop remains available while cancellation is pending, with duplicate taps suppressed and an announced stopping state. Confirm Stopped only after acknowledgement. Preserve partial text and label it incomplete. Retry creates another response version; it does not append a fabricated continuation or repeat a write.

Streaming appends text in readable chunks without animating every character. Follow the bottom only while the reader is already there. If they scroll away, preserve position and expose a 44-point “Jump to latest” control with an unread-update indicator. Do not steal focus, repeatedly announce tokens, or resize the composer. VoiceOver announces preparation, completion, interruption and cancellation once; the reply remains navigable by paragraph. Respect Reduce Motion; use a static status label instead of a flashing caret or skeleton shimmer.

When the keyboard opens, inset the scroll content and dock the composer above it. The input grows to a bounded height, then scrolls internally. Multiline input, selection, dictation, paste and system text editing remain native. Text fields keep native editing inside one regular-glass functional shell; the floating composer is itself that shell. Do not add a second glass background to the inner editor or duplicate native button material. Reduced Transparency uses an opaque neutral surface with the same geometry. Dynamic Type may wrap labels and move metadata below content; it never shrinks type to preserve a mockup.

Backgrounding must not promise continued on-device generation. Persist input, received text and run state; on return reconcile the runtime and show paused/interrupted if work stopped. Restore conversation, scroll position and drafts. Conversation loading, empty and failure are separate A24–A26 states; retain cached conversations during refresh. A deleted or inaccessible conversation explains its unavailability and offers a new conversation.

## Markdown responses

Agent responses support Markdown in both streaming and completed states. Use one shared `AgentMarkdownBody` renderer for every response version, partial reply and appearance. Plain conversational replies remain valid; add headings and lists only when they help the answer. User messages remain literal text unless an explicit preview mode is introduced.

Support paragraphs, headings, bold, italic, ordered/unordered lists, block quotes, links, inline code and fenced code. Support simple tables and read-only task lists as explicit extensions. Markdown checkboxes are content, never controls that mutate closet data. Raw HTML is not rendered; unsupported or malformed syntax degrades to readable text. Remote Markdown images and embeds do not load automatically; authorized clothing media uses the existing typed media component.

Shared typography: body 17/24, primary response heading 22/28 medium, secondary heading 20/26 medium, lower headings 17/24 semibold; map Markdown heading levels to semantic heading traits without oversized page titles. Use 12-point block gaps and 20-point section gaps, a fixed list-marker lane, and at most two visible indentation levels before simplifying the presentation. Emphasis uses weight/style rather than a new accent color. Quotes have an inset neutral rule. Links are underlined as well as tinted. Inline code uses system monospaced text with a subtle neutral backing; fenced code has a labelled, horizontally scrollable block and a 44-point Copy code action. Ordinary prose wraps; code and wide tables scroll inside their own block, never the entire conversation. Tables retain header associations and use labelled rows at accessibility sizes. Use the existing light/dark semantic tokens and Dynamic Type.

Streaming preserves completed block identities and the reader's scroll position. Buffer incomplete Markdown delimiters, links and fences or display their unfinished text literally; do not flash raw syntax, repeatedly rebuild earlier blocks, or hide received text indefinitely. A link becomes interactive only when its syntax and destination are complete and validated. On Stop/error, preserve the exact partial source and render a readable incomplete response. Announce meaningful status changes rather than every formatting change. Headings, lists, links and code remain selectable and accessible to VoiceOver.

Persist Markdown source with the response ID/version. Default Copy produces readable plain text with paragraph/list structure and useful link destinations; More offers **Copy Markdown** for the exact source. Copy code includes only that code block's contents. All copy variants exclude hidden reasoning and tool payloads, retain an incomplete marker for partial replies, and acknowledge clipboard success before showing confirmation. A content-sharing preview must show the same response version and formatting the user saw.

Validate link destinations against an explicit scheme policy. External web links open through the system browser; internal closet links resolve through authorized typed record references. Reject executable schemes and do not treat Markdown URLs or model-written buttons as tool authorization. Saved receipts and review actions remain trusted structured components outside the Markdown body.

Native acceptance includes fragmented bold/link/fence chunks, Unicode and emoji boundaries, long URLs/code lines, nested lists, malformed tables, cancellation inside a block, large text, light/dark, text selection, VoiceOver structure, rejected URLs, both copy formats and persisted response-version fidelity. Paper demonstrates styling, not a running Markdown parser.

## Progress and time

One compact status row combines a native indeterminate indicator, an event-backed phase and elapsed time. Preparation, checking context, writing, validating and saving are distinct states. Show counts only when a real event reports completed work and a known denominator (for example 8 of 14 dates). Never infer a percentage from generated tokens or disclose hidden reasoning. Do not invent an ETA.

Use a monotonic clock for elapsed duration, frozen at terminal status; show a localized timestamp for the message. Display seconds during short work and minutes:seconds for longer work. A18 details exposes measured total time and time to first text, actual runtime and the authorized context summary. Missing measurements read “Unavailable”, not zero. Keep generation duration separate from saving and feedback delivery time.

Slow and hard-timeout thresholds belong to runtime configuration, not the visual system. Slow status preserves Stop and offers a manual path. A hard timeout preserves input and partial output, identifies that the attempt ended and offers a fresh attempt. Runtime download progress is determinate only if supplied by the system; otherwise show preparation. Unsupported hardware, disabled intelligence, download required and temporary failure route to A07 with the correct reason and a clearly named rules/manual alternative. Offline must not disable working on-device assistance merely because connected features are unavailable.

## Response actions and versions

V2 completed assistant responses have Copy, Try another response when supported, and More/details. V2 adds Helpful and Not helpful. Symbols use the shared icon catalog with 44-point targets, labels and selected traits. Selected feedback uses a thicker symbol and accent-soft background. Actions attach to the displayed response version, not the entire conversation. Copy and feedback remain available on a clearly labelled partial response; Retry never transfers prior approvals.

Copy writes rendered text in reading order without hidden prompts, tool payloads or internal IDs. Include a visible incomplete marker for partial replies. Announce “Response copied” only after clipboard success; on failure announce the failure and retain a retry action. A27 shows the copied/selected state. A28 retains previous versions with disabled first/last navigation edges. Feedback and receipts remain associated with their original version. Details may expose context sources, tool outcomes and timing; never hidden reasoning, secrets or an invented confidence score.

## Feedback for evaluations

Thumbs up records Helpful; thumbs down opens A19 with optional reasons and a note. Reasons are incorrect closet details, instruction not followed, not useful, slow, and other. No reason is preselected in a fresh form; the Paper selection illustrates an edited state. Neither a reason nor a note is required to submit a rating. Changing the rating updates the same response-scoped record. Clear feedback is available from More. During submission, retain the button label with a progress indicator and prevent duplicate requests. A20 acknowledges actual receipt; A21 retains the local draft after failure. Pending is never labelled received. If acknowledgement is lost, say delivery could not be confirmed and reconcile the same idempotency key; do not claim nothing was shared.

Default content sharing is off. The consent review names the exact response text being attached; sharing a prompt requires a separate explicit choice. Do not attach the whole conversation, photos, private notes or Inbox content. Retain draft consent and selections locally, but do not silently upload later. Backend/evaluation transport, retention and deletion remain service gates; an unconfigured service shows an honest unavailable state rather than a fake submission.

Suggested versioned feedback envelope: feedback ID/idempotency key, response ID, response version, run ID, rating, reason enums, optional user note, consent version and explicitly selected attachments. Runtime/model version and application version support evaluation grouping; do not infer them. Stable pseudonymous identifiers are sufficient; no email or username is needed. Respect analytics/privacy preferences and the approved retention/deletion policy before enabling collection.

Operational measurements: first-text latency, total response duration, cancellation and error outcomes, actual tool result, proposal approval/rejection and persisted receipt. Missing metrics are unknown. Ratings are subjective signals, not correctness ground truth. Evaluate authorization, correct item references, stale-data handling, unsupported claims, draft validity and recovery separately using consented examples or synthetic fixtures. Report sample sizes and runtime/version cohorts; do not show a fabricated quality score to users.

## Optional current weather context

Basic native WeatherKit is shared V1/V2, not external research or a cloud LLM. Weather availability is independent of Agent eligibility: it can work when Foundation Models cannot. A33 retains its existing canonical identity and returns to the actual context/response draft without sending or saving. [Weather context](weather-context.md) owns opt-in/off, Apple city-query disclosure, explicit location gesture, matching place/date/timezone, source/provider/fetch timestamps, required attribution and bounded fresh/Saved/unavailable states. Fresh explicitly selected data may inform a next request; stale context is never silently treated as fresh, and model prose cannot invent weather. Cancel/Continue without weather preserves the private task and manual styling; no closet/photo/body/chat uploads or changes to body-use consent. Forecast coverage uses returned periods up to ten days, never a two-week or historical-weather promise.

## Approval and recovery

A02 proposes; A03/A10 review a version-bound draft; A22 executes the approved version; A04 shows the persisted receipt. A23 invalidates approval when source data changes. Refreshing a draft requires another review. Saving is not response streaming: Stop generation is not rollback. Unknown write outcomes use A09 and reconcile the operation ID before retry. Leaving the view cannot undo a committed change. No result claims saving, publishing or sending without a receipt.

## Verification before implementation acceptance

Verify streaming, cancellation acknowledgement, long replies, reader-scrolled-up behavior, keyboard/dictation, large text, VoiceOver, Reduce Motion, Reduced Transparency and neutral dark mode on device. Inject first-token failure, midstream failure, timeout, background suspension, send retry, stale proposals and unknown write outcomes. Test copy failure, feedback pending/success/failure/change/clear, no-service mode and explicit content consent. Inspect actual telemetry for correct version linkage and absence of default chat-body uploads. Paper screenshots establish static layout only.

## Reference patterns

[ChatGPT recovery guidance](https://help.openai.com/en/articles/7996703-troubleshooting-chatgpt-error-messages) supports stopping and retrying a stuck generation. [ChatGPT reporting](https://help.openai.com/en/articles/10245791-reporting-content-in-chatgpt-and-openai-platforms) places reporting near response feedback. [Claude feedback guidance](https://support.claude.com/en/articles/12902405-claude-in-chrome-troubleshooting) uses response feedback with additional detail. AQD adapts these patterns to its on-device runtime and explicit write-review contract; this research used official documentation, not an authenticated audit of every product variant.

## Motion inheritance

Use [Global motion](motion.md), particularly C-stream, C-receipt and C-save. No animation per token, Markdown relayout or elapsed-time tick. Keep Stop immediate, preserve partial responses, and follow the latest message only while the reader is already at the bottom. The [coverage matrix](motion-coverage.md) assigns A01–A30.

## Complete composer refinement · October 2, 2026

[Agent input](agent-input.md) now owns autofocus, multiline growth, media/file capture, selected closet context, voice dictation, busy-label shimmer and their recovery/accessibility contracts. A34–A55 extend the existing lifecycle; A01 and all existing composers use the same richer shell. Page 00 owns the multimodal composer and shimmer/recovery masters. These remain Paper/design targets, not an implemented streaming or speech runtime.

For V2, completed responses expose Copy, Retry when supported and More/details. Helpful / Not helpful and version comparisons described in the future sections above remain V2. The user-requested shimmer applies only to the active status label, with a static Reduce Motion/VoiceOver equivalent; streamed prose never shimmers.

## Selective assistance indicators

Agent supplies an explicit assistance context. Its starter prompts, response toolbar, regeneration, Refresh draft, Try again, resend and native Retry menu use ordinary task labels and symbols without an AI badge. Keep the shared badge on focused model-powered assistance in Closet, Home and planning where it clarifies an otherwise ordinary action. See [the badge contract](icons.md#ai-assistance-badge).
