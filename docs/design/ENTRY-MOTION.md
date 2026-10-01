# Welcome and first-piece motion

Visual source: Paper E02, E06 and page 00 **Motion · Welcome and first piece**. This is a native motion specification with static keyframes, not a working animation or performance result. Do not recreate a local gallery.

## Reference and intent

Reviewed the signed-in [Mobbin welcome collection](https://mobbin.com/search/apps/ios?content_type=screens&sort=trending&filter=screenPatterns.Welcome+%26+Get+Started), including [Luma](https://mobbin.com/screens/501e618c-bd44-44cf-8ef6-57bbb2d03cb0) and [Shop](https://mobbin.com/screens/cfb5f163-40cf-438f-a57a-99624e6120a9), on October 1, 2026. Luma establishes depth through overlapping imagery; Shop puts product imagery around a clear message and action. These observations inform composition, not copied artwork or measured animation timings.

AQD uses one clothing-led entrance: the look stays anchored while two piece photographs unfold outward into a balanced composition. On Start my closet, the shirt photograph carries into the first-piece frame. This continuity connects browsing possibilities with adding one real piece. Reference photographs are illustrative; they are not a literal outfit assembled from those exact pieces and are never added to the user's inventory.

## Shared motion values

[Global motion](MOTION.md#global-values) is the single timing/policy definition. Use motion.arrival (320 ms), motion.arrivalStagger (40 ms), motion.arrivalOffset (12 pt horizontal / up to 6 pt vertical), and motion.reduced (0–120 ms). Native navigation owns entry continuity timing. This supersedes the earlier 600/680 ms welcome and fixed 360 ms navigation timings.

## Sequence and behavior

1. Launch uses the normal system launch screen; no artificial splash delay. When ready, E02 shows its wordmark, message and both actions immediately. All hero images are visible from the first frame.
2. The shirt starts 12 pt left and 6 pt down from its final location; the shoe starts 12 pt left and 6 pt up. Animate translation to zero. Keep photographic corners and image crops stable. No rotation, zoom, blur animation, floating loop or text stagger.
3. The shirt begins at 0 ms and the shoe at 40 ms. Both settle by 360 ms. The look anchor, text, controls and screen layout do not move.
4. Start my closet acts immediately even during entrance. Cancel the entrance and navigate to E06. Use one shared image identity for the illustrative shirt where native navigation supports it; native source-matched navigation carries it to the receiving frame with system-owned timing. Preserve system Back gestures. If shared-element navigation conflicts with the system transition, use the standard navigation transition instead of two simultaneous animations.
5. E06 keeps Choose a photo and Add without a photo immediately enabled. Opening Photos or manual entry remains a system transition. The illustration is never treated as a chosen photo, uploaded item or saved record.
6. Returning to Welcome shows its settled state without replaying the entrance. Pause/cancel on backgrounding or interruption; restore the final state. There is no replay loop or required swipe carousel.

## Accessibility and performance

- Reduce Motion: show final hero positions immediately; use standard reduced-motion navigation or a short crossfade. No spatial card travel.
- VoiceOver: treat the hero as one decorative illustration or one concise image description, not three focus stops. No announcements of animation frames. Keep reading order title, supporting text, primary action, account action.
- Large text/compact phones: preserve readable text and 44 pt targets; allow vertical scrolling. Scale or shorten the bounded hero before sacrificing the actions. Avoid absolute positioning for text or buttons.
- Use packaged, licensed, predecoded image assets in production. If images fail, keep the copy and actions usable; do not show an indefinite loading animation.
- Animate only the two bounded image layers, using transforms rather than relayout per frame. No new animation library, live shaders, particle systems or continuous blur. Measure frame pacing, memory and tap responsiveness on the minimum supported device and a current device.
- Verify first launch, immediate tap, rapid Back, interrupted launch, image failure, Reduce Motion, VoiceOver and accessibility text. Static Paper frames do not prove these runtime behaviors.
