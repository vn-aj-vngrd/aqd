# Today

The first destination (house icon): a personal stack of in-app cards. They are not WidgetKit or Home Screen widgets, and there are no external integrations.

## Configuration

- At least one instance, no maximum, repeats allowed. Stable instance IDs keep repeated kinds and personal content independent. Stock order on first use: Today's look, Week in wear, Closet in use. Empty data changes card content, not the saved list.
- **Customize Today** opens a draft editor: add, configure, duplicate, remove, reorder. Saved layout is authoritative: never reset it or silently add or drop kinds. Save is atomic; failure keeps the old layout and the draft.
- Cards read existing records and never write them. Sample content is never stored as user data.

## Kinds

| Kind | Shows | Empty or lost source |
| --- | --- | --- |
| Today's look | Plan entry for today, or a pinned entry | Offer a plan or manual builder; a deleted pin offers Review plan, never a silent substitute. |
| Week in wear | Actual wear this locale week, or a chosen week | No history offers first wear; loading never shows zero. |
| Closet in use | Utilization for the latest completed month, or a chosen one | Explain insufficient data; no fabricated percentage. |
| Upcoming plans | Next 7 or 14 days, or one plan | Offer planning; deleted assignments show as unassigned. |
| Wear again | Least recently worn available piece, or a pinned piece | Exact last-worn date; none opens Closet. |
| Favorite outfits | Owned favorites, or one outfit | Empty opens Outfits. |
| Theme | One chosen theme | Empty offers Add outfits; a deleted theme needs Configure. |
| Fit journal | Latest fit memory, or a chosen one | Empty opens Add fit; not wear, not Agent context. |
| Weather | Launcher to existing weather setup, Off by default | Adding never enables weather. |
| Quick actions | Ordered subset of Add piece, Build outfit, Planner, Record wear, Add fit, Open Closet | Default is Add piece, Build outfit, Planner, Record wear (a two by two grid, one column at accessibility sizes); saved choices never change. Commands never auto-save or auto-wear. |
| Note | Own text, optional title | Blank note cannot apply. Full text kept; long notes show Read more. |
| Photo | One prepared local photo, optional title and caption | A missing photo blocks apply; lost media offers Replace. |

Personal cards are never uploaded, published or sent to Agent. Photo cards use the shared `SharedPhotoSourceButton`.

## Acceptance

- Reopen after restart with the saved layout and personal content intact.
- A failed save keeps the previous layout and the draft.
- Each kind handles empty, loading, invalid and lost-source states without writing records.

## Reading the stack

- Each card has one title and no eyebrow. Metadata uses separate lines or commas, never a middle dot.
- Today's look leads with one primary button chosen by `TodayPresentation.look`: Record wear for a current plan, Review plan when the outfit changed or is flagged, Choose outfit when the outfit is gone, Build outfit or Add piece with no plan. The outfit opens from its picture; Plan details is the only quiet link. Worn and skipped looks offer no button.
- Upcoming plans show short relative days (Today, Tomorrow, then Mon, Oct 19) and skip today's entry while a Today's look card already shows it.
- Closet in use names the month, not a date range, and keeps one short sentence when there is nothing to show.
- Quick actions are compact capsules, each at least 44 pt tall, two per row.
