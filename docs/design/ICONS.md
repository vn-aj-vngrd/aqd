# Icon catalog

The visual master is the Paper page 00 icon library. Native implementation uses SF Symbols; Paper uses consistent schematic vectors on a 24-unit grid. Default visual size 22 pt, minimum interactive target 44 pt. Inactive regular weight; active semibold weight (reference stroke 1.7 → 2.35), semantic accent and selected container. Filled variants may be used only when the system provides the matching symbol and the meaning remains clear. Every icon-only control has a localized action label.

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
