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
| S1 | Real Today cards and contextual destinations for plans/wear/insights/favorites/theme/journal/actions | TODAY-01/02/06 | Implemented, unit verified | `AQD-Slice: #22/S1` | `f964d3c` |
| S2 | Twelve kind-specific configurations, independent note/photo snapshots, atomic layout task/reorder/minimum-one/defaults/Undo/restart | TODAY-02–05 | Implemented, unit verified | `AQD-Slice: #22/S2` | `8ca33b1` |
| S3 | Reachable retained-personal-content management, reviewed delete/reference refusals/Undo/media recovery | TODAY-03/04/07 | Implemented, unit verified | `AQD-Slice: #22/S3` | `33896d8` |
| S4 | Capture/photo controls, cancellable local background-removal proposal/review/fallback and pinned first-outfit completion | Affected W, LOCAL-02/04 | Implemented, unit verified | `AQD-Slice: #22/S4` | Pending |
| S5 | Shared off/consent/place/date/loading/saved/unavailable/late-response weather and Today/Outfit/Planner callers | Scoped LOCAL-16/manual | Planned | `AQD-Slice: #22/S5` | Pending |

## Verification and resume

Reuse verified unchanged unit inputs only; source-bind final evidence. Independent source failures never become empty/zero. All E2E/rendered/media/model qualification remains #30; numerical weather’s qualification is not claimed by unit tests. Continue after companion #28, then current-head CI/Codex/protected delivery.

## S1 source cards

Today reads acknowledged plan occasions, actual dated wear, active-Closet utilization, deterministic eligible least-recent pieces, favorites and private journal records. Routes open the existing outfit/plan/history/insight/journal tasks without creating records. Empty history differs from a read failure and from an existing-history empty week. Utilization defaults to the latest completed month; its link opens that same month. Week summaries count distinct local dates and piece IDs through today. Upcoming windows compare each entry in its own recorded timezone and preserve multiple occasions. Configuration controls, personal cards and weather follow in the later slices.

Missing Today query APIs failed `/tmp/aqd-22-s1-red.log`. Core62 pass `/tmp/aqd-22-s1-core.log`, including completed-month rollover, locale-week boundaries, stable piece-ID ties, unavailable-piece exclusion and distinct upcoming entry identities. Core62 and physical native159 passed `/tmp/aqd-22-s1-unit.log`. Bounded increment review checked actual-record reads, distinct occasion identity, failure-versus-empty rendering, explicit wear actions and same-period destinations. All E2E remains #30.

## S2 customization receipt

Customize Today offers all twelve kinds, independent duplicate IDs, native drag and non-drag reorder, minimum-one refusal, period/source selection, ordered quick actions and independent private Note/Photo content. Nested Apply updates the durable parent draft; cancellation preserves the previous instance. Full note/caption text is retained without arbitrary limits. Photo selection and framing reuse the existing explicit source/preparer/editor path and check instance/source/token identity before applying asynchronous results. Theme creation retains the nested Today task. Lost pinned sources remain unavailable rather than substituting another source.

Done atomically saves the configuration, retained personal content and one-level layout Undo with an immutable operation receipt. Failed saves retain readable input and the prior configuration; retry reconciles the original operation. Restore defaults is provisional and reversible before Done; removing placements keeps saved content. Clean open/cancel writes no draft or layout. Acknowledged layout Undo reuses the same save boundary. Current/base/nested/default-Undo drafts, saved personal cards and acknowledged layout Undo protect their actual photo recipes. All other global tasks yield to an active Today task; restart recovers it after earlier retained tasks.

Schema V17 adds payload records while freezing V16. A populated V16 migration preserves owner, custom order/IDs and optional identity without reseeding. The missing-API tracer failed `/tmp/aqd-22-s2-red.log`. Core62 and physical native162, comprising149 Swift Testing and13 XCTest, pass `/tmp/aqd-22-s2-unit.log`. Final3 actual Today store/model cases pass `/tmp/aqd-22-s2-final.log`, adding clean-cancel and final mutation-lock recovery checks. Bounded increment review covered nested ownership, atomic failure/unknown reconciliation, revision guards, preserving migration, source disappearance and media retention. Retained-content management/deletion follows in S3. All E2E/rendered/device-quality acceptance remains #30.

## S3 retained personal content receipt

Note/Photo configuration exposes Saved notes and photos even after every personal placement is removed or defaults are restored. Selecting a retained card copies an independent content/instance snapshot. Each exact card has a native More → reviewed Delete with explicit Cancel. Live placements and recoverable current/base/nested/default-Undo drafts refuse deletion. A related acknowledged layout Undo is disclosed in the review and released atomically with the selected card; unrelated Undo and other records remain. UI observes Undo release even when the layout itself is unchanged.

Schema V18 adds durable deletion tasks/receipts. The same operation survives confirmed failure, unknown acknowledgment and restart; acknowledged/cancelled tasks cannot become a second deletion. Media cleanup runs only against released actual references. A source shared by independent photo cards remains until the final owner releases it. The V17 layout-required marker is preserved: an already-Today-capable schema missing its full layout is corruption, rather than permission to reseed.

The missing-API tracer failed `/tmp/aqd-22-s3-red.log`. Core62 and physical native164, comprising151 Swift Testing and13 XCTest, pass `/tmp/aqd-22-s3-unit.log`. Two actual-store regressions prove active/draft refusals, disclosed Undo release, unknown/reopen/exact-operation deletion and independent-photo last-owner cleanup without implicit wear. Bounded increment review covered deletion identity/revision/ownership, readable failed/unknown tasks, cancel/no-write review, observable Undo and reference-safe original ownership. All E2E/rendered/focus/media quality acceptance remains #30.

## S4 capture and optional background removal receipt

The accepted-photo Change menu opens the shared native processing/review/manual-crop task. The Vision implementation performs one local foreground-instance request at a time, unions all returned instances, preserves the full source extent on neutral ground and produces a proposed metadata-minimized photo. Request/draft/operation/source/recipe identity is checked before preview and again before applying; Cancel abandons the job without promising immediate compute termination. Original/Removed, enlarged inspection, retry and crop fallback never save a piece. Existing first-piece category-derived guidance and pinned outfit creation remain unchanged and covered by their existing tests.

Background removal is **not activated** until issue30 qualifies garment quality, latency and memory. Its current entry truthfully offers the unavailable/manual path. API availability and green unit tests are not that qualification; no Vision garment result or performance is claimed here.

Schema V19 records the derived-to-original media edge. Live piece/personal/draft/Undo references protect both sources. Reset in the shared framing editor can return a processed capture to its original, then apply new manual framing; it changes only the parent draft until Save. Superseded derived bytes release safely while shared originals remain. New media edges must be included in issue29 archive/restore/erase ownership.

The missing-API tracer failed `/tmp/aqd-22-s4-red.log`. Core62 and physical native165, comprising152 Swift Testing and13 XCTest, pass `/tmp/aqd-22-s4-unit.log`. Final2 focused cases pass `/tmp/aqd-22-s4-final.log`, adding stale-proposal refusal with no staged media and last-owner draft cleanup. The first stale fixture staged an unowned photo before AppState’s normal staging cleanup and was corrected to use the actual running-app import order. Bounded increment review traced original reachability, recipe Reset, source/operation checks, cancellation, full-extent preparation and gated activation. All E2E/rendered/garment/model/device performance remains #30.
