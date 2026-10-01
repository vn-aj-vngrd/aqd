# Domain documentation

AQD uses one root `CONTEXT.md` and `docs/adr/` for cross-feature architectural decisions. The `apps/ios` layout alone does not require separate bounded contexts. Read the glossary and relevant ADRs before exploring a feature. Missing ADRs are not a blocker; create one only when resolving a lasting architectural decision.

Use glossary terms in specs, tests, tickets, and reviews. Detailed feature behavior lives in `docs/features/`, confirmed versus proposed choices in `docs/product/decisions.md`. Flag a conflicting ADR before replacing its decision; record the reasoning and superseding decision. Avoid duplicating the glossary in individual feature specs.
