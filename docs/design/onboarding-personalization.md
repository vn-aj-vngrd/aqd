# Onboarding personalization

October 6, 2026. L61 offers **Personalize my closet** → L152–L154 → first-piece capture L04. Explore first and Skip setup remain available. Returning users are not asked again; Profile → **Style** edits these answers. This replaces the earlier later-only preference decision.

## Three short questions

| Screen | Question and answers | Concrete use |
| --- | --- | --- |
| L152 | What would you like help with? Wear more of my closet / Plan outfits faster / Try new combinations | Prioritize an eligible unworn-piece suggestion, next unassigned date, or a new combination of owned available pieces. Choose up to two; no answer is valid. |
| L153 | What does your week look like? Everyday / Work / Evenings | Default occasion suggestions only. Do not infer employment, schedule or calendar events. Multiple choices allowed. |
| L154 | What feels like you? Relaxed / Minimal / Classic; Anything you avoid? | Soft style preferences plus user-entered fit/material/color constraints. Do not infer body shape, gender, health or sensitive traits. Multiple choices allowed. |

The examples illustrate an explicit selected answer; fresh setup starts unselected. A skipped answer is unknown, never the first option. Keep the questionnaire to these three steps; no mandatory clothing quota or account. Back retains the draft, Skip setup discards unsaved setup answers, and Save persists them locally before capture. Re-entering from Style uses existing answers and returns there after Save. Save failure keeps answers; no success until durable storage confirms.

## Recommendations with and without Agent

Use deterministic eligibility first: owned, active, available pieces; valid outfit composition; exact date/occasion; explicitly pinned items and constraints. Preferences rank eligible choices rather than bypassing those requirements. Never invent a garment or record wear. Goals affect ordering of useful Home actions, not a fabricated score, confidence percentage or promise of learning.

If there is no eligible suggestion, show the appropriate Add piece, Build outfit or empty-history action. Unknown history is not proof an item was never worn. A suggestion explains one factual reason, such as “Uses a piece with no recorded wear,” and opens L18/L06 for review. Dismissal is not a destructive change; recommendations must not keep interrupting the main task. Existing L23's utilization card remains factual reporting, not an AI recommendation.

When the on-device model is available and style context is enabled in L28, pass only the selected preferences and bounded allowed wardrobe data to the Agent. Answers are context, not model training. V1 does not send them to a provider. When unavailable, manual tools and deterministic ranking still work; L19/L80/L81 explain the model state. V2 provider choice requires its separately documented opt-in and data scope.

Apple documents runtime model availability in [Generating content with Foundation Models](https://developer.apple.com/documentation/FoundationModels/generating-content-and-performing-tasks-with-foundation-models). AQD deliberately selects an on-device-only V1 policy regardless of other provider capabilities. Apple's [onboarding guidance](https://developer.apple.com/design/human-interface-guidelines/onboarding) informs the brief, skippable setup.

## Motion and accessibility

Use native forward/back transitions, stable question placement, and a static “1 of 3” progress label. No sliding choices or animated progress that delays input. Selection feedback is immediate; Continue remains available when empty. Preserve scroll/focus with keyboard and larger text, and announce the new question once. Reduce Motion uses native reduced transitions or a short opacity change. Welcome follows [entry motion](entry-motion.md); no idle loop, waiting gate or replay on Back.

Paper supplies static states and timing requirements. Smoothness, interruptions, largest text, VoiceOver, keyboard and real on-device recommendation quality require later native implementation tests.
