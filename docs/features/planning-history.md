# P — Planning, actual wear, and insights

## Phase boundary

V1 completes local manual dates/two-week plans, three-calendar-month routines, events/trips/packing, wear/history/correction and factual insights, with supported bounded assistance. Optional basic native Apple WeatherKit selected-place/date context belongs to V1 and is inherited by V2, independent of AI availability; external calendar, advanced external weather providers/context, alerts/notifications and expanded travel/collaborative planning remain V2. See [V1 release](../product/v1-release.md), [V2 backlog](../product/v2-backlog.md) and [V2 design](../design/v2-requirements.md).

## Outcome and placement

Planner is the dedicated third root in both phases, not a Closet segment; Closet has only Pieces/Outfits/Themes. Planner organizes intended clothing use; History records actual use; Stats explains that history. Week is default, Month alternate, preserving selected date. Today summarizes planned looks/upcoming entries; these links and outfit Plan actions open Planner with date context. Back restores origin, scroll and preserved selection. Plans are not social recommendations, and account setup never gates this private core.

## Planning contract

A plan has ID, owner, name, date range, explicit timezone, and optional event/routine. A plan entry has its own ID, local date, occasion/slot, optional outfit reference, and state: unassigned, planned, worn, skipped. Multiple entries can exist on a date. Planned assignment is not a wear record.

An event supplies dates, optional destination and activities. A routine supplies start/end dates, selected weekdays, occasions, and preferred looks. Working default: store resolved entries when saving; recurrence is a plan authoring aid, not a background generator that changes saved choices without review.

Dates are calendar dates in the plan's chosen timezone. Traveling/device-zone changes do not shift an already assigned local day. Start/end are inclusive. Calendar months are calendar months, not a hard-coded 90 days. Initial assisted ranges support two weeks and up to three calendar months; larger ranges require a separately specified slice.

## Manual and assisted flows

Calendar and agenda expose date, occasion, assignment, and state. Create a named plan, assign saved outfits, move/replace/remove entries, and leave intentional gaps. Existing plans are not overwritten silently. Outfit revisions after assignment flag affected future entries for review; confirm the updated composition or choose another outfit. Historical wears retain their snapshots.

Focused assistance or Agent receives dates, activities, mood, pinned pieces, repetition preferences, availability, and optional weather. Generate bounded batches into one reviewable draft; show range, gaps, repeats, and conflicts before committing. Working default: bulk save is all-or-nothing; failure retains the draft, with no partially applied calendar.

Routine edit choices: this entry, this and future entries in the routine, or the whole routine. Future edits preserve worn/skipped historical entries. Overlapping date/occasion entries warn and offer keep-both or replace; the agent chooses neither silently.

Trips use the same event/plan model. Packing list is a deduplicated set of owned items in assigned outfits, with checked state. Changing assignment recalculates contents while preserving checks for retained IDs. Repeated wear does not invent quantities of owned items. Blank/unavailable assignments produce a visible packing gap.

Weather follows the [confirmed V1 contract](../product/v1-release.md#optional-live-weather-contract): off until chosen, pre-action search/request disclosure, selected coordinates/date sent to Apple, manual city without location permission and explicit one-shot When In Use only. Include source/place/timezone/date/freshness and supplied Apple attribution. Current temperature/condition and daily low/high/precipitation appear only when returned. Forecasts have at most ten days of actual returned coverage, not full two-week/three-calendar-month or historical weather. Missing/out-of-range weather is unavailable, never substituted/invented; user assumptions stay distinct from sourced facts. Saved weather ≤24 hours is labelled and never fresh Agent input. Cancel does not enable/apply; Apply changes parent draft only, not saved plans. Failure/offline keeps manual Outfit/Planner complete without AI/network. Laundry/unavailable pieces show a conflict; repeated available pieces are allowed. Packing luggage constraints are later assistance refinement, not fabricated capacity guarantees.

## Wear and history contract

Working default consistent with current behavior: one wear per identical item set per local calendar day; distinct combinations on a day are allowed. A stable operation ID prevents retry duplication. The recorded day/timezone does not change when the device travels. The user can backdate or correct a record; correcting a date/item set rechecks duplicates.

A record snapshots item IDs and minimal names/categories, optional outfit/plan-entry ID, date/timezone, and provenance. Photos and notes are not required in historical snapshots. Item total = estimated prior wears + recorded occurrences; estimates do not imply dated history. Marking planned entries worn creates or links the matching record. Undoing a wear returns every entry linked to that record to planned and removes its recorded item counts once; skipped creates no record. Deleting a plan never deletes actual history. Editing an outfit does not rewrite what was worn earlier.

Profile's [private fit journal](profile-account.md#v1-private-fit-journal) stores dated memories, separately from plans and actual wear. Its required editable date defaults to today in the recorded timezone; later device-zone changes preserve the calendar day. Adding/editing/deleting a fit or linking/unlinking its outfit never records wear, changes counts or marks a plan worn. Only a separate explicit Record wear action uses the same item-set/day and operation-ID deduplication above, including when a matching wear already exists. Journal outfit snapshots survive outfit deletion independently of actual-wear snapshots; neither snapshot is evidence that a wear occurred.

Stats: most/least worn uses total count but labels estimates; recorded utilization is active items with at least one dated AQD wear / all active items. Prior estimates are excluded from recorded utilization and time-window stats. Monthly wear reports distinguish wear occasions from individual item totals. Unknown history and empty denominators show “Not enough recorded history,” not a misleading percentage.

## Acceptance

- P1: Save a two-week manual plan, leave gaps, restart, move one entry, and preserve the other assignments.
- P2: Create office weekdays for three calendar months; edit future entries without changing history.
- P3: Keep two occasions on one day; overlapping slot proposals request a conflict choice.
- P4: Change device timezone and preserve assigned days in the plan's timezone.
- P5: Travel packing deduplicates item IDs and updates after outfit replacement.
- P6: Generation/bulk-save failure or cancellation leaves the calendar unchanged and the draft recoverable.
- P7: Planning/passing a date does not increment wear; mark/undo/backdate/correct handles duplicates consistently.
- P8: Outfit/item changes leave actual-wear snapshots interpretable; deleting a plan preserves history.
- P9: Recompute each displayed statistic from records, with correct window, denominator, and estimate labeling.
- P10: Add/edit/delete journal fits and link/unlink outfits without changing wear counts or planned state; separately record a matching wear twice and count it once. Journal dates/snapshots remain stable across device-zone/outfit changes and deletion.

- P11 / LOCAL-16: Test selected-place/date identity and late-response rejection, available/unsupported dates and timezone/DST, weather-off/offline/manual paths, AI-ineligible weather, foreground request budgets/coalescing/cooldown, expiry/stale/purge/unit behavior and SDK attribution under the linked contract. Native acceptance target only; no build/device/performance pass is claimed.

## Dependencies

[Wardrobe](wardrobe.md), [Outfits](outfits-themes.md), and durable local date handling precede Planner. Manual planning/history precede assisted filling. Notifications and external calendar sync are later slices.
