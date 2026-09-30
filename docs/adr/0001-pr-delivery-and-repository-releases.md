# ADR 0001: PR delivery and repository releases

Status: Accepted, October 1, 2026.

## Decision

GitHub Issues hold AQD delivery tickets. main/master accept changes through PRs with current CI and resolved review threads, without administrator bypass. The repository allows squash merges only. Conventional commit subjects and PR titles feed semantic-release after successful main CI. Tags/GitHub releases own repository versions; native build numbering/distribution stays a separate delivery concern.

The shared agent lifecycle requires current-head Codex review before merging, including work implemented by another agent. A missing review is a blocker, not successful CI. Repository rules enforce PR/check/thread policy; the current-head Codex completion check is an additional agent delivery obligation until a reliable review status integration is configured.

## Reason and consequences

This matches the owner's Relay/Roleway flow, keeps version calculation deterministic after squash, and separates observed review/build/release evidence. The initial empty GitHub repository received the existing main baseline before protection; subsequent changes use PRs. The desired branch rules are stored in `.github/branch-rules.json`; live settings must still be read before claiming enforcement.

Future changes to required checks or automated review enforcement update this ADR, the policy file, and the live repository together.
