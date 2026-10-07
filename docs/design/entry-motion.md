# Welcome wardrobe motion

Updated October 5, 2026. Shared V1/V2 visual design: Paper E02, V1 L60/L67, the connected review copy, and the phase-owned **Motion · Welcome and first piece** reference. This is a native motion handoff with static keyframes, not working animation or measured performance. UI remains in Paper; no local gallery or product code is added.

## Intent and imagery

Twelve original garment cutouts make the wardrobe feel full and useful. Pieces gather, briefly form looks, then settle into a calm composition around the message **More from what you already own.** The text, wordmark and actions remain stationary and usable throughout. The illustration shows possibilities; it does not promise those exact looks, actual user inventory or an automated purchase.

[Original imagery and provenance](assets/welcome/README.md) replace the earlier stock/lifestyle Welcome collage. The [atlas layout](assets/welcome/atlas-layout.json) records exact source crops and layer positions; the twelve garments are individually editable Paper layers. V1 light/dark, V2 Welcome and connected review share this asset/composition. Welcome uses the atlas alpha on a transparent hero ground in both appearances. Dark controls use night tokens; preserve garment separation and test dark garment visibility on real screens.

## Sequence

[Global motion](motion.md#global-values) owns timing. Use the dedicated Welcome sequence only for first arrival; routine navigation keeps its native timing.

| Frame | Target | Behavior |
| --- | --- | --- |
| Gathered · 0 ms | Twelve visible pieces, gently collected toward the hero center; 0.96 scale and small initial rotations | Copy and both actions already enabled. No blank loading reveal or splash delay. |
| Looks forming · 520 ms | Tops, bottoms and shoes align into small outfit groups; other pieces stay within the hero | Smooth ease-out movement and small rotations. Stagger groups by at most 80 ms within this phase, not twelve accumulating delays. |
| Settled · 1,200 ms | Full twelve-piece wardrobe composition used by E02/L60/L67 | Ease into final positions, scale 1 and authored rotations. Stop completely; no idle float, endless loop or replay on Back. |
| Reduce Motion | Settled frame immediately | Remove travel, scale, rotation and staggering. Native reduced navigation or up to 120 ms opacity-only transition where appropriate. |

The 350 × 324 reference hero bounds all travel; maximum planned movement is about 230 pt horizontally / 190 pt vertically between poses. These are static keyframe positions, not instructions to relayout each frame. Animate transforms on stable layers. Do not move clothing into the text/buttons or add elastic bounce, full-screen particles, blur animation or independent camera movement.

## Routing and interruption

Start my closet acts immediately during any pose, cancels the sequence, then uses native navigation: V1 L61 private onboarding; V2 E06 first-piece flow. V1 Take a quick tour opens L62; V2 returning-account action opens the identity flow. No illustrative garment is carried in as a selected photo or saved record. Keep native Back gestures and draft protection.

Returning to Welcome uses the settled pose. On backgrounding, disappearance, interrupted navigation or reduced-motion preference changes, cancel the sequence and restore settled; never replay or stack timers. Failed/missing image decoding preserves copy/actions with a quiet static fallback. No network fetch is required for packaged imagery.

## Accessibility and delivery checks

- Treat the entire hero as decorative, or one concise image description; never twelve focus stops or frame announcements. Reading order stays heading, supporting text, primary action and phase-specific secondary action.
- Larger text/localization/compact phones use a scrollable content layout and a smaller bounded hero before sacrificing readable text or 44 pt actions. Text/buttons do not use absolute motion positions.
- Use native SwiftUI/UIKit layer transforms and the shared policy; no animation framework, backend, shader or video dependency. Decode the atlas once and crop/cache appropriately; avoid twelve independent full-resolution decodes. Record actual peak memory and asset quality rather than claiming Retina/performance from a static screenshot.
- Verify minimum supported/current devices, first arrival, immediate/rapid taps, Back, background interruption, unavailable image, both appearances, Reduce Motion/Transparency, VoiceOver and larger text. Native motion, frame pacing and accessibility remain unverified until authorized implementation.
