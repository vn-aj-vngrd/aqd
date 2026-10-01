# U — Profile, account, privacy, and durability

## Outcome and separation

Profile is social presence: avatar, username, display name, bio, real followers/following counts, and public Pieces / Outfits / Themes. Owner view also exposes publication management and settings. Closet remains the source of owned/private content; Profile does not create a second closet or show all private items to visitors.

Working default: public social profiles and explicitly curated public closet content. Private-profile/follow-request behavior is deferred. A user may remain socially unlisted while using private features. Guest/local identity must not display invented network counts or a fictitious share URL.

## Identity and settings

Private first use and manual wardrobe work do not require a social account. Joining social features requires chosen sign-in, unique username, and a clear local-data association flow. Recommended username: 3–30 characters using letters, digits, periods, underscores; validate case-insensitive uniqueness server-side. Display name 1–80; optional bio up to 160 user-perceived characters. Username changes preserve stable author/user IDs.

Settings own account access, privacy/publication controls, notification preferences, blocked users, data export/recovery, sign-out, and account deletion. Style preferences used for personalized creation live in Closet; Profile can link to them. Camera/Photos permissions are requested when the user starts capture, not during mandatory onboarding.

Avatar uses user-selected media; body/face/measurement capture for virtual try-on is out of scope. Profile edits preserve pending content on failure. Share profile uses a real resolvable public URL only once connected; disconnected mode explains its limitation.

## Data durability

Signed-in backup/sync/reinstall recovery, useful export, account deletion and isolated caches are mandatory V1 under [DATA acceptance](../product/v1-release.md#data-contract). Backend/conflict/retention selection remains unresolved and blocks launch. Device-only guest use remains available with its recovery limitations disclosed.

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


Owner and visitor profiles use the same compact header and collection layout. The bio preview is always a single line with a tail ellipsis when it overflows; tapping opens a full-description sheet. Edit profile shows a live count out of 160, normalizes line breaks to spaces and retains over-limit drafts with an inline error instead of saving or silently cutting content. See the [shared profile component contract](../design/components.md#compact-profile--owner-and-visitor) for Unicode, legacy records and accessibility rules.

Settings links to private Liked posts and Saved inspiration collections. These are activity references, separate from owned outfit favorites and the public Profile grid. See the discovery specification for unavailable references, optimistic changes and collection access.
