# System design decision register

The [V1 release definition](../V1-RELEASE.md) requires all core workflows, working auth/account durability, social/Inbox and launch evidence. [V2 backlog](../V2-BACKLOG.md) holds extras. Service selection and commercial prices remain unresolved; this refinement deploys nothing.

Updated October 1, 2026. This is a workshop summary. Product choices and service gates remain governed by [OPEN-QUESTIONS](../OPEN-QUESTIONS.md); approved lasting architectural choices should be recorded in docs/adr.

## Confirmed in this conversation

| Choice | Meaning |
| --- | --- |
| First release includes all V1 surfaces | Private closet/creation, planning/wear, Agent, discovery/publishing/profiles/follows and human Inbox. |
| Launch from zero | 50k users was an example for scalability, not initial traffic or an operating target. |
| iOS first | Publish on iOS now; Android is outside the current launch. |
| Web/social presence | Include landing pages and a Facebook page. |
| Design documentation | Keep architecture, costs and related workshop material together in this folder. |

## Recommendations, not approvals

| Recommendation | Basis |
| --- | --- |
| Supabase Pro initially | Integrated backend and relational model reduce initial delivery/operations work. |
| Supabase Storage initially | Simpler access/lifecycle integration while photo demand is small. |
| Cloudflare Pages | Low-cost static landing/support pages. |
| Consider R2 when warranted | Photo bandwidth economics; allow migration through stable media references. |
| $414 baseline / $600 first-year reserve | Planning assumptions in Costs; excludes development, ads, taxes and unpriced business work. |
| Freemium and $4.99/month or $49.99/year hypothesis | Needs user willingness-to-pay and capability validation. |
| Optional Instagram, ads and paid staging | Not requested as mandatory launch spending. |

The on-device AI preference and private first use without signup already come from the product specifications. The detailed offline/account-sync proposal has not received a separate answer in this conversation.

## Open before connected release

- Select services/region, identity methods, domain/brand and actual operating budget.
- Decide local-account association, account-scoped storage, sync conflicts, recovery/export and tombstone retention.
- Decide photo limits/variants, public access/cache revocation and deletion/backup policy.
- Finalize moderation/report/block operations, rate limits and responsible operating process.
- Finalize messaging retention, account deletion effects, notifications and accurate encryption claims.
- Validate on-device Agent capability/latency on physical devices; decide weather retrieval if included.
- Validate subscription value, launch market, price and entitlements before payment implementation.
- Define measurable reliability/performance goals, then load test actual flows before capacity claims.

## Next design iteration

Trace capture → outfit → plan → wear → publish → discover → message. Review the minimal data model and authorization boundaries, then approve a concrete service mapping. Deliver implementation slices in dependency order while preserving the complete first-release scope.
