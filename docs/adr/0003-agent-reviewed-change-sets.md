# ADR 0003 — Agent reviewed change sets, undo and live evals

Status: accepted. Date: October 20, 2026.

## Context

Agent runs on Apple's on-device model, which is small, changes with each iOS release and can slip on tool choice. It already prepares drafts the owner approves. It could not archive or delete, approval was all-or-nothing, an applied change could not be undone, notes reached the model by default against the written contract, and no live check gated a release.

## Decision

- Every mutation is a review the owner approves or rejects. There is no "always allow" and no standing permission, because a wrong tool call on a small model must never reach the closet.
- Related changes form one change set with a tickable row per record. Apply uses only ticked rows and checks every row against its reviewed revision before the first write. A failure rolls back what the attempt changed.
- Archive is the reversible path. Delete is a separate destructive confirmation with the exact impact and no undo.
- A receipt keeps what is needed to undo (the earlier state, or the id of what was created) and offers Undo only while every record it touched is unchanged since the apply.
- Private notes are off by default behind their own switch, and are data that can never authorize a change.
- Reliability comes from the deterministic layer (rules, validation, revision checks, approval); the model fills typed arguments. Deterministic evals gate CI. The live on-device eval gates every release with pooled pass-rate bars, since only the device can show the real model.

## Consequences

Reviews cost one tap more than a trusted agent would, which is the point. Every undo needs the record unchanged since, so an owner who keeps editing loses the button, never their work. A trip is undone whole or not at all; a piece delete cannot be undone. The live gate needs the owner's unlocked iPhone, so a release waits for it. Apple's Evaluations framework needs the iOS 27 SDK and may later replace the scorer once the deployment target allows.
