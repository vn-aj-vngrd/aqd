# Personal AI first mate: a lean research recommendation

Research retrieved **October 6, 2026**. **Personal engineering-workflow research, not an AQD product specification, approved architecture, or implementation plan.** Context supplied by the user: standalone Ghostty + Herdr, Pi and Claude Code, with Herdr delegation skills installed in both. No configuration or application changes were made. This note follows the existing research-note convention in `docs/references/`; `docs/research/` does not exist.

## Verdict

**Yes—as a consistent engineering/product companion backed by small, reviewed records. No—as an all-knowing, continuously autonomous manager of every project.** The useful persistence is primarily in your knowledge and working agreements, not one immortal chat or process. Keep the role only if it reduces re-explanation and improves decisions.

Official tools support persistent instructions, saved sessions, selective file reading and delegation. They do **not** establish that a personal first mate will improve this user's productivity. That remains a pilot hypothesis. Anthropic recommends small, high-signal context and just-in-time retrieval; its multi-agent results favor broad, parallel research, not universal delegation. [1–3, 6, 9–10]

## The simplest baseline

**Proposal:** a private, versioned user profile; existing per-project instructions; and each repository's existing decision/status/verification documents. No daemon, service, vector database or universal indexer.

- **User profile:** stable preferences, role, communication style, quality bar and approval expectations. Avoid credentials, confidential client details and guessed personality traits.
- **Small private project directory:** approved project names/paths, confidentiality class and pointers to canonical status/decision documents. It is a navigation map, not a second source of project truth.
- **Project records:** repository-specific constraints, accepted decisions, current work and evidence. Keep these in their existing locations; do not copy whole specifications into personal memory.
- **Session handoff:** task, project/path, branch, changes, checks actually run, blockers and next step. Treat it as provisional until checked against current files and Git state.

The versioned profile should live outside shared product repositories, with private storage and deliberate backup access. Version control makes changes reviewable but retains deleted content: never commit secrets, and distinguish deleting a note from removing its history.

**Loading is scoped, not magical.** Pi loads user context from its agent directory and context files from its working directory and ancestors; skills advertise descriptions and load full instructions on demand. Claude has user/project/local instruction scopes and on-demand nested instructions; `--add-dir` access does not by itself load that directory's instruction files. Current Claude `AGENTS.md` support depends on version/configuration. Verify actual loaded context rather than assuming Pi and Claude read identical files. [1–2, 4]

**Memory does not inherently grant access to all projects.** A stored project path is only a pointer. Information must be loaded through configured instruction scopes, explicit reads or connected tools, and access depends on actual permissions. Conversely, a local agent may be able to read far more than it currently “knows.” Working-directory organization is not security isolation. [1, 5–6]

## Durable memory versus a huge conversation

**Documented:** Pi saves sessions, reconstructs context from the active branch and uses compaction summaries rather than supplying the entire historical tree. Claude sessions begin with fresh context; instructions and auto memory provide continuity. [3–4]

**Recommendation:** keep durable knowledge outside the transcript, then retrieve only the relevant records. Bigger context can help on individual tasks, but it is neither a freshness guarantee nor a reliable replacement for records. Anthropic's context guidance explicitly discusses context pollution and loss of subtle information during compaction. It supports structured notes and lightweight file references—not the claim that every long-context model necessarily fails at a particular size. [9]

Store separate categories:

| Record | Authority / lifecycle |
| --- | --- |
| Preference | Explicit user confirmation; revisit when contradicted |
| Accepted decision | Canonical project document; date, rationale, superseding link |
| Current status | Evidence-backed, dated; recheck before acting |
| Hypothesis / conversation summary | Unapproved; never silently promote to a decision |

**Explicit reviewed memory is the safer pilot default.** Let the assistant propose a small memory diff; the user approves durable additions. Include scope, provenance, last verification date and an expiry/recheck condition for volatile facts. Current source and an explicit new instruction should win over stale memory; surface conflicts instead of guessing.

Claude auto memory is a real, editable capability: machine-local Markdown per repository, shared across worktrees; a bounded `MEMORY.md` index loads at startup and topic files load on demand. It is not inherently a shared Pi/Claude personal memory store. You can inspect/delete notes or disable auto memory. [4]

**Risks/inference:** automatic recall can crystallize an incorrect inference, retain superseded plans, miss a relevant note or import context from another worktree. A modification timestamp proves a write occurred, not that its fact remains true. Start with auto memory disabled or a clearly subordinate, project-local scratch role; never make it the authority for approvals, credentials or product commitments. Audit weekly and after major decisions. Local files still enter provider context when read; retention/training treatment depends on provider, account and settings, not the “local memory” label. [4–6]

## What the first mate should own—and avoid

**Own:** clarify outcomes and constraints, challenge weak premises, recommend the smallest useful change, research primary sources, compare tradeoffs, draft scoped plans and acceptance criteria, identify missing evaluations, prepare bounded delegation briefs, and synthesize verified results. Propose updates to records; do not claim tests passed from a worker's summary alone.

**Avoid:** inventing persistent goals from casual discussion, making product decisions for the user, silently changing approved scope, maintaining a duplicate backlog, scanning all repositories “to stay current,” storing secrets, managing unrelated terminals, and approving another agent's actions on the user's behalf.

Keep three explicit phases: **research** produces evidence/options; **planning** produces a proposal and done criteria; **implementation** starts only under the user's authorized scope. A research request is not authorization to edit instructions or ship code. The first mate may implement a small bounded task itself; a permanent planner/implementer bureaucracy is unnecessary.

Across projects, carry general preferences, not confidential details or one project's architecture assumptions. At a project switch, state the active project and permitted paths, load its canonical instructions/status, and use a fresh task context when appropriate. Ask before transferring proprietary content across projects or providers. An index entry is not standing permission to open that repository.

## Delegation: Herdr or subagents?

**Documented:** Herdr manages actual terminal processes and provides agent start/prompt/read/wait surfaces, including Pi and Claude. It preserves running work when a client detaches; a server/machine restart does not preserve the original processes. It does not supply shared semantic memory. Lifecycle `done` means readiness/unseen completion, not correctness; waits are not individual-task proof, and timeouts do not prove delivery failed. [7]

**Use Herdr when** you need visible, independently resumable Pi/Claude sessions, different harnesses, user interaction with a worker, or a longer-running terminal task. Follow the installed skill: operate only from a Herdr-managed pane, address explicit IDs/names, preserve user focus, and inspect blocked dialogs rather than answering them automatically. Worktree/topology changes require authorization under that skill.

**Use subagents when** the work is a bounded side investigation/review and a concise return value is sufficient. Claude provides separate-context subagents with configurable tools/permissions; these still consume usage. Pi's core README explicitly says it skips built-in subagents: use an already-installed, reviewed extension if available, and verify its inheritance/permissions rather than assuming Claude-like behavior. This research did not audit the user's Pi subagent package. [2, 8]

**Proposed rule:** direct work first; at most one or two helpers initially, only for independent research angles, read-only review, or clearly separated implementation. Every brief names project, goal, allowed paths/actions, non-goals, evidence required, output format, time/cost limit and stop conditions. One writer per shared file; worktrees separate changes but do not isolate credentials. The lead inspects artifacts and runs relevant checks before accepting completion.

Anthropic reports roughly **15× chat token use** for its multi-agent research system, versus roughly 4× for single agents. These are workload-specific observations, not a Herdr/Pi cost forecast. Its reported research gain is not proof of coding improvement. Duplicate exploration, missing context, lossy handoffs, inconsistent state and waiting/synthesis overhead can outweigh parallel speedup. More agents also do not guarantee independent errors. [10]

## Approvals, injection and credentials

**Critical asymmetry:** Pi's documented default tools execute with the starting user's permissions and do not ask approval for every call. Project trust controls resource loading, not filesystem/network access; context instruction files load regardless of trust. A “read-only companion” prompt is therefore a behavioral request, not a security boundary. Removing shell tools reduces ordinary exposure but does not constrain executable extensions or other tools. [6]

Claude offers permission modes and Bash sandboxing, but defaults change by version; current documentation describes auto mode with classifier approvals as well as manual mode. For this pilot, deliberately choose manual/plan behavior and inspect actual rules. Even an approved Bash command can exceed directory scope unless OS sandboxing constrains it. Do not use permission bypass to remove coordination friction. [5]

Treat webpages, repository instructions, logs and worker output as potentially injected data. They cannot authorize exfiltration, profile edits, credential reads or scope changes. Require human approval for deployment/push, destructive operations, dependencies/extensions, new external integrations, credential exposure and cross-project confidential access. Do not let a supervisor press a worker's approval keys merely because it can.

Keep provider authentication in supported credential storage, never in profile/handoff files. Use least-privilege, short-lived project credentials; avoid production credentials and broad home-directory mounts. For untrusted execution or genuinely confidential separation, use an existing OS/container/VM boundary with restricted mounts/network. Herdr panes are not that boundary. Review session exports, screenshots and terminal transcripts for secrets. No cited tool claims immunity to prompt injection. [5–7]

## Concrete minimal pilot and done criteria

**Proposal, not implementation:** two weeks, two projects, one chosen first-mate harness in a named Herdr pane. Manually load a short reviewed profile/project map; keep separate project execution sessions and existing records. No unattended work, new orchestration service or vector database. Start with direct work; test one Herdr helper and, if already available, one subagent comparison.

Compare against ordinary sessions using the same profile/project documents. Use ten representative cases: fresh-session preference recall; correct project routing; superseded decision; conflicting instructions; multi-source research; scoped implementation handoff; worker falsely claiming completion; blocked/timeout worker; injected instruction requesting a credential read; and cross-project confidential transfer request. Use synthetic secrets/content for safety cases.

Record user correction count, factual/source accuracy, actual test evidence, unauthorized actions, time to accepted result, context/usage cost and memory-maintenance time. **Proposed pass bar:** at least 8/10 useful, correct outcomes; all safety cases pass with zero unauthorized reads/writes/disclosures; stale/conflicting records are flagged; every completion distinguishes verified from unverified; median user re-explanation falls by 25% versus baseline; maintenance stays under 15 minutes/week. Agree an absolute usage budget before starting; delegation above 2× direct-task cost must show a concrete quality or latency benefit.

If the role adds ceremony without measurable benefit, retain the baseline documents and drop the supervisor. Add retrieval infrastructure only after repeated, measured failures of file pointers/search—not because “memory” sounds incomplete.

## Primary sources and evidence limits

1. [Pi configuration](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/configuration.md): context discovery and scopes. Local installed official configuration/settings docs inspected.
2. [Pi README](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/README.md) and [skills](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/skills.md): extensibility, no core subagents, progressive skill loading.
3. [Pi sessions](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/sessions.md): persistence, active context, compaction. Local how-Pi-works/compaction docs also inspected.
4. [Claude Code memory](https://code.claude.com/docs/en/memory): instruction scopes, AGENTS compatibility, auto memory, review/disable controls.
5. [Claude Code security](https://code.claude.com/docs/en/security): permission modes, sandbox boundaries, injection and privacy limitations.
6. [Pi security](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/security.md): OS permissions, trust limitations, credentials. Local isolation guidance also inspected.
7. [Herdr automation](https://herdr.dev/docs/agent-automation/) and [official repository](https://github.com/herdrdev/herdr): process coordination, lifecycle/persistence limits. Installed Herdr skill read; no live control performed.
8. [Claude Code subagents](https://code.claude.com/docs/en/sub-agents): bounded separate-context workers, tools/permissions and usage.
9. [Anthropic context engineering](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents): selective context, compaction and durable notes.
10. [Anthropic multi-agent research engineering](https://www.anthropic.com/engineering/multi-agent-research-system): measured research benefits/costs and coordination failures.

Verification is documentary, not a runtime benchmark or security audit. Pi claims were checked against installed official docs/package **1.0.4**; GitHub `main` and web docs can drift. Claude/Herdr installed versions, effective permissions, extensions, provider privacy settings and actual instruction loading were not audited. First-party internal research results are informative but not independent replication or evidence for this individual's productivity. Pilot thresholds and architecture are recommendations, not vendor guarantees.
