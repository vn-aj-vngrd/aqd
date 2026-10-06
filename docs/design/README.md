# Design handoff by phase

Read [rules](rules.md) and [DESIGN.md](../../DESIGN.md). [iOS Paper](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0) and [web Paper](https://app.paper.design/file/01M3W6P0PN9SSQ1J3N6V23A9WK) own visual UI. The iOS file has exactly three pages, in order: **00 · Foundations**, **01 · V1**, **02 · V2**. Foundations organizes 26 retained master boards under six numbered groups: tokens/type, icons/brand, navigation/chrome, controls/forms/surfaces, images/composition, and states/feedback/Agent/motion. Its six headers and root positions are reference organization, not a user funnel; master dimensions/children and paired roles remain intact. Structural clones require explicit synchronization. V1 has nine ordered journey groups, with supporting states beside their owning flow; dark phone duplicates are removed while Foundations retains paired light/dark colors. V2 has nine groups covering canonical features, connected journeys and future expansions; shared private UI matches V1, with public/account/sync/Inbox additions instead of a replacement Profile layout.

| Phase / contract | Owns |
| --- | --- |
| [V1 flow](v1-flow.md) and [coverage](v1-coverage.md) | Page 01 · V1 complete local app: Home/Closet/Planner/Agent/local Profile, complete private journeys, welcome/onboarding/tour, Settings and appearance/recovery. |
| [V2 flow](v2-flow.md) and [coverage](v2-coverage.md) | Page 02 · V2, section 08: complete connected review and preserved core acceptance references. |
| [V2 expansion requirements](v2-requirements.md) | Page 02 · V2, section 09: prepared requirements for every extension in the full backlog. |
| [Screen map](screens.md) | Retained canonical V2 E/W/P/S/A/I/U routes and shared states. |
| [Private fit journal](profile-fit-journal.md) | Profile grid, empty/add/detail states L160–L163, shared V2 owner U01/U25, separate public projection U26, native More utilities and explicit publication boundary. |
| [Photo capture and editing](capture-photo.md) | V1/V2 missing-photo drafts, photo-required save, portrait/landscape Fit, optional crop/rotation and preserved originals/drafts. |
| [Entry](entry-identity.md), [entry motion](entry-motion.md) | V2 private-first capture plus identity/recovery; V1 uses its separate local entry. |
| [Agent experience](agent-experience.md), [input](agent-input.md) | V2 conversation/rich context/stream/review/recovery; V1 retains the complete local conversation/history/review/recovery experience, with supported on-device context and manual/rules paths. |
| [Web](web.md) | V2 landing/admin visual and responsive contracts. No V1 staff admin. |

[Quality criteria](quality-criteria.md) defines the review checklist, severity and handoff evidence for every UI change. [Icons](icons.md) and the [icon manifest](icon-manifest.json) define the shared Foundations masters; clone registered glyphs, never draw ad hoc screen icons.

[Planner calendar](planner-calendar.md) defines the default Week view, alternate Month view, selected-date add flow and save/recovery behavior.

Shared rules apply only to states present in a phase: [Components](components.md), [Icons](icons.md), [Liquid Glass](liquid-glass.md), [Native presentations](native-presentations.md), [Native iOS acceptance](native-ios.md), [Motion](motion.md)/[coverage](motion-coverage.md), and [Search/feeds](search-and-feeds.md). Community/account/human-chat references are V2, not V1 requirements. The five base destinations and private journal apply to both phases.

[iOS manifest](paper-manifest.json) and [web manifest](web-paper-manifest.json) own phase-labelled inventory. [Assets](../references/assets.md) owns illustrative photography/licensing. The old connected offline examples remain V2 recovery references; the approved V1 now has its own page and no hidden social tabs.

[V1 release](../product/v1-release.md), [V2 backlog](../product/v2-backlog.md) and [V2 core release](../product/v2-release.md) own scope. [Verification](../delivery/verification.md) distinguishes live static Paper review from native/runtime/service checks. Earlier design history stays in [the archive](../delivery/archive/design-review-log.md).

[V1 interactions](v1-interactions.md) maps visible actions, native presentations, returns and shared recovery. [Onboarding personalization](onboarding-personalization.md) defines six questions plus numbered review/progress, explicit No preference/refusal instead of skip, optional body details and the identical editable Settings flow.
