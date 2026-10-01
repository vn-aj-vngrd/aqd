# Provider comparison

Recommendation snapshot: October 1, 2026. No services have been purchased or provisioned by this workshop.

## Comparison for AQD

| Option | Fit | Tradeoff |
| --- | --- | --- |
| Supabase | Integrated PostgreSQL, Auth, Storage, Realtime and server-side functions fit the relational wardrobe/social model. | Lowest initial integration effort in this proposal; sync, moderation, messaging rules and recovery remain application work. |
| Cloudflare | Pages for static web; R2 for media; Workers/Queues for custom operations. | Useful complementary building blocks. A $5 Workers plan is not a complete identity/database/messaging backend price. |
| AWS | Broad managed-service choices and infrastructure control; Amplify can simplify configuration. | Price and operate the whole architecture, not Lambda alone. Consider when workload, requirements, existing expertise or credits justify it. |
| Azure | Managed hosting/database and Microsoft ecosystem options. | No current AQD requirement specifically favors it; evaluate if organizational integration, credits or expertise changes the economics. |

These effort/fit judgments are engineering recommendations, not vendor performance benchmarks. AWS and Azure are not inherently more expensive under every workload. Compare total infrastructure and engineering/operating cost for the same capabilities, region and reliability requirements.

## Recommended starting mapping

| Responsibility | Proposed service / boundary |
| --- | --- |
| Identity and relational data | Supabase Auth + PostgreSQL. |
| Ordinary owner-scoped reads | Supabase-backed authorized reads; explicit ownership and access policies. |
| Sensitive multi-record operations | Narrow server-side commands/transactions for plan application, publication, message requests and approved Agent actions. |
| Photos | Supabase Storage initially; separate private originals and public derivatives. |
| Inbox refresh | Supabase Realtime hints plus authorized durable message queries. |
| Slow/retryable work | Add durable jobs and a suitable worker only for actual processing requirements; respect runtime limits. |
| Landing/support pages | Cloudflare Pages, static pages on one domain. |
| Authentication emails | Configured external delivery, initially Resend Free if demand fits. |
| Agent | On-device preference and explicit deterministic fallback; no cloud-provider switch. |

No second always-on API server is required merely because the logical diagram contains a backend box. Do not put privileged service credentials in iOS. Public reads, owner reads and participant messaging have distinct authorization rules. Realtime does not itself implement a finished chat product or offline synchronization.

If photo bandwidth becomes significant, evaluate R2 independently while keeping auth/database in Supabase. Separate media adds authorization, cache and lifecycle work; adopt it when those costs are justified. A demonstrated media-heavy acquisition plan can justify choosing it earlier.

## Primary references

[Supabase pricing](https://supabase.com/pricing), [Realtime authorization](https://supabase.com/docs/guides/realtime/authorization), [function limits](https://supabase.com/docs/guides/functions/limits), [Cloudflare platform pricing](https://developers.cloudflare.com/workers/platform/pricing/), [AWS Amplify concepts](https://docs.amplify.aws/swift/how-amplify-works/concepts/), and [Azure basic application architecture](https://learn.microsoft.com/en-us/azure/architecture/web-apps/app-service/architectures/basic-web-app).
