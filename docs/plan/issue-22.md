# Issue22: Today, capture and photo editing

- Issue: https://github.com/vn-aj-vngrd/aqd/issues/22
- Companion: [#28](issue-28.md), same PR after journal consumers exist.
- Branch: `van/issue-28/profile-and-today`; baseline `51c87f3ec2e84a58d6a7efbcb66383def82684eb` (merged PR35/v1.4.0).
- Endpoint: one PR for #28 + #22, current-head unit CI/Codex, resolved findings, protected squash and merged-SHA repository release verification.
- Physical iPhone17ProMax only. Owner confirmed connected/unlocked readiness October16; device discovered available. All simulators shut down. All E2E authoring/execution, rendered accessibility/media/model/device qualification stays #30.
- Methods: existing Core, actual temporary PieceStore and native AppState/editor seams, red/green behavior tests. No new interview for settled specs. Preserve existing tests/data, migrations, stable IDs, drafts, immutable operation receipts and reference-scoped media cleanup.

## Scope and slices

Read Today’s twelve-kind feature/configuration/media contract, TW01–TW20/catalog designs, capture/wardrobe acceptance and complete optional weather boundary. Preserve first-piece/pinned-outfit foundations; extend actual domains, never sample records. Numerical weather stays withheld until entitlement, supplied attribution/legal placement and complete LOCAL-16 pass. Weather Settings/Agent integration and full archive/erase close in #27/#29.

| Slice | Working outcome | Acceptance | State | Marker | SHA |
| --- | --- | --- | --- | --- | --- |
| S1 | Real Today cards and contextual destinations for plans/wear/insights/favorites/theme/journal/actions | TODAY-01/02/06 | Implemented, unit verified | `AQD-Slice: #22/S1` | Pending |
| S2 | Twelve kind-specific configurations, independent note/photo snapshots, atomic layout task/reorder/minimum-one/defaults/Undo/restart | TODAY-02–05 | Planned | `AQD-Slice: #22/S2` | Pending |
| S3 | Reachable retained-personal-content management, reviewed delete/reference refusals/Undo/media recovery | TODAY-03/04/07 | Planned | `AQD-Slice: #22/S3` | Pending |
| S4 | Capture/photo controls, cancellable local background-removal proposal/review/fallback and pinned first-outfit completion | Affected W, LOCAL-02/04 | Planned | `AQD-Slice: #22/S4` | Pending |
| S5 | Shared off/consent/place/date/loading/saved/unavailable/late-response weather and Today/Outfit/Planner callers | Scoped LOCAL-16/manual | Planned | `AQD-Slice: #22/S5` | Pending |

## Verification and resume

Reuse verified unchanged unit inputs only; source-bind final evidence. Independent source failures never become empty/zero. All E2E/rendered/media/model qualification remains #30; numerical weather’s qualification is not claimed by unit tests. Continue after companion #28, then current-head CI/Codex/protected delivery.

## S1 source cards

Today reads acknowledged plan occasions, actual dated wear, active-Closet utilization, deterministic eligible least-recent pieces, favorites and private journal records. Routes open the existing outfit/plan/history/insight/journal tasks without creating records. Empty history differs from a read failure and from an existing-history empty week. Utilization defaults to the latest completed month; its link opens that same month. Week summaries count distinct local dates and piece IDs through today. Upcoming windows compare each entry in its own recorded timezone and preserve multiple occasions. Configuration controls, personal cards and weather follow in the later slices.

Missing Today query APIs failed `/tmp/aqd-22-s1-red.log`. Core62 pass `/tmp/aqd-22-s1-core.log`, including completed-month rollover, locale-week boundaries, stable piece-ID ties, unavailable-piece exclusion and distinct upcoming entry identities. Core62 and physical native159 passed `/tmp/aqd-22-s1-unit.log`. Bounded increment review checked actual-record reads, distinct occasion identity, failure-versus-empty rendering, explicit wear actions and same-period destinations. All E2E remains #30.
