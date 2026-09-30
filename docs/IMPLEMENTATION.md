# Initial iOS implementation

This document tracks the runnable first increment. [PRODUCT.md](PRODUCT.md) owns the product vision; [feature specifications](features/README.md) own detailed target behavior. Neither is a list of shipped features. The next authorized slice is defined in [Implementation plan](IMPLEMENTATION-PLAN.md); this documentation pass adds no app functionality.

## Gap after product refinement

The refined target uses Home, Closet, Agent, Inbox, Profile, moves discovery search into Home, introduces human messaging, and changes Home to All / Following community feeds and adds personal Planner, events, routines, travel packing, app-level focused AI actions, and a broader gated Agent. None of those changes were implemented in the product-definition pass. Current Home remains Personal / Community, with a separate Search tab and no Inbox. Current themes have one free-text theme per outfit, not the proposed many-to-many collection model. Current Agent can answer and prepare limited outfit/theme drafts; it cannot yet upload through chat, apply arbitrary edits, prepare calendar plans, or execute a production action loop. Public closets, follows, sync/recovery, and moderation remain incomplete. Source and prior test evidence describe the existing increment only.

## Closet-first navigation update

Home is a Personal / Community feed. Icon-only navigation is Home, Closet, Agent, Search, Profile. Agent opens full screen with Back. Add is a two-action bottom sheet for manual clothing capture and outfit composition. Profile has pieces/outfits/themes, bio editing, a reviewable text-summary share action, and separate account settings. Follows and public profile URLs remain unavailable; no fake counts or links are shown. The earlier weather service remains implemented and tested but is no longer displayed in Home’s feed.

## Available locally

- Private onboarding with an empty closet or an explicit sample-wardrobe option.
- Manual clothing entry, photo-library import, camera capture on supported devices, editing, archive/restore, and confirmed deletion.
- Search by item metadata, outfit names, and themes; category and archived filters.
- Manual outfit composition, editable local suggestions, theme grouping, favorites, and confirmed outfit deletion.
- Wear recording with same-combination/same-day deduplication and same-day undo.
- Personal Home feed of saved outfits and clothing, with detail links and favorites.
- Local profile, editable go-to mood, counts, most-worn item, and wardrobe utilization.
- A limited on-device helper for outfit suggestions, unworn/most-worn queries, and “find/show” metadata searches.
- Manual condition, ownership-age range, and prior wear count; backward-compatible optional fields.
- Standalone themes created manually or reviewed from Agent suggestions.
- Community inspiration opens Agent with a suggested prompt rather than generating inside the feed.
- Persistent local data, including imported photo data, saved atomically to Application Support.

## V1 AI: on device

Ask AQD uses Apple Foundation Models on iOS 26+ when Apple Intelligence and the system model are available. No AI requests leave the device and no account is required. The app checks model availability and offers explicitly labeled Quick rules when unsupported, disabled, or downloading. Each independent model session receives a bounded snapshot of up to 24 active pieces (names, categories, colors, tags, wear counts, condition, ownership age, material, and fit), excluding photos and private notes. Questions are limited to 500 characters, output to 500 tokens, and model-selected piece indices are validated before becoming a reviewable draft. The model sees only this subset; Quick rules provides deterministic full-closet wear/search queries. The cloud AI client was removed from the app. Existing server AI files are deferred experiments, not the V1 runtime.

One real generation and review/save flow passed in the iOS 26.5 simulator with its model available. Physical-device performance and broader prompt quality remain unverified.

## Connected community implemented, awaiting deployment

- Email/password sign-in and registration against Supabase Auth; confirmation-email messaging, token refresh, and Keychain session storage.
- Explicit public outfit snapshots, a feed of the newest 30 posts, local filtering, private likes/bookmarks, owner-only deletion, and an Agent entry for inspiration.

These paths compile and their server contracts/access policies have local tests, but are **not deployed or live-provider verified**. No AQD Supabase project is configured. OpenAI credentials are not needed for V1. The app honestly gates online actions until configuration and sign-in are available. See [Backend setup](BACKEND-SETUP.md).

## Not implemented

Cloud wardrobe backup/sync, automatic photo tagging, automatic device location, public closet/profile browsing, follows, reporting/blocking/moderation, password recovery/account deletion UI, and semantic community search. These remain necessary work before a public release. No API key or backend is required to use the local wardrobe.

This is an initial functional product, not the complete V1 or an App Store release.

## Initial behavior decisions

- The local wardrobe is private by default. Public sharing is an explicit outfit snapshot, not a visibility switch that pretends to expose the entire closet. Photos are downscaled for public snapshots; private notes and wear history are excluded.
- Each saved outfit has one free-text theme; an empty theme becomes Everyday.
- Suggestions require a top + bottoms + shoes, or a dress + shoes. Optional layers/accessories come from the same active closet. Matching theme tags take priority, then fewer recorded wears. A variation rotates available choices.
- Suggestions are rules, not model-generated reasoning. No weather or preference-learning claims are made. On-device AI is a separate explicitly labeled mode; Quick rules never pretends to be model output.
- A wear record captures item IDs, an optional outfit ID, and a timestamp. The same set of items can be recorded once per calendar day in the current device timezone. Different combinations are separate records.
- Wearing an outfit records one wear for each included item. Individual-piece wear recording is also available. Undo removes today's matching record.
- Archived items remain in saved outfits and historical records, but cannot enter new suggestions or newly saved outfits. Restore or remove them before recording another wear for that outfit.
- Deleting a piece removes it from saved outfits, deleting any that become empty. Historical wear records remain. Deleting an outfit preserves clothing and wear history.
- Wardrobe utilization is the fraction of active items with at least one recorded wear, across all time. Monthly statistics count wear records, including individual-piece records.
- Samples are opt-in and identifiable. Removing samples preserves user items and removes sample references from saved outfits. Replacing a sample photo turns that piece into a user piece.
- Photos are normalized to at most 1400 pixels on their longest edge and saved as JPEG. The system Photos picker only supplies the selected image; the app does not request full-library access.
- Failed persistence does not publish unsaved changes. Unreadable data blocks editing rather than replacing the saved file.

## Structure

`apps/ios/AQD/Core/` owns models, persistence, and deterministic suggestion rules. `Features/` owns SwiftUI flows; `Design/` owns small shared visual components. `Services/CloudService.swift` owns optional Supabase authentication, community requests, and the AI function client.

`apps/ios/Package.swift` exposes the same core files to host-based tests. The iOS application itself remains a standard Xcode project.

## Verification

Run the checks in [iOS setup](../apps/ios/README.md). Automated tests cover core state and persistence; they do not prove physical-camera access, real-device performance, cloud backup, live AI, or App Store readiness.
