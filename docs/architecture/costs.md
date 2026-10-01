# Launch costs

Pricing snapshot: October 1, 2026. All figures are USD, before taxes and currency conversion. This is a recommended budget, not a paid-service selection or purchase authorization.

## Assumptions

Launch from zero users; one Supabase Pro production project at Micro compute; static landing/support pages; existing Mac/iPhone and support inbox; self-built branding/content; no paid ads or cloud AI. Assume twelve full months of production billing and usage within included allowances. Development before production may cost less.

## First-year baseline

Monthly equivalents spread annual payments over twelve months; they are not each service's actual billing schedule.

| Item | Starting setup | Monthly equivalent | First-year cost |
| --- | --- | ---: | ---: |
| iOS publishing | Apple Developer Program, annual membership | $8.25 | $99 |
| App backend | Supabase Pro, one Micro project | $25 | $300 |
| Photos/media | Supabase Storage within included allowances | Included | Included |
| Domain | One standard non-premium domain; $15 budget allowance | $1.25 | ~$15 |
| Landing pages | Cloudflare Pages Free, static pages | $0 | $0 |
| Privacy/terms/support/account-deletion pages | Same static hosting; authoring/legal review separate | $0 hosting | $0 hosting |
| Website analytics | Cloudflare Pages included web analytics | $0 | $0 |
| Login/reset email delivery | Resend Free within limits | $0 | $0 |
| Support email | Existing inbox; optional available domain forwarding | $0 extra | $0 extra |
| Facebook page | Organic page/posts, no paid ads | $0 platform | $0 platform |
| Instagram | Optional organic account | $0 platform | $0 platform |
| Source control/CI | GitHub Free within allowances | $0 | $0 |
| Agent inference | Preferred on-device runtime; no cloud model | $0 cloud fees | $0 cloud fees |
| **Estimated baseline** | | **$34.50** | **$414** |

Apple membership and domain: approximately **$114 upfront**. Backend: **$25 monthly**, including the first month. Approximate first-month cash requirement: **$139**. If Apple membership or a domain is already held, the incremental amount differs.

Recommend reserving **$600 total for year-one operations**, leaving $186 above the baseline. This is a planning allowance, not a guaranteed billing ceiling. Advertising has a separate budget.

## Optional additions

| Addition | Extra monthly | Extra first year | When needed |
| --- | ---: | ---: | --- |
| Separate paid Supabase Micro staging project | From $10 | From $120 | Persistent hosted staging; local development can precede it. |
| Facebook/Instagram ads | Example discretionary allowance: $50 | $600 if used all year | Only after measurable activation and retention. |
| Cloudflare Workers paid plan | From $5 plus usage | From $60 plus usage | Custom media authorization or background operations on Cloudflare. |
| Cloudflare R2 | Usage-dependent | Usage-dependent | Photo economics justify a separate storage service. |
| Paid email, monitoring, larger DB compute | Usage/plan-dependent | Usage/plan-dependent | Free/included allowances or performance become insufficient. |
| Professional support mailbox | Provider-dependent | Provider-dependent | Branded sending/receiving beyond existing inbox/forwarding. |

Free-tier email is not unlimited: Resend Free has a **100-email daily cap**. Configure production authentication email delivery and evaluate launch-day demand. Static hosting does not cover unlimited dynamic function work. Backend usage, database growth, realtime connections/messages, image transformations and optional recovery add-ons can increase the bill.

## Costs excluded from the baseline

Development time/compensation, hardware, purchased assets, outsourced content, legal review, business registration/accounting, paid acquisition, taxes, app-sale commissions/refunds, SMS, external weather and any future cloud AI. These need separate estimates rather than a fabricated zero cost. Supabase database backups should not be treated as proof of complete photo backup/recovery; design and verify the required media lifecycle separately.

## Sources

- [Apple Developer Program enrollment](https://developer.apple.com/programs/enroll/): $99 per membership year; local pricing/tax may differ.
- [Supabase pricing](https://supabase.com/pricing): Pro from $25/month; $10 compute credit covers one Micro instance; additional projects and usage cost extra.
- [Porkbun domain pricing](https://porkbun.com/products/domains): standard .com advertised from $11.08; $15 here is an allowance, not a quote for an available name. Premium names and other TLDs differ.
- [Cloudflare Pages](https://www.cloudflare.com/products/pages/): static hosting and web analytics; respect [platform limits](https://developers.cloudflare.com/pages/platform/limits/).
- [Resend pricing](https://resend.com/pricing): Free plan and daily sending limits.
- [GitHub pricing](https://github.com/pricing): Free plan; included CI quotas apply.
- [Cloudflare Workers pricing](https://developers.cloudflare.com/workers/platform/pricing/) and [R2 pricing](https://developers.cloudflare.com/r2/pricing/): optional usage-based components.

Meta page/account creation has no ordinary platform subscription requirement; advertising and content production are separate. The [Meta Pages information page](https://www.facebook.com/business/tools/facebook-pages) required login during research, so it did not supply a readable pricing quotation.

## October 2 scope adjustment: web admin and landing

A public landing site and separate restricted admin web app are now explicit architectural surfaces. Static hosting may fit existing allowances, but the prior $414/year baseline is not an updated all-in estimate: it excludes admin development, additional backend/event/job usage, staff MFA/email operations and any selected crash monitoring/uptime/alert plan. Monitoring provider, retention and staff count are unselected, so their incremental monthly/yearly cost is **TBD**, not zero. Reprice the complete operating budget after those choices; avoid adding a second database or always-on API merely for admin. See [ADMIN-WEB](admin-web.md).
