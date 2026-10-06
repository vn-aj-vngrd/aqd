# Planner: week, month and quick add

V1 section 05 in [Paper](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-2-0) uses the shared tokens and [quality criteria](quality-criteria.md). [V1 flow](v1-flow.md) owns the surrounding journey; routines, trips, packing and conflicts remain independent paths.

## Views and navigation

- **Planner is a dedicated root tab** in both V1 and V2: Home · Closet · Planner · Agent · Profile. Closet contains only Pieces · Outfits · Themes. V2 human Inbox is a persistent root-toolbar entry, not a sixth tab; V1 has no Inbox. Home/outfit Plan links enter Planner with their date/outfit context and preserve the source for Back.
- **Default is Week**, as shown by L09 and the existing L33 Planner reference. Show the current week, selected-day agenda and upcoming plans. Month is an explicit alternate view, not a replacement default.
- **Month** opens L85. Display the real month grid, previous/next month controls, selected date and its agenda. Week returns to the week containing the selected date. Switching views preserves selection, scroll context and existing plans.
- Filled accent marks selection; an outlined current date remains visible when another date is selected. Dots indicate dates with plans. Accessibility labels state the full date, today/selected status and plan count; dots are not the only cue.
- Tapping a date updates the agenda. Adjacent-month dates navigate to that month. Native implementation uses the user's locale, calendar and first weekday, handles 4–6 week months and leap years, and provides a Today shortcut in the month/year picker.
- Header + retains date-prefilled creation. Today/selected-day Add is removed from L09/L33/P01/L82/L84/L85; do not repeat toolbar creation beside the agenda heading. Populated L09/L33/P01/P02 omit redundant creation footers; P01/P02 duplicate creation nodes remain hidden, not separate actions. Empty-date L82 retains its prominent Plan an outfit action. These entries do not create a record by themselves. Other populated month/supporting copies remain outside this bounded review.

## Add and save

| State | Reference | Behavior |
| --- | --- | --- |
| Week with plans | L09 / L33; V2 P01 | Dedicated Planner root; tap a plan for detail/edit or Month for broader browsing. |
| Month with plans | L85 | October 2026 example, October 5 selected, visible outfit agenda. |
| Empty selected date | L82 | October 7 selected, brief empty message and Plan an outfit. No fake existing plan. |
| Date-prefilled form | L83 / L10 | Date and timezone inherit selection. Outfit opens the local picker; the shown L83 sample is after choosing An easy afternoon. |
| Saved date | L84 | Return to the same date/view after successful persistence. Agenda and date marker update once. Plan saved confirmation offers Undo. |

The initial form has no outfit selected. Save accepts a valid date/timezone and either an explicitly selected outfit or the user's Leave unassigned action. Leave unassigned saves a clearly labelled unassigned plan; it never silently selects the sample outfit. Name/occasion can be edited. Cancel/Back preserves the existing draft contract and leaves the calendar unchanged. An empty closet links to adding a piece or allows an unassigned plan.

On save, show progress and disable repeat submission. Failure retains the form and offers retry using the same operation identity; there is no success banner or calendar dot until persistence succeeds. A real conflict opens L42, then returns to the retained date/view after resolution; cancel preserves the draft. Undo removes only the just-created entry, keeps any pre-existing plans and recomputes the day's marker. An expired Undo leads to ordinary edit/delete with confirmation. Recording actual wear is always a separate action.

## Grouped forms and agenda surfaces

The Week strip in L09/L33/P01 uses one opaque semantic surface, 12-point corners, 8-point padding and 80-point reference height. Seven unchanged date targets remain 44 × 64 points; selection retains its check/fill/accessible state. Do not put a separate card around every date. Month calendars retain their existing surface and date semantics.

Packing L39/P07 uses separate opaque 12-corner, 80-point minimum rows, 12-point gaps and 12 × 14-point padding, with matching 48 × 56-point full-Fit garment thumbnails, a flexible name/use-count lane and a trailing 44-point checkbox target. Remove rules; retain the original checks and deduplicated item IDs. Review unassigned dates is its own 54-point surface. The four visible fixture rows are a sample of the stated list, not an invented packed-progress total. Assignment changes preserve checks for surviving IDs; native scrolling and persistence remain acceptance requirements.

Plan a look groups Outfit and Timezone into one opaque surface. New plan groups Timezone, Repeat days and Choose outfits; routine detail groups Occasion and Repetition; trip detail groups Timezone, Outfit plan and Packing list. Use one related-row surface, not separate cards for each input: 12-point corners, 54-point minimum rows, 14-point horizontal content insets, 22-point trailing disclosure glyphs and no decorative separators between rows. Spacing and fixed lanes distinguish the choices. Leading labels flex; values and disclosure lanes retain space rather than collide. Labelled text/date fields remain separate 16-corner field surfaces. Keep 16 points between form groups and protect dirty drafts on dismissal.

Agenda entries use consistent opaque 12-corner surfaces, 14-point padding, 12-point cover/text/disclosure gaps, real 64 × 80-point outfit covers, a flexible text lane and a fixed 22-point disclosure. The baseline card is at least 108 points; long titles and accessibility text increase height. Titles use 17/24 and metadata 15/21, with 4 points inside the text stack. Keep 8–12 points from a section heading to its card and 24 points between agenda sections. Standalone cards do not inherit table-style bottom rules. Compact trip summary rows without covers use the same opaque 12-corner ground and 14-point horizontal inset, a 54-point minimum target, flexible title, retained date lane and fixed disclosure. No fake entries on an empty date; hidden/offscreen examples do not establish a scroll implementation.

Planner selection persists while switching Week/Month or pushing an editor. Returning from Home/outfit contextual entry restores the source state; switching root tabs preserves each root's calendar selection and scroll. Native safe areas and growing scroll content keep the five-slot bar stable. Neither selecting a date nor creating/editing/deleting a plan records actual wear.

## Native acceptance

The Paper examples are static. Implement the grid and agenda as one accessible, scrollable screen with stable bottom navigation. Date targets are at least 44 × 44 points; at larger text sizes use an accessible date picker/list rather than squeezed labels. Verify VoiceOver chronological order, month announcements, keyboard/focus return, dark appearance, short phones, long month names, DST/timezone transitions, multi-plan days, empty months and interruption/recovery. Preserve the selected calendar date when travelling; do not silently shift an all-day plan through UTC conversion.
