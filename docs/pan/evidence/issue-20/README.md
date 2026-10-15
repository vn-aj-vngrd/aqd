# Foundation #20 acceptance evidence

[Issue plan](../../issue-20.md) maps the actual Foundation clauses to F1–F6. These are synthetic simulator fixtures, not personal garment photos or physical-device qualification. Code slice: `ca761fd3202dcf5704b6ae6e3eec5ecf85e19a46`. Environment: iPhone 17 Pro Max E3686DA1-1D81-4CD9-A876-9797D94C63DF, iOS27.0/24A434, Xcode27.0/27A266a.

| Run | Actual outcome | Published receipt |
| --- | --- | --- |
| Original top anchor with the strengthened OCR expectation | Failed as intended. Only line 1 is rendered where active line 7 must be visible. | [RED summary](notes-red-summary.json), [before](notes-before.png) |
| Final production source, native units plus eight selected UI cases | 84 native unit passes, 7 UI passes and one UI failure, zero skips. The failure was a driver alternating full-body swipes past Availability before Notes focus. This run remains Failed. | [Combined summary](combined-summary.json), [inputs](combined-inputs.json) |
| Actual proof runner, declared dark-mode source-close subcase | One selected case passed, zero failures/skips; dark screenshot inspected and original light preference restored. This subset does not pass all eight cases. | [Dark summary](dark-summary.json), [inputs](dark-inputs.json), [dark form](capture-dark.png) |
| Measured scroll driver and short/multiline OCR | Three affected cases passed, zero failures/skips. Short text and active line 7/caret were inspected above Apply and keyboard. | [Correction summary](notes-correction-summary.json), [inputs](notes-correction-inputs.json), [short OCR](notes-short-ocr.txt), [multiline OCR](notes-multiline-ocr.txt) |

[Build receipt](build-receipt.json) binds Core20 and generic unsigned Release passes to the same production inputs. The summary's device-level parameter-expanded counts do not represent additional logical tests. Only UI test source changed between combined and correction inputs. Unchanged interaction/expectation cases retain their earlier results; current-head hosted CI independently runs the complete eight-case issue manifest and publishes its actual result bundle.

## Inspected key states

| AC | Screenshot | What the actual test also asserts |
| --- | --- | --- |
| F1 shared controls/largest text | [Largest text](largest-text.png), [dark form](capture-dark.png) | Validation changes disabled Save to enabled; native keyboard and footer remain usable. |
| F2 destination identities | [Tabs](tabs.png) | Five named native destinations, selected traits and Agent source return. Later product roots remain incomplete. |
| F3 real photo/save/reopen | [Save receipt](save-receipt.png), [edited piece after process relaunch](saved-after-relaunch.png) | Real Photos selection, explicit crop, acknowledged save, exact edited record and durable relaunch. |
| F4 safe editing/recovery | [Short note](notes-short.png), [multiline after rotation](notes-after.png), [unreadable retained draft](draft-recovery.png) | Apply/cancel/discard and exact values survive relaunch; unreadable draft refuses replacement. |

[Artifact index](artifact-index.json) maps each unmodified image to its actual local result bundle and exported attachment filename. Those local source paths identify provenance; publish the tracked images/reports at their evidence commit. During PR delivery, link and read back the real `native-ios-acceptance` Actions artifact for the large current-head `.xcresult`, logs, source identity and all exported attachments. Artifact retention is 30 days. Publication remains a gate until that actual run/artifact is accessible. Screenshot inspection is distinct from test passes. Older failures remain in [verification history](../../../delivery/verification.md); full OS/device/accessibility/performance and integrated E2E remain #30.

## Reproduce

1. Read the plan, select the installed target through `node scripts/ios-destination.mjs --json`, and use non-sensitive fixtures.
2. Run `./scripts/prove-ios.sh 20` from the repo root. The persisted manifest contains the eight selected identifiers, not the full regression suite.
3. Inspect the reported output's summary, `inputs.json`, attachment manifest, rendered screenshots and Notes OCR receipts. A failed/skipped/missing case blocks acceptance.
4. Run feature unit/Debug and generic unsigned Release checks through `aqd-verify`; inspect the actual current-head PR checks and Codex review separately.
