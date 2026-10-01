# Design handoff

Release scope is governed by [V1 release definition](../V1-RELEASE.md) and [V2 backlog](../V2-BACKLOG.md). Paper includes future/proposal states; screen inventory alone does not authorize every enhancement for launch.

[Open AQD in Paper](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0). Paper is the sole visual source. The local gallery and renderers were retired on October 1, 2026 after verifying 99 screens and 13 reference boards in Paper.

- Page 00 owns visual tokens and component masters. Token changes propagate; cloned geometry must be updated in affected instances.
- [Screen map](SCREENS.md) owns route and state contracts.
- [Entry and identity](ENTRY-IDENTITY.md) explains first use, optional discovery and auth recovery.
- [V1 coverage](V1-COVERAGE.md) maps all 15 release groups, new lifecycle screens, shared states and remaining launch gates.
- [V1 flow review](V1-FLOW.md) links the dedicated page 09 walkthrough from Welcome through optional auth, first outfit, planning/wear, travel, community and Inbox, with recovery branches and deferred scope.
- [Entry motion](ENTRY-MOTION.md) specifies the welcome sequence, timing and Reduce Motion alternative.
- [Native acceptance](NATIVE-IOS.md) defines implementation checks.
- [Native presentations](NATIVE-PRESENTATIONS.md) selects native menus, adaptive popovers, bottom sheets, editor modals and confirmations.
- [Manifest](paper-manifest.json) is the verified inventory, not an executable design source.
- [Liquid Glass controls](LIQUID-GLASS.md) defines native material choices for inputs, Back, buttons, tabs and presentations. Temporary captures are ignored and are not documentation deliverables.

Edit visuals in Paper. Update these documents only when behavior or handoff contracts change. Native app and service implementation are separate from static design completion.

[Agent experience](AGENT-EXPERIENCE.md) defines response streaming, measured progress and timing, copy, response versions, evaluation feedback and recovery. Paper page 05 contains the states; page 00 contains reusable patterns.

Current inventory: **179 screens and 48 reference boards** (227 artboards across ten pages). Agent now has A01–A30, plus A31–A33 lifecycle/context reviews. Evaluation feedback/version-comparison states are V2 references.

[Global motion](MOTION.md) defines native ownership, shared values, interruption and accessibility. [Motion coverage](MOTION-COVERAGE.md) assigns all screen states; page 00 Foundations · Global motion is the visual reference.

[Search and feeds](SEARCH-AND-FEEDS.md) defines public/private search layouts and states, shared control density, thumbnails and infinite-scroll continuation.

[Offline experience review](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-7-0) is a separate proposal: four viewport examples and a scope board. Offline personal closet, online social features. It is not an approved replacement for the existing cached-social contracts.

Page 00 **Components · Native controls and open menus** shows page-specific open commands, native alert/action choices, switches, Appearance selection, rich-popover adaptation and dark/opaque variants. [Native presentations](NATIVE-PRESENTATIONS.md) owns the full native-control and per-page V1 mapping.
