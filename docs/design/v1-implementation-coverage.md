# V1 Paper → native implementation coverage

## Completion requirement

Every screen/state on Paper’s **01 · V1** page and every associated control must be implemented and functional. A reachable placeholder, static design `complete` flag, enum/model declaration or baseline test count is not screen acceptance. Reference-only boards retain their owning behavior without inventing extra push routes. Canvas section headers are not app destinations.

## Live inventory · October9, 2026

Read-only Paper census: AQD iOS file `01M3SM2KBHBZG6MA0Q744Y9NW0`, page `p-2-0`, token hash `fdeb7346`.

- **227 roots / 13,055 nodes**:169 canonical screen/states,20 Today reference states,38 other reference roots.
- `get_basic_info` and `get_children` expose only the first100; the complete depth1 root tree supplied all227 IDs. Exact set comparison against the manifest found no missing, duplicate or unexpected root IDs.
- [Per-root ledger](evidence/v1-implementation-coverage.json) retains every root, registered identity/label, source-coverage classification and unverified runtime acceptance. Labels are manifest labels, not a fresh per-node copy export.
- **Zero complete screens certified by this audit.**39 roots have source-partial behavior,5 are explicit placeholder destinations,172 have no complete functional counterpart established,11 are structural references. These classifications are not a completion percentage.
- Live Closet JSX/screenshot confirms three segments, image-led collection, search/Add and five destinations. Live Customize Today tree confirms configure/More/Add/reorder/defaults/Done; Planner tree confirms Week/Month/date navigation and agenda. These bounded reads are not an inspection of every descendant/control or a Paper-to-native parity pass.

## Domain gaps

| Owning family | Current source | Required implementation |
| --- | --- | --- |
| Welcome, preferences and tour | App opens roots directly; no onboarding/preferences entities | Private entry, durable onboarding/resume, review/refusal/body consent, shared Style entry modes and replayable preview-only tour |
| Capture and Pieces | Real photo source/editor/drafts/save receipts/search/filter/archive/delete/recovery | Complete details and wear-aware sorts, first-outfit activation, cross-domain impacts/cascades, capability-gated background removal/tag proposals, final visual/accessibility parity |
| Outfits and themes | Segments explicitly say not implemented | Builder/chooser/pins/replacement/review, stable saved/edit/favorite/delete records, memberships and complete Plan/Wear routes |
| Planner, routines and trips | Placeholder root | Week/Month/shared date/agenda/timezones, plans/routine scopes/trips/packing/bulk review/conflicts |
| Wear, history and insights | Prior-wear estimate only | Dedup/backdate/correct/Undo, immutable historical snapshots, calendar/history and reproducible insights |
| Today and TW01–TW20 | Stable stock instance identities; explanatory cards | All12 working kinds, Customize/library/configuration/reorder/duplicate/remove/defaults/Undo, durable drafts, retained notes/photos/reference-safe deletion and independent source/recovery states |
| Agent and voice | Native full-screen launch/Back/Open Closet | Real capability states, conversations/composer/context/consent, streaming/stop/retry, voice/transcript, proposals/approvals/pending actions and domain receipts |
| Profile and journal | Placeholder root | More menu/local identity/avatar clearing, private fit memories/photos/notes/outfit snapshots, edit/delete/wear separation and source returns |
| Settings and local data | Semantic colors/protected persistence infrastructure | Appearance preference, Style/help/permissions/capability/tour replay, export, validated staged replacement restore, exact global erase and recovery |
| Weather/media/native references | Weather kind identifier/manual photo editing only | Owning off/unavailable/review/error/cancel behavior; gated real capabilities, consent and manual fallback. Numerical weather remains withheld until required legal/attribution/capability acceptance |

Source map: `apps/ios/AQD/AQDApp.swift`, `AppState.swift`, `UI/{RootViews,ClosetView,PieceCaptureView,PhotoEditorView,PieceDetailsView,NativeTabs}.swift`, `Persistence/PieceStore.swift`, `Core/Sources/AQDCore/TodayConfiguration.swift`. The durable schema currently contains pieces/photos/drafts/operation proofs/cleanup/Today identity configuration, not the other V1 domains. Future media owners must extend the reference graph before retaining shared bytes.

## Evidence and next gate

Current recovery/toolbar source passed **20 Core /71 native /9 UI**, zero skips, on both iOS18.1 and26.5: `/tmp/aqd-codex-round8-group-ios18.log`, `/tmp/aqd-codex-round8-group-ios26.log`. These prove scoped operations, not full Paper coverage. SDK27, physical Camera/Settings/VoiceOver, largest accessibility text, media quality/performance and integrated full-domain acceptance remain unverified. No Paper design was changed by this audit.

Full [#6](https://github.com/vn-aj-vngrd/aqd/issues/6) stays open. Baseline [#7](https://github.com/vn-aj-vngrd/aqd/issues/7)/PR #9 remains awaiting protected delivery; outfits/themes [#8](https://github.com/vn-aj-vngrd/aqd/issues/8) follows it. Actual linked follow-ups are now [Planner#10](https://github.com/vn-aj-vngrd/aqd/issues/10), [wear/history#11](https://github.com/vn-aj-vngrd/aqd/issues/11), [Today#12](https://github.com/vn-aj-vngrd/aqd/issues/12), [onboarding/preferences#13](https://github.com/vn-aj-vngrd/aqd/issues/13), [Agent#14](https://github.com/vn-aj-vngrd/aqd/issues/14), [Profile/journal#15](https://github.com/vn-aj-vngrd/aqd/issues/15), [Settings/recovery#16](https://github.com/vn-aj-vngrd/aqd/issues/16), [Pieces/capture completion#17](https://github.com/vn-aj-vngrd/aqd/issues/17), [gated weather#18](https://github.com/vn-aj-vngrd/aqd/issues/18) and [every-screen integrated acceptance#19](https://github.com/vn-aj-vngrd/aqd/issues/19). Dependencies are explicit; no out-of-order app implementation or waived capability gate is implied. For each affected screen inspect direct JSX/styles/assets, implement real actions and durable failure/return behavior, then record rendered/native evidence. Never mark the whole page complete from a subset.
