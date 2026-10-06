# V2 Paper coverage

Coverage retained from October 1 and reclassified October 5, 2026 against [V2 release definition](../product/v2-release.md). [Open Paper page 02 · V2, section 08](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0). Board 00 is the overview; 01–16 are screen strips with conditional/independent branches; 17 is the coverage/launch gate map; 18 identifies V2; 19 consolidates the offline review examples and notes; 20 covers Agent input, voice and streaming. Every strip starts at step 00. Screen copies are static review references; V2 sections 01–07 own canonical screens.

All 15 V2 groups have a design route/state reference. This establishes specification coverage, not complete runtime behavior or approved service policies. Shared states/native controls handle variations without adding a separate artboard for every network response. Provider, sync/conflict/deletion, moderation and weather decisions remain launch gates.

| V2 group | Workflow | Review boards | Canonical references | Coverage / boundary |
| --- | --- | --- | --- | --- |
| V2-01 | Entry and Home | 01–02 | E01–E13, S15–S18, S48 | Return intent and record-derived states |
| V2-02 | Wardrobe | 01, 12 | W01, W06–W12, W21, W27–W29 | Photo/manual, lifecycle and preserved drafts |
| V2-03 | Outfits and themes | 03–04, 12, 15 | W13–W19, A03, A31 | Pin, replace, private save and membership |
| V2-04 | Planner and packing | 05–06, 13 | P01–P08, P12 | Manual/assisted range, conflict and packing |
| V2-05 | Wear and insights | 05, 12 | P09–P11 | Actual wear, correction/undo and snapshots |
| V2-06 | Agent and focused actions | 03, 08, 15, 20 | A01–A18, A22–A26, A29–A32, A34–A55 | Rich input/context/voice, streaming, history, recovery, approval and receipts; native/media/speech capability gates remain |
| V2-07 | Contextual styling | 03, 06, 15 | W17, W20, A33 | Place/date, missing source and coverage limits |
| V2-08 | Authentication | 02, 09 | E03–E04, E10–E11, E15–E17, U12 | Apple/email defaults; callback/session gates |
| V2-09 | Durability and lifecycle | 09–11 | E08, E13, E17, U09–U24 | Sync, conflict, restore, export and deletion |
| V2-10 | Profile | 02, 07, 14 | E07, U01–U06, U25–U26, UP01–UP07, S06–S07, S13–S14 | Shared private journal/preferences base plus explicit public identity/collections and privacy |
| V2-11 | Publishing and discovery | 07, 14 | S01–S09, S19–S21, S25–S47, U04 | Types, search, reaction and revocation |
| V2-12 | Comments | 14 | S22–S24, S10–S11 | Plain-text discussion, retry/delete/report |
| V2-13 | Human Inbox | 07–08, 16 | I01–I07, X08, U08 | Persistent V2 root-toolbar entry → I01 → conversations (not a tab); Back/startup/incoming intents preserve origin root/scroll/selected tab; requests, real acknowledged unread and delivery |
| V2-14 | Safety and support | 14, 16–17 | S10–S11, U06, U08, U13 | Report → operator review → revoke/remove; operator/service policy still gated |
| V2-15 | Native and launch quality | 08, 17 | X01–X08 + page 00 masters | Device/accessibility, restore/load/deployment tests required; not proven by Paper |

## Gaps closed in this pass

- Added E15–E17: expired session, sign-in failure and account association progress.
- Added U16–U24: confirmed backup, upload failure, conflict summary/field choice, clean-install restore/partial failure, export and deletion outcomes.
- Added A31–A33: theme-only review, exact-field edit proposal and selected weather context.
- Added 09–16 review strips for account/data, wardrobe lifecycle, office routines, discovery/comments/safety, Agent and Inbox branches.
- Your data now links to Backup and sync and Restore account closet. V2 settings/response/first-save screens hide deferred notification/survey/server-feedback entry points.
- Labelled E14/U07/A19–A21/A27–A28 V2, preserving their designs for later review.

## Shared state and native presentation coverage

Use [SCREENS](screens.md) for route/state ownership. Email progress/invalid/resend/consumed link/cancelled provider reuse E03/E04/E10/E11/E16; session expiry uses E15. Association reconciliation uses E17/U22 and collisions use E13. Pending/failed export uses U19 with U10 selection retained. Deletion reauthentication uses the auth flow and returns to U15; received/failed/unknown states use U20 with one request ID. Confirmed deletion uses U21.

U17 opens U24 for explicit competing fields; cancellation preserves both revisions. U18/U23 cover partial media restore. Loading/no-cache/error/revocation inherit X01–X08 and the shared media/search/feed contracts. Dirty dismissal, theme/outfit deletion, block, date/occasion selection, native share/export, permission and account-switch confirmation use native sheet/alert/picker presentations defined by the screen map and page 00 masters. Exact destructive target/impact stays visible.

A33 uses native selected-place/date controls and states for source/time, retrieval failure and unsupported coverage. Missing context never becomes live weather. A31/A32 use the same draft/review/save/unknown/stale contract as outfit proposals. A10 remains human message review, with no default Inbox read access.

## Remaining decisions and implementation evidence

- Final identity methods/callbacks and legacy password migration; Apple/email links remain a working default.
- Actual sync revision/conflict, retention, export/deletion and recovery policies; illustrative statuses are not confirmed service behavior.
- Weather provider/coverage and physical-device on-device quality; long plans and every approved action require tests.
- Moderation: report → scoped operator queue → review → action → access revocation → user-visible result. Board 17 records this operating requirement; no operator app is designed here. Assign an operator and choose the protected workflow before launch.
- Landing/support/privacy/terms/Facebook presence and store readiness are operational launch surfaces, not new phone tabs. Board 17 maps the requirement; final branded web/Facebook layouts are outside this app-screen pass.
- Accessibility/keyboard/larger text, persistence/restart, real two-account journeys, server access, deployment/restore and workload checks remain unverified by static Paper. No native code was implemented.

## V2 extension boundary

The [V2 backlog](../product/v2-backlog.md) includes the connected core and all expansions. [V2 requirements](v2-requirements.md) prepares every extension. Existing future artboards remain in V2 feature sections with V2 layer names. Reference masters may show future feedback variants; implement only the V2 actions (copy/retry/details) at launch. The offline proposal board remains a proposal; actual account cache/sync behavior is governed by V2 data checks, not an unconditional offline-social promise.

For the Closet inspiration route and return behavior, see [V2 flow](v2-flow.md#exit-behavior).
