# V2 Paper coverage

Coverage retained from October 1 and reclassified October 5, 2026 against [V2 release definition](../product/v2-release.md). [Open Paper page 02 · V2, section 08](https://app.paper.design/file/01M3SM2KBHBZG6MA0Q744Y9NW0/p-B-0). Board 00 is the overview; 01–16 are screen strips with conditional/independent branches; 17 is the coverage/launch gate map; 18 identifies V2; 19 consolidates the offline review examples and notes; 20 covers Agent input, voice and streaming. Every strip starts at step 00. Screen copies are static review references; V2 sections 01–07 own canonical screens.

All 15 V2 groups have a design route/state reference. This establishes specification coverage, not complete runtime behavior or approved service policies. Shared states/native controls handle variations without adding a separate artboard for every network response. Connected provider, sync/conflict/deletion and moderation policies remain launch gates. Basic native Apple WeatherKit is approved/shared with V1 under [weather context](weather-context.md); native validation and advanced-provider decisions remain separate gates.

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

U17 opens U24 for explicit competing fields; cancellation preserves both revisions. U18/U23 cover partial media restore. Loading/no-cache/error/revocation inherit X01–X08 and the shared media/search/feed contracts. Routine dirty dismissal, bounded theme/outfit/piece deletion, block and sign-out use contextual native action sheets; critical global erase/replacing restore/account deletion use final alerts after real impact/typed/auth review. Date/occasion selection, share/export and permission remain their native picker/system tasks. Exact authorized target/revision/impact stays visible; confirmation references are not pushed screens. See [risk policy](native-presentations.md#confirmation-states-not-pushed-screens).

A33 remains on its existing canonical page/node and is shared with V1 under [weather context](weather-context.md). Native selected-place/date controls carry source/timezone/freshness/attribution and off/Saved/loading/failure/actual ≤ten-day forecast bounds. Restore the actual caller/draft/focus; Apply context never saves wardrobe records. Missing context never becomes live weather. A31/A32 use the same draft/review/save/unknown/stale contract as outfit proposals. A10 remains human message review, with no default Inbox read access.

### Shared local background-removal coverage

| Source / native reference | Controls / default gate | Return / boundary |
| --- | --- | --- |
| W27 AMO-1 Change OKO-0 reuses L78 OIZ-0; actual-W27 open Menu reference1011-0, p-B-0 | Change1072-0 →107V-0; Choose107W-0 → PhotosPicker, Take107Y-0 → camera, Remove background1080-0 → shared1010-0 or unavailable105C-0; Remove photo1082-0 → W07. Accepted media, verified capability, no competing job; Original default, no automatic/no-photo action. | Dismiss Menu before operation. Picker/camera cancel/failure retains photo/fields; Remove photo retains fields and disables Save. No account/consent/sync/publication triggered by removal; no photo sent for removal, not an app-wide no-sync claim. |
| Shared p-2-0 processing1010-0; previews1025-0/103A-0; failure104E-0; unavailable105C-0 | Cancel101E-0 / disabled Use101W-0; Original1035-0/103I-0 and Removed1037-0/103G-0; preview Cancel102P-0/1040-0 and Use102B-0/103M-0; failure Try again106B-0/Crop106D-0/Cancel104Y-0; unavailable Crop105I-0/Cancel105W-0 | Cancel retains accepted draft/recipe/fields and restores focus; Use applies selected rendition to parent draft only. Retry one fresh identity-checked job; crop → W31 OKR-0. Ignore stale completion on cancellation/replacement/retry/dismiss/save. Multiple foreground labels preview union, not failure or garment taxonomy; user can reject person/hanger/clutter with Original/Cancel. Native behavior/masks unverified; same atlas pixels are illustrative only. |

All six roots are reference-only, not canonical routes. [Capture contract](capture-photo.md#background-removal-reference-states) and [portable evidence](evidence/background-removal.json) preserve IDs, parent overrides and current inventory.

## Remaining decisions and implementation evidence

- Final identity methods/callbacks and legacy password migration; Apple/email links remain a working default.
- Actual sync revision/conflict, retention, export/deletion and recovery policies; illustrative statuses are not confirmed service behavior.
- Shared native WeatherKit entitlement/attribution/permission/freshness/actual forecast coverage and physical-device on-device quality remain unverified; advanced weather providers stay V2. Long plans and every approved action require tests.
- Moderation: report → scoped operator queue → review → action → access revocation → user-visible result. Board 17 records this operating requirement; no operator app is designed here. Assign an operator and choose the protected workflow before launch.
- Landing/support/privacy/terms/Facebook presence and store readiness are operational launch surfaces, not new phone tabs. Board 17 maps the requirement; final branded web/Facebook layouts are outside this app-screen pass.
- Accessibility/keyboard/larger text, persistence/restart, real two-account journeys, server access, deployment/restore and workload checks remain unverified by static Paper. No native code was implemented.

## V2 extension boundary

The [V2 backlog](../product/v2-backlog.md) includes the connected core and all expansions. [V2 requirements](v2-requirements.md) prepares every extension. Existing future artboards remain in V2 feature sections with V2 layer names. Reference masters may show future feedback variants; implement only the V2 actions (copy/retry/details) at launch. The offline proposal board remains a proposal; actual account cache/sync behavior is governed by V2 data checks, not an unconditional offline-social promise.

For the Closet inspiration route and return behavior, see [V2 flow](v2-flow.md#exit-behavior).

## Contextual confirmation references

October 6 handoff retains 22 V2 illustrations: 21 native confirmation cases plus one direct draft-action/result reference (YW9-0), not 22 decisions or new feature routes. Across both phases the 39 illustrations comprise 17 V1 and 22 V2 examples, including U12's nested journey copy and the direct result. Ten existing canonical IDs remain converted STATE references; 29 new references (eight V1 / 21 V2) include direct YW9-0 and rich review ZMA-0, not new canonical routes. The 39 case entries plus ZMA-0 give 40 illustrated views and only 38 native cases (17 V1 / 21 V2 including nested U12). U12 / 5B1-0 retains its registered canonical ID; DAI-1 is the nested journey STATE reference, not another canonical screen. Both show an action sheet over actual U05/held origin: Cancel preserves session/local work; Sign out clears authorized tokens/session/caches after acknowledgement only, never erases local records. Failure preserves session; unknown reconciles before retry. The worker's 210 feature-root subtotal is not grounds to change the 211 registered V2 canonical IDs.

Additional IDs belong in this reference catalog, **not canonical route rows**. Caller fields/candidate visibility in the artifact are baseline inventory; final state contracts and current source revisions govern implementation.

| Reference root / native presentation | Actual caller | Deliberate command / exact scope and result |
| --- | --- | --- |
| XQI-0 · action sheet | W18 More / W19 Delete; W23 selected theme | Delete selected theme/memberships only → originating Themes; outfits/pieces/wear survive. Weekend's 8 outfits are a fixture, not runtime count. |
| ZMA-0 · rich impact-review task | W15 selected owned outfit with linked public posts | Hold explicit Keep published (ZNB-0) / Unpublish (ZNF-0) bound to actual post IDs/revisions; Continue (ZNK-0) opens XSH-0 over retained review clone ZNN-0. See [full review contract](#outfit-deletion-linked-publication-review); not a new canonical ID or dialog. |
| XSH-0 · action sheet | W15 → real ZMA-0 [linked-publication impact review](#outfit-deletion-linked-publication-review) → final sheet over retained review clone ZNN-0 | Delete selected outfit/memberships; unassign affected future plans while retaining their dates/occasions, preserve past plans/pieces/wear/private-memory snapshots → originating Outfits. Apply only the held Keep published / Unpublish choice bound to exact public-post IDs/revisions; no inferred public choice. Cancel keeps review/choice/source; stale impacts require refreshed review, failure retains recovery, unknown reconciles both scopes before retry. |
| XUH-0 · action sheet | W12 real impact review | Delete reviewed piece/references only → originating Closet; revalidate exact counts/revisions, preserve historical snapshots and separately authorized public lifecycle. |
| XWH-0 · action sheet | Dirty editor/known failed-save X06; W13 fixture | Discard only caller draft → pending exit, not saved records or unknown-completion writes. |
| XZQ-0 · critical alert | Qualifying plan draft: 12 new dated assignments / 12 edited notes, October 7–18, Asia/Manila | Predicate: substantial actual dirty diff AND draft retention unavailable AND no in-flight write AND no unknown write outcome. Cancel retains the full draft; Discard work drops only the qualifying unsaved assignments/notes → pending exit, preserving saved plans/outfits. Otherwise XWH-0 ordinary action sheet or direct clean exit. Fixture counts/date span are examples, not a numeric global threshold or runtime verification. |
| Y1U-0 · action sheet | S10/I06/public profile/post/comment exact person; S06 fixture | Block selected stable account ID → actual source with access enforced across feed/search/profile/Inbox, after acknowledgement. |
| Y45-0 · action sheet | U08 selected blocked record and its stable account association | If identity is unavailable, say so honestly while retaining the selected blocked-record association; never invent a name/avatar. Unblock only that associated account ID → refreshed list; missing/unresolved association cannot confirm and requires recovery. No automatic follow/message. |
| Y5M-0 · action sheet | I04 received request | Decline selected request → originating Requests; pending/failure retains request. |
| Y87-0 · action sheet | U04/owned public content commands | Unpublish selected snapshot → refreshed public collection; revoke future AQD retrieval/bookmark/chat access, not exported copies/private source. Never U01 private-journal host. |
| YAI-0 · action sheet | S22 own acknowledged comment | Delete exact comment → retained thread/scroll; unknown send reconciles first, no deleting another person's comment. |
| YCT-0 · action sheet | A05 owned Agent conversation | Delete selected Agent conversation → retained list; other drafts/wardrobe and human Inbox unaffected. |
| YEJ-0 · action sheet | P10 selected wear record | Undo selected wear once, restore linked plan state → originating date/history. |
| YI7-0 · action sheet | A42 recording | Stop capture/drop staged recording and transcript → retained typed composer; ignore late transcription, no automatic Send. |
| YKL-0 · critical alert | Shared L16 real localDevice impact/typed ERASE task, entered from V2 U09 | Only valid exact ERASE on retained L16 (Paper host clone ZKW-0, typed field ZL3-0) can present the final alert, never directly over U09. Cancel keeps L16 input/focus/store and held U09 origin. Erase local closet only → empty private state; includes local profile/preferences/Agent/journal/AQD media, excludes remote account/public snapshots/backups/original Photos/exported archives. |
| YMR-0 · critical alert | Shared L15 reviewed replacement with U09 return | Revalidate archive/revisions and replace current local store transactionally → shared restore progress/result with true U09 origin. Nonreplacing U18 account restore remains a task, not this alert by default. |
| YO2-0 · critical alert | U15 valid typed deletion and required reauthentication | Delete account submits one authorized request → U20 received/failed/unknown reconciliation; U21 only after confirmed access removal. |
| YSO-0 · action sheet | Shared private L163 detail, V2 actual source | Delete selected memory → private U01 journal/nearest surviving memory. Only after successful commit and reference checks remove unreferenced AQD-owned media; preserve media used by other memories and all public projections/outfits/wear/original Photos. Failure never triggers premature cleanup. |
| YUG-0 · action sheet | Shared L161/L162 private fit draft; L162 fixture | Remove draft photo only, retain fields; Save requires date plus photo/outfit; release unreferenced owned media only after valid Save. |
| YW9-0 · direct draft action/result reference | W07 selected piece photo draft | Remove directly clears the draft photo selection with no redundant confirmation; retain metadata and prior accepted media for draft recovery, disable Save until a valid photo is selected. No saved-record/media deletion. Dirty exit is a separate XWH-0 decision, not Remove confirmation. |
| ZGW-0 · action sheet | P02/P05 selected plan entry | Remove reviewed occurrence/future/whole scope → originating agenda/date; retain wear/completed past entries. Scope review remains a task. |

For the 21 native confirmation cases, Cancel retains the actual caller's record/draft/selection/scroll/focus, not a hard-coded root. YW9-0 is a direct draft action and has no confirmation Cancel group. OS-supported action-sheet dismissal equals Cancel; alerts require deliberate buttons. Dismiss menus first, revalidate ownership/access/revision/exact counts before one operation, and acknowledge results before receipts. Confirmed failure keeps prior records/drafts with owner-local recovery; unknown completion uses existing save/send/sync/deletion reconciliation and stable operation identity before any retry or destructive discard. Interrupted recording stops the microphone; Cancel retains safe staged work without automatically restarting capture.

Shared fit-draft discard Z1X-0 and changed-photo recipe discard Z3U-0 remain reusable V1 reference recipes with V2 actual-source return; photo editing never discards the whole parent through L106/XWH-0. Private editors remain account-independent. Public publication/identity/privacy/body-use consent stays explicit; opening or confirming a private task grants no public/cloud consent.

October 7 bounded follow-up historical checkpoint: parent-confirmed496 roots (18 Foundations/192 V1/286 V2),380 unchanged canonical identities,116 root references (18/23/75) plus four nested offline references. Latest background-removal inventory is parent-confirmed502 roots/34,712 nodes (18/197/287 roots),122 root references (18/28/76) plus the same four nested references; six new references, no canonical routes. Added V2 menu references are ZTD-0/A04 receipt, ZVD-0/W15 owned detail and ZXE-0/A20 feedback receipt; ZRD-0 is V1-owned. These are not canonical routes or added confirmations. Saved-record Edit uses W13 editExisting/Save changes; receipt conversation return requires acknowledged authorized retained context; feedback exposes only that return and retains extension-only scope. UP07 shares grouped full-row scrolling Review and separate safeAreaInset Save; UP05 shares the54-point Height row with unchanged64×44 unit control. See [native menu contract](native-presentations.md#outfit-and-receipt-trailing-more) and [scoped evidence](evidence/ui-refinements.json). Native behavior remains unverified.

Historical confirmation checkpoint — frozen inventory: 492 roots (18 Foundations / 191 V1 / 283 V2), 380 registered canonical IDs (169 / 211 including U12 STATE), 112 root references (18 / 22 / 72) plus four nested offline references. The 29 new references are eight V1 and 21 V2. Canonical registration does not mean mandatory push navigation. Foundations supplies generic grammar only, no feature UI.

### Outfit deletion linked-publication review

ZMA-0 is the real rich-review reference between W15 Delete and XSH-0 when the selected outfit has linked public posts, not a new canonical ID. XSH-0 uses retained review background clone ZNN-0. Keep published ZNB-0 / Unpublish ZNF-0 must be held before Continue ZNK-0. Fixture references 2AY-0 (outfit), 2Q3-0 (past plan) and 39L-0 (publication) illustrate association only; Paper node IDs are never production record keys. Show the exact outfit, affected future-plan/membership impact and authorized linked public-post IDs/counts from current revisions. Require an explicit **Keep published** or **Unpublish** choice, held with the outfit ID and exact post-ID/revision set; no default inferred from opening Delete. Keep published preserves the reviewed public snapshots; Unpublish revokes future AQD retrieval only for those reviewed posts, never others or exported copies. Only completed review opens XSH-0 over that retained task. Cancel on the sheet returns to the unchanged review with choice held; Back preserves the source until deliberate scoped discard. Revalidate all IDs/access/revisions before committing; stale impact returns to refreshed review and renewed approval. Failure preserves review/choice and actionable scoped recovery; unknown local/public outcomes reconcile the existing operation(s), never assume either scope completed or blindly retry.

EX01–EX07 future native gates are **requirements only**, not new enabled controls, payments or runtime features: exact input/data/removal scope, genuine charge/merge/account review where applicable, and unknown reconciliation remain prerequisite tasks. Do not invent marketplace payments or counts from those gates.

Frozen repair evidence records the six V2 findings resolved and seven affected base-size renders (YKL-0, XZQ-0, XSH-0, Y45-0, YW9-0, YSO-0, ZMA-0), plus the two V1 repair renders. This bounded static scope is not certification of all states or runtime. YKL-0's final centered alert YMF-0 is at top 287; validated input is above it through ZKY-0 with a 14-point gap. Those Paper measurements/IDs are reference layout only, not native geometry or production keys.

Native acceptance remains outstanding: adaptive sheet/popover anchoring and supported dismissal, safe Cancel and focus/background exclusion, largest text/long labels/RTL/dark/opaque material, interrupted/stale-target and duplicate-action tests, store rollback, sign-out/cache scope, two-account authorization/public revocation, recording shutdown, and service re-auth/retention/reconciliation. Static Paper/reference inspection is not device or service certification.
