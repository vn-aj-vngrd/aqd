#!/usr/bin/env bash
set -euo pipefail

# Called only after trusted main push CI succeeds, under release-main concurrency.
head="$(git rev-parse HEAD)"
if [[ "$head" != "${RELEASE_SHA:?Expected the successful CI commit}" ]]; then
  echo "Checkout does not match the successful CI commit." >&2
  exit 1
fi

git fetch origin main --tags
git merge-base --is-ancestor "$head" origin/main
remote="$(git ls-remote origin refs/heads/release)"
if [[ -n "$remote" ]]; then
  git fetch origin refs/heads/release
  previous="$(git rev-parse FETCH_HEAD)"
  if [[ "$previous" != "$head" ]] && git merge-base --is-ancestor "$head" "$previous"; then
    echo "release=false" >> "$GITHUB_OUTPUT"
    echo "A newer CI-validated commit already owns the publication branch." >> "$GITHUB_STEP_SUMMARY"
    exit 0
  fi
  # A divergent publication branch is an error, never a force-push opportunity.
  git merge-base --is-ancestor "$previous" "$head"
fi

# main can advance to a failing commit; this cursor advances only after passed CI.
git checkout -B release "$head"
git push origin HEAD:refs/heads/release
echo "release=true" >> "$GITHUB_OUTPUT"
