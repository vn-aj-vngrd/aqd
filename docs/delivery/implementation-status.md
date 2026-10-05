# Implementation status

Checked October 5, 2026. [Issue #3](https://github.com/vn-aj-vngrd/aqd/issues/3) establishes a reproducible SwiftUI app in `apps/ios/` and an isolated Supabase backend for **01 · Entry & identity**. The historical prototype was not restored. This slice does not establish full V1 launch readiness.

| Area | Current status | Next evidence required |
| --- | --- | --- |
| Repository tooling | Present; check commands live in root `package.json`. | Record results in [verification](verification.md). |
| Product and feature contracts | Specified; acceptance IDs are target checks. | Implement and verify the authorized slice. |
| iOS Entry & identity | Native source/project, adaptive tokens, durable private capture, optional preferences, Apple/email adapters and explicit account association implemented. | [Current evidence](verification.md); hosted auth, physical camera/Apple and distribution remain gates. |
| Other iOS and web UI | Paper/design targets; native and browser behavior unverified. | Implement the remaining authorized slices. |
| Private wardrobe, planning and Agent | Historical prototype reports exist; current release unverified. | Restore/establish the source baseline, then follow the [implementation plan](implementation-plan.md). |
| Identity and explicit first-closet association | Supabase selected by owner. Local real auth/RLS/private media/idempotent receipts verified; public profile creation is explicit. | Hosted project/SMTP/Apple team, account lifecycle and general cloud restoration/sync are outstanding. |
| Public content and Inbox | Service and policy gates remain open. | Resolve [decisions](../product/decisions.md), then test real services and access boundaries. |
| Full V1 launch | Unverified. | Complete [release acceptance](../product/v1-release.md), including device/service/operating evidence. |

## Historical records

[Prototype implementation](archive/prototype-implementation.md) preserves the earlier behavior, data rules and design handoff notes. [Prototype checks](archive/prototype-verification.md) and [design review log](archive/design-review-log.md) preserve reported evidence. Read them when restoring the prototype or tracing a prior review; they are not current shipping claims.

Update this file when reproducible implementation changes. Record exact tests and limitations separately in [verification](verification.md).
