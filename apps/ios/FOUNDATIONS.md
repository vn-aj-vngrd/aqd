# Native foundations

Foundation #20 extends the existing capture app, not a component-gallery destination. [DESIGN](../../DESIGN.md) and [native contracts](../../docs/design/native-ios.md) own requirements; [verification](../../docs/delivery/verification.md#foundation-20-authorized-native-verification--october14) owns current observed results and blockers; earlier dated receipts remain historical.

## Reuse the real consumers

| Component | Responsibility | Current consumers |
| --- | --- | --- |
| `AppTheme` | 25 paired semantic color roles; native appearance inheritance | Existing roots, capture, details and photo editor |
| `AppMetrics` | Spacing, radii, control minima, scalable typography and recorded-timezone date labels | Shared controls and visible plan dates |
| `AppEmptyState`, `EmptyStatePage` | Centered native message with semantic typography; page actions use bottom safe-area footer, inline card notices opt out of viewport filling | Collection/search, Profile, Planner, wear and recovery empties |
| `PrimaryAction`, `SecondaryAction` | Solid primary/plain secondary; optional native destructive role and danger fill, wrapping, neutral disabled state, one pending spinner and duplicate-activation refusal | Capture/save/receipt, photo editor, details and Agent manual return |
| `ActionStack`, `ActionFooter` | 12-point action gap and native safe-area content footer | Existing capture/editor/detail tasks; no viewport or keyboard offsets |
| `LabeledControl`, `LabeledField` | Persistent label, opaque native input, associated validation/helper, Increase Contrast boundary; optional feature-owned editing focus | Name/metadata/notes; native Category and Availability Pickers |
| `MetadataText` | Native footnote/secondary typography, wrapping, Dynamic Type, dark/RTL and single static-text exposure | Capture Photo caption and photo-source explanation |
| `DisclosureRow`, `SurfaceGroup` | Reference-backed54pt disclosure geometry; container-owned separators only between rows | Photo-source group consumes `SurfaceGroup`; `DisclosureRow` is ready for section-owned rows, not imposed on the plain More details link |
| `SemanticFeedback`, `OperationProgress` | Explicit app-owned state, decorative symbol, one meaningful accessibility label/native spinner | Missing-photo/name validation, import/editor progress, acknowledged receipt, Today read failure |
| `NativeTabs` | Public native tab items, stable root hosts, prominent source-preserving full-screen Agent and Settings-scoped chrome visibility | Today / Closet / Planner / Agent / Profile |

TextFields receive their spoken persistent name directly; the input shell must not overwrite a Picker's native selected-value label. Feedback severity is supplied by the caller, never guessed from error prose. Existing mixed failure/conflict/unknown-write channels keep their exact recovery text. Success appears only after a real acknowledgment. `AppAppearance` is a presentation utility; section09 owns persistence and Settings controls.

The Closet destination uses registered `hanger`, not the `tshirt` garment-placeholder role. Selected tab symbols use native semibold configuration and explicit accent tint; inactive symbols use secondary tint. UIKit owns geometry, materials, selected traits and accessibility targets; no private subview hacks or custom glass bar. The Agent-as-tab-launch HIG exception remains explicit. On iOS27 the native prominent tab separates Agent from the four destinations, using UITab identity and selection APIs; earlier systems keep native grouped tabs.

## Paper reference inventory

Live read-only file `01M3SM2KBHBZG6MA0Q744Y9NW0`, Foundations `p-1-0`: 26 roots / 2,101 nodes, token hash `fdeb7346`, October13. All26 roots were enumerated through the complete root tree. Detailed reads were bounded to affected component descendants; enumeration does not certify every descendant or native parity.

| Roots | Native ownership |
| --- | --- |
| `1-0` | Introductory reference; not an app route |
| `WCL-0`, `WCQ-0`, `WDN-0`, `WDS-0`, `WDX-0`, `WE2-0`, `10N9-0` | Seven structural section headers; no invented destinations |
| `FP1-0`, `1JB-0` | Semantic palette, type/space/material roles |
| `14I-0`, `A9A-0` | Shared control states/sizing, native selection and editing |
| `4LD-0` | Flat input/disclosure/group geometry; calendar/conversation behavior belongs to its consuming section |
| `4E1-0`, `10S3-0` | Empty/loading/recovery and five app-owned feedback roles |
| `4GB-0`, `JKP-0`, `4MI-0` | Native presentations, five destination identities and registered symbol roles |
| `83E-0` | Native motion ownership; no custom navigation animation added |
| `7US-0` | Photographic avatar reference, not permission to seed people/assets; Profile consumer belongs to08 |
| `10NC-0`, `10ND-0`, `10NK-0`, `10NL-0`, `10NM-0` | Native chrome/opaque content, critical/routine decisions, API/accessibility reference contracts |
| `11H4-0` | Official kit27 and historical UIKit26.5 provenance; not AQD runtime evidence or redistributable production UI |

Affected live descendant trees: `14I-0`, `4LD-0`, `4E1-0`, `4GB-0`, `10S3-0`, `10NM-0`, `JKP-0`, `1JB-0`, `83E-0`, `11H4-0`; computed action/field/group/feedback/tab styles and the `14I-0` render were inspected. Official kit asset `11HE-0` was read for provenance, not copied into the app. V1 Foundation references `X71-0` and `X7B-0` were inspected: their sheet/capture/menu/proposal/Profile compositions remain reference-only, not permission to implement outfits or Profile in Foundation. Legacy internal Home labels in the native master do not change the app's Today identity.

## Current native qualification

[Verification](../../docs/delivery/verification.md) owns current and historical native receipts. Shared metadata, semantic Back/Close, tab selection and capture/details recovery have scoped evidence; the current iPhone17ProMax/iOS27 Notes short/multiline keyboard proof now passes after the bottom-anchor correction. Preserve earlier failed receipts and all original assertions, with older-runtime/broader regression qualification retained for #30. No physical-phone capability/performance acceptance is inferred.

The [implementation plan verification policy](../../docs/delivery/implementation-plan.md#verification-policy--owner-approved-october15) governs feature checks versus final runtime hardening. [Current status](../../docs/delivery/implementation-status.md) summarizes delivered behavior without duplicating execution counts here.

## Code-only parity follow-up · historical October13

The [bounded Paper/docs → source comparison](../../docs/design/evidence/foundation-code-parity.json) records concrete nodes, role geometry and reference variations. Actions preserve the pill when text grows; disabled fill is opaque `color-line`. Field labels follow the Foundations15pt medium/secondary master; ordinary helper text stays regular. Disclosure rows use54pt/12pt corners/8pt vertical insets, not the52pt/16pt-corner selection-field role. Feedback uses14pt vertical/16pt horizontal padding. Source commands retain their distinct56pt reference, label-aligned separator and no trailing chevrons; their native sheet content now scrolls. More details remains the plain supporting link in the capture reference.

Reset now creates a new preview request even at zero rotation; pending work prevents accepting an unfinished zero-degree retry, and superseded results cannot replace it. At this code-only checkpoint, new/updated native tests were authored **but not run**. No build, simulator or runtime verification ran in that follow-up; the [current verification](../../docs/delivery/verification.md) supersedes its execution status. Pixel-level/native material, accessibility and acceptance remain deferred; conflicting master/consumer weights are disclosed rather than claimed identical.

## Keep storage and recovery at existing seams

Shared views emit user intent. `CaptureModel` retains drafts and operation identities; `PieceStore` validates current records and exact acknowledgments; `PhotoPreparer` prepares local media; the existing reference graph protects current pieces/drafts/recipes before cleanup. No schema, migration, receipt or cleanup algorithm changes in Foundation.

Section-owned records/validators extend their real consuming feature and this existing local store. Do not add a generic future platform, remote command framework, cloud fallback or new storage domain here. Existing isolated SwiftData/media tests and UUID-isolated public UI journeys are the reusable failure/restart fixtures. They never reset the ordinary closet. Physical file protection and device backup behavior still require device observation.

## Capability evaluation gate

No Foundation Models, Vision removal, voice, weather retrieval or cloud assistance is enabled by Foundation. Opening Agent does not claim a model is available. Manual capture/save stays independent.

Before enabling a capability in its owning section:

- **Deterministic media:** use the manual-original baseline and portrait/landscape/square/panoramic, eight EXIF orientations, low-resolution and high-resolution JPEG/HEIC sources; include invalid/truncated/oversized media, cancellation, stale jobs and relaunch. Existing `PhotoPreparer` enforces64MiB compressed input,40million source pixels,32,768 pixels per axis and serial preparation per actor. These are input limits, not measured peak memory. Profile actual peak memory, decode/edit latency and UI responsiveness on oldest-supported/current physical phones; report failures rather than infer speed from synthetic pixels.
- **Vision:** follow the [30–50 consented garment stress corpus and reviewer rubric](../../docs/references/local-background-removal.md#proposed-acceptance-and-evaluation-not-yet-verified), compare Original/manual crop, permit at most one active photo job, and prove token/revision-bound cancellation. Availability alone cannot enable the action or establish garment quality.
- **Agent:** use [representative failure/quality fixtures](../../docs/features/agent.md) and [status/timeout behavior](../../docs/design/agent-experience.md). Include insufficient/unavailable closets, ambiguous names, invalid IDs/output, stale revisions, malicious captions, interruption and duplicate/unknown writes. Compare manual and explicitly labelled rules baselines. Record model/device/OS/language, first-token/end-to-end latency, bounded context, invalid-proposal rate and actual local availability. Set slow/hard-timeout and context budgets in runtime configuration before activation, based on that evaluation; Foundation has no enabled request path or fabricated measured threshold.
- **Privacy/cost:** V1 has no cloud-model fallback, AQD backend call or default wardrobe/photo/chat telemetry. Weather has its separate consent/attribution/request budgets. Generated prose never authorizes a write; reviewed version-bound validation and one durable receipt remain mandatory.

No device quality, latency, memory or energy evaluation has run for this slice. These are release gates and a reusable evaluation recipe, not performance results.

`LocalDataSummaryView` reuses grouped icon/count rows across export, restore and erase reviews, with plural-aware labels and intrinsic accessible text sizing.
