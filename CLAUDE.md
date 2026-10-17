@AGENTS.md

## Claude Code

- Skills are shared with other agents: `.claude/skills` points at `.agents/skills`. Invoke `/aqd-implement`, `/aqd-verify`, `/aqd-review`, `/aqd-ship <issue>`.
- `.claude/settings.json` pre-approves read-only and check commands and blocks reading local signing config. A `PostToolUse` hook formats edited Swift files and runs the layer check; fix any violation it reports before continuing.
- Use dedicated tools (Read, Edit, Grep, Glob) over shell equivalents. For native work run `swiftlint lint --quiet` and the unit scope in [apps/ios/README.md](apps/ios/README.md) before claiming done.
- Do not write plans, status or notes into the repo. Record them as GitHub issue comments; keep personal preferences in your own memory.
