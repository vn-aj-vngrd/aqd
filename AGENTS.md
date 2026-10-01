# AQD agent guidance

For product or feature work, read [docs/PRODUCT.md](docs/PRODUCT.md) and the relevant specification in [docs/features/README.md](docs/features/README.md). Use [CONTEXT.md](CONTEXT.md) for domain terms and [docs/OPEN-QUESTIONS.md](docs/OPEN-QUESTIONS.md) to distinguish confirmed choices from working defaults and service gates.

Before implementing a module, read [docs/IMPLEMENTATION-PLAN.md](docs/IMPLEMENTATION-PLAN.md) and inspect [docs/IMPLEMENTATION.md](docs/IMPLEMENTATION.md). Deliver the authorized slice using existing app patterns; update implementation status and [docs/VERIFICATION.md](docs/VERIFICATION.md) with actual evidence. Product refinement alone does not authorize app changes.

Before adding a screen, changing shared UI, choosing icons, or reviewing an interface, read [docs/DESIGN-RULES.md](docs/DESIGN-RULES.md). Use [DESIGN.md](DESIGN.md) for the authoritative target visual system and [docs/COMPONENTS.md](docs/COMPONENTS.md) for reusable component contracts.

Before committing, opening a PR, or changing release automation, read [docs/DEVELOPMENT-WORKFLOW.md](docs/DEVELOPMENT-WORKFLOW.md). Use conventional commit subjects and PR titles; ticket references belong in the body.

## Agent skills

### Issue tracker

GitHub Issues in `vn-aj-vngrd/aqd` hold tickets and implementation specs. Read `docs/agents/issue-tracker.md` before ticket operations.

### Triage labels

Use the confirmed default five triage states. Read `docs/agents/triage-labels.md` before assigning state labels.

### Domain docs

Single-context: root `CONTEXT.md` and `docs/adr/`. Read `docs/agents/domain.md` before domain exploration or architecture changes.

For implementation, bug fixes, review fixes, or PR delivery, follow [docs/agents/LIFECYCLE.md](docs/agents/LIFECYCLE.md) through its current-head checks and release gates, within the user’s authorized scope. Keep this file as the shared Codex/Claude/other-agent entry point.
