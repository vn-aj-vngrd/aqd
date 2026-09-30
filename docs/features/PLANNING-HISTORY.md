# P — Planning, actual wear, and insights

## Outcome and placement

Closet's Planner organizes intended clothing use; History records actual use; Stats explains that history. A Today entry shows the user's next planned look, not a social Home recommendation. Entry from an outfit can schedule it directly.

## Planning contract

A plan has ID, owner, name, date range, explicit timezone, and optional event/routine. A plan entry has its own ID, local date, occasion/slot, optional outfit reference, and state: unassigned, planned, worn, skipped. Multiple entries can exist on a date. Planned assignment is not a wear record.

An event supplies dates, optional destination and activities. A routine supplies start/end dates, selected weekdays, occasions, and preferred looks. Working default: store resolved entries when saving; recurrence is a plan authoring aid, not a background generator that changes saved choices without review.

Dates are calendar dates in the plan's chosen timezone. Traveling/device-zone changes do not shift an already assigned local day. Start/end are inclusive. Calendar months are calendar months, not a hard-coded 90 days. Initial assisted ranges support two weeks and up to three calendar months; larger ranges require a separately specified slice.

## Manual and assisted flows

Calendar and agenda expose date, occasion, assignment, and state. Create a named plan, assign saved outfits, move/replace/remove entries, and leave intentional gaps. Existing plans are not overwritten silently. Outfit revisions after assignment flag affected future entries for review; confirm the updated composition or choose another outfit. Historical wears retain their snapshots.

Focused assistance or Agent receives dates, activities, mood, pinned pieces, repetition preferences, availability, and optional weather. Generate bounded batches into one reviewable draft; show range, gaps, repeats, and conflicts before committing. Working default: bulk save is all-or-nothing; failure retains the draft, with no partially applied calendar.

Routine edit choices: this entry, this and future entries in the routine, or the whole routine. Future edits preserve worn/skipped historical entries. Overlapping date/occasion entries warn and offer keep-both or replace; the agent chooses neither silently.

Trips use the same event/plan model. Packing list is a deduplicated set of owned items in assigned outfits, with checked state. Changing assignment recalculates contents while preserving checks for retained IDs. Repeated wear does not invent quantities of owned items. Blank/unavailable assignments produce a visible packing gap.

Weather includes place, source timestamp, and relevant date. Beyond available forecast coverage, label assumptions or omit weather claims. Laundry/unavailable pieces show a conflict; repeated available pieces are allowed. Packing luggage constraints are later assistance refinement, not fabricated capacity guarantees.

## Wear and history contract

Working default consistent with current behavior: one wear per identical item set per local calendar day; distinct combinations on a day are allowed. A stable operation ID prevents retry duplication. The recorded day/timezone does not change when the device travels. The user can backdate or correct a record; correcting a date/item set rechecks duplicates.

A record snapshots item IDs and minimal names/categories, optional outfit/plan-entry ID, date/timezone, and provenance. Photos and notes are not required in historical snapshots. Item total = estimated prior wears + recorded occurrences; estimates do not imply dated history. Marking planned entries worn creates or links the matching record. Undoing a wear returns every entry linked to that record to planned and removes its recorded item counts once; skipped creates no record. Deleting a plan never deletes actual history. Editing an outfit does not rewrite what was worn earlier.

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

## Dependencies

[Wardrobe](WARDROBE.md), [Outfits](OUTFITS-THEMES.md), and durable local date handling precede Planner. Manual planning/history precede assisted filling. Notifications and external calendar sync are later slices.
