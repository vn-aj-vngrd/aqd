# AQD system design

Updated October 1, 2026. This folder records our architecture workshop and launch economics. It is a planning reference, not evidence of implemented services or approval to create paid accounts.

## Starting point

- Launch on iOS, with landing/support pages and a Facebook page.
- Start from zero users. The 50,000-user discussion is a future scale example, not launch sizing.
- First release includes the full V1: private wardrobe, outfits/themes, planning/wear history, Agent, public profiles/publishing, discovery/follows, and human Inbox.
- Recommend Supabase initially, with Cloudflare Pages for static web pages. Service selection remains pending.
- Estimated baseline: **$414 for year one**, equivalent to **$34.50/month**. Reserve **$600 for operations**, with advertising separate. See assumptions in Costs.

## Documents

| Document | Purpose |
| --- | --- |
| [V1 flow and coverage](../design/V1-FLOW.md) | Selected wardrobe workflow, Paper review, auth/Home branches and deferred Alta capabilities. |
| [Architecture](ARCHITECTURE.md) | Responsibilities, data boundaries, flows, private/public separation, and proposed sync. |
| [Costs](COSTS.md) | Monthly and annual launch budget, billing schedule, optional expenses, and sources. |
| [Providers](PROVIDERS.md) | Supabase, Cloudflare, AWS, and Azure tradeoffs; proposed starting service mapping. |
| [Scalability](SCALABILITY.md) | Growth triggers, media migration, and the illustrative 50k-user calculation. |
| [Pricing strategy](PRICING-STRATEGY.md) | Proposed freemium tiers, unit economics, and validation before monetization decisions. |
| [Decisions](DECISIONS.md) | Confirmed user choices, recommendations, and unresolved gates. |
| [Editable Excalidraw board](aqd-system-design.excalidraw) | Initial workshop architecture, with editable native shapes. |
| [Original board preview](aqd-system-design-preview.png) | Initial workshop screenshot; some open questions have since been answered. |

## Authority and maintenance

[Product](../PRODUCT.md), [feature specs](../features/README.md), [CONTEXT](../../CONTEXT.md), [open questions](../OPEN-QUESTIONS.md), and [DESIGN](../../DESIGN.md) retain their existing authority. Paper remains the sole app visual source. This folder does not introduce a second UI design system or duplicate the domain glossary.

The decision register here summarizes this workshop; it does not silently replace confirmed choices in OPEN-QUESTIONS. Record an ADR when a lasting architecture decision is actually approved. Update estimates when service selection, traffic, retention or prices change; record real implementation and verification in their existing documents.
