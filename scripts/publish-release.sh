#!/usr/bin/env bash
set -euo pipefail

export GITHUB_REF=refs/heads/release
export GITHUB_SHA="$(git rev-parse HEAD)"
tag="$(git tag --points-at HEAD --list 'v*' --sort=-version:refname | head -n1)"
if [[ -z "$tag" ]]; then
  pnpm exec semantic-release
  tag="$(git tag --points-at HEAD --list 'v*' --sort=-version:refname | head -n1)"
fi
test -n "$tag"

# Tags can survive a failed GitHub API publication. Retry the release, not the tag.
if draft="$(gh release view "$tag" --json isDraft --jq .isDraft)"; then
  if [[ "$draft" == true ]]; then
    gh release edit "$tag" --draft=false
  fi
else
  gh release create "$tag" --verify-tag --generate-notes --title "$tag"
fi
published="$(gh release view "$tag" --json isDraft,tagName --jq 'select(.isDraft == false) | .tagName')"
test "$published" = "$tag"
