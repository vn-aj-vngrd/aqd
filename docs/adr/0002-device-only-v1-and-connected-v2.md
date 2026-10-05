# ADR 0002 — Device-only V1 and connected V2

Status: accepted product boundary; persistence/provider details remain proposals. Date: October 5, 2026.

## Context

The earlier V1 definition required the full connected wardrobe/social/Inbox product, account sync and operations. The owner explicitly requested a small private Apple-device closet/planner MVP without social features or unnecessary recurring backend costs, and retention of the complete vision in V2.

## Decision

V1 stores AQD clothing data/media locally, has no sign-in, social UI, managed cloud sync or app backend, and supports complete Home/Closet/Agent/local Profile/Settings/onboarding, outfits/themes/plans/routines/trips/wear with explicit archive export/restore. Prefer native APIs and complete local Agent/history and optional on-device generation with a manual/rules path. Exclude AQD stores/media from automatic backup by default; disclose device-loss risk and the exception for user-selected exports. iPhone is the first target, not a new all-Apple-platform commitment.

V2 extends those same private features and records and retains all prior connected core and deferred enhancements, with the required backend/auth/media/sync/social/Inbox/moderation/admin infrastructure and prepared design requirements. Sign-in/association/upload must be explicit and must never publish private records automatically.

## Consequences

V1 needs no recurring backend service but loses automatic recovery and cross-device access. Apple distribution/support expenses remain separate. Optional AI depends on hardware/OS/settings/readiness and quality; failure never blocks manual use. V2 requires security, provider/policy/cost and operation decisions before implementation. Stable local IDs/schema/archive versions preserve a future migration seam without prematurely implementing networking.

The October 1 full-connected V1 scope is superseded and preserved as [V2 core release](../product/v2-release.md). This is planning/design authority only; no feature implementation or remote provisioning is authorized. [V1 architecture](../architecture/v1.md), [V2 architecture](../architecture/v2.md) and [decisions](../product/decisions.md) own details.

The same-day owner clarification supersedes the first narrowed draft: themes/routines/trips and complete local Agent/Profile/Settings remain V1. V2 is additive; no existing feature is dropped or local data reset.
