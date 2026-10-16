# Wear insights refinement research

Owner-requested October17 UI research; references inform composition, not proof of AQD runtime behavior.

- [TikTok Studio official help](https://support.tiktok.com/en/using-tiktok/creating-videos/creator-tools-on-tiktok) organizes analytics around overview/key metrics and further detail. AQD uses a compact monthly overview followed by daily activity and item rankings; it does not copy social engagement metrics.
- [Apple Swift Charts](https://developer.apple.com/documentation/charts) provides native marks, axes and accessibility. AQD uses daily bar marks with date/count accessibility labels, integer axes and the existing local wear records.

AQD choices: real monthly wear records, distinct pieces, recorded days and active pieces; zero values and a zero baseline when no dated records exist; no fabricated seed wear, trends or percentages. Month title has no card surface, only the arrow controls use native glass; Wear history is a toolbar icon. All-time estimates stay separately qualified. Rendered/gesture/VoiceOver acceptance remains issue30.
