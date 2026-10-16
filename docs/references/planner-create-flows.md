# Planner creation flow references

Checked **October 17, 2026**. First-party documentation research for the owner's creation-form refinement. This note records source facts and design rationale; adopted AQD behavior remains in the feature and design contracts. No competitor app was installed or exercised, and these pages do not establish exact current toolbar geometry.

## Observed source facts

| Source | Documented behavior | Useful distinction |
| --- | --- | --- |
| [Apple Calendar: create and edit events on iPhone, iOS 27](https://support.apple.com/guide/iphone/create-and-edit-events-in-calendar-iph3d110f84/27/ios/27), “Add an event” | Creation starts with the event title, followed by location and scheduling details; the user completes the flow with Done. Longer meeting information can be reached by scrolling. | Identity comes before secondary details; completion is explicit. The text documents Done, not an Add/Save label or a verified top-right text placement. |
| [Fantastical for iOS: adding events and tasks](https://flexibits.com/fantastical-ios/help/adding-events-and-tasks), “Using natural language,” “Looking up locations,” and “Using drafts” | The creation screen accepts a description, then Add creates the item. Show Details exposes location. A draft can be retained while checking the calendar and resumed; the guide describes pulling down the creation header to retain it. | Progressive detail and drafts support an interrupted planning task without equating an unfinished item with a scheduled event. |
| [Things: features](https://culturedcode.com/things/features/), “Beautiful To-Dos” and “Magic Plus” | To-dos open on a white editing surface; optional tags, checklist, start date and deadline remain available without initially dominating the editor. New to-dos can be created in a relevant list/date context. | A compact initial editor can retain advanced capability. This is a first-party feature description, not evidence for a particular toolbar Save placement. |

## AQD application choices

The following are **AQD design choices**, informed by the patterns above and the owner's explicit request, rather than claims that every planner uses the same layout:

- Put one primary completion or forward action at the top trailing edge as text: Next/Review for a staged flow, Save/Add for a committed result, Done for a selection return. Do not label a review-only step Save or imply it has written a plan.
- Keep dismissal at the leading edge and the title centered. Avoid repeating the same completion action as a large footer button. In-form photo, outfit and timezone controls remain next to the fields they affect.
- Lead with the entity's identifying content: plan name, piece photo/name, outfit composition, or fit photo/linked outfit. Group related dates and timezone together rather than repeating a label above and inside every separate card.
- Use white parent surfaces with the established warm neutral inner controls in light appearance. Reserve restrained gold for interactive text, selection and focus; keep normal field values charcoal, secondary explanations quiet, and destructive actions semantically distinct. Preserve semantic dark-mode equivalents and accessible disabled states.
- Keep optional information visibly available with short labels or disclosure rows. Keep essential consequences and required validation readable; don't hide AQD's distinction between a plan, a fit memory and recorded wear in decorative copy or an unrelated disclosure.
- Preserve existing retained drafts, no-write cancellation, review boundaries, pending/unknown-outcome reconciliation and duplicate-save protection. Moving a button is not permission to replace those behaviors with automatic saving or to copy Fantastical's dismissal gesture.

## Verification boundary

This is documentation evidence, not AQD rendering, interaction, accessibility or physical-device acceptance. Source inspection and appropriate unit/build checks can verify implementation structure; rendered end-to-end acceptance remains under issue 30 and the repository's verification policy.
