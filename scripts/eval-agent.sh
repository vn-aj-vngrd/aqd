#!/bin/bash
# Deterministic synthetic pipeline checks. Live model evaluation is manual in DEBUG AI settings.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPORT_FILE="${1:-/tmp/aqd-agent-evaluations.json}"
AQD_AGENT_EVAL_REPORT="$REPORT_FILE" swift test --package-path "$ROOT/apps/ios/Core" --filter AgentReliabilityEvaluationTests
printf 'Synthetic context evaluation report: %s\nLive model quality was not evaluated.\n' "$REPORT_FILE"
