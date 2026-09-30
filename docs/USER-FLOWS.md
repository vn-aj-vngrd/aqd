# Product journeys

These flows describe the refined target in [PRODUCT.md](PRODUCT.md). They are not test results for the current app. Detailed behavior and acceptance are owned by [feature specifications](features/README.md).

## Capture a wardrobe item

1. Open Closet's Add sheet, or ask Agent to add an item.
2. Choose Photos, Camera, or manual entry. Agent opens the same user-controlled capture flow.
3. Review the image, name, and category. Fill optional details or review proposed classification.
4. Save the private item and find it by category or search.

Permission denial offers another capture path. Classification failure preserves the photo and entered details for manual completion. Unknown metadata remains editable rather than being fabricated.

## Create a look or theme

1. Open the outfit builder and choose owned items, or request a suggestion from the screen or Agent.
2. Review the pieces, context, and explanation; replace any piece.
3. Name and save the outfit, then organize it into one or more themes.
4. Create an empty theme if organizing a future collection.

An incomplete closet explains what is missing. Archived/unavailable items are identified. A failed save retains the draft. AI output does not become a saved outfit or theme merely because it appears in a response.

## Plan two weeks

1. Open Closet → Planner and choose dates.
2. Assign saved outfits manually, or request a draft with mood, occasion, repetition, and availability constraints.
3. Review every day, intentional gaps, repeated pieces, and conflicts.
4. Replace or move entries, then save the plan.
5. Open a day's entry and mark it worn or skipped when appropriate.

Future scheduling does not change wear counts. Recording the same actual wear again must not double count. Weather gaps are explicit. Bulk saves are atomic: a failure leaves persisted plans unchanged and preserves the reviewed draft for recovery.

## Set up office or travel

For office: define the weekday recurrence and three-month date range, choose reusable looks or request assignments, review the schedule, and save. Later edits distinguish one entry, future entries, or the whole routine.

For travel: create an event with destination and dates, prepare outfits for its activities, review the plan, and derive a deduplicated packing list from assigned owned items. Replacing a planned outfit updates that list. The event and dates remain private unless explicitly included in a reviewed share action.

An event is context; the plan is the dated clothing intention. Neither becomes a theme automatically.

## Ask and act through Agent

1. Ask a supported general question, request an insight, or specify a product task.
2. Agent uses authorized context and states relevant gaps or ambiguity.
3. For an action, review the proposed objects, date range, changes, and visibility.
4. Approve or edit the proposal.
5. Receive an action result and open the saved record; correct or undo where supported.

General answers stay within style, clothing, weather, travel, and everyday planning. Personal statistics state their data basis. Publishing/deletion and bulk changes require concrete review. Cancellation or failure is never presented as completion.

## Publish and discover

1. From a piece, outfit, theme, or worn look, choose Share.
2. Preview the public content and included media. Check that private notes, plans, and unrelated items are absent.
3. Publish and view the post on the public profile.
4. Search users, public closets, outfits, and themes from Home; browse All, or Following for followed creators' accessible posts.
5. Like, bookmark, follow, inspect a public closet, or request an inspired outfit.
6. Review the interpretation using the viewer's own pieces, then save it privately.

No follows produces an actionable empty Following feed. Private or removed content is inaccessible through search and bookmarks. AI-created and actually worn looks retain distinct meanings.

## Manage identity and settings

Profile presents social identity and public wardrobe collections. Account settings contain privacy, notifications, account access, and lifecycle controls. Personal style and planning preferences belong in Closet. Closet remains the user's private management workspace regardless of public participation.

## Chat with a creator

1. Open an accessible creator profile and choose Message.
2. Start or resume the human conversation in Inbox.
3. If required, the recipient accepts a message request before the chat proceeds.
4. Send text or share a reference to accessible public wardrobe content.
5. Inspect delivery state and retry a failed message without creating duplicates.

Blocked users cannot continue contact. Removed/private shared content respects its current access rules. Agent-prepared messages show recipient and content for user approval before sending; human conversation history is not automatically available to Agent.
