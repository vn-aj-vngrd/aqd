# Historical prototype backend setup

This procedure describes the earlier prototype and absent source paths. It is retained for restoration/reference. Current service selection and complete V1 requirements are governed by [decisions](../../product/decisions.md) and [release acceptance](../../product/v1-release.md).

V1 AI uses Apple Foundation Models on the device. No OpenAI key, cloud AI endpoint, or account is required. Ask AQD offers Quick rules when the model is unavailable. Do not deploy `wardrobe-assistant` for V1; its server files remain deferred experimental work and are not called by the iOS app.

Supabase is only needed for optional community accounts and sharing. Use a dedicated AQD project; do not reuse another product database.

1. Select the Supabase organization and approve the project cost before provisioning.
2. Authenticate the CLI and link the dedicated project with `supabase link --project-ref AQD_PROJECT_REF`.
3. Review and apply the migration with `supabase db push`. Its unused AI quota tables/functions are legacy infrastructure; V1 does not call them.
4. Configure Auth email confirmation and email delivery.
5. Copy `apps/ios/Configuration/Local.example.xcconfig` to `Local.xcconfig` and supply the project URL and publishable key. Rebuild. Never place service-role or model-provider secrets in the app.

The private wardrobe remains on the device after sign-in. Community publishes only explicitly selected outfit snapshots. Cloud wardrobe sync, reporting, blocking, moderation, password recovery, and account deletion UI are not implemented and remain necessary before public release.

Before enabling community, test with two separate accounts: registration/confirmation, expired sessions, publish, feed, private likes/bookmarks, owner-only deletion, signed-out rejection, and network failure. Check that private notes and wear history never appear in public posts.

See [verification](../verification.md) for the boundary between local tests and live evidence.
