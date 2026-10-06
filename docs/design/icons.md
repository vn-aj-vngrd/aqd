# Icon catalog

Phase scope: shared native/visual rules apply to both phases. Five-destination base navigation applies to both phases. Full-app E/W/P/S/A/I/U routes, online identity and connected states are V2 references. Complete private themes/planning/Agent are retained in V1. V1 uses only its [dedicated local flow](v1-flow.md) and [complete local release](../product/v1-release.md); [V2 requirements](v2-requirements.md) own connected and extension coverage.

The visual master is Paper page 00 **Foundations · Icons and navigation states** (`4MI-0`). [Icon manifest](icon-manifest.json) records every app-owned role in this catalog, its master node and native symbol, including aliases for equivalent actions. Clone these registered masters rather than drawing SVGs in individual screens. Register any new role in Foundations and the manifest before use; token tint/size adaptations are allowed, geometry stays shared. Existing structural clones are not live-linked: a master geometry change requires explicit synchronization of affected copies. System-owned chrome and decorative artwork are outside this app-icon inventory. Native implementation uses SF Symbols for action/navigation symbols, a native ProgressView for indeterminate loading and the custom AQD AI assistance badge; Paper uses consistent schematic vectors on a 24-unit grid. Default visual size 22 pt, minimum interactive target 44 pt. Inactive regular weight; active semibold weight (reference stroke 1.7 → 2.35), semantic accent and selected container. Filled variants may be used only when the system provides the matching symbol and the meaning remains clear. Every icon-only control has a localized action label.

## Complete app-owned catalog

The usage inventory identifies **41 semantic roles**, with aliases and selected variants listed separately. Phase columns show actual icon evidence in that phase's canonical/reference designs, not a claim about feature availability or unique visible live-instance counts. Geometry classification covers the supplied exports plus recent repairs; representative live checks reconcile new/uncertain symbols. Exact sources and limits belong to the [Foundations library evidence](evidence/foundations-library.json). Native names are implementation assignments, not proof that schematic Paper vectors are Apple assets.

| Role | Native symbol / implementation | V1 | V2 |
| --- | --- | --- | --- |
| Home | `house` | Yes | Yes |
| Closet | `hanger` | Yes | Yes |
| Agent | `sparkle` | Yes | Yes |
| Inbox | `envelope` | — | Yes |
| Profile | `person.crop.circle` | Yes | Yes |
| Search | `magnifyingglass` | Yes | Yes |
| Add | `plus` | Yes | Yes |
| Back / previous | `chevron.backward` | Yes | Yes |
| Like | `heart` / `heart.fill` | — | Yes |
| Bookmark | `bookmark` / `bookmark.fill` | — | Yes |
| Forward disclosure / next | `chevron.forward` | Yes | Yes |
| Settings | `gearshape` | Yes | Yes |
| Edit | `square.and.pencil` | Yes | Yes |
| Check / selected option | `checkmark` | Yes | Yes |
| More | `ellipsis` | Yes | Yes |
| Lock / private | `lock` | Yes | Yes |
| Calendar / Planner | `calendar`; checked variant `calendar.badge.checkmark` | Yes | Yes |
| Send | `arrow.up` | Yes | Yes |
| Close / remove attachment | `xmark` | Yes | Yes |
| Photo | `photo` | Yes | Yes |
| Camera | `camera` | Yes | Yes |
| Copy response | `doc.on.doc` | Yes | Yes |
| Helpful | `hand.thumbsup` / `hand.thumbsup.fill` | Yes | Yes |
| Not helpful | `hand.thumbsdown` / `hand.thumbsdown.fill` | Yes | Yes |
| Retry / regenerate | `arrow.clockwise` | Yes | Yes |
| Stop response | `stop.fill` | Yes | Yes |
| Clock / time / Wear insights | `clock` | Yes | Yes |
| Jump to latest | `arrow.down` | — | Yes |
| Comments | `text.bubble` | — | Yes |
| Tag / Style action | `tag` | Yes | Yes |
| Closet context / garment placeholder | `tshirt` | Yes | Yes |
| Microphone | `mic` | Yes | Yes |
| Recording waveform | `waveform` | Yes | Yes |
| AI assistance badge | Custom informational star + AI capsule | Yes | Yes |
| Rotate photo | `arrow.counterclockwise` | Yes | Yes |
| Downward disclosure | `chevron.down` | Yes | Yes |
| Delete | `trash` | Yes | Yes |
| Report | `flag` | — | Yes |
| Block | `nosign` | — | Yes |
| Information | `info.circle` | — | Yes |
| Indeterminate progress | Native `ProgressView`; schematic circular spinner | Yes | Yes |

Aliases reuse geometry: Planner/Plan a day → calendar (Plan a day may use the checked variant); attachment → plus; image file → photo; remove attachment → close; finish recording → check; response details → more; previous/next response → back/forward; category placeholder/Make look → context; Agent empty state → Agent. Selected/disabled tint and documented stroke weight do not create new roles. CSS-rendered checkmarks and Stop squares retain the Check/Stop semantics.

### System-owned symbols

These are listed for completeness, but are **not AQD master glyphs**: status-bar signal/Wi-Fi/battery; keyboard Shift/Delete/language/dictation; native date-picker previous/next; Apple sign-in logo; native Photos/camera/source-sheet chrome. The OS supplies their production geometry, accessibility and adaptation. App-owned photo/camera/close controls remain in the table above. Crop grids, radio dots, switches, slider thumbs, grabbers, home indicators and photographic/decorative artwork are not additional icon roles. Text-only Reset/Zoom/Category are not invented icons.

October 6 Settings repair: registered regular/selected masters retain IDs `4Q8-0`/`4QB-0`, but replace the malformed polygon with a shared [eight-tooth outline fallback](https://github.com/tailwindlabs/heroicons/blob/master/optimized/24/outline/cog-8-tooth.svg). Seven retained glyph wrappers across six roots were repaired after a 455-root path scan. Keep 22-point geometry, existing semantic tint and regular/selected stroke weights; native code still uses SF `gearshape`. Master/menu renders checked; offline Night retint is not a live Night/native acceptance sample.

Back and disclosure mirror in right-to-left interfaces. Disabled controls use the semantic secondary foreground and native disabled state. Decorative symbols are hidden from VoiceOver. Native status, Apple sign-in, keyboard and other OS chrome keep their system-owned glyphs. The page 00 icon board lists every inventoried app-owned role with native names and phase usage, plus registered variants/aliases and system-ownership guidance. It is an icon library, not a collection of app screens. The edit master reuses the existing square-and-pencil reference from the Trip plan header, rather than the rejected one-off Profile drawing. Send arrows are vector masters, not Unicode text glyphs. This catalog consolidation is not a claim that every pre-existing screen icon has been migrated.

Both phases use Home · Closet · Planner · Agent · Profile. Planner clones the registered calendar master; the envelope is V2's root-toolbar Inbox action, not a sixth tab. V1 has no Inbox control.

Agent navigation uses a single four-point sparkle in the same 22-point optical box as the other tab icons. Keep the Agent label and existing selection pill. Inactive uses semantic secondary gray; selected uses the shared accent and stronger symbol weight. Dark appearance follows night-secondary/night-accent. Paper uses the matching schematic vector; native implementation uses SF Symbols `sparkle`. This navigation symbol identifies the destination and does not indicate model availability, generation or successful saving.

## Agent response actions

| Role / accessibility label | Native symbol | Selected / active |
| --- | --- | --- |
| Copy response | `doc.on.doc` | Brief checkmark only after clipboard success |
| Helpful | `hand.thumbsup` | `hand.thumbsup.fill`, semibold and selected trait |
| Not helpful | `hand.thumbsdown` | `hand.thumbsdown.fill`, semibold and selected trait |
| Try another response | `arrow.clockwise` | Disabled during active retry |
| Response details and actions | `ellipsis` | Native menu |
| Stop response | `stop.fill` | Solid square on accent circular control |
| Response time | `clock` | Informational; no button semantics |
| Previous / next response | `chevron.backward` / `chevron.forward` | Disabled at version boundaries |
| Jump to latest | `arrow.down` | Visible when reading above new content |

Response toolbar glyphs are 20 points within 44-point targets. Keep regular/semibold stroke consistency with the main icon library. Never use a success checkmark to imply a draft has been saved.

## Social post actions

| Action | Default | Active / meaning |
| --- | --- | --- |
| Like / Unlike post | `heart` | `heart.fill`, accent, selected |
| Save / Remove bookmark | `bookmark` | `bookmark.fill`, accent, selected |
| View comments | `text.bubble` | Press feedback only; opens comments |
| Show tagged pieces | `tag` | Visible tag layer plus count; not auto-detected |

All have 44-point targets. Photo tags and filled action states are demonstrated on the page-00 social component board.


## AI assistance badge

The Foundations icon catalog's **AI assistance** specimen owns a separate, minimal status badge: a small four-point star plus AI inside an opaque capsule. It indicates model-powered assistance without becoming part of the action wording. Keep visible labels such as “Suggest an outfit” unchanged; never prepend AI to the task sentence. Agent navigation uses the standalone sparkle, without the AI capsule.

Use the badge selectively for focused model-powered assistance outside Agent: outfit suggestions, variations, Style this, photo-assisted capture and planning assistance in Closet, Home and related task screens. Agent already establishes the assistance context: its prompt shortcuts, response toolbar, regeneration, Refresh draft, Try again and resend controls have no AI badge. Manual editing, approval/save, ordinary network retries, conversation loading, human Inbox and deterministic Quick rules remain unmarked. The badge is informational, not a separate tap target, completion receipt or promise of availability.

The full badge is 38 × 20 pt: 8 pt four-point star, 10/12 pt bold system AI label, 3 pt internal gap, capsule radius without a decorative border. Use accent foreground on accent-soft; dark appearance uses night-accent on night-accent-soft. The same opaque capsule works on prominent and secondary actions and in Reduce Transparency. The small text is a supplementary badge; the task label retains the normal accessible action size. Native Dynamic Type scales the badge and reflows the action rather than shrinking either.

Full-width buttons center the badge and task label together: badge first, then label, with an 8 pt gap and 20 pt side padding. Disclosure rows place the badge before the label and retain the trailing chevron. Agent Retry menus retain only their task label and native retry symbol. On narrow layouts or at accessibility sizes, expand the control or stack the badge into a separate leading line so neither overlaps the label. Mirror leading placement in right-to-left layouts.

Agent regeneration toolbar controls use the shared 20 pt retry arrow alone inside the unchanged 44 × 44 pt target. Do not add a compact star capsule to response actions.

Expose the task in the localized accessibility label, such as “Suggest an outfit,” with an accessibility hint such as “Uses AI” on marked assistance actions. Hide the decorative badge’s children from VoiceOver so the task is not announced as “AI Suggest an outfit.” AI availability controls enabled state; the badge does not claim generation, save or service setup has succeeded.

## Agent input symbols

| Action | Native symbol / accessible label |
| --- | --- |
| Attachment menu | `plus` / Add to message |
| Selected closet context | `tshirt` / Choose context; speak current mode |
| Dictation | `mic` / Record voice message |
| Recording level | `waveform` / Recording; visual level is decorative |
| Finish recording | `checkmark` / Finish recording |
| Camera | `camera` / Take photo |
| Image file | `photo` / Browse image files |
| Remove attachment | `xmark` / Remove named attachment |
| Jump to latest | `arrow.down` / Jump to latest response |

All icon-only actions have at least 44 pt targets. AI badges identify focused assistance outside Agent only, never Agent suggestion/retry actions, manual selection, mic recording, media readiness or navigation. Stop keeps the shared square symbol and spoken busy/cancellation state.
