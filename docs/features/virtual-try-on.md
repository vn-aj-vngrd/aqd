# Future — Personal virtual try-on

Status: future exploration, outside the initial product. Documenting this direction does not authorize implementation, a cloud-provider change, or service deployment. No provider or delivery date is selected.

## Purpose

Let a person preview how owned clothing might look on them using a private full-body photo. “Preview on me” is a proposed action for a piece or saved outfit. This personal try-on photo is separate from the public Profile avatar.

Alta is the experience reference, not a requirement for feature parity. Its official site advertises outfit previews on a personal virtual avatar; the underlying implementation and measurement accuracy have not been verified.

## Proposed first slice

- Optional setup when the person first requests a preview; never block onboarding or manual wardrobe use.
- Capture or select a clear, fully clothed full-body photo with guidance on lighting, pose, and unobstructed clothing.
- Start with one supported garment category, then validate simple outfits before expanding to layers, shoes, and accessories.
- Use an existing image-based virtual try-on API through a secure backend. Provider credentials never ship in the app.
- Show generation progress, actionable photo/unsupported-item errors, and retry behavior that avoids duplicate requests or unexpected charges.
- Keep generated previews private by default, label them as AI-generated appearance previews, and let the person explicitly save or discard them.
- Missing garment photos require adding a suitable photo; metadata-only pieces remain usable in normal outfits.

These are working recommendations, not settled acceptance criteria. Complete multi-piece outfit previews need separate validation; support for individual garments does not establish reliable composition of an entire outfit.

## Measurements and complexity

Body measurements are not required for the proposed photo-based preview. Do not collect them without a demonstrated purpose and selected provider support. A generated picture does not guarantee garment size, tightness, length, or fabric drape.

A measured, rotatable 3D avatar and physically accurate fitting are separate, substantially more complex capabilities. They would need additional body and garment data and their own specification. They are excluded from this proposed first slice, as are live AR/video try-on and training or hosting our own model.

## Privacy and product boundaries

Cloud try-on would send selected person and garment images outside the device. Explain the provider and processing purpose and obtain explicit consent before upload. Keep this optional service separate from the current on-device text Agent; do not extend the existing “no AI requests leave the device” claim to try-on.

Define private media access, provider/app retention, replacement and deletion, account deletion, and generated-image ownership before implementation. A try-on photo must not become the public Profile avatar or published wardrobe content automatically. Replacing or deleting the photo must have a clear effect on saved previews under the selected policy.

## Decisions and evidence required

| Gate | Required decision or evidence |
| --- | --- |
| Scope | Supported garment categories, single-item versus simple-outfit behavior, entry point, and preview saving. |
| Provider/backend | Commercial terms, service availability, secure request handling, and selected runtime. |
| Privacy | Explicit upload consent, provider training/retention terms, private storage, and deletion behavior. |
| Quality | Test with actual wardrobe photos, varied body shapes/skin tones/poses, garment details, and supported outfit combinations. Record identity/body distortion and garment mismatch failures. |
| Cost/reliability | Measure end-to-end latency, successful-preview cost including retries, quotas, billing behavior, timeouts, and duplicate-request handling. |
| Release | Checkable feature acceptance criteria and actual device/service evidence; API documentation alone is not product validation. |

## Feasibility research

Sources checked October 1, 2026; refresh capabilities, terms, and prices before selection.

- [Alta official website](https://www.altadaily.com/): advertises outfit previews on a virtual avatar of the user.
- [FASHN Try-On v1.6](https://docs.fashn.ai/api-reference/tryon-v1-6): person and garment image inputs without required measurements; documented processing about 5–17 seconds and one credit per output. An example candidate, not a selected provider.
- [FASHN Try-On Max](https://docs.fashn.ai/api-reference/tryon-max): broader wearable-item support, variable processing time and credit cost; listed as Preview when researched. This does not establish reliable multi-item AQD outfit previews.
- [FASHN API pricing](https://help.fashn.ai/plans-and-pricing/api-pricing): on-demand pricing of $0.075 per credit when researched. Storage, backend operation, additional generations, and retries add cost.
- [Google try-on guidance](https://support.google.com/googleshopping/answer/16253678?hl=en-GB): generated images illustrate appearance and do not determine or guarantee actual fit.
- [FASHN data retention and privacy](https://docs.fashn.ai/api-overview/data-retention-privacy): review current provider handling before agreeing to any privacy claim.

Assessment: a narrow API-based photo preview is feasible with moderate integration work. Reliable complete-outfit previews need quality evaluation; accurate measured 3D fitting is a separate major feature.
