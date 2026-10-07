# AQD agent guidance

[Documentation router](docs/README.md) selects task branches and authoritative owners. Read the affected contracts, not entire folder catalogs.

- **Engineering:** read [lifecycle authority](docs/agents/lifecycle.md) and select only the authorized stage. Establish [current status](docs/delivery/implementation-status.md); read the [plan](docs/delivery/implementation-plan.md) when selecting/changing an implementation slice. Record changed scope and actual evidence in [verification](docs/delivery/verification.md). Product refinement authorizes documentation, not app implementation.
- **Product/spec:** read [definition](docs/product/definition.md), affected [feature](docs/features/README.md), applicable [decision](docs/product/decisions.md) and phase release acceptance. [V1 release](docs/product/v1-release.md) owns launch scope; [V2 backlog](docs/product/v2-backlog.md) retains deferred work.
- **UI:** read [foundations](DESIGN.md), [procedure](docs/design/rules.md), then the affected feature/design contract via [design routing](docs/design/README.md). Apply [quality criteria](docs/design/quality-criteria.md) to changed inventory; specialist catalogs fire only for their branch. V1 control changes update [interaction coverage](docs/design/v1-interactions.md), including state/return behavior.
- **Commit/PR/release:** read [workflow](docs/delivery/workflow.md) only when those operations are authorized. Preserve required CI/Codex, protection and SHA-bound squash gates. Conventional Commit/PR titles; ticket references in the body.
- **Issues:** read [tracker configuration](docs/agents/issue-tracker.md) before operations and [triage labels](docs/agents/triage-labels.md) before assigning labels.
- **Domain/architecture:** [CONTEXT.md](CONTEXT.md) owns vocabulary; read [domain guidance](docs/agents/domain.md) for terminology/architecture changes and [ADRs](docs/adr/README.md) for lasting decisions.
