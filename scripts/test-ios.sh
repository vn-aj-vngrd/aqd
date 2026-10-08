#!/bin/bash
# Run from any directory: ./scripts/test-ios.sh
# Override only the simulator destination with IOS_DESTINATION.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DESTINATION="${IOS_DESTINATION:-platform=iOS Simulator,id=E5DAD2A0-6375-4737-B33D-3A08A4D9FDAA}"
DERIVED_DATA="${IOS_DERIVED_DATA:-/tmp/aqd-uitest-derived}"
# The real PhotosPicker UI test needs a normal Photos-library source. Seeding
# adds synthetic pixels only and preserves all existing Simulator photos.
# A destination expressed by name must supply IOS_PHOTO_DEVICE explicitly.
PHOTO_DEVICE="${IOS_PHOTO_DEVICE:-${DESTINATION##*,id=}}"
if [[ "$PHOTO_DEVICE" == "$DESTINATION" ]]; then
  printf 'Set IOS_PHOTO_DEVICE to the destination simulator UUID for Photos seeding.\n' >&2
  exit 1
fi
"$ROOT/scripts/seed-ios-test-photo.sh" "$PHOTO_DEVICE"

swift test --package-path "$ROOT/apps/ios/Core"

# The default device is the local iOS 26.5 iPhone 17 Pro simulator.
# No credentials, team, provisioning, local xcconfig, or signing hooks are used.
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
  build test
