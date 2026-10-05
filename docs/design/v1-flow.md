# V1 complete local flow
October 5, 2026. [V1 release](../product/v1-release.md) owns scope and LOCAL acceptance. The visual source is [Paper page 01 · V1](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-2-0). Numbered sections follow the earlier review-page format: read each header, then its phones left to right and by row. Step labels are zero-based within each section; L identifiers stay stable.

Home / Closet / Agent / Profile use the same AQD design foundation as V2. Home shows private Today; Closet has Pieces / Outfits / Themes / Planner. Agent opens the same native full-screen task pattern, with Back returning to the originating destination. Profile is personal on this device; Settings is reached there. V2 adds Inbox and connected controls without replacing these private journeys.

## Numbered sections
| Section | Ordered references | Purpose and branches |
| --- | --- | --- |
| 01 · Welcome, onboarding and tour | L60 → L61; L62 → L63 → L64 → L65 → L66; L01 | Welcome shares V2's twelve-piece original garment hero and prepared motion sequence, with private start and tour. Tour is optional; L01 supplements the privacy explanation. No signup. |
| 02 · Home and first piece | L02 → L04 → L05 → L43 / L44; L23 | Empty Home, optional media/manual capture, first-save guidance and planned Home. Readiness derives from actual available categories; illustrative populated Home is an independent returning state. |
| 03 · Closet and themes | L03 / L20 / L21 / L32 / L33 / L34 / L35 | Owned Pieces, Outfits, Themes and Planner; local search/edit/availability/archive/delete use shared forms and exact-impact native alerts. Theme membership never creates a public post. |
| 04 · Create, review and save an outfit | L06 / L18 → L07 → L08; L27 | Manual or supported local suggestion, pin/replace, optional themes, reviewed private save and actual receipt. Editing preserves selection/context. |
| 05 · Planning, routines and trips | L09 / L10 / L36 / L37 / L38 / L39 / L40 / L42 | Dates, routines/events/trips, deduplicated packing and exact conflict review. These are related entry points and conditional cases, not one compulsory funnel. |
| 06 · Actual wear and insights | L11 → L12 / L41 | Record, backdate, correct/undo and inspect factual recorded-data insights. Plans and elapsed dates never record wear. |
| 07 · Local Agent | L24 / L25 / L28 / L29 / L30 / L31 / L26 / L46 / L47 / L19; L68–L74 | Conversation, context, generation/stream, history, theme/field-change review and capability fallback. Independent states include keyboard and verified local voice permission/listen/transcribe/review/fallback/context; generated prose never serves as a receipt. |
| 08 · Local Profile and Settings | L48 → L49 / L45 / L13 → L50 / L51 / L52 | Optional personal name/photo/preferences, owned shortcuts, System/Light/Dark, privacy/help and truthful model capability. |
| 09 · Local data and recovery | L14 / L15 / L16 / L17 / L22 | Sensitive archive export, validated full replacement, exact local erase, failed save and unreadable-store recovery. No sync/account restore. |
| 10 · Appearance | L53–L59 / L67 | Dark references for privacy entry, Home, Closet, Agent, Profile, Settings, appearance and the V2-style Welcome. All local routes inherit both appearances and accessibility rules. |

## Welcome, onboarding and tour contract
Fresh install opens L60, sharing V2's wordmark, editorial photos, type and controls. Start my closet opens L61; Take a quick tour opens L62. Onboarding explains optional photo/manual capture, private local storage and export/device-loss limits before the first piece. Explore first opens empty Home. Permissions are requested only when the user chooses the corresponding media action. Name, photo and style preferences are optional later; there is no compulsory quiz or item count.

Tour steps show Home, Closet, Agent and Profile with explicit **Preview only** labels. Demonstration content never becomes a real record. Each step has Back, Next/Finish and Skip; Back on the first step returns to its entry. Finishing from Welcome opens L66 with Add my first piece / Open Home. Skipping opens empty Home, or returns to Settings when replayed. Settings → Take the tour replays it without changing wardrobe, drafts, preferences or last real destination. Store completion/skip and step state locally; returning users do not repeatedly see onboarding.

For accessibility, focus moves into the tour sheet, background controls are inert, progress and actions have meaningful labels, and larger text uses scrollable content rather than clipped copy. The tour stays readable in dark mode, Reduce Motion/Transparency and localization. Existing users who update to V2 do not repeat the V1 tour; explain only newly enabled connected controls after opt-in.

## Local interaction and recovery
Every entry has native Back and preserves the original draft. A dirty exit offers Keep editing / Discard changes. Save follows validation and successful local persistence; failed/unknown execution reconciles one operation identity. PhotosPicker/camera refusal or cancellation retains manual entry. Search has loading/empty/no-match/error states and restores the previous query/scope.

All complete private W/O/P/A contracts apply within the phase boundary. Shared forms/menus/pickers/sheets cover selected dates, recurrence, activity/destination/timezone, availability, rename/membership, archive/restore/delete, reporting range and actual wear correction. L36 is the routine example; its event/trip variant collects destination/activities instead of recurrence, then uses L40/L42 and L38/L39. Existing private canonical references remain reusable and are mapped in [coverage](v1-coverage.md).

Use on-device Foundation Models for supported bounded drafting; validate eligibility/readiness and selected context. Label deterministic assistance Quick rules, with direct manual routes. Image or speech intake appears only when a demonstrated on-device path is available; unavailable features explain the limitation without a cloud fallback. External research, human messaging and live weather are V2 extensions.

## Review boundary
The phones and sample timings/records are static requirements. [Native acceptance](native-ios.md), [V1 architecture](../architecture/v1.md) and [LOCAL checks](../product/v1-release.md#local-acceptance) require an implemented, reproducible build. No new product code, native runtime test or infrastructure is delivered on this planning branch.
