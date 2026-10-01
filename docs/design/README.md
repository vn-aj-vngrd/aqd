# Design handoff

For UI work, begin with [rules](rules.md) and root [DESIGN.md](../../DESIGN.md), then follow the affected branch below. [Paper](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0) owns visuals. Page 00 owns tokens and component masters; structural clone changes need explicit synchronization.

## Shared controls and behavior

| Contract | Read when |
| --- | --- |
| [Components](components.md) | Reusing shared primitives, states, geometry or accessibility contracts. |
| [Icons](icons.md) | Choosing symbols or assistance badges. |
| [Liquid Glass](liquid-glass.md) | Choosing native control material and opaque adaptations. |
| [Native presentations](native-presentations.md) | Selecting menus, sheets, exits, title alignment and open states. |
| [Native iOS acceptance](native-ios.md) | Verifying implementation on supported devices. |
| [Global motion](motion.md) | Adding transitions, loading or feedback. |
| [Motion coverage](motion-coverage.md) | Checking a route's assigned motion and accessibility variants. |
| [Search and feeds](search-and-feeds.md) | Scoped search, control density and pagination. |

## Flows and platform surfaces

| Contract | Read when |
| --- | --- |
| [Screen map](screens.md) | Locating routes, states and artboards. |
| [Entry and identity](entry-identity.md) | First use, optional identity and recovery. |
| [Entry motion](entry-motion.md) | Welcome and first-piece choreography. |
| [Agent experience](agent-experience.md) | Response lifecycle, Markdown, approval and recovery. |
| [Agent input](agent-input.md) | Media/context selection, dictation, streaming and input recovery. |
| [Web](web.md) | Landing/admin appearance and responsive behavior. |
| [V1 flow review](v1-flow.md) | Reviewing numbered Paper journeys and return paths. |
| [V1 coverage](v1-coverage.md) | Mapping release groups to designs and remaining gates. |

## Inventory and evidence

[iOS manifest](paper-manifest.json) and [web manifest](web-paper-manifest.json) own recorded inventory; use their counts instead of copying them into indexes. [Asset provenance](../references/assets.md) owns reference imagery and licensing.

[Offline examples](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-7-0) remain a proposal, not an approved replacement for cached-social contracts. [V1 release](../product/v1-release.md) and [V2 backlog](../product/v2-backlog.md) determine which designed states ship.

Record static review separately from native/device/service evidence in [verification](../delivery/verification.md). Earlier canvas/gallery retirement and refinement reports remain in [the design review archive](../delivery/archive/design-review-log.md).
