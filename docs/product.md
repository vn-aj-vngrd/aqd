# Product

A complete private closet on one iPhone: add pieces, build outfits and themes, plan dates and trips, record wear, ask Agent, keep a private fit journal. No account, network or AI hardware is required for manual use.

## V1 scope

| Area | Included | Boundary |
| --- | --- | --- |
| Today | Customizable in-app card stack, thirteen kinds ([today](features/today.md)) | No system widgets or integrations. |
| Closet | Pieces, outfits, themes with search, filter, sort, archive, lifecycle ([wardrobe](features/wardrobe.md), [outfits-themes](features/outfits-themes.md)) | One cover photo required for a new piece. No publishing. |
| Planner | Dates, plans, routines, trips, packing, wear history, insights ([planner](features/planner.md)) | Local calendar only. |
| Agent | Local conversation, grounded queries, reviewed drafts and actions ([agent](features/agent.md)) | On-device model when ready; manual paths always work. |
| Profile | Private fit journal, optional identity, style preferences, Settings ([profile](features/profile.md)) | No online identity. |
| Data | Durable local store, versioned archive export, reviewed restore, local erase | No sync or merge. |
| Weather | Optional Apple WeatherKit context for a selected place and date | Off until chosen; the one network exception. |

Onboarding, light/dark appearance and complete loading, empty, error, permission and cancel states are part of every area.

## Decisions

- **Device-only V1** ([ADR 0002](adr/0002-device-only-v1-and-connected-v2.md)): AQD stores and media stay on the device and out of automatic backup. Original Photos and exported archives are outside AQD's control.
- **Apple-native first:** SwiftUI, SwiftData with CloudKit off, PhotosPicker, Foundation Models when eligible. Optional capabilities never raise the iOS 18 deployment minimum.
- **Agent is a draft maker.** Nothing it proposes changes records until the user reviews and approves; no cloud model, social or send tools in V1.
- **Weather** sends only the selected coordinates and dates to Apple, shows Apple's required attribution, and never blocks manual work. Numeric weather stays hidden until the attribution placement passes review.
- **Free local use;** no subscription or entitlement backend.
- **Personal target device** is the iPhone 17 Pro Max; broader device qualification is later launch work.

## V2 backlog

Connected extension of the same app and data. Sign-in, backup and sync, public Profile, posts and feeds, bookmarks, Inbox and moderation, shared and inspired outfits, virtual try-on, external calendar and advanced weather, notifications, billing, admin web, Android. Each needs its own spec and provider, cost and security decisions before work starts. Sign-in or upload must be explicit and never publish private records automatically.
