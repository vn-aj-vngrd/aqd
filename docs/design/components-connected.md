# Connected component reference

Read only for V2 public profile/social/account UI. [Shared components](components.md) owns reusable primitives; features own behavior, [V2 release](../product/v2-release.md) owns phase acceptance. Native geometry/adaptation remains OS-owned.

## Compact public profile — V2 owner and visitor

The shared profile header places a 64-point avatar beside the display name and follower/following counts. The navigation title uses the username so the display name is not repeated. Use 12-point vertical gaps, a 15/22 bio, and a two-column action row with an 8-point gap. Follow/Following and Message use 15/20 medium labels, 12-point corners and **44-point minimum controls**; label line height must not duplicate the outer hit-area height. Preserve pending/failure state without changing button width. Counts are 44-point targets and come only from authorized public data.

Pieces / Outfits / Themes retain the shared compact segmented control. All three views keep the same profile shell, selected state and independent scroll position. Pieces use a two-column labelled garment grid; Outfits use photographic/composition covers; Themes use named collection collages with accessible public counts. Only published records and memberships appear. Ordinary cards remain flat. The shared pattern is illustrated on page 00 and S06/S13/S14. At larger Dynamic Type sizes, wrap the name, keep the bio preview to one ellipsized line with full-text disclosure, allow buttons to grow and collapse grids to one column rather than clipping text or reducing touch targets.


### Post action row

Like and comment use adjacent controls with at least 44-point targets and `--spacing-4` between them. Inline counts belong inside their combined controls. The flexible spacer keeps Save at the trailing edge. Do not add extra icon margins inside the targets. Page 00 Content and form patterns includes the shared row; Home All and Reduced Transparency use the same geometry.


### Social actions, tags and comments

Page 00 **Components · Social actions and piece tags** owns default/liked/saved/pending/failure action states, creator-selected photo tags, tag list fallback and comment composer states. Reuse the existing 22-point symbols, 44-point targets and 4-point post-action gap. Heart/bookmark use matching filled active symbols and selected semantics; Comment opens a destination and has no sticky active appearance.

Photo tags sit bottom-leading with 12-point inset, native functional material/opaque fallback and an accessible count. Revealed markers are numbered and backed by a list. Use C-select for local toggle feedback, N-push for the pieces list, N-photo or N-push for the public piece, and N-push/C-message for comments. Never use animation to imply publication or successful comment delivery. Exact privacy, validation and lifecycle rules are in the discovery specification.

Post footer captions use 15/22 regular text and a 4-point gap below the action row, consistently across All and Following. Place themes in post detail; linked tag counts stay on the photo. Large text expands layout and wraps accessible controls rather than shrinking hit targets. Long counts use locale-aware compact display with the full number in accessibility labels.


### V2 account and review states

E15–E17, U16–U24 and A31–A33 reuse status/header/home indicator, body/metadata hierarchy, native rows, primary/secondary action stacks and shared save/error states. Exact account, record/revision, artifact and operation status is supplied by real records. Conflict choice opens U24 without discarding either revision. Export/deletion progress/failed/unknown variants retain the operation; native share, reauthentication, confirmation and place/date pickers remain platform-owned. See [V2 coverage](v2-coverage.md).

Shared V1/V2 connected-core response actions are Copy, Retry and Details. Helpful/Not helpful and version-comparison masters prepare V2 extensions; show them when their real lifecycle is enabled. V1 omits Notifications and the acquisition survey. V2 connected core gates those controls until V2-E09/E15 transport/collection is enabled. Inbox gates remote mute until its notification transport exists. No unavailable toggle implies a service exists.


## Public bio and owner projection

The public owner projection U26 and visitor variants share avatar/name/count lanes, 12-point content gaps, single-line bio and collection grids. Public owner management uses More, not loose Add/Settings/Edit/Share duplicates; visitor navigation keeps Back/More and Follow/Message. Default owner root U01 instead shares V1's private dated journal layout, single More and icon-only Profile navigation, with V2 Inbox/additive connected commands. Public username editing and verified-link sharing remain separate from private identity/fit editing.

`ProfileBioPreview` displays exactly one 15/22 line, width-constrained with tail ellipsis (never a manually shortened saved value). The containing button has a 44-point target and opens a native About sheet with the full, selectable, wrapping description and Done. VoiceOver receives the full description plus an opens-details hint. Empty bios omit the row for visitors; owners add one through Edit profile. Dynamic Type keeps the single-line preview at the selected system size without shrinking type; full text remains available in the sheet. This constraint applies to profile bios, not chat replies, explanatory error text or accessibility labels.

`ProfileBioEditor` is optional, limited to 160 user-perceived characters (grapheme clusters), with a live count and matching persistence/API validation. Normalize pasted line breaks to spaces for this single-line field; trim outer whitespace on save. Reject an over-limit save with an inline error, preserve the draft and focus the field. Do not truncate pasted text silently. Existing over-limit records remain fully readable; require a valid length only when saving a changed bio. Other profile edits must not silently erase the existing bio. Do not truncate the editor value itself; allow native horizontal scrolling/selection. Names/usernames keep their separate existing limits.
