# Issue 21: Welcome, onboarding and tour

## Scope

- Issue: https://github.com/vn-aj-vngrd/aqd/issues/21
- Branch: `van/issue-21/welcome-onboarding-tour`
- Authorized endpoint: continue the established full `aqd-ship` lifecycle for this issue, including protected PR/CI/Codex, squash merge and repository release verification.
- Predecessor: #20 delivered by PR #31, squash `8b0688022f1876c85d000e4cc316c493fd35ac57`, repository release v1.1.1. Its PR/main CI and Codex passed.
- Baseline: clean `8b06880`; no inherited issue-21 application changes.
- Contracts: [section 01](../delivery/implementation-plan.md#01--welcome-onboarding-and-tour), [entry](../design/entry-identity.md), [personalization/PREF](../design/onboarding-personalization.md), [entry motion](../design/entry-motion.md), [source returns](../design/v1-flow.md#welcome-onboarding-and-tour-contract), scoped LOCAL-04/13/15.
- Local verification: physical iPhone 17 Pro Max only. Current discovery reports connected/paired, Developer Mode enabled, iOS27.0.1/24A446. The owner confirmed connected/unlocked readiness before the first run. All local simulators were shut down and verified to have zero booted devices. Repeat the readiness prompt if a lock/disconnection interrupts testing.

## Slices

| Slice | Working outcome and boundaries | Acceptance | Focused proof | State | Marker | SHA |
| --- | --- | --- | --- | --- | --- | --- |
| S0 | Local test entry points require the physical phone and preserve the device-ready prompt; hosted CI remains separate | Owner device instruction | Runner RED/GREEN, 57 tooling tests, docs checks; actual physical Core20/native84 passed | Local gate passed | `AQD-Slice: #21/S0` | Pending |
| S1 | Fresh private entry, bypass and preview-only tour persist the actual route/completion and resume after interruption | E1/E2/E5 | Core/native restart tests and focused physical entry/tour journeys | Planned | `AQD-Slice: #21/S1` | Pending |
| S2 | Shared seven-step answers/refusals, review and atomic save work from onboarding/Profile/Settings with true source returns and retained drafts | E3/E4, PREF-01/02/03/07 | Validation/persistence/failure tests and physical save/cancel/relaunch journeys | Planned | `AQD-Slice: #21/S2` | Pending |
| S3 | Optional height/units and transactional self-description picker preserve edits, explicit refusal and body-use consent | E3/E4, scoped PREF-04/05/07 | Unit round trips/graphemes, native failure recovery and physical keyboard/custom-description proof | Planned | `AQD-Slice: #21/S3` | Pending |
| S4 | Final feature proof covers all owned states/controls, publishes real device evidence and qualifies the complete diff | E1–E6 | Selected physical E2E, inspected images, source-bound reports, Standards/Spec and remote gates | Planned | `AQD-Slice: #21/S4` | Pending |

## Acceptance and evidence

The issue uses prose Build/Prove clauses. E1–E6 below preserve those clauses as traceable groups; PREF/LOCAL scopes retain their original owners.

| AC / expected outcome | Slice | Required scenario/check | Observed result and artifacts | Status |
| --- | --- | --- | --- | --- |
| E1: splash has no imposed delay; fresh/returning/interrupted sessions resume actual local state without repeated onboarding/demo records | S1 | Fresh launch, private-start/explore, persisted relaunch and existing populated store | Not run | Not run |
| E2: pre-entry bypass stays outside the questionnaire and does not mark preferences complete | S1/S2 | Welcome/private introduction, Explore first, returning launch | Not run | Not run |
| E3: seven numbered steps require explicit answers/refusals, keep body details optional/use off, validate review and support editing | S2/S3 | Substantive/mixed/all-declined/incomplete, goals limit, custom shape/over-limit, height units, accessible progress | Not run | Not run |
| E4: one preference editor serves actual onboarding/Profile/Settings callers; save/cancel/failure/unknown/restart preserve source, draft and prior saved values | S2/S3 | Real callers, retained draft, dirty exit, same-operation retry/reconciliation and confirmed receipt | Not run | Not run |
| E5: Today/Closet/Agent/Profile tour supports Back/Next/Finish/Skip/replay, restores caller and inserts no records | S1 | Preview-only journey from Welcome/introduction and Settings, interruption/relaunch, actual record counts | Not run | Not run |
| E6: owned Paper inventory/control returns, light/dark, native interaction and scoped privacy/capability limits are accounted for | S4 | Live Paper inspection; rendered physical evidence; unit/build/repository checks and independent review | In progress; Paper is now available | Not run |

Owned canonical references: L172, L60, L61, L01, L152–154, L166–171, L173–177, L62–66. All 23 live Paper subtrees were fetched from the AQD iOS file on V1, token hash `fdeb7346`; exact JSX for Welcome, private introduction, tour Today and ready-to-begin was inspected for S1. Read remaining full question/picker content when implementing S2/S3. These references are states, not 23 independent destinations. Pending/unknown persistence references L149/L150 are shared recovery behavior.

### S0 evidence

The old actual runner first failed the new expectations because it accepted a local simulator and forced physical signing off. The corrected runner refuses absent/local simulator destinations before tool discovery, requires the owner's readiness response and local signing, and requires explicit physical UI selections. Local proof and photo-seeding entry points also refuse simulator fallback. Hosting is explicit through `GITHUB_ACTIONS`; existing required CI remains on GitHub's machines.

`/tmp/aqd-issue21-device-runner-red.log` retains the two genuine failures. `/tmp/aqd-issue21-device-guards-final.log` passes all nine runner scenarios. `/tmp/aqd-issue21-device-tooling-final.log` passes all 57 repository tests, zero failures/skips. `pnpm check:agents` and whitespace checks pass. Standards/Spec inspection of this bounded tooling/docs increment found no actionable defect; it changes no app behavior.

After the owner answered Ready now, the real runner used the discovered physical iOS destination and existing ignored local development signing. `/tmp/aqd-issue21-s0-native.log` records Core20 and native84 passed. `/tmp/aqd-issue21-s0-native.xcresult` and `-summary.json` confirm Passed84/failed0/skipped0 on physical iPhone17ProMax, iOS27.0.1/24A446. The summary tool initially could not write Xcode's report cache inside the sandbox; the same extraction succeeded with the required sandbox access. The native run itself exited0. These are baseline/unit checks, not issue21 UI acceptance. No simulator was started.

Preference export/restore/erase closure belongs to section09. Outfit ranking/model evaluation portions of PREF-05/06 require their real consuming sections and capability evidence before assistance is enabled; this issue creates no model feature or fabricated evaluation pass. Keep stored preference/context permission semantics explicit and verify the currently implemented seams.

## Deferred final verification

#30 retains broad integrated E2E, minimum/other-device OS coverage, complete VoiceOver/RTL/accessibility, physical media/protection/backup and performance qualification. Current feature UI proof must run on the owner's physical phone and cannot be waived into #30. No simulator may be launched locally to replace unavailable physical proof.

## Review and delivery

- Standards/Spec: S0 bounded tooling/docs inspection passed; feature review remains pending.
- Current check baseline: predecessor results belong to PR #31, not this feature.
- Current source changes: device policy/plan only; application implementation has not started.
- Final receipt: persist actual slice SHAs and qualified evidence before the final gate head.

## Shipping

- PR locator: `vn-aj-vngrd/aqd`, head `van/issue-21/welcome-onboarding-tour`; resolve/reuse its single PR.
- Local gate and published proof: Pending.
- GitHub owns actual current-head CI/Codex/thread/merge/release state.

## Resume

- Current phase: S0 local gate passed; live design/code inspection for S1.
- Next action: commit S0 and record its SHA, then implement S1 in a tested/committed vertical slice. Device readiness is confirmed; prompt again after any lock/disconnection.
- Dirty ownership: issue21 device guidance/plan and its subsequent explicitly staged changes only.
- External blocker: none confirmed. Paper is available and the first physical native check passed after confirmed readiness.
