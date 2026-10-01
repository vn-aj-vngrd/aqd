# Search, density and feed continuation

Paper page 00 owns the Search, Control sizes and Feed continuation masters. These contracts describe static designs; services and native interactions require implementation verification.

## Search scopes and presentation

Community search uses All / People / Pieces / Outfits / Themes, in that order, in one compact segmented control. All previews named groups with See all; do not mix unlabelled result types. People show portrait, display name, handle and accessible public details. Pieces use two-column image/name/owner tiles. Outfits use larger cover tiles with creator attribution. Themes use collection collages, name, creator and accessible outfit count. Every tab has its own selected state, result count when known, scroll and pagination cursor. Preserve the query when changing tabs.

Closet search uses Pieces / Outfits / Themes and only the current owner's records. Today search opens this scope. Community queries, history and results never become private-closet queries implicitly. Public-profile search is restricted to that creator's published records. Existing list searches, such as conversations or pickers, reuse the same query lifecycle inside their named scope; do not add irrelevant community tabs.

The same compact control is used before, during and after typing. Native search provides clear, cancel, keyboard Search and focus restoration. Blank input shows recent queries (if opted in and available), with individual removal and Clear recent; no fabricated trending searches. Whitespace-only queries do not fetch. Clear retains scope and selected tab. Cancel restores the source and its scroll position. Large text uses a horizontally scrollable labelled scope row rather than clipping or shrinking text; touch targets remain at least 44 points.

## Query lifecycle and states

Debounce typing briefly, cancel superseded work and accept results only for the latest query, scope and tab. Search submits immediately. Initial loading uses neutral skeletons matching the selected result geometry. Refresh retains current results and identifies that they are updating; do not show old results as matching a new query. Empty results name the current query/tab, offer clear filters or another category and preserve the query. Never render a request failure as no results.

Each tab inherits: blank/recent, focused typing, loading, populated, no matches, filters with no matches, initial failure with Retry, offline cached results with an honest stale label, offline with no cache, loading more, pagination failure with inline Retry, and end reached. No permission to fetch private data is inferred from an empty state. Failed images retain tile size and show the shared category fallback. Removed/blocked results revalidate on open and use Content unavailable. Unknown totals are omitted, never shown as zero. Sorting is stable with a tie-break ID; each tab resets pagination on query/filter/scope change.

Keyboard and screen-reader focus stay in the field during typing. Announce settled result counts politely, never every keystroke or skeleton. Return from a result restores query, tab, filters and scroll. Search history is local and account-scoped; clearing it is immediate and does not delete wardrobe records.

X07 separates the docked system-keyboard reference from the scrollable results viewport; it is never an inset content card. Space and Search belong to the native keyboard, with the Search submit label and system styling. No AQD prominent/glass buttons are added inside the keyboard. Runtime uses actual keyboard insets and native placement, not the mockup's fixed height; accommodate language, predictive row, third-party keyboards and hardware keyboard without covering results/actions. The Paper layout is an authored approximation, not an imported Apple kit or runtime keyboard.

## Two used control sizes

Standard buttons use a 44-point visible surface and target with 17-point text; standard segments use a 52-point track and 44-point segment surface. Use for primary steps, forms, confirmation, entry and Home's primary mode selector.

Compact buttons use a 36-point visible surface centered in a 44-point target with 15-point text. Compact segments use a 44-point track, 36-point selected surface and 13-point labels. Use on owner/visitor profile actions and collection tabs, and search scope tabs. The shared silhouette, tint, pressed/selected/disabled/loading states are unchanged. Never overlap enlarged targets; retain at least 44 points per segment. At large accessibility text, grow both variants or use stacked/scrollable native controls; density never overrides legibility. Profile sections use 8-point gaps. These are the only density variants; color/semantic roles are separate.

## Infinite feed and result pagination

All and Following reuse one post component and pagination footer. A long-content reference demonstrates multiple Piece, Outfit and Theme posts. Viewport states show a partial previous post, the next post and the continuation footer above safe-area chrome. Initial full-feed loading is distinct from loading the next page.

Start the next cursor request near the end; permit only one request per scope/query/cursor. Retain all loaded posts, reserve media aspect ratios, deduplicate by post ID and maintain the visible anchor. Append without entry cascades or automatically scrolling. Native progress with “Loading more…” appears after loaded content; do not replace content with a full skeleton. No artificial percentage or elapsed-time claim. Reduce Motion removes custom shimmer/translation; use the system progress treatment and text.

Failure keeps posts and shows “Couldn't load more” with Retry at the same footer. Offline keeps cached content and shows connection status; never retry in an unbounded loop. End reached replaces the spinner with “You're all caught up” only when confirmed by the cursor response. New posts arriving above do not move the reader; show a New posts action. Pull-to-refresh keeps content until replacement succeeds and preserves the current scope. VoiceOver exposes Load more as an alternative and announces completion once; keyboard/focus stays on the current post. Return from detail restores the anchor and loaded pages. Filtering or switching account cancels and scopes pending requests.

## Linked-piece thumbnails

Public-piece lists, marker editing and the published-piece picker share 56 × 64 thumbnails, a two-line text lane and a trailing disclosure. Use the linked piece's photo or a deliberate creator crop; existing fixture crops are reused consistently for coat/bag references. The complete row is a target; thumbnail is decorative to VoiceOver when the row names the piece. Missing/loading photos reserve geometry; revoked pieces remove private imagery and names. Never substitute an unrelated garment photo.

Search uses one trailing Cancel in every query/scope/loading/recovery state. Do not render a second Back control with the same source destination. Opening a search result pushes its detail with Back; returning restores the search query and results rather than dismissing search.
