# 0002 — Native Entry and explicit closet association

Status: accepted for issue #3, October 5, 2026.

## Context

The owner requested a scalable, maintainable iOS foundation and selected Supabase for Entry identity. No tracked app baseline existed. Private capture must work without authentication; sign-in must not publish or silently move records.

## Decision

Use one SwiftUI iPhone app target with typed Core, shared semantic Design, feature flow coordinators and external Services. Adopt Swift 6 complete concurrency checks and pin the Supabase SDK/lockfile. Prefer feature folders to premature frameworks or dependency containers.

Persist the bounded Entry closet in an atomic, versioned local document with protected separate JPEG files. Refuse to overwrite unreadable storage. Keychain stores auth and email transactions; a matching PKCE callback is required. This document is a small-first Entry store, not a full wardrobe sync engine. A future persistence migration must preserve IDs and ownership and handle unsupported versions explicitly.

Association requires explicit review, persists a frozen snapshot/operation ID, and calls a transaction on Supabase. Owner RLS protects private records and media; a narrowly scoped private security-definer function checks the authenticated identity and returns an idempotent receipt. Local ownership changes only after every saved ID is confirmed. Existing account closets stay separate; no implicit merge is permitted. Sign-out hides other-account records without deleting them.

## Consequences

This supports native private use and independently testable identity/ownership boundaries with few layers. General sync, large inventories, cloud media restoration, account deletion/retention and all other app features require their own scoped implementation. Supabase choice does not authorize a paid hosted plan or establish SMTP/Apple/production readiness.

See [setup and verification](../../apps/ios/README.md) and [current evidence](../delivery/verification.md).
