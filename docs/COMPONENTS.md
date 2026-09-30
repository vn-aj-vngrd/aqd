# UI component contracts

Read this for component reuse/extraction; [Design rules](DESIGN-RULES.md) owns visual values and review. Feature specs own domain behavior. Names below are logical roles, not instructions to create new files for every row.

## Existing primitives to inspect first

| Role | Current implementation | Contract |
| --- | --- | --- |
| Root/detail headers | `screenHeader` | Left root title, compact detail/modal title; account controls only in Profile. |
| Primary/secondary actions | `PrimaryButton`, `ActionButtonStyle` | Shared compact sizing, enabled/loading semantics supplied by the feature, clear action label. |
| Icons | `AppIcon`, `IconLabel`, `AppSymbol` | Licensed family, decorative glyph hidden from accessibility; labeled actions retain accessible names. |
| Mutually exclusive tabs | `SegmentedTabs` | Equal options, selected trait; changes view state rather than submitting. |
| Scrolling filters | `FilterChip`, `ChipRail` | Category/filter action, explicit selection, clear/reset behavior belongs to parent. |
| Search input | `SearchField` | Query/clear; owner versus discovery scope is explicit in the feature. |
| Piece imagery/card | `GarmentImage`, `GarmentTile` | Photo/placeholder, metadata and selected state; no ownership or persistence logic inside rendering. |
| Look imagery | `OutfitComposition` | Composition from supplied resolved pieces; missing references are handled by the feature before rendering. |
| Recovery states | `EmptyWardrobe`, `ErrorBanner` | Distinguish empty/error/loading, concise next action, preserve entered work. |
| Add sheet | Current `CreateView` | Clothing or manual outfit paths; cancellation returns to origin; no duplicate editor implementation. |

Use source for exact initializer signatures and limits; this table is not a cached API declaration.

## Feature components to shape only when needed

| Role | Inputs / output | States and boundary |
| --- | --- | --- |
| Item draft form | Draft + existing validation → review/save intent | Media loading/cancel/error, required name/category, optional details; save via domain action. |
| Piece chooser | Items/query/filters/pinned/selected IDs → selection | Retain selections under filtering, unavailable selections shown, no creation side effect. |
| Theme membership editor | Outfit/theme IDs → proposed memberships | Empty collection valid; no outfit deletion when theme removed. |
| Plan calendar/agenda | Dated entries + timezone → selected date/entry | Multiple occasions/gaps/status; rendering never marks wear automatically. |
| Plan draft review | Proposed changes/conflicts → approve/edit/cancel | Whole range visible; approval binds proposal version. |
| Packing checklist | Derived owned IDs + check state → toggle | No duplicated quantity claims; replaced assignments reconcile checks. |
| History/insight rows | Trusted records/statistics → open source record | Date/estimate/scope labels; no model arithmetic inside a chart. |
| Public post card | Accessible snapshot + reaction state → action intent | Creator/detail, pending reaction, unavailable content; no private-source fields. |
| Profile collections | Accessible public IDs + owner capabilities → open/manage | Owner-only controls; truthful connected/disconnected counts. |
| Conversation/message rows | Authorized message/status/reference → retry/open | Request/pending/sent/failed, inaccessible references, no automatic Agent reading. |
| Agent proposal review/receipt | Typed proposal/version/result → approve/edit/cancel | Draft and succeeded result visually distinct; destination/impact visible. |

Extract a shared component for actual repeated behavior; keep one-off feature structure local. Preview fixtures represent realistic states and are not production posts, people, or network metrics. Build functional vertical slices before polishing isolated components.
