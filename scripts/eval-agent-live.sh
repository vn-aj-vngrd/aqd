#!/bin/bash
# Release gate for the Agent: runs the live on-device eval on the physical iPhone, pulls the reports and fails when
# any bar in AgentEvalGate.thresholds is missed. Keep the phone unlocked with Apple Intelligence on, and AQD in the foreground.
#
#   AQD_DEVICE_UDID=<udid> IOS_DEVELOPMENT_TEAM=<team> scripts/eval-agent-live.sh
#
# AQD_EVAL_SUITES (default "golden heldout tidy") and AQD_EVAL_RUNS (default 3) choose what runs. AQD_EVAL_SKIP_INSTALL=1 reuses the installed build.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UDID="${AQD_DEVICE_UDID:?Set AQD_DEVICE_UDID to the connected iPhone (xcrun devicectl list devices)}"
SUITES="${AQD_EVAL_SUITES:-golden heldout tidy}"
RUNS="${AQD_EVAL_RUNS:-3}"
TIMEOUT="${AQD_EVAL_TIMEOUT_SECONDS:-2400}"
BUNDLE="com.aqd.private"
OUT="$(mktemp -d "${TMPDIR:-/tmp}/aqd-agent-eval.XXXXXX")"
STAMP="$(date +%y%m%d%H%M)"

if [ "${AQD_EVAL_SKIP_INSTALL:-}" != "1" ]; then
  : "${IOS_DEVELOPMENT_TEAM:?Set IOS_DEVELOPMENT_TEAM to build and install}"
  cd "$ROOT/apps/ios"
  xcodebuild -project AQD.xcodeproj -scheme AQD -configuration Debug -destination "platform=iOS,id=$UDID" -derivedDataPath build/dd \
    DEVELOPMENT_TEAM="$IOS_DEVELOPMENT_TEAM" CURRENT_PROJECT_VERSION="$STAMP" MARKETING_VERSION=1.0.1 -allowProvisioningUpdates build | tail -3
  git checkout -- AQD.xcodeproj/project.pbxproj
  xcrun devicectl device install app --device "$UDID" build/dd/Build/Products/Debug-iphoneos/AQD.app
fi

copy() { xcrun devicectl device copy from --device "$UDID" --domain-type appDataContainer --domain-identifier "$BUNDLE" --source "Documents/$1" --destination "$2" >/dev/null 2>&1; }

REPORTS=()
for suite in $SUITES; do
  for run in $(seq 1 "$RUNS"); do
    label="gate-$STAMP-$suite-$run"
    echo "Running suite '$suite', run $run of $RUNS"
    xcrun devicectl device process launch --device "$UDID" --terminate-existing "$BUNDLE" \
      --aqd-agent-eval --aqd-agent-eval-label "$label" --aqd-agent-eval-suite "$suite" >/dev/null
    waited=0
    until copy "AQD-agent-eval-$label-done.json" "$OUT/$label-done.json"; do
      if copy "AQD-agent-eval-$label-error.json" "$OUT/$label-error.json"; then echo "The eval failed: $(cat "$OUT/$label-error.json")" >&2; exit 2; fi
      sleep 20; waited=$((waited + 20))
      if [ "$waited" -ge "$TIMEOUT" ]; then echo "Timed out waiting for '$label'. Is the phone unlocked with AQD in the foreground?" >&2; exit 2; fi
    done
    copy "AQD-agent-eval-$label.json" "$OUT/$label.json"
    REPORTS+=("$OUT/$label.json")
  done
done

LIST="$(IFS=,; echo "${REPORTS[*]}")"
echo "Reports: $OUT"
AQD_AGENT_EVAL_REPORTS="$LIST" swift test --package-path "$ROOT/apps/ios/Core" --filter AgentEvalGateTests/liveReportsClearTheGate
echo "Agent eval gate passed over ${#REPORTS[@]} runs."
