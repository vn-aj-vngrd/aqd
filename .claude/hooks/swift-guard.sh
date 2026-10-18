#!/bin/sh
# After an edit to a Swift file: format it (whitespace only) and enforce the layer rules.
# Exit 2 sends the layer violations back to the agent.
root="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel)}"
file=$(python3 -c 'import json,sys; print(json.load(sys.stdin).get("tool_input",{}).get("file_path",""))' 2>/dev/null)
case "$file" in
  */apps/ios/*.swift) ;;
  *) exit 0 ;;
esac
command -v swiftformat >/dev/null && swiftformat --config "$root/apps/ios/.swiftformat" "$file" >/dev/null 2>&1
output=$(cd "$root" && node scripts/check-ios-layers.mjs 2>&1) || { printf '%s\n' "$output" >&2; exit 2; }
exit 0
