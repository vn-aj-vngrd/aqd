# AQD documentation

AQD is a personal digital closet for organizing owned pieces, creating outfits and themes, planning clothing use, and optionally sharing real wardrobe content.

## Read first

| Document | Owns / read when |
| --- | --- |
| [Product definition](PRODUCT.md) | Purpose, navigation, and product boundaries. |
| [Canonical vocabulary](../CONTEXT.md) | Domain terminology and relationships. |
| [Feature specifications](features/README.md) | Feature-specific behavior, states, access rules, and acceptance IDs. |
| [Delivery scope](V1-SCOPE.md) | Milestone outcomes and release boundaries. |
| [Implementation plan](IMPLEMENTATION-PLAN.md) | Readiness, dependency order, first module, and completion evidence. |
| [Component map](COMPONENTS.md) | Existing reusable UI and the contracts needed by future slices. |
| [User journeys](USER-FLOWS.md) | Cross-feature journeys; detailed rules stay in feature specs. |
| [Decisions](OPEN-QUESTIONS.md) | Confirmed choices, working defaults, and unresolved service policies. |
| [Implementation status](IMPLEMENTATION.md) | Current app behavior and target gaps. |
| [Verification](VERIFICATION.md) | Actual build/test/device/service evidence and limitations. |
| [Backend setup](BACKEND-SETUP.md) | Optional prototype community setup; not a production backend selection. |
| [UI rules](DESIGN-RULES.md) | Shared design patterns and interface review requirements. |
| [Design system](../DESIGN.md) | Implemented visual conventions, distinct from target navigation. |
| [Assets](ASSETS.md) | Visual references, sources, and licensing. |
| [Alta reference notes](references/ALTA-NOTES.md) | Supplied comparison, provenance, and adaptation boundaries. |

For implementation, read the relevant feature, its dependencies, and the implementation plan. Acceptance IDs are target checks, not passing tests. Record implementation and verification evidence separately; a written requirement does not prove it ships.

This pass is documentation only. The SwiftUI app lives in `apps/ios/`; future Android can use `apps/android/` without duplicating the shared product contracts.
