# Profile and Today unit evidence

[Source-bound receipt](unit-receipt.json) records actual Core/native unit results and hashes for the grouped issues28/22. [Profile plan](../../issue-28.md) and [Today plan](../../issue-22.md) retain the eight slice commits, red/green checks and independent review dispositions.

| Acceptance | Actual check | Observed result and boundary |
| --- | --- | --- |
| Identity, J1/J3/J5, scoped LOCAL13 | LocalIdentityPersistenceTests, PersonalEditorRecoveryTests | Optional clear/remove, retained task, failed/unknown/restart and actual shared photo ownership pass. Failed-retention Discard was reproduced and corrected. |
| J1–J5/P10, scoped LOCAL14 | FitJournalPersistenceTests | Required date and photo/outfit content, 500-grapheme note validation, immutable outfit snapshot, edit/delete/retry/reopen and explicit duplicate-safe wear pass. Journal changes never implicitly record wear. |
| Shared optional photos | FitJournalPersistenceTests, BackgroundPhotoTests, existing media suites | Prepared recipe validation, retained current/base drafts and original/derived last-owner cleanup pass. Actual garment/edge quality is unverified. |
| TODAY01/02/06 | TodaySourcesTests, PersonalEditorRecoveryTests | Actual local records, locale-week/completed-month/zone windows, stable least-recent ties, distinct occasions and persistent read failure versus empty state pass at unit/source level. |
| TODAY03–05 | TodayLayoutPersistenceTests | Atomic layout/content, nested Apply/cancel, full long notes, independent duplicate identities, failed/unknown/restart/defaults/Undo and populated migration pass. Old snapshots cannot reopen acknowledged older text. Native menus/reorder/focus are source reviewed, unrendered. |
| Scoped TODAY07 | TodayPersonalCardTests | Reachable retained-card selection, active/draft reference refusal, disclosed Undo release, acknowledged/unknown/restart deletion and shared-media last-owner cleanup pass. Full archive/restore/erase closes in issue29. |
| Capture, affected W/LOCAL02/04 | BackgroundPhotoTests and existing capture/readiness suites | Original retention/reset, stale proposal refusal, preserved category-derived pinned-outfit path and durable media ownership pass. Background-removal activation stays gated for issue30. |
| Scoped LOCAL16/manual | WeatherContextTests, WeatherContextPersistenceTests | Off/consent/qualification gates, freshness/expiry/absent precipitation, destination timezone, shared requests/budgets, late Off, atomic preference retry/cache purge and parent-draft-only context pass with synthetic fixtures. No real WeatherKit or permission/attribution qualification is claimed. |
| All UI/E2E/accessibility/performance and integrated acceptance | Not run | Deferred to issue30 by owner direction, including focused E2E authoring/execution. No simulator or native CI. |

Final source, test counts and build results are in the receipt. Raw `.xcresult`, device/signing logs and personal identifiers stay local. Synthetic mark/provider/media fixtures prove mechanisms, not Apple provenance, garment quality or rendered acceptance. Repository CI runs fast tooling unit checks only. Numerical weather and background-removal activation remain gated until their complete physical qualification.
