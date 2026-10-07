# AQD documentation

Start with the row matching your task, then read the relevant contract. Folder indexes are navigation, not a request to load every document.

| Task | Start here | Owns |
| --- | --- | --- |
| Understand the product or scope | [Product](product/README.md) | Purpose, journeys, release boundaries and decision status. |
| Implement or review a feature | [Features](features/README.md) | Detailed behavior, access rules, states and acceptance IDs. |
| Design or review UI | [Design](design/README.md) | Components, native controls, motion, routes and Paper traceability. |
| Plan services or operations | [Architecture](architecture/README.md) | System boundaries, provider proposals, costs and growth. |
| Deliver or verify work | [Delivery](delivery/README.md) | Plan, current implementation, evidence and repository conventions. |
| Operate engineering skills | [Agent configuration](agents/README.md) | Lifecycle, tracker, triage and domain reading rules. |
| Understand a lasting decision | [ADRs](adr/README.md) | Approved choices and their reasoning. |
| Review reference provenance | [References](references/README.md) | Asset sources, licensing and competitor notes. |

Root [CONTEXT.md](../CONTEXT.md) owns vocabulary. Root [DESIGN.md](../DESIGN.md) owns visual foundations; Paper owns the visual canvas. [AGENTS.md](../AGENTS.md) is the agent entry point.

Specifications describe targets. [Current status](delivery/implementation-status.md) describes implementation; [verification](delivery/verification.md) describes observed evidence. Historical reports live in [the delivery archive](delivery/archive/README.md) and are read only when tracing prior work or restoring the prototype.

## Authority and read branches

| Question | Authoritative owner | Load boundary |
| --- | --- | --- |
| Is behavior in this phase? | V1/V2 release and V2 backlog | Relevant scope/acceptance rows; full phase checklist for readiness review. |
| What must the feature do? | Affected feature contract | Shared/V1 behavior for local work; connected/extension sections only for those changes. |
| How does it work technically? | Architecture/ADR | Affected mechanics; provider/cost/scaling proposals only for selecting services or measured capacity work. |
| How does it look/return? | Design branch | Foundations + procedure + affected contract + applicable quality/reference; catalogs are not blanket prerequisites. |
| Who approved it / what is unsettled? | Decisions/ADRs | Applicable approval/open question; do not treat historical recommendations as approval. |
| What was actually observed? | Current delivery status/verification | Establish baseline before capability/readiness claims; archive only for earlier evidence. |
| Why that API/asset choice? | Dated research/source provenance | API evaluation, factual challenge, licensing or provenance audit, not routine UI implementation. |

**Read-only review:** current source/status and affected acceptance; lifecycle review stage only. **Docs refinement:** owner documents plus link/evidence validation; native acceptance stays unverified, not waived. **Implementation:** authorized lifecycle stages, relevant plan slice and affected behavior/mechanics/UI. **PR/release:** workflow and delivery stages only when authorized. Folder indexes select branches rather than requesting all descendants.
