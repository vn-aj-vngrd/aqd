# Initial build verification

Recorded 2026-09-30. This is a local initial product, not a production or live-provider sign-off.

| Boundary | Result | Evidence / limits |
| --- | --- | --- |
| iOS compilation | Passed | Xcode 26.5, Swift 6, shared AQD scheme, Debug generic iOS Simulator, signing disabled. |
| Core behavior | Passed | 7 Swift host tests: persistence, validation, owned active recommendations, wear deduplication/undo, deletion, sample cleanup, and failed/corrupt storage. |
| AI function contracts | Passed | 10 Node tests with mocked network responses; input/output validation, auth, quota, and provider errors. No paid live model call. |
| Edge type checking | Passed | Deno check of the function entry point. |
| Database policies | Passed locally | Migration and transactional SQL tests on isolated PostgreSQL 17 with synthetic Auth roles/users. Owner isolation, anonymous rejection, private reactions, quota, and cascade deletion. Not a deployed Supabase test. |
| Simulator interaction | Partial | iPhone 16 Plus on iOS 18.1: empty state, opt-in samples, mark worn, change suggestion, save named outfit, open Closet. Saved data survived app restart/install. |
| Visual inspection | Passed at captured scope | Home in light, dark, and accessibility large text; Closet layout. Screenshots in `.impeccable/review/`. |
| Physical camera / device | Unverified | Requires a physical iPhone and permission. |
| Real accounts, community, OpenAI | Unverified | AQD backend and server credentials are not configured. |

Current visual evidence: `phone-home.png`, `phone-dark.png`, `phone-large-text.png`, and `phone-closet.png`. The Closet capture predates the final contrast-token adjustment but shows the same layout. The file `phone-onboarding.png` is an invalid SpringBoard capture and must not be treated as app evidence.

Manual interaction verification stopped when the Mac became locked. No claim is made that every UI path, small-screen layout, VoiceOver sequence, camera permission flow, or connected service has been exercised. Follow the manual acceptance path in [iOS setup](../apps/ios/README.md) and the live checks in [backend setup](BACKEND-SETUP.md).

Reproduce compilation and Swift tests using [iOS setup](../apps/ios/README.md); reproduce function tests with `npm --prefix supabase/functions test`. The database fixture is `supabase/tests/access.sql`.

## Design review

An independent Impeccable review found one material copy issue: absolute offline/privacy language conflicted with optional AI and explicit public sharing. That copy is corrected and the app rebuilt successfully. Refreshed Home light/dark/large-text captures show no visual regression. The Create footer, expanded Home explanation, and local-helper fallback still need rendered verification after the Mac is unlocked; the review is therefore not fully closed. No QUALITY BAR calibration card was available, and no web detector ran for this native app.

## Glass navigation and on-device AI update

The app now compiles with Foundation Models (guarded by iOS 26 availability), a native Liquid Glass tab bar, dedicated Search role, scroll minimization, and capsule primary buttons. All five tab destinations were exercised on iPhone 17 Pro / iOS 26.5; the Home date truncation observed in the first pass was fixed and visually confirmed. Current glass captures are `glass-home.png` and `glass-dark.png`. The Mac is now accessible.

The cloud AI request method was removed from the iOS client. V1 model generation uses the system on-device model; no OpenAI key or Supabase account is needed for it. Model output quality remains unverified until a supported Apple Intelligence device with a ready model is available. Earlier Node/server tests concern deferred cloud work, not the new on-device model.

### On-device generation evidence

Foundation Models reported available in the iPhone 17 Pro / iOS 26.5 simulator. “Give me a weekend outfit” produced a real model response and a three-piece draft (sample tee, shorts, sneakers). Review opened the editable outfit composer with the generated name “Weekend Casual” and theme “Weekend”; Save completed. This proves one simulator generation/review path, not model quality across all prompts or physical-device performance. No cloud model request was involved. Unsupported-device messaging is implemented but not yet interaction-tested.

## Minimal UI refinement

The user replaced the serif/cobalt direction with a minimal native system. Shared content actions now use `ActionButtonStyle`, recurring symbols use `AppSymbol`, and every screen title goes through `screenHeader`. Source scan confirms no sparkle symbols, serif styles, or large-control padding remain. Xcode simulator build passes.

On iPhone 17 Pro / iOS 26.5, Home, Closet, Create, and Ask AQD were visually inspected. The compact Wear today action recorded a wear and changed to Undo wear; undo restored the initial state. Light/dark Home and accessibility-large text were captured. Accessibility action buttons stack vertically to avoid uneven wrapped labels. See `minimal-home.png`, `minimal-dark.png`, `minimal-large-text.png`, `minimal-closet.png`, and `minimal-assistant.png` under `.impeccable/review/`.

[Design rules](DESIGN-RULES.md) are linked from root AGENTS.md. No business logic changed in this visual pass. This evidence does not establish physical-device performance or a complete VoiceOver audit.

## Monochrome components, account sheet, and full-screen Agent

The App Store component structure now uses AQD’s neutral palette, shared shadowed chips, segmented tabs, and explicit root search fields. Weather endpoints returned live responses; Home displayed the selected Cebu weather in the simulator. Ten Swift tests (including three weather-service tests) passed in this refinement batch.

The final Agent presentation builds successfully for iOS Simulator. On iPhone 17 Pro / iOS 26.5, the fourth navigation item opened Agent full screen with a Back control and no tab bar. Back restored Home and its selected tab after a native selection-restoration fix. Home/Create shortcuts use the same cover. The account avatar opened the rounded grouped account sheet, and its profile row opened the editor. Current Agent capture: `.impeccable/review/agent-fullscreen.png`. Final full-screen presentation has not been rechecked at accessibility text sizes or in dark mode; earlier captures cover the shared palette only.

## Closet, feed, and profile restructuring

Navigation now uses five icon-only destinations in order: Home, Closet, Agent, Search, Profile. Final simulator build passed. Eleven Swift tests passed, including a migration fixture that removes the newly introduced optional JSON keys and verifies older wardrobes load, clothing condition/age/prior wears persist, wear undo preserves the prior count, and standalone themes survive reload.

Rendered checks on iPhone 17 Pro / iOS 26.5 confirmed the Personal / Community selector, feed posts, icon-only bar, center full-screen Agent, profile collection grid, and two-action Add sheet. Add clothing transitioned from the sheet to the manual editor. The final feed is captured in `.impeccable/review/personal-feed.png`. These new layouts have not yet been comprehensively checked with VoiceOver, accessibility text, dark mode, or a physical camera.

Public profiles, follows, and profile URLs are not implemented. Profile shows unavailable connection counts and explains this on tap. Sharing offers a user-reviewed text summary through the system share sheet, not a fictitious public URL. Connected outfit community code still requires backend configuration; no deployment or real social account verification occurred.

A live on-device theme request initially returned outfit pieces with its theme. Theme-only request handling was corrected to offer a theme draft without an outfit action, using the submitted question snapshot. A repeat request produced “Minimalist.” and opened the editable New theme form through Review theme. The review was cancelled without saving the test theme. This verifies one simulator model path, not broad natural-language intent or output quality.

## Header cleanup and active navigation icons

Removed the shared account/avatar control from Home, Closet, and Search; Profile retains its settings sheet entry. Selected tab assets now use filled Lucide adaptations, with a heavier Search outline. The native selected pill and accessible tab names remain. The simulator build passed. Home, Closet, Search, and Profile were inspected in light appearance; active Home and Profile silhouettes were visually confirmed. Dark mode and VoiceOver were not re-exercised for this cosmetic change.
