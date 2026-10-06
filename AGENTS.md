# AQD agent guidance

Read only the documents relevant to the task; [docs/README.md](docs/README.md) routes by responsibility.

- **Product/spec work:** read [product definition](docs/product/definition.md), the relevant [feature](docs/features/README.md), and applicable [decisions](docs/product/decisions.md). [V1 release](docs/product/v1-release.md) owns launch scope; [V2 backlog](docs/product/v2-backlog.md) owns deferred work.
- **Implementation/fixes/reviews:** follow [lifecycle](docs/agents/lifecycle.md) within the user's authorized scope. Read [plan](docs/delivery/implementation-plan.md) and [current status](docs/delivery/implementation-status.md); update status and [verification](docs/delivery/verification.md) with actual evidence. Product refinement authorizes documentation, not app implementation.
- **UI work:** apply [design quality criteria](docs/design/quality-criteria.md) for creation, review, polish and implementation handoff; read [design rules](docs/design/rules.md) and root [DESIGN.md](DESIGN.md), then the affected component/flow contract through the [design index](docs/design/README.md). For V1 controls, update [interaction coverage](docs/design/v1-interactions.md) with destinations and state/return behavior.
- **Commits/PRs/releases:** read [workflow](docs/delivery/workflow.md). Use Conventional Commits and PR titles; ticket references belong in the body.

## Agent skills

- **Issue tracker:** GitHub Issues in `vn-aj-vngrd/aqd`; read [tracker configuration](docs/agents/issue-tracker.md) before ticket operations.
- **Triage labels:** five confirmed default states; read [label mapping](docs/agents/triage-labels.md) before assigning labels.
- **Domain docs:** root [CONTEXT.md](CONTEXT.md) is the glossary; [docs/adr/](docs/adr/README.md) holds lasting decisions. Read [domain guidance](docs/agents/domain.md) for domain/architecture work.
