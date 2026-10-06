# Design quality criteria

Use this checklist when creating, changing, reviewing or implementing AQD UI. Apply it to the affected journey and shared component copies. [DESIGN.md](../../DESIGN.md) owns token values; [Components](components.md) owns component behavior. This checklist defines how to judge the result, not another theme.

## Review procedure

1. Identify the phase, routes, states and shared components from the Paper manifest and flow contract. Record the exact inventory reviewed.
2. Inspect rendered screens and computed styles against each criterion below. Classify evidence as Pass, Fail, Not applicable or Native verification required.
3. Fix failures at the shared token/component level when possible, then synchronize structural copies. Preserve approved product behavior and V1/V2 boundaries.
4. Confirm changed screens and representative variants in one final batch. Record fixes, exceptions and native acceptance gaps in [verification](../delivery/verification.md). Do not mark unseen screens or runtime behavior as passed.

## Criteria

| ID | Criterion | Observable acceptance |
| --- | --- | --- |
| DQ01 | Task and hierarchy | The title, current state and next action are clear. One task action dominates. Draft, review, saved and unavailable states are distinct. The selected tab/segment matches the visible content. |
| DQ02 | Spacing and alignment | Use the spacing scale and 20-point phone content inset. Related items sit closer than separate sections. Primary/plain-secondary stacks use a 12-point gap and 50-point secondary bounds. Title/date pairs use an 8-point gap. Repeated rows have stable leading/trailing lanes. |
| DQ03 | Typography | Equivalent roles share size, weight and line height. Secondary actions are regular weight; primary labels are medium. Titles remain legible without colliding with Back or trailing actions. Long text wraps rather than shrinking. |
| DQ04 | Controls and surfaces | Primary actions use solid semantic accent; content secondary actions are plain action-text without border/shadow. Approved soft Back/View outfit controls remain flat. Inputs are opaque with 16-point corners, 14-point padding and no decorative shadow. Settings rows share grouped semantic surfaces. |
| DQ05 | Compact selection | Filter visuals are 32 points high; segmented rails are 36. Only selected segments have a surface fill. Selection has a visible check/fill/label, with nonoverlapping native hit targets of at least 44 points and Dynamic Type expansion. |
| DQ06 | Color and appearance | Use semantic light/dark roles, including image grounds and destructive states. Text contrast is at least 4.5:1, or 3:1 for large text; meaningful control boundaries meet 3:1. Color is never the sole state cue. Native materials also need Increase Contrast/Reduce Transparency testing. |
| DQ07 | Images and demo truth | Each image matches its piece label and color. The same named look retains its pieces across flows; different looks have distinct compositions. Preserve proportions and full-image Fit until an explicit crop. Counts, dates and selected states agree; production-facing layouts contain realistic examples rather than implementation placeholders. See [asset mapping](../references/assets.md). |
| DQ08 | Icons and navigation | Use consistent SF Symbol roles and optical alignment. Agent uses a single sparkle. Settings uses a recognizable gear. Each screen has a clear native exit; duplicate Skip/Not now/Cancel exits are removed. Navigation and safe areas stay anchored to the viewport. |
| DQ09 | Forms and recovery | Labels describe the field without Required/Optional suffixes. Save reflects valid prerequisites. Missing/loading/error/permission states explain the next step and preserve drafts. Destructive confirmation identifies scope and retains a safe exit. |
| DQ10 | Flow and phase integrity | V1 remains complete and local: five destinations (Home/Closet/Planner/Agent/Profile), private journal/Settings, manual routes when Agent is unavailable. V2 extends it with explicit connected scope/consent. Every key control has a destination or documented native presentation. |
| DQ11 | Fit and accessibility | At the reference viewport, content is not obscured by chrome or clipped unintentionally. Long content scrolls; bottom actions remain reachable. Native acceptance covers smaller phones, landscape, largest accessibility text, VoiceOver order/names, keyboard, Reduce Motion and interruptions. A Paper screenshot verifies only static composition. |
| DQ12 | Implementation handoff | Reuse named components and tokens. Specify initial, selected, disabled, loading, error and success states where relevant, plus save/cancel semantics. Link the route, feature contract and Paper reference. Keep demo fixtures separate from actual user data. |

## Severity and completion

- **P0:** A misleading destructive action, privacy breach or blocked core task. Resolve before handoff.
- **P1:** Wrong route/state, hidden or unreachable control, contradictory data, missing recovery, or unreadable content. Resolve before the affected flow is ready.
- **P2:** Spacing, type, surface, icon or copy inconsistency. Fix across related instances in the same pass.
- **Native verification required:** A behavior Paper cannot establish. Name its implementation acceptance check; this is neither a static failure nor a runtime pass.

A static handoff is ready only when its recorded inventory has no unresolved P0/P1 findings, P2 exceptions are explicit, and native checks are listed separately. A score or a clean automated scan alone does not establish polish.

## Approved component decisions

- Home has no Settings shortcut. Settings belongs under Profile, including the local V1 profile and tour preview.
- Header Edit uses a 22-point `square.and.pencil` symbol in the same 44-point circular control as Back, with semantic ink rather than action blue. Its native accessibility label is Edit plus the object name.
- Piece/theme disclosure rows use opaque semantic surface, 12-point corners, 14-point horizontal padding, 54-point minimum height and a fixed 22-point trailing lane. Do not apply this to tabs, filter chips or statistics.
- Empty-state garment artwork is illustrative; it must not imply an already-saved record. Decorative icons use SVG/SF Symbols, not text glyphs, and are hidden from accessibility.
- Planner starts in Week. Month is an alternate view with the same selected date and shared agenda; see [Planner calendar](planner-calendar.md).

- Navigation title and Profile link for preferences read **Style**. Internal feature/data names may remain style preferences.
- Every new V1 action updates [the interaction checklist](v1-interactions.md), including its shared/system presentation and cancel/failure behavior.
