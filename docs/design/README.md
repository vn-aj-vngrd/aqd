# Design handoff by phase

Read [rules](rules.md) and [DESIGN.md](../../DESIGN.md). [iOS Paper](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0) and [web Paper](https://app.paper.design/file/01M3W6P0PN9SSQ1J3N6V23A9WK) own visual UI. The iOS file has exactly three pages, in order: **00 · Foundations**, **01 · V1**, **02 · V2**. Foundations retains its shared tokens/component masters; structural clones require explicit synchronization. V1 has ten numbered flow groups. V2 has nine groups covering canonical features, complete connected journeys and future expansions.

| Phase / contract | Owns |
| --- | --- |
| [V1 flow](v1-flow.md) and [coverage](v1-coverage.md) | Page 01 · V1 complete local app: Home/Closet/Agent/local Profile, complete private journeys, welcome/onboarding/tour, Settings and appearance/recovery. |
| [V2 flow](v2-flow.md) and [coverage](v2-coverage.md) | Page 02 · V2, section 08: complete connected review and preserved core acceptance references. |
| [V2 expansion requirements](v2-requirements.md) | Page 02 · V2, section 09: prepared requirements for every extension in the full backlog. |
| [Screen map](screens.md) | Retained canonical V2 E/W/P/S/A/I/U routes and shared states. |
| [Entry](entry-identity.md), [entry motion](entry-motion.md) | V2 private-first capture plus identity/recovery; V1 uses its separate local entry. |
| [Agent experience](agent-experience.md), [input](agent-input.md) | V2 conversation/rich context/stream/review/recovery; V1 retains the complete local conversation/history/review/recovery experience, with supported on-device context and manual/rules paths. |
| [Web](web.md) | V2 landing/admin visual and responsive contracts. No V1 staff admin. |

Shared rules apply only to states present in a phase: [Components](components.md), [Icons](icons.md), [Liquid Glass](liquid-glass.md), [Native presentations](native-presentations.md), [Native iOS acceptance](native-ios.md), [Motion](motion.md)/[coverage](motion-coverage.md), and [Search/feeds](search-and-feeds.md). Community/account/chat and five-destination references in these documents are V2, not V1 requirements.

[iOS manifest](paper-manifest.json) and [web manifest](web-paper-manifest.json) own phase-labelled inventory. [Assets](../references/assets.md) owns illustrative photography/licensing. The old connected offline examples remain V2 recovery references; the approved V1 now has its own page and no hidden social tabs.

[V1 release](../product/v1-release.md), [V2 backlog](../product/v2-backlog.md) and [V2 core release](../product/v2-release.md) own scope. [Verification](../delivery/verification.md) distinguishes live static Paper review from native/runtime/service checks. Earlier design history stays in [the archive](../delivery/archive/design-review-log.md).
