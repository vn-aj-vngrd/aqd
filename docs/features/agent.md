# A — Agent and focused assistance

## Phase boundary

V1 has a complete local Agent destination with conversation/history/cancel/retry/copy/Markdown, grounded local queries, outfit/theme/plan drafts and reviewed local actions. On-device/rules/manual availability states are required. Optional basic native WeatherKit selected-place/date context is V1, governed by the [weather contract](../product/v1-release.md#optional-live-weather-contract), not an unrestricted weather tool. Advanced external weather providers/context, online research/social/message tools and server feedback are V2; photo/speech context needs verified on-device support. See [V1 release](../product/v1-release.md), [V2 backlog](../product/v2-backlog.md) and [V2 design](../design/v2-requirements.md).

## Scope and outcome

One capability surface supports both full-screen Agent and focused app actions. Agent covers style, clothing, weather, travel, and everyday planning, using authorized wardrobe context and domain actions. General answers are distinct from personal facts and verified current information. Unsupported topics get a brief scope explanation and relevant next step.

On-device AI remains the user's preference in both phases. Current Foundation Models code demonstrates limited text-based drafting, not image tagging, comprehensive multi-month planning, or a production tool loop. Unsupported device/model state opens the reason-specific availability screen; manual work remains available in Closet/Planner. Deterministic tools never pose as conversational AI. V2 includes a planned explicit LLM provider option; no provider is selected or provisioned by this design.

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
| Weather/current information | Explicit selected location/date and permitted native WeatherKit retrieval in V1/V2; advanced sources V2 | Only fresh matching returned data is Agent input; source/place/timezone/date/freshness and SDK attribution required. Saved/expired/missing/out-of-range context is not current fact. No wardrobe/photos/body/chat sent to weather/search services; unavailable weather never blocks manual work. |

Full ownership/access validation happens when actions execute, not only during prompt construction. User notes, generated text, public captions, and imported metadata cannot authorize a tool call. Photos/private notes are absent from current model context; adding them requires a scoped reviewed feature.

## Proposal and action contract

A proposal has stable ID, capability, exact target IDs/revisions, proposed changes, source/context limits, preview, and status. It is a draft, not a saved entity. Approval binds to that proposal version; editing targets/content or changed source revisions requires refreshed preview/review.

Execution has an idempotency key and states proposed → approved → executing → succeeded/failed/cancelled. Rejected proposals do not execute. On retry, determine prior completion before resending. Changes succeed through the same domain operations as app buttons. Show receipts linking actual saved entities; report partial or unknown outcomes honestly. Bulk plan application follows the all-or-nothing contract in [Planner](planning-history.md).

Cancellation stops generation and prevents unapproved writes. If an approved write has already committed, cancel does not claim rollback; show completion and available undo. New conversation turns do not silently reuse an old approval. Permanent deletion/publication/message sends require visible exact impact or destination.

## Context and output quality

[Shared preference onboarding](../design/onboarding-personalization.md) supplies explicit goals, occasions, style, fit/comfort, colors/patterns and optional self-described height/body shape. The same draft/save flow is editable from Settings and Profile Style. Unknown/explicitly declined answers stay unknown; the entered questionnaire uses numbered progress and no skip controls. Optional body context requires its purpose-specific use permission and enabled Style context; no photo-derived measurement, body score, exact-size promise or implicit cloud inclusion. Revoking use excludes those details from new attempts, not an already-running request. Deterministic eligibility and manual creation remain available without any answers or model capability.

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

## Agent availability and provider selection

Owner decision, October 6, 2026: keep the Agent tab visible, as the fourth of Home · Closet · Planner · Agent · Profile, with its existing sparkle icon, explicit Agent accessibility name and native selection treatment on every AQD-supported iPhone; the shared tab bar has no visible captions. Availability changes the destination content, never the navigation identity. Check the on-device runtime when opening Agent and before generation. Unsupported V1 devices show an explanation rather than a composer that cannot send. The closet, manual outfits and planning remain usable; no hardware upgrade prompt or automatic cloud fallback.

Use [SystemLanguageModel availability](https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/availability-swift.enum/unavailablereason), with an OS/API guard and supported-locale checks, rather than a hard-coded iPhone model list. Apple distinguishes deviceNotEligible, appleIntelligenceNotEnabled and modelNotReady; [Apple's sample](https://developer.apple.com/documentation/foundationmodels/adding-intelligent-app-features-with-generative-models) demonstrates reason-specific alternatives. Unknown or unsupported OS/locale conditions get honest generic unavailability copy, not an unsupported-hardware claim.

| Runtime condition | User-facing message | Recovery and Paper |
| --- | --- | --- |
| Device not eligible | Agent isn’t supported on this iPhone. This version uses Apple Intelligence, which this iPhone doesn’t support. Your closet and planner still work. | L19: Open Closet primary; About Agent opens local capability/help. No retry implying unsupported hardware can become eligible. |
| Intelligence disabled | Turn on Apple Intelligence. Agent needs Apple Intelligence enabled on this iPhone. | L80: How to enable it opens local instructions for iPhone Settings; Open Closet secondary. Do not assume a private deep link into Apple's Settings panel. |
| Model not ready | Agent isn’t ready yet. Apple Intelligence is still preparing its on-device model. | L81: Check again re-reads runtime state, never fabricates download progress; Open Closet secondary. |
| OS/API/locale unsupported or unknown | Agent is unavailable on this iPhone, with the verified reason where known. | Manual route; OS update guidance only when actually applicable. No endless retry. |
| Available | Existing Agent conversation/composer | Revalidate before sending. Availability alone does not prove output quality or image/speech capability. |

The fourth-slot Agent launches the existing native full-screen task. Back/dismissal restores the originating tab/task, preserved selection, scroll and accessibility focus; Open Closet selects Closet without losing the previous task. Preserve local conversations, drafts, selected context and approvals when availability changes. Existing conversation history stays readable through history/data controls, with no composer or write action that requires an unavailable model. A running attempt that loses availability stops safely, retains received content/draft and requires fresh validation before a new attempt. The same reason applies to focused Suggest/Style/Plan actions: explain it in context, retain pins/fields and offer manual creation. Do not replace model chat with an unlabeled rules engine. Re-check on foreground return and explicit Check again; do not spin indefinitely.

WeatherKit is independent of this model gate: unavailable Agent/AI does not disable optional weather in Home/Outfit/Planner. LOCAL-16 tests this distinction; models cannot invent live forecasts or silently retrieve weather without the weather contract's consent/request budgets.

V2 adds a user-selected LLM provider option, including on iPhones without Apple Intelligence. On-device remains available where supported; cloud use is opt-in, never inferred from opening Agent, a failed local request or app upgrade. Before the first cloud request, show provider identity, included text/closet/media context, where processing occurs, relevant retention/deletion terms, connectivity and actual pricing/quota requirements. No automatic failover between providers. Provider/network/quota errors preserve the draft and offer an explicit retry/change provider/manual route. Provider changes affect new attempts; old history keeps provider provenance and existing local tool approval/ownership/revision checks apply equally. V1 shows no nonfunctional provider picker or promised release date. Provider, model, credentials/backend, billing and retention implementation are unresolved V2 decisions.

Acceptance: Agent tab is visible on eligible/ineligible devices; each availability condition routes correctly; no unavailable composer/send or fake response appears; Back/manual routes preserve destination/draft; foreground availability changes restore usable Agent only after a runtime check. Validate Dynamic Type, VoiceOver reading order/focus, both appearances and actual device/locale/OS combinations. V2 additionally tests first-request consent, unsupported hardware with a selected cloud provider, opt-out/provider changes, quota/offline/errors and prohibition of implicit cloud fallback. Static Paper states are not runtime proof.
