#!/bin/bash
# Run from any directory: ./scripts/test-ios.sh
# Default: Core and native unit tests. Use IOS_TEST_SCOPE=all or e2e explicitly.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DESTINATION="${IOS_DESTINATION:-}"
if [[ -z "$DESTINATION" ]]; then
  DESTINATION="$(node "$ROOT/scripts/ios-destination.mjs")"
fi
DERIVED_DATA="${IOS_DERIVED_DATA:-/tmp/aqd-uitest-derived}"
SCOPE="${IOS_TEST_SCOPE:-unit}"
TEST_SELECTION=()
case "$SCOPE" in
  unit) TEST_SELECTION=(-only-testing:AQDTests) ;;
  e2e) TEST_SELECTION=(-only-testing:AQDUITests) ;;
  all) ;;
  *) printf 'Invalid IOS_TEST_SCOPE: %s (expected unit, e2e or all).\n' "$SCOPE" >&2; exit 1 ;;
esac

# Only UI runs need synthetic Photos-library fixtures. Unit runs never seed Photos.
if [[ "$SCOPE" != unit ]]; then
  PHOTO_DEVICE="${IOS_PHOTO_DEVICE:-${DESTINATION##*,id=}}"
  if [[ "$PHOTO_DEVICE" == "$DESTINATION" ]]; then
    printf 'Set IOS_PHOTO_DEVICE to the destination simulator UUID for Photos seeding.\n' >&2
    exit 1
  fi
  "$ROOT/scripts/seed-ios-test-photo.sh" "$PHOTO_DEVICE"
fi

if [[ "$SCOPE" != e2e ]]; then
  swift test --package-path "$ROOT/apps/ios/Core"
fi

# The default destination is the installed target iPhone 17 Pro Max simulator.
# No credentials, team, provisioning, local xcconfig, or signing hooks are used.
# Conditional array expansion preserves zero arguments under macOS Bash 3.2 nounset.
xcodebuild \
  -project "$ROOT/apps/ios/AQD.xcodeproj" \
  -scheme AQD \
  -configuration Debug \
  -destination "$DESTINATION" \
  -derivedDataPath "$DERIVED_DATA" \
  -disableAutomaticPackageResolution \
  -parallel-testing-enabled NO \
  -collect-test-diagnostics never \
  CODE_SIGNING_ALLOWED=NO \
  ${TEST_SELECTION[@]+"${TEST_SELECTION[@]}"} \
  build test
