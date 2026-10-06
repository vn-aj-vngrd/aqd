# U — Profile, account, privacy, and durability

## Phase boundary

The connected identity/public Profile/account contract below belongs to V2. V1 includes a private fit journal in local Profile, optional name/photo/style preferences, existing wear/history/insight and Style shortcuts, Settings, appearance/tour/help and local export/restore/erase. V1 has no online identity, authentication, association/sync, followers/public counts or account deletion. V2 extends this local Profile only after connected opt-in. See [V1 release](../product/v1-release.md), [V2 backlog](../product/v2-backlog.md) and [V2 design](../design/v2-requirements.md).

## V1 private fit journal

Profile is a personal dated fit-memory journal, not a duplicate Pieces/Outfits/Themes closet. Local identity (name/avatar) is optional. Profile has one native More toolbar icon containing Add fit, Edit profile, Style, Wear insights and Settings, without duplicate root/body controls. No capability is removed; menu cancellation retains journal position and restores trigger focus. No social identity, followers/public counts, publish action or AQD network upload exists in V1.

- A memory has a stable ID, required calendar date (today by default, editable), explicit timezone, optional single user-selected local photo, optional existing outfit link, and optional private note of at most 500 user-perceived characters. Save requires a photo **or** an existing outfit; neither a date-only nor date-and-note-only draft can save. Retain over-limit input with inline validation, never silently truncate. Dates use [planning/history's local-date semantics](planning-history.md): changing device timezone does not shift the saved day.
- Photo-only, outfit-only and photo-plus-outfit memories are valid. Without a photo, render the linked outfit's actual piece composition, never a fabricated wearer/try-on photo. Capture a minimal outfit snapshot (outfit ID/name, ordered piece IDs/names/categories) when linking; preserve it across outfit edits/deletion so the memory remains interpretable. Available authorized piece media may illustrate that snapshot; unavailable media is labelled honestly, not invented or silently replaced with another look.
- A journal memory is neither a planned outfit nor a recorded actual wear. Adding/editing/deleting a memory or linking/unlinking an outfit changes no wear counts or plan state. Record wear is a separate explicit action through the existing duplicate-safe wear contract; a fit date is not evidence of wear.
- Add/change photo uses the same native source sheet as [local capture](../design/capture-photo.md): Choose from Photos / Take photo, then system picker/camera, one accepted photo copied locally. Shared import, orientation/Fit, preparation, cancellation, late-result and permission/failure protection apply, but piece capture's mandatory-photo rule does not. Preserve all fields and the prior accepted photo until successful replacement; no library-wide access or upload is implied. A selected iCloud Photos asset may need Apple's download; AQD still stores its accepted copy on device.
- Edit date/note/photo/link in a draft; Save commits atomically and failures retain the draft and prior saved record. Back/interactive dismissal protects unsaved edits with Keep editing / Discard changes. Confirm photo removal and memory deletion with exact impact and safe Cancel; photo removal is a draft change until Save. Removing the last photo/link cannot save an empty record: offer another photo/outfit or separately confirmed Delete memory. Outfit deletion is not journal deletion: preserve the snapshot and memory, including photo-less memories, with an unavailable-link state. That retained snapshot permits later date/note edits without forcing a replacement photo/outfit; it is not a way to create new empty memories. Unlinking deliberately removes that association/snapshot, subject to the same save validation.
- Delete memory removes only its AQD-owned media/derivatives not referenced elsewhere, never the linked outfit, wear history, another memory, or original Photos asset. Replacement/cleanup releases superseded media only after commit and reference checks. Local erase includes journal records, snapshots, notes, photos and drafts; original Photos and exported copies remain outside AQD's control. No automatic backup/recovery: explicit versioned export/validated reviewed restore includes journal data and referenced media under the [V1 data contract](../product/v1-release.md#data-contract). Private journal notes/photos do not enter Agent context implicitly.

### Journal acceptance (V1)

- J1: Empty Profile explains private memories and directs Add fit through the same More menu as populated Profile. Edit profile, Style, Wear insights and Settings remain available there, without duplicating the closet or showing invented totals.
- J2: Save/reopen photo-only, outfit-only and combined entries; edit today's default date. Block date-only/note-only and over-500-character saves while retaining input. Outfit-only shows composition, not a wearer image; device-zone changes preserve dates.
- J3: Cancel source sheet/picker/camera/editor, deny camera, fail/cancel import (including late results) or fail Save; retain fields, link and previously accepted media. Draft recovery survives interruption; retries create one memory.
- J4: Add/link/unlink/edit/delete fits without changing plans or wear totals. Explicit Record wear reuses or rejects the same item-set/day duplicate rather than incrementing twice; undo follows the existing wear contract.
- J5: Cancel removal/deletion and retain data; confirm replacement/photo removal/memory deletion with exact scoped effects and draft protection. Deleting/editing an outfit preserves memory snapshots; lost media shows an honest unavailable state.
- J6: Export/restore round-trips journal data/media/dates; cancelled/invalid/failed restore preserves good data. Erase clears AQD-owned journal copies/drafts, not Photos/exported copies. Verify backup exclusion and no AQD uploads/public surface; disclose device/app-loss risk.
- J7: VoiceOver labels date, photo/link state, validation and actions; focus enters/returns from source sheet. Dynamic Type, 44-point targets, keyboard-safe scrolling, light/dark and reduced motion/transparency retain access to Save and safe exits.

This is owner-approved design/spec scope only, not application implementation or verified native behavior. V2 adds [explicit reviewed sharing](../product/v2-backlog.md#private-fit-journal-and-explicit-sharing), never automatic posting.

## Outcome and separation

V2's default owner Profile retains V1's private dated fit journal, identity/layout, More management and shared private editors. Inbox and connected commands are additive; they do not replace the journal with a public closet. Public social presence is a separate explicit projection: avatar, username, display name, bio, real followers/following counts and curated public Pieces / Outfits / Themes. Private name/avatar editing does not force a username or authentication; public identity editing remains a separate reviewed connected action. Closet remains the source of owned content, and private journal/photo/note/body data never transfers automatically to the public projection.

Working default: public social profiles and explicitly curated public closet content. Private-profile/follow-request behavior is deferred. A user may remain socially unlisted while using private features. Guest/local identity must not display invented network counts or a fictitious share URL.

## Identity and settings

Private first use and manual wardrobe work do not require a social account. Joining social features requires chosen sign-in, unique username, and a clear local-data association flow. Recommended username: 3–30 characters using letters, digits, periods, underscores; validate case-insensitive uniqueness server-side. Display name 1–80; optional bio up to 160 user-perceived characters. Username changes preserve stable author/user IDs.

Settings own account access, privacy/publication controls, notification preferences, blocked users, data export/recovery, sign-out, and account deletion. Private preferences for goals/occasions/style/fit/comfort/colors/patterns and optional height/self-described body shape use the [same shared questionnaire](../design/onboarding-personalization.md) from onboarding, Settings → Style and Profile → More → Style. Entered questions require an explicit answer or No preference/refusal before Continue; there are no skip controls. Supplied values remain editable/removable, body details remain optional, and body-use permission starts off. These details are not public attributes or inferred from photos. V1 saves them locally within explicit export/restore/erase; V2 does not silently send them to a cloud provider. Camera/Photos permissions are requested when the user starts capture, not during mandatory onboarding.

Avatar uses user-selected media; body/face/measurement capture for virtual try-on is out of scope. Profile edits preserve pending content on failure. Share profile uses a real resolvable public URL only once connected; disconnected mode explains its limitation.

## Data durability

Signed-in backup/sync/reinstall recovery, useful export, account deletion and isolated caches are mandatory V2 under [DATA acceptance](../product/v2-release.md#data-contract). Backend/conflict/retention selection remains unresolved and blocks launch. Device-only guest use remains available with its recovery limitations disclosed.

The local prototype stores embedded photos/JSON. Future connected durability must preserve stable item/outfit IDs, theme memberships, history, and plans, with versioned migrations and explicit ownership. Local-account association previews what will be backed up. User choice to sign in is not blanket permission to publish.

Backend, sync conflict resolution, storage encryption/recovery, and identity providers remain deployment decisions. Until resolved, do not claim multi-device sync or recoverability after app removal. Preserve local prototype content during a feature migration; validate migrations against old fixtures before replacing storage.

Working sign-out default: clear online tokens and hide cached private connected data, with local-only data handled through an explicit reviewed choice; never expose one account's data to the next. Export must be useful for personal records and media, excluding other people's private chats. The format is a backend/data-lifecycle gate to finalize.

Account deletion previews affected private/connected/public data, requires reauthentication where supported, and provides honest completion/failure status. Remove public posts/closet access and authentication under the service's actual retention policy. Chat retention after sender deletion must be settled before Inbox launch; do not promise erasure from another user's device without that capability.

## Acceptance

- U1: Private onboarding works without signup, body photos, a mandatory quiz, or social participation.
- U2: Visitor Profile shows only accessible public collections and actual network counts.
- U3: Owner publishes selected content from the existing closet identity; private records do not leak through Profile totals.
- U4: Username conflict/edit failure preserves input and resolves with actionable validation.
- U5: Sign-in association/migration preserves local wardrobe IDs and media without automatic publishing.
- U6: Sign-out/account switching prevents cross-account disclosure; cancellation preserves the current session/data.
- U7: Export/recovery/deletion behavior matches the chosen service policy and is verified before production claims.
- U8: Profile settings are reachable from Profile only; Home/Closet do not repeat account controls.

## Gates

Local identity editing can proceed independently. Connected identity, unique usernames, public links, counts, sync, and destructive lifecycle wait for service decisions in [Open decisions](../product/decisions.md).

## Entry sequence

The [entry and identity design](../design/entry-identity.md) keeps private capture before optional preferences. Authentication preserves the originating intent; local association is explicit and only requested when needed. Existing identities skip profile setup. New social identities are collected at the first social action. Email recovery, camera denial and account/local conflicts have dedicated reference states; provider and merge policies remain service gates.

## Public profile presentation

S06, S13 and S14 show populated Outfits, Pieces and Themes selections under one compact public-profile header. S07 remains the deeper searchable public closet. Follow and Message are compact equal-width actions, with full accessible targets; navigation uses the username and identity content shows the display name once. Theme counts and cover collages contain only accessible published memberships. Tab changes retain the same identity/actions and preserve each collection's scroll position. No private inventory counts are exposed.


The owner public projection and visitor profiles use the same compact public header and collection layout; this does not replace the default private journal Profile. The bio preview is always a single line with a tail ellipsis when it overflows; tapping opens a full-description sheet. Edit profile shows a live count out of 160, normalizes line breaks to spaces and retains over-limit drafts with an inline error instead of saving or silently cutting content. See the [shared profile component contract](../design/components.md#compact-public-profile--v2-owner-and-visitor) for Unicode, legacy records and accessibility rules.

Settings links to private Liked posts and Saved inspiration collections. These are activity references, separate from owned outfit favorites and the public Profile grid. See the discovery specification for unavailable references, optimistic changes and collection access.
