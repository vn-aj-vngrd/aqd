# AQD documentation

AQD is a personal digital closet for organizing owned pieces, creating outfits and themes, planning clothing use, and optionally sharing real wardrobe content.

## Read first

| Document | Owns / read when |
| --- | --- |
| [Product definition](PRODUCT.md) | Purpose, navigation, and product boundaries. |
| [System design](system-design/README.md) | Architecture, launch costs, provider tradeoffs, scaling, pricing hypotheses, and decision status. |
| [Canonical vocabulary](../CONTEXT.md) | Domain terminology and relationships. |
| [Feature specifications](features/README.md) | Feature-specific behavior, states, access rules, and acceptance IDs. |
| [V1 release definition](V1-RELEASE.md) | Complete mandatory features, auth/data contracts, gap analysis and launch evidence. |
| [V2 backlog](V2-BACKLOG.md) | Extras explicitly outside the first release. |
| [Delivery scope](V1-SCOPE.md) | Milestone outcomes and release boundaries. |
| [V1 design coverage](design/V1-COVERAGE.md) | Every release group mapped to Paper flows/screens, V2 boundaries and service gates. |
| [V1 flow review](design/V1-FLOW.md) | Paper walkthrough, first-outfit activation and selected workflow coverage. |
| [Agent lifecycle](agents/LIFECYCLE.md) | Triage, specs, implementation, review, PR gates, merge, and release handoff. |
| [Development workflow](DEVELOPMENT-WORKFLOW.md) | Local hooks, commits, CI, and automatic repository releases. |
| [Implementation plan](IMPLEMENTATION-PLAN.md) | Readiness, dependency order, first module, and completion evidence. |
| [Component map](COMPONENTS.md) | Canonical reusable design contracts and native mappings. |
| [User journeys](USER-FLOWS.md) | Cross-feature journeys; detailed rules stay in feature specs. |
| [Decisions](OPEN-QUESTIONS.md) | Confirmed choices, working defaults, and unresolved service policies. |
| [Implementation status](IMPLEMENTATION.md) | Current app behavior and target gaps. |
| [Verification](VERIFICATION.md) | Actual build/test/device/service evidence and limitations. |
| [Backend setup](BACKEND-SETUP.md) | Optional prototype community setup; not a production backend selection. |
| [UI rules](DESIGN-RULES.md) | Shared design patterns and interface review requirements. |
| [Entry and identity](design/ENTRY-IDENTITY.md) | First use, optional discovery, sign-in and recovery. |
| [Screen inventory](design/SCREENS.md) | Complete route/state map and Paper coverage. |
| [Design system](../DESIGN.md) | Authoritative target design, tokens, native behavior and Paper links. |
| [Assets](ASSETS.md) | Visual references, sources, and licensing. |
| [Alta reference notes](references/ALTA-NOTES.md) | Supplied comparison, provenance, and adaptation boundaries. |

For implementation, read the relevant feature, its dependencies, and the implementation plan. Acceptance IDs are target checks, not passing tests. Record implementation and verification evidence separately; a written requirement does not prove it ships.

This pass is documentation only. The SwiftUI app lives in `apps/ios/`; future Android can use `apps/android/` without duplicating the shared product contracts.
