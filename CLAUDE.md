@AGENTS.md

## Claude Code

- Feature delivery uses the factory described in [AGENTS.md](AGENTS.md); start it from `~/Documents/van`, not from this repo.
- `.claude/settings.json` pre-approves read-only and check commands and blocks reading local signing config. A `PostToolUse` hook formats edited Swift files and runs the layer check; fix any violation it reports before continuing.
- Use dedicated tools (Read, Edit, Grep, Glob) over shell equivalents. For native work run `swiftlint lint --quiet` and the unit scope in [apps/ios/README.md](apps/ios/README.md) before claiming done.
- Do not write plans, status or notes into the repo. Record them as GitHub issue comments; keep personal preferences in your own memory.
