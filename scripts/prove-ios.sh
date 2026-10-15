#!/bin/bash
# Run a persisted issue selection and retain real reports plus visual attachments.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ISSUE="${1:-}"
if [[ ! "$ISSUE" =~ ^[1-9][0-9]*$ ]]; then
  printf 'Usage: scripts/prove-ios.sh <positive-issue-number>\n' >&2; exit 1
fi
CASES="${IOS_TEST_CASES_FILE:-$ROOT/apps/ios/acceptance/issue-$ISSUE.txt}"
if [[ ! -f "$CASES" ]]; then
  printf 'Missing acceptance selection: %s\n' "$CASES" >&2; exit 1
fi
if [[ -n "${IOS_PROOF_OUTPUT:-}" ]]; then
  mkdir "$IOS_PROOF_OUTPUT" # Existing output is refused, preserving prior receipts.
else
  IOS_PROOF_OUTPUT="$(mktemp -d "/tmp/aqd-issue-$ISSUE-proof.XXXXXX")"
fi
export IOS_PROOF_OUTPUT
cp "$CASES" "$IOS_PROOF_OUTPUT/test-cases.txt"
if [[ -z "${IOS_DESTINATION:-}" ]]; then
  IOS_DESTINATION="$(node "$ROOT/scripts/ios-destination.mjs")"
fi
export IOS_DESTINATION
export IOS_DERIVED_DATA="${IOS_DERIVED_DATA:-/tmp/aqd-issue-$ISSUE-derived}"
export IOS_RESULT_BUNDLE="$IOS_PROOF_OUTPUT/results.xcresult"
export IOS_TEST_SCOPE=e2e IOS_TEST_CASES_FILE="$IOS_PROOF_OUTPUT/test-cases.txt"
cd "$ROOT"
node --input-type=module - "$ISSUE" <<'JS' > "$IOS_PROOF_OUTPUT/inputs.json"
import { execFileSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
const git = (...args) => execFileSync('git', args, { encoding: 'utf8' }).trim();
const paths = git('ls-files', '--cached', '--others', '--exclude-standard', '-z', '--', 'apps/ios', 'scripts/test-ios.sh', 'scripts/prove-ios.sh', 'scripts/validate-ios-proof.mjs', 'scripts/ios-destination.mjs', 'scripts/seed-ios-test-photo.sh').split('\0').filter(Boolean);
console.log(JSON.stringify({ issue: process.argv[2], head: git('rev-parse', 'HEAD'), dirty: git('status', '--short'), destination: process.env.IOS_DESTINATION, fixture: 'Synthetic asymmetric Photos image; UUID-isolated test stores', toolchain: execFileSync('xcodebuild', ['-version'], { encoding: 'utf8' }).trim(), sha256: Object.fromEntries(paths.map(path => [path, createHash('sha256').update(readFileSync(path)).digest('hex')])) }, null, 2));
JS
printf 'Acceptance evidence: %s\n' "$IOS_PROOF_OUTPUT"
STATUS=0
"$ROOT/scripts/test-ios.sh" > "$IOS_PROOF_OUTPUT/run.log" 2>&1 || STATUS=$?
if [[ -d "$IOS_RESULT_BUNDLE" ]]; then
  xcrun xcresulttool get test-results summary --path "$IOS_RESULT_BUNDLE" > "$IOS_PROOF_OUTPUT/summary.json"
  xcrun xcresulttool export attachments --path "$IOS_RESULT_BUNDLE" --output-path "$IOS_PROOF_OUTPUT/attachments"
else
  printf 'No result bundle. See %s/run.log\n' "$IOS_PROOF_OUTPUT" >&2; exit 1
fi
if [[ "$STATUS" -ne 0 ]]; then exit "$STATUS"; fi
node "$ROOT/scripts/validate-ios-proof.mjs" "$IOS_PROOF_OUTPUT/summary.json" "$IOS_TEST_CASES_FILE" "$IOS_PROOF_OUTPUT/attachments/manifest.json"
