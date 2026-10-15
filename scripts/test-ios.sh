#!/bin/bash
# Run from any directory: ./scripts/test-ios.sh
# Default: Core and native unit tests. E2E is reserved for issue30.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DESTINATION="${IOS_DESTINATION:-}"
PHYSICAL=false
if [[ "$DESTINATION" == platform=iOS,id=* ]]; then
  PHYSICAL=true
else
  printf 'Local native checks require the physical iPhone destination. Prompt for the connected, unlocked iPhone, then set IOS_DESTINATION=platform=iOS,id=<current-device-UDID>. Local simulators stay shut down.\n' >&2
  exit 1
fi
SIGNING_ARGUMENTS=(CODE_SIGNING_ALLOWED=NO)
if [[ "$PHYSICAL" == true ]]; then
  if [[ "${IOS_DEVICE_READY:-}" != 1 ]]; then
    printf 'Prompt the owner to connect and unlock the physical iPhone; set IOS_DEVICE_READY=1 only after their readiness response.\n' >&2
    exit 1
  fi
  if [[ ! "${IOS_DEVELOPMENT_TEAM:-}" =~ ^[A-Z0-9]{10}$ ]]; then
    printf 'Physical tests require the existing local IOS_DEVELOPMENT_TEAM signing identity; keep signing configuration outside Git.\n' >&2
    exit 1
  fi
  SIGNING_ARGUMENTS=(CODE_SIGN_STYLE=Automatic "DEVELOPMENT_TEAM=$IOS_DEVELOPMENT_TEAM" -allowProvisioningUpdates)
fi
DERIVED_DATA="${IOS_DERIVED_DATA:-/tmp/aqd-uitest-derived}"
SCOPE="${IOS_TEST_SCOPE:-unit}"
TEST_SELECTION=()
if [[ "$SCOPE" != unit && "${AQD_E2E_ISSUE:-}" != 30 ]]; then
  printf 'E2E execution is deferred to issue #30. Feature delivery uses unit tests only.\n' >&2; exit 1
fi
case "$SCOPE" in
  unit) TEST_SELECTION=(-only-testing:AQDTests) ;;
  e2e) TEST_SELECTION=(-only-testing:AQDUITests) ;;
  all) ;;
  *) printf 'Invalid IOS_TEST_SCOPE: %s (expected unit, e2e or all).\n' "$SCOPE" >&2; exit 1 ;;
esac

if [[ -n "${IOS_TEST_CASES_FILE:-}" ]]; then
  if [[ "$SCOPE" != e2e || ! -f "$IOS_TEST_CASES_FILE" ]]; then
    printf 'Selected UI cases require e2e scope and an existing IOS_TEST_CASES_FILE.\n' >&2; exit 1
  fi
  TEST_SELECTION=()
  while IFS= read -r TEST_CASE || [[ -n "$TEST_CASE" ]]; do
    [[ -z "$TEST_CASE" || "$TEST_CASE" == \#* ]] && continue
    if [[ ! "$TEST_CASE" =~ ^AQDUITests/[A-Za-z_][A-Za-z_0-9]*/test[A-Za-z_0-9]+$ ]]; then
      printf 'Invalid selected UI test identifier: %s\n' "$TEST_CASE" >&2; exit 1
    fi
    TEST_SELECTION+=("-only-testing:$TEST_CASE")
  done < "$IOS_TEST_CASES_FILE"
  if [[ ${#TEST_SELECTION[@]} -eq 0 ]]; then
    printf 'No selected UI test identifiers; refusing a wider or empty run.\n' >&2; exit 1
  fi
fi
RESULT_ARGUMENTS=()
if [[ -n "${IOS_RESULT_BUNDLE:-}" ]]; then
  RESULT_ARGUMENTS=(-resultBundlePath "$IOS_RESULT_BUNDLE")
fi

if [[ "$PHYSICAL" == true && "$SCOPE" != unit && -z "${IOS_TEST_CASES_FILE:-}" ]]; then
  printf 'Physical UI runs require an explicit focused test selection and declared fixtures. Broad device E2E remains in #30.\n' >&2
  exit 1
fi

if [[ "$SCOPE" != e2e ]]; then
  swift test --package-path "$ROOT/apps/ios/Core"
fi

# Local tests use the explicit physical phone and existing local signing team.
# Hosted native/simulator CI is removed; all native checks use the physical phone.
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
  "${SIGNING_ARGUMENTS[@]}" \
  ${TEST_SELECTION[@]+"${TEST_SELECTION[@]}"} \
  ${RESULT_ARGUMENTS[@]+"${RESULT_ARGUMENTS[@]}"} \
  build test
