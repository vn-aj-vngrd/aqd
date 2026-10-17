# Planner, wear and insights

Planner is the third root (Week default, Month alternate, selected date preserved). Planner organizes intent, History records actual use, Stats explains it. Back restores origin, scroll and selection. Nothing here needs an account.

## Plans

- A plan has an ID, name, inclusive date range, explicit timezone and optional event or routine. An entry has its own ID, local date, occasion, optional outfit and a state: unassigned, planned, worn, skipped. Several entries can share a date. Assigning is not wearing.
- An event supplies dates, destination and activities. A routine supplies a range, weekdays, occasions and preferred looks. Entries are stored resolved on save; recurrence is an authoring aid, not a background generator.
- Dates are calendar dates in the plan's timezone and do not shift when the device travels. Manual plans span up to two weeks; routines up to three calendar months.
- **Plan a look / plan authoring** follow the [modal pattern](../../DESIGN.md#add-and-edit-modal-pattern): a hero preview, inline outfit strip with an Unassigned (or Gap) chip, then date, occasion, weather context and timezone.
- Existing plans are never overwritten silently. An edited outfit flags future entries for review. Overlapping date and occasion entries warn and offer Keep both or Replace.
- Routine edits apply to this entry, this and future entries, or the whole routine; worn and skipped history stays intact.
- Bulk save is all-or-nothing. A failure keeps the draft; no partial calendar.
- **Trips** use the same model. Packing is a deduplicated set of owned pieces from assigned outfits with check state; reassigning recomputes while keeping checks for retained pieces. Blank assignments show a packing gap.
- **Weather** is optional (see [architecture](../architecture.md)): selected place and date, source, freshness and attribution shown, at most ten forecast days, never invented, never required. Saved weather older than 24 hours is labelled and never fresh Agent input.

## Wear

- One wear per identical piece set per local day; different combinations are allowed. A stable operation ID prevents retry duplicates. Recorded day and timezone never change. Wear can be backdated or corrected, rechecking duplicates.
- A record snapshots piece IDs with minimal names and categories, optional outfit and plan entry, date, timezone and provenance. Photos and notes are not required.
- **Record wear** shows a pinned tappable canvas of the pieces with an inline piece strip, a "Worn on" date and timezone. Planning never records wear.
- Marking a planned entry worn creates or links the record; undoing returns linked entries to planned and removes the counts once. Skipped creates no record. Deleting a plan or editing an outfit never rewrites history.
- A fit memory in Profile is separate; only an explicit Record wear action records wear.

## Insights

Piece total = estimated prior wears + recorded occurrences, with estimates labelled. Recorded utilization = active pieces with at least one dated wear / all active pieces, excluding estimates. Monthly reports separate occasions from piece totals. Missing history or an empty denominator says "Not enough recorded history", never a percentage.

## Acceptance

- Create, edit and delete a plan, trip and routine without touching wear history.
- Resolve an overlap with Keep both and with Replace.
- Record, backdate, correct and undo a wear; a duplicate set on one day is caught once.
- A failed bulk save leaves the draft and no entries.
