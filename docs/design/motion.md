# Global motion

Phase scope: shared native/visual rules apply to both phases. Five-destination base navigation applies to both phases. Full-app E/W/P/S/A/I/U routes, online identity and connected states are V2 references. Complete private themes/planning/Agent are retained in V1. V1 uses only its [dedicated local flow](v1-flow.md) and [complete local release](../product/v1-release.md); [V2 requirements](v2-requirements.md) own connected and extension coverage.

Paper page 00 **Foundations · Global motion** owns the visual reference. This contract owns named behaviors and implementation handoff for every screen. [Coverage](motion-coverage.md) assigns all 201 canonical screen/state contracts and appearance variants. Local L references inherit their source and shared native motion recipes, including optional tour navigation. These are design specifications, not implemented animation or measured performance.

## Apply the policy

1. Use the screen's coverage row to select the navigation and content recipe. Native navigation takes precedence over custom page reveals.
2. Use the shared values below; do not invent per-screen delays, springs or animation libraries. Implement one `AQDMotion` policy in the existing native design system when app work is authorized.
3. Scope animation to the changed component. Preserve focus, selection, drafts, stable record identity and scroll position.
4. Apply the Reduce Motion alternative, interruption rules and verification cases before considering the native implementation complete.

## Optional native weather inheritance

Shared [WeatherKit](weather-context.md) uses OS push/sheet/search/permission transitions and existing C-form/C-load/C-select recipes. Grow/reflow only changed rows; bounded opacity fade for fresh/Saved/unavailable replacement, no animated numbers, decorative condition travel or looping forecast. Reduce Motion uses immediate or existing opacity-only state change; native progress remains OS-owned. Preserve caller draft/focus/scroll during city/date changes and invalidate late requests on Cancel. Settings confirmation writes only the optional local preference; weather apply is not outfit/plan Save or a receipt. [Weather evidence](evidence/weatherkit-v1.json) records static references, not measured motion.

## Global values

Durations below are AQD design choices, not Apple-prescribed timings. Never override system transition duration with these values.

| Key | Value | Use / curve |
| --- | --- | --- |
| motion.press | 100 ms | Custom button feedback only; ease-out. Native buttons keep their own feedback. |
| motion.crossfade | 150 ms | Local content/status/photo replacement; ease-out. |
| motion.reflow | 220 ms | Small layout/selection/insert changes; smooth spring, zero extra bounce. |
| motion.welcomeSequence | 1,200 ms total | First Welcome arrival only: 520 ms forming phase, then 680 ms settle; smooth ease-out, no elastic bounce. |
| motion.welcomeTravel | Within bounded hero; about 230 pt horizontal / 190 pt vertical maximum | Twelve garment transforms use the authored keyframes; never overlap text/actions. |
| motion.welcomeStagger | 0–80 ms per group within forming phase | Parallel outfit groups; no accumulating per-item delays. |
| motion.reduced | 0–120 ms | Immediate state or opacity-only crossfade. No spatial travel. |
| motion.pressScale | 0.98 minimum | Only a custom standalone button that lacks native press feedback; keep hit region unchanged. Never shrink text fields, rows, or navigation. |

Use SwiftUI `.smooth(duration:extraBounce: 0)` for bounded local reflow where supported; use ease-out for opacity. UIKit uses an equivalent interruptible animator. Duration is a design target, not a guaranteed exact spring settle time. API availability follows the app's deployment target. No separate dependency is needed. Native timing/gesture progress is system-owned.

## Recipes

| ID | Trigger and result | Standard behavior | Reduce Motion |
| --- | --- | --- | --- |
| N-root | Switch root destination | Native TabView/tab controller. Preserve each destination's stack/scroll. No direction slide or page cascade. Agent follows its established full-screen route. | System adaptation; no added movement. |
| N-push | Open detail or next onboarding step | Native navigation push and interactive Back. Destination text appears as part of navigation, without delayed reveal. | System adaptation; custom fallback opacity only. |
| N-sheet | Focused edit, confirmation or picker | Native sheet/alert/menu/picker/full-screen presentation and dismissal. Keyboard and detents remain native. Dirty drafts use the existing discard guard. | System adaptation; no second transition. |
| N-photo | Open a visible piece/outfit cover into detail | Native zoom navigation with matched source identity if supported and reliable. Otherwise N-push. Do not add a second matched-geometry or fade layer. Missing/offscreen source falls back to normal dismissal. | Choose non-spatial navigation; no custom zoom. |
| C-select | Filter, chip, segment, follow or feedback state | Native controls animate themselves. Custom selection color/check changes use press; dependent content uses crossfade only after available. Keep current content while fetching. | Immediate selection; optional short opacity replacement. |
| C-load | Initial loading, cached refresh, empty, error | Reserve final geometry. Native labelled progress indicator for real work; no imposed wait or minimum spinner duration. Loaded content crossfades once. No stagger for every cell or pagination page. | Static neutral placeholders; meaningful native progress may remain. |
| C-change | Add/remove/reorder item; swap outfit piece; local expansion | Reflow only affected views using stable IDs. Preserve pinned pieces and visible scroll anchor. Drag follows finger directly; valid drop settles using reflow. Undo reverses the same local change. | Update layout immediately; optional short content crossfade. |
| C-save | Save, publish, record wear or delete | Pending state retains geometry. On confirmed receipt, update destination locally and show persistent success copy; optional one success haptic. No animation can imply a write completed before its receipt. Unknown outcome stays pending/reconciling. | Same state/text; no travel or celebration. |
| C-form | Focus, validation, disclosure | Native focus/keyboard; inline error appears in reserved space or local reflow. Scroll invalid input into view once after submission; never shake or repeatedly steal focus. | Immediate layout/focus; retain error semantics. |
| C-message | Human message insert / conversation change | Native conversation navigation. One local insertion reflow; sent/pending/failed updates in place. Auto-follow only when already at latest or after own send; otherwise show new-message affordance. | Immediate insertion/status; no animated forced scroll. |
| C-stream | Agent waiting, streaming, tools, stop, retry | Labelled native progress; status crossfade. Render chunks normally, not character-by-character animation. Coalesce layout updates; no animation per token or Markdown relayout. Keep Stop immediate and partial text on interruption. | Same content, static state transitions; preserve reading position. |
| C-receipt | Copy, feedback, accepted request | Short local crossfade to confirmation, with accessible announcement; preserve context. Do not animate every icon or announce every stream fragment. | Immediate or short fade. |
| E-arrival | First visit to Welcome | Twelve original garment layers gather, form looks and settle using the dedicated Welcome sequence and authored keyframes. Text/actions are visible and active immediately. Replay only on a genuinely fresh introduction, not Back. | Final composition immediately. |

### Native ownership and Liquid Glass

Use native large-title collapse, scroll edges, refresh, scrolling physics, interactive Back, tab selection, sheets, keyboard, switches, menus and Photos picker. Standard components adopt system appearance and behavior. Custom glass is only for functional chrome; let the native glass container manage morphing when needed. Do not animate blur radius, redraw glass in content cards, or put a crossfade on top of a native transition. Reduce Transparency changes the material, not the navigation model.

For image-to-detail continuity, prototype native zoom with `matchedTransitionSource` and `navigationTransition` only where the source represents the same record. Do not zoom unrelated thumbnails into forms, authentication screens, destructive confirmations or Agent replies. SDK availability and interrupted dismissal need device checks.

## Flow decisions

- **Entry:** splash has no timer. Welcome has the one authored arrival. Onboarding steps use native push/Back and retain drafts; selection responds immediately. Authentication/picker/permission UI remains native. First successful save produces an in-place receipt followed by user-directed continuation, never an auto-dismiss race. [Entry choreography](entry-motion.md) references these global values.
- **Today:** root tabs and V2 All/Following modes preserve state. Today numbers update once after a confirmed wear, without counting up. Feed items and avatars crossfade only on first successful load or actual replacement; cached images do not repeatedly fade. The initial screen and scrolled continuation are the same view, not a transition pair.
- **Closet:** filtering changes data with C-select/C-load. Open a garment via N-photo; editing stays N-push/N-sheet. Camera and media permissions are native. Adding/removing pieces and outfit swaps use C-change; missing/unavailable items remain visibly explained. Do not animate the entire grid on sort or save. Theme edits share the same rules.
- **Planning:** native date changes and sheet entry. Drag follows the finger; invalid drop returns to its original slot without persisting. Confirmed assignment/undo locally reflows; a planned date passing never creates wear. History and insights update only from records, without animated percentages, rings or score counting.
- **Agent:** full-screen entry/dismissal uses native presentation and restores the origin. History opens with native navigation. Generation/streaming/tool steps use C-stream; elapsed time updates once per second with stable-width digits and no announcement per tick. Progress bars represent real measurable work only. Approved writes use C-save, not a “thinking” animation as proof of success. Feedback/copy use C-receipt; errors remain readable until action.
- **Inbox:** human chats use C-message. Requests move only after confirmed acceptance; failed send stays with its draft. Keyboard and attachments use system transitions. New messages never pull a reader away from older content.
- **Profile/settings:** collection tabs use native selection, photos crossfade, and follow changes stay local. Settings rows, sheets, export and account actions stay native. Destructive confirmation remains stable; no playful motion. Account switches clear stale private content before revealing the next account.

## Interruption, accessibility and performance

All custom effects are interruptible. A second action retargets from current presentation values, not a queued animation. Cancel obsolete transitions and requests independently; animation completion must never be a business-operation trigger. Back, Stop, Cancel and primary actions work during motion. On backgrounding, cancel ornamental motion and resume in final state; do not replay stale success effects.

Read `accessibilityReduceMotion` reactively. Remove custom scale, translation, zoom, stagger and animated scroll when enabled. Retain meaning with immediate state and optional <=120 ms opacity change. Keep VoiceOver focus attached to the logical element, move it once for a modal/error when needed, and expose selected/disabled/busy states as semantics. Dynamic Type and RTL must not depend on fixed animation coordinates. Haptics are optional, respect system availability/settings, and supplement visual/text feedback; do not add sounds or repeated haptics for streaming/loading.

Avoid looping skeleton shimmer by default, parallax, bounce, confetti, springy text, autoplay decorative imagery, count-up statistics and scroll-triggered section reveals. Animate bounded layers; downsample/predecode photos and avoid expensive image work on the main thread. Keep a stable placeholder size to avoid layout shifts. Avoid broad implicit animation on the screen root, especially with streaming, keyboard and scrolling updates.

Performance acceptance is measured on the minimum supported device and a current device: no sustained dropped frames in normal scroll/transition interactions, frame work within the display's current refresh budget (about 16.7 ms at 60 Hz or 8.3 ms at 120 Hz), responsive taps during transitions, and no blank frame after image dismissal. These are targets, not current claims. Profile with Instruments and the SwiftUI animation/performance tools; lower display refresh rates and accessibility settings must remain usable.

## Verification checklist

- Exercise every coverage row's primary recipe; representative native tests may be grouped by shared component, but test flow-specific cancellation/data effects separately.
- Rapid taps, drag cancellation, interrupted Back/zoom, background/resume, double-submit, slow media and missing source thumbnail preserve state.
- Fresh/returning onboarding, first save, filter/sort, outfit replacement, planner conflict/undo, live streaming/Stop, reading older chats and account switching remain correct.
- Verify Reduce Motion on/off live, VoiceOver focus, accessibility text, RTL, dark appearance, Reduce Transparency and keyboard safe areas.
- Compare standard/reduced behavior; verify smoothness on hardware. Paper boards and screenshots prove documentation/visual states only.

## Apple references

Reviewed October 1, 2026. Apple's native ownership and accessibility guidance informs the policy; AQD durations above are authored choices.

- [Motion HIG](https://developer.apple.com/design/human-interface-guidelines/motion)
- [SwiftUI animations](https://developer.apple.com/documentation/swiftui/animations)
- [Smooth animation](https://developer.apple.com/documentation/swiftui/animation/smooth(duration:extrabounce:))
- [NavigationTransition](https://developer.apple.com/documentation/swiftui/navigationtransition)
- [Reduce Motion environment](https://developer.apple.com/documentation/swiftui/environmentvalues/accessibilityreducemotion)
- [Adopting Liquid Glass](https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass)
- [Applying Liquid Glass to custom views](https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views)

## Agent busy-label shimmer exception · October 2, 2026

At the user’s request, C-stream permits a restrained luminance sweep only on the active preparing/writing status label, roughly one cycle per 1.8 s. This supplements the single shared native spinner; it never estimates progress, animates streamed prose or hides received text. Stop at completion, failure or confirmed cancellation. Reduce Motion, VoiceOver and backgrounding use the same static readable label. [Agent input](agent-input.md) defines the exact state and recovery scope; the Paper master displays a static phase, not a running animation.
