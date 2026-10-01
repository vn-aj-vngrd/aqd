# Icon catalog

The visual master is the Paper page 00 icon library. Native implementation uses SF Symbols, with the AQD AI badge as the explicit assistance indicator exception; Paper uses consistent schematic vectors on a 24-unit grid. Default visual size 22 pt, minimum interactive target 44 pt. Inactive regular weight; active semibold weight (reference stroke 1.7 → 2.35), semantic accent and selected container. Filled variants may be used only when the system provides the matching symbol and the meaning remains clear. Every icon-only control has a localized action label.

| Role | Native symbol |
| --- | --- |
| home | `house` |
| closet | `hanger` |
| agent | `text.bubble` |
| inbox | `envelope` |
| profile | `person.crop.circle` |
| search | `magnifyingglass` |
| plus | `plus` |
| back | `chevron.backward` |
| heart | `heart` |
| bookmark | `bookmark` |
| chevron | `chevron.forward` |
| settings | `gearshape` |
| check | `checkmark` |
| more | `ellipsis` |
| lock | `lock` |
| calendar | `calendar` |
| send | `arrow.up` |
| close | `xmark` |
| photo | `photo` |

Back and disclosure mirror in right-to-left interfaces. Disabled controls use the semantic secondary foreground and native disabled state. Decorative symbols are hidden from VoiceOver. Native status, Apple sign-in, keyboard and other OS chrome keep their system-owned glyphs. The page 00 icon board shows every reference glyph and all five navigation selections.

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

Paper page 00 **Icon specification — AI assistance** owns a separate, minimal status badge: a small four-point star plus AI inside an opaque capsule. It indicates model-powered assistance without becoming part of the action wording. Keep visible labels such as “Suggest an outfit” unchanged; never prepend AI to the task sentence. Retain Agent’s conversation navigation symbol.

Use the badge for model-powered outfit suggestions, variations, Style this, planning assistance, Agent prompt shortcuts, draft regeneration and resending an Agent prompt. Manual editing, approval/save, ordinary network retries, conversation loading, human Inbox and deterministic Quick rules remain unmarked. The badge is informational, not a separate tap target, completion receipt or promise of availability.

The full badge is 38 × 20 pt: 8 pt four-point star, 10/12 pt bold system AI label, 3 pt internal gap, capsule radius and a 1 pt semantic divider edge. Use accent foreground on accent-soft; dark appearance uses night-accent on night-accent-soft. The same opaque capsule works on prominent and secondary actions and in Reduce Transparency. The small text is a supplementary badge; the task label retains the normal accessible action size. Native Dynamic Type scales the badge and reflows the action rather than shrinking either.

Full-width buttons center the task label independently and dock the badge at the trailing edge, 16 pt inset, reserving 64 pt on both sides at the base size. Disclosure rows keep the label leading and badge trailing before the existing chevron. Native Retry menus put the badge after Retry and before the retry symbol. On narrow layouts or at accessibility sizes, expand the control or stack the badge into a separate trailing line so neither overlaps the label. Mirror trailing placement in right-to-left layouts.

Regeneration toolbar controls use an 18 × 16 pt compact capsule containing only the same 8 pt star, plus the existing 16 pt retry arrow with a 4 pt gap inside the unchanged 44 × 44 pt target. The star’s capsule supplies badge identity without squeezing tiny AI letters into an icon-only action.

Expose the task in the localized accessibility label, such as “Suggest an outfit” or “Try another response,” with an accessibility hint such as “Uses AI.” Hide the decorative badge’s children from VoiceOver so the task is not announced as “AI Suggest an outfit.” AI availability controls enabled state; the badge does not claim generation, save or service setup has succeeded.
