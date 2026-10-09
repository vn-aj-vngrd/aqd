# Implementation status

## Current boundary · October 9, 2026

PR #5 merged through protected latest-head review/CI and SHA-bound squash to `cccdc24`; merged-main CI and repository release passed, and non-draft `v1.0.1` points to that commit. This is a repository release, not native distribution. The separate owner-authorized full private V1 implementation is tracked in [#6](https://github.com/vn-aj-vngrd/aqd/issues/6), with baseline/capture [#7](https://github.com/vn-aj-vngrd/aqd/issues/7) on `van/issue-7/native-v1-baseline`.

Native app/project/shared scheme, Foundation core, persistence/media and public UI tests are prepared on the baseline branch from `cccdc24`, awaiting protected PR delivery. Independent full-diff standards/spec reviews and final correction reviews passed after recovery fixes. Latest corrected checks passed **20 Core tests, 64 native tests and 8 public UI tests** in full iOS18.1 and iOS26.5 runners, Xcode26.5/Swift6.3.2; the final unsigned Release simulator build passed. PR #9 is open; its first native CI run on hosted Xcode26.6 failed a screenshot metric despite passing Core/native tests. The metric and first two Codex findings passed remote native CI on `97dc74c`. Four subsequent Codex findings are corrected and independently reviewed locally: interrupted bootstrap, unused Fit files, visible draft-recovery refusal and receipt routing to Pieces. Two further recovery findings are corrected and independently reviewed: successful draft retry clears only its own failure message, and archived edits refresh details/Restore revisions independently of the active collection. Hosted preview verification now waits for enabled Use before capturing asynchronous output. Active draft-failure feedback now survives cancelled/empty imports, and denied camera access offers Settings while restrictions have separate recovery copy. Bootstrap validation uses a protected, bounded transient DB/WAL copy after hosted26.6 exposed source-byte changes during inspection. Save now atomically retains a temporary exact presentation link until explicit receipt Back/Open acknowledgment; interrupted creation/edit re-entry recovers the committed result read-only without duplicates or rewinding newer records. Acknowledgment failures remain visible and retain the link; completed proof never recreates acknowledged links or owns media. Public picker verification handles its observed remote-accessibility boundary with confirmed synthetic landmark coordinates. Incomplete photo cleanup now stays visible/retryable across all five held native destinations, including Agent, with live failure/clearance observation and preserved navigation. Hosted cold-build/serial-UI workload exceeded the former25-minute job limit; the45-minute budget retains every mandatory test. Hosted native CI37866557466 passed20 Core/62 native/8 UI on the preceding recovery head, but latest Codex found repeated historical receipt restaging. Exact ownership-aware artifact discovery now queues only still-present managed legacy bytes, preserving immutable proof and refusing unsafe paths; completed work leaves DB/WAL unchanged across repeated calls/reopen. Both final bounded reviews and current local20/64/8 checks pass. Fresh final-head remote gates remain pending; physical Camera/Settings transitions remain unverified. Real PhotosPicker capture, crop/rotate/reset/cancel, acknowledged save/receipt/Closet search/edit and process relaunch are exercised with explicitly synthetic pixels. Saved Today stock identities survive reopening. Queued photo cleanup reconciles after restart without depending on vanished UI operation state. Screenshot review found and repaired a double-offset crop preview; the subsequent genuine UI pixel-landmark RED→GREEN compares preview against the accepted rendition. No whole LOCAL/TODAY/PREF/J ID, complete V1, physical VoiceOver/device/media performance, SDK27, weather or Vision acceptance is claimed.

| Area | Current truth | Required next evidence |
| --- | --- | --- |
| V1 | Full private scope specified; scoped native baseline #7 is verified/reviewed, awaiting protected delivery. Pieces UI exists; other root capabilities and complete Today customization are unfinished, with explicit baseline placeholders. | [LOCAL acceptance](../product/v1-release.md#local-acceptance) on reproducible native source. |
| V2 | Full connected core and extension vision retained, additive to V1. | [Service decisions](../product/decisions.md), authorized slices and connected/native/browser acceptance. |
| Design | Prepared phase journeys, shared foundations and source-derived native references. | Rendered native navigation, keyboard, accessibility, permissions, materials and durability/recovery. |
| Repository tooling | Available; commands belong to `package.json`. | [Actual scoped results](verification.md); tooling is not app testing. |
| Distribution | Unverified for both phases. | Repository release, device/store/support and, for V2, service/operations gates separately. |

## Blockers and next authorized action

- Protected baseline delivery remains pending. Review findings were fixed and final standards/spec reviews passed; actual20 Core/64 native/8 UI checks include stale-draft recovery, availability/sort, dirty framing exits, outside-dismiss→archive/undo→fresh deletion and receipt return to the Closet root. Native remote CI/Codex and protected merge/release remain unverified. Complete outfits/themes, Planner/wear, Today, Agent, Profile/journal/preferences/Settings and all-domain recovery are not implemented.
- Numerical weather is release-blocked: the Paper attribution row is hidden and details-only legal placement is unverified. Withhold numbers until required Apple assets/placement are satisfied; [weather policy](../product/v1-release.md#optional-live-weather-contract) and [UI contract](../design/weather-context.md) retain the full gates.
- Icon-only native tabs remain a public-API/HIG feasibility gate. Current accessibility destination is **Today**, not the historical Home name; [native target](../design/native-ios.md) owns availability and acceptance.
- Static cleanup/removal fixtures use identical pixels, not validated Vision masks. Native/dialog kit inspection is source provenance, not AQD runtime certification.
- SDK27 and physical-device capability/quality evidence remain unavailable; current toolchain evidence is baseline-only. Numerical weather remains withheld, with its legal/entitlement gates intact.

The merge-first gate is complete. Continue #7 under the [implementation plan](implementation-plan.md) and [lifecycle](../agents/lifecycle.md); full #6 remains open. Scoped test/build results are not complete release acceptance, and no required item is silently waived.

## Current evidence and history

[Verification](verification.md) owns observed results and their limits. [Manifests](../design/paper-manifest.json) own recorded identity/locator inventory; no live Paper recheck is claimed here. [Vector repair](../design/evidence/native-dialog-vector-repair.json) is the latest recorded static confirmation checkpoint; [Today](../design/evidence/today-customization.json), [native source repair](../design/evidence/native-dialog-repair.json) and [action surfaces](../design/evidence/action-surfaces.json) retain scoped receipts and exclusions.

The complete pre-cleanup status is preserved in [October 7 archive](archive/implementation-status-2026-10-07.md). Its once-current counts, names and unresolved items are historical unless carried forward above. Prototype records remain accessible through [archive routing](archive/README.md).

## October7 editable confirmation repair — current Paper/docs checkpoint

Historical heading retained for incoming links: [original checkpoint](archive/implementation-status-2026-10-07.md#october7-editable-confirmation-repair--current-paperdocs-checkpoint). Current truth is above.

## October7 Today/native/action follow-up — historical pre-vector checkpoint

[Original dated record](archive/implementation-status-2026-10-07.md#october7-todaynativeaction-follow-up--historical-pre-vector-checkpoint).

## Handoff

[V1 release](../product/v1-release.md) owns launch scope; [V2 backlog](../product/v2-backlog.md) retains deferred work. Documentation completion establishes neither native acceptance nor permission to implement. [Original handoff and subsequent refinements](archive/implementation-status-2026-10-07.md#handoff) remain recoverable.
