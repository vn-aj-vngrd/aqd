# Issue tracker: GitHub

Issues and implementation specs live in https://github.com/vn-aj-vngrd/aqd. Use `gh` from this checkout. Verify `gh api user --jq .login` is `vn-aj-vngrd`; if needed use `gh auth switch --hostname github.com --user vn-aj-vngrd`. This is the personal account associated with vanajvanguardia@gmail.com.

Read an issue with `gh issue view <number> --comments`. Create/update multiline bodies with a temporary file and `--body-file`; pass labels/assignees through structured CLI flags. Link the originating issue in the PR and keep feature behavior in its existing spec instead of copying it into multiple tickets. Search for duplicates before filing. Tickets use real GitHub numbers.

PRs as a request surface: no. PR review and requested fixes remain part of delivery; unsolicited external PRs are not a feature-request queue. Resolve ambiguous issue/PR numbers before triage. Work spanning modules uses linked child issues with explicit dependencies.
