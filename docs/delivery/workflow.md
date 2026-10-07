# Development and releases

## GitHub identity

Repository: [vn-aj-vngrd/aqd](https://github.com/vn-aj-vngrd/aqd). Use the personal account `vn-aj-vngrd`, associated with `vanajvanguardia@gmail.com`. Verify `gh api user --jq .login`; if the wrong account is active, run `gh auth switch --hostname github.com --user vn-aj-vngrd` and retry. Diagnose connectivity and actual permission errors if switching does not help; never expose tokens.

Read [the engineering lifecycle](../agents/lifecycle.md) for delivery authority and the full ticket → spec → review → PR → squash → release procedure. The same policy applies to Codex, Claude, and other agents. Agents whose runtime does not automatically load AGENTS.md must load it before work; it is the shared policy source.

## Local setup

Use Node 24 and pnpm 10.12.1. Run `pnpm install --frozen-lockfile`; the prepare script installs Lefthook locally. If lifecycle scripts were disabled, run `pnpm setup:hooks`. Existing custom `core.hooksPath` must be reconciled explicitly if Lefthook reports a conflict. CI skips local hook installation.

The root package contains repository tooling only. `apps/ios/` is the intended native location, not proof of tracked source/buildability; [current status](implementation-status.md) owns the source boundary. This does not introduce a JavaScript app framework.

## Branch and commit

Fetch `origin/main` and start `van/issue-<actual-number>/<short-kebab-description>` for ticketed work, for example `van/issue-12/item-capture` for GitHub #12. Use `van/<short-kebab-description>` for setup work without a ticket; never invent a ticket number. Continue fixes on the existing PR branch. `main` is integration; `master`, if created, receives the same protection. All new changes reach them through PRs.

Commit subjects follow Conventional Commits: `<type>(optional-scope)!: Summary`, at most 100 characters. Examples: `feat(closet): Add item capture`, `fix(planner): Preserve assigned dates`, `chore: Update tooling`. The validator owns supported types. Ticket references belong in the body so release parsing remains consistent. A breaking change uses `!` or a `BREAKING CHANGE:` footer with a description.

Lefthook checks staged whitespace, runs tooling tests for changed foundation files, and rejects direct pushes/deletions to main/master. Its commit-msg hook validates the subject. CI validates PR titles independently of local hooks. Use a conventional PR title and squash merge, retaining breaking-change footers in the final commit. Git-generated merge/revert subjects are allowed locally for maintenance; they do not replace conventional PR titles.

## Automatic versioning

After a merge/push to `main`, successful CI triggers Release for that exact commit. Release runs only for successful same-repository push events and uses full Git history. Concurrency belongs to the guarded publication job, so failed/cancelled CI workflows cannot displace eligible releases. `queue: max` retains up to 100 pending jobs rather than replacing the previous pending job; the SHA/ancestry guard handles completion order. See [GitHub concurrency](https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency). `scripts/prepare-release.sh` advances the `release` publication branch to the successful CI SHA with a fast-forward push. This branch is a CI-validated publication cursor, not an integration branch or a place for manual work.

semantic-release publishes from `release`, so a newer failing commit on `main` cannot suppress an older successful commit's release. Delayed untagged runs skip when `release` already contains a newer CI-validated descendant. A tagged ancestor still runs publication recovery without rewinding the cursor; divergent history fails instead of force pushing. Re-running the same SHA is safe. `scripts/publish-release.sh` verifies a version tag points to the checked-out SHA and a non-draft GitHub release exists. If an earlier publication pushed the tag but failed to create the GitHub release, a retry creates the missing release with generated notes and `--verify-tag`; it preserves the existing tag. A release left as a draft by a partial upload is published on retry. API failures remain failures, and final verification requires a non-draft release. Main/master remain protected and are never pushed by the release job.

Like Relay and Roleway, `.releaserc.json` makes `feat` minor, breaking changes major, and other conventional types patch, including docs/chore/ci. A release uses the strongest change since the previous tag. Without an existing release tag, semantic-release starts at `v1.0.0`; later versions advance automatically. Skipped/no-change reruns do not mint duplicate versions.

Release publishes a `vX.Y.Z` Git tag and GitHub release notes using the job's contents-write `GITHUB_TOKEN`. Release notes include maintenance and documentation changes. There is no npm publication, version-bump commit, or hook bypass commit. Tags and releases are the repository version source; root package.json is private tooling, not an app version.

This is repository release automation. It does not yet update Xcode's `MARKETING_VERSION`/build number, archive/sign the app, upload TestFlight, or publish to the App Store. Add native build/version injection and its CI gate when the app is tracked and build delivery is authorized. Current CI verifies repository tooling, not the untracked iOS prototype.

## GitHub policy

The repository is connected to `origin`. Its active “AQD integration branches” ruleset covers main/master with no bypass actors, PR-required changes, strict `Repository tooling` checks, resolved review threads, linear history, and blocked force pushes/deletion. Squash merging is enabled; merge-commit and rebase methods are disabled. The already committed initial baseline was pushed once to initialize the empty repository before protection was enabled.

The owner is a solo maintainer; a separate human approval count is not required. Required Codex review is a lifecycle gate: current repository rules enforce CI and thread resolution, but do not themselves prove Codex has reviewed. Configure the Codex GitHub integration for this repository and verify each latest-head review before merging. See [Lifecycle](../agents/lifecycle.md).

Repository settings are live state. Re-read ruleset and merge settings before changing them or diagnosing blocked merges; this document is not proof they remain enabled.

Default `GITHUB_TOKEN` permissions are supplied per job; no personal access token is needed for this setup. If tag rules restrict automated creation, permit the release job through the repository rules. Keep main changes behind PR review. Release triggers on successful main push CI, including the squash commit GitHub creates on merge.

## Titles and readable PRs

Commits and PR titles use the same conventional subject validator. Choose the type for the final combined behavior, not the last review-fix commit. Prefer an imperative sentence-case summary under 72 characters; 100 is the validator limit. Keep ticket references in the body, including `Closes #<number>` when the merged change completes it.

Use the PR template for features, fixes, refactors, and maintenance. Start with the problem and resulting behavior. Its table records each meaningful change/finding, action/reason, and observed verification result. Use plain English and concrete verbs. Include technical details only when they help assess behavior, compatibility, migration, privacy, or a failure. Remove placeholder instructions and unrelated history; use None for an empty applicable section. A short PR needs only a few precise rows, not padding.

Write Passed, Failed, or Not run with evidence/reason; never turn a planned test into a result. Update the body after review fixes and verify the squash title/body. For multiline issue/PR bodies, write a temporary file and pass `--body-file`.

## Verification

Run `pnpm check` for validator, real release-analyzer, notes, and workflow guard tests. Inspect `pnpm exec lefthook run pre-commit` and a temporary commit-message file through `pnpm exec lefthook run commit-msg <file>` to check installed hook behavior.

`pnpm release:dry-run` needs a configured reachable remote, release branch, and appropriate authentication; it is not an offline test. A GitHub CI pass, release tag, native build, and deployed app are separate evidence boundaries.

References: [Lefthook installation](https://lefthook.dev/usage/commands/install/) and [semantic-release configuration](https://semantic-release.gitbook.io/semantic-release/usage/configuration).
