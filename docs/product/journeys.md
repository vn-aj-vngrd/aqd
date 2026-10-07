# Product journeys by phase
October 5, 2026. Requirements and Paper references, not implemented behavior. [V1 flow](../design/v1-flow.md) and [V2 flow](../design/v2-flow.md) own the walkthroughs.

## V1 — Complete personal app on one device
1. V2-style Welcome → private onboarding → optional Today/Closet/Agent/Profile tour → first piece or empty Today. Skip and Settings replay never add sample data or discard drafts.
2. Photo/camera/manual capture → editable name/category → private save → actual missing-category guidance/readiness. Denial/cancel/failure keeps manual entry and the draft.
3. Manual or supported on-device outfit drafting → pin/replace → optional independent themes/favorites → explicit save → reopen after restart.
4. Dedicated Planner root → dated look, event, two-week schedule, three-calendar-month routine or trip → review exact conflicts → atomic save → deduplicated packing. Optional selected-place/date native WeatherKit context → disclosed city/request actions → review → Apply to parent draft only; cancel changes nothing. No external calendar or live-weather dependency; manual planning stays complete offline.
5. Today → record actual wear → history/insights → backdate/correct/undo. Calendar intention never increments wear.
6. Local Agent → bounded selected wardrobe metadata → truthful preparing/stream/cancel/retry/history → exact reviewed outfit/theme/plan/edit/wear proposal → trusted save receipt. Rules and manual routes work when generative assistance is unavailable.
7. Local Profile → dated private fit journal → Add fit with date plus photo or existing outfit, optional private note → explicit local save/detail/edit/scoped deletion. This never records wear or publishes. Optional identity remains; the single More icon opens Add fit/Edit profile/Style/Wear insights/Settings; Settings includes System/Light/Dark, assistance/privacy/help and replayable tour.
8. Export all described local records/media/Profile/Agent to a reviewed chosen archive destination → staged validated restore/full replacement. Local erase shows exact effects; exported files/original Photos remain outside AQD control.

Today / Closet / Planner / Agent / Profile stay aligned with V2; Today is the first destination's visible and accessibility name. Closet includes only Pieces/Outfits/Themes; Planner defaults to Week, with Month alternate. Fourth-slot Agent uses the shared native full-screen task pattern, dismissing to origin. Contextual plan links retain date and return state. Core private work needs no account, app backend or network. All flows include honest loading/empty/error/cancel/success states and local restart recovery.

## V2 — Extend the same app
Retain every V1 journey, identifier and private default. Online identity is optional until a connected action is requested. Sign-in → exact reviewed local-account association → account-scoped sync/backup/recovery; collisions retain separate datasets. Account switching isolates caches and queues. Do not reset V1 records or re-onboard existing users.

Add All/Following/discovery/public search to the retained Today route, public/curated controls to Profile, and persistent human Inbox access in root toolbars, not an additional tab. Inbox opens I01 before conversations and restores origin root/scroll/selected tab on Back, including incoming intents. Piece/Outfit/Theme → exact public preview → publish → accessible public Profile. Follows/reactions/bookmarks/comments require acknowledgment; Make my version drafts from the viewer's owned wardrobe. Unpublish/block/removal revoke access across entry points.

Creator → first-contact message request → accept/decline → participant-scoped human chat/public references → reliable retry/read/unread. Agent-prepared send requires exact recipient/content approval; human chat never becomes default model context.

Extend verified V1 local photo/voice assistance with broader model/input capabilities; extend V1 basic WeatherKit with advanced external weather providers/context, calendar/research, alerts and remote notifications and every future feature in the [full V2 backlog](v2-backlog.md). Operators use separate protected admin routes for selected report evidence, enforcement/audit, aggregate analytics, jobs/health/cost and controls. Detailed UX states are prepared in [V2 requirements](../design/v2-requirements.md); connected infrastructure, retention/access, cost and provider proof remain gates.
