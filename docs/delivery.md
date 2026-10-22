# Delivery

## Knowledge policy

GitHub issues hold plans, slice status, checks run and evidence. Repo docs hold only stable contracts and decisions. Write status and receipts as an issue comment, never as a repo file; link the issue from the PR. Delete a doc that no longer changes behavior.

## GitHub

Repository [vn-aj-vngrd/aqd](https://github.com/vn-aj-vngrd/aqd), personal account `vn-aj-vngrd`. Check `gh api user --jq .login`; if wrong, `gh auth switch --hostname github.com --user vn-aj-vngrd`. Never print tokens.

- Read issues with `gh issue view <n> --comments`; write multiline bodies with `--body-file`. Search for duplicates first and use real issue numbers.
- Triage labels (one state, one category): `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`; category `bug` or `enhancement`.
- `main` takes changes only through PRs: current CI, resolved review threads, linear history, squash merge, no admin bypass. Rules live in `.github/branch-rules.json`; read live settings before diagnosing a block.

## Setup

Node 24, pnpm 10.12.1. `pnpm install --frozen-lockfile` installs Lefthook (`pnpm setup:hooks` if scripts were disabled). The root package is tooling only; the app is in `apps/ios`.

## Branches and commits

- Branch `van/issue-<n>/<short-kebab>` for ticketed work, `van/<short-kebab>` otherwise. Never invent an issue number.
- Subject `action(part): Description`, at most 100 characters, one line, no body, no co-author lines. Types are enforced by `scripts/validate-commit-message.mjs`. Breaking change: `!` or a `BREAKING CHANGE:` footer.
- Hooks check whitespace, tooling tests and commit subjects, and block direct pushes to `main`.
- PR title uses the same format for the final combined change. Put `Closes #<n>` in the body and fill the PR template with actual results.

## Verification

- Feature work uses Core and native unit tests plus a Debug build on the physical iPhone 17 Pro Max. UI behavior is also checked by hand on that phone.
- End-to-end UI tests and broad device qualification are deferred to issue #30.
- Run native tests with `scripts/test-ios.sh` (`IOS_TEST_SCOPE=unit`, device UDID from `xcrun devicectl list devices`, local signing team, `IOS_DEVICE_READY=1` only after the owner confirms the phone is connected and unlocked). Hosted native CI is not used. The factory alone runs app unit tests and UI proof screenshots on the iPhone 17 Pro Max simulator; they support a PR but do not replace the phone checks.
- Tooling: `pnpm check` and `pnpm check:agents` (Markdown links).

## Shipping an issue

1. Implement in vertical slices, each tested and committed.
2. Push the issue branch and open one PR against `main`.
3. Wait for CI and the Codex review on the **current head**. Fix valid findings in focused commits; every push needs fresh CI and review. A pending or unavailable review is a blocker, not a pass.
4. Squash-merge bound to the verified head SHA.
5. Verify main CI and the repository release for the merged SHA. A retry resumes at the first unsatisfied step.

## Releases

After CI succeeds on `main`, the release workflow fast-forwards the `release` branch to that SHA and semantic-release publishes a `vX.Y.Z` tag and GitHub release (`feat` minor, breaking major, anything else patch). Reruns are safe and never rewind or force-push. This is repository versioning only; signing, TestFlight and App Store distribution are separate scope.
