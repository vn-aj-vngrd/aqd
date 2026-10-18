import assert from "node:assert/strict";
import { mkdtempSync, mkdirSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";
import { checkColors } from "./check-ios-colors.mjs";

function project(files) {
  const root = mkdtempSync(join(tmpdir(), "aqd-colors-"));
  for (const [path, text] of Object.entries(files)) {
    const full = join(root, "apps/ios/AQD", path);
    mkdirSync(join(full, ".."), { recursive: true });
    writeFileSync(full, text);
  }
  return root;
}

test("flags literal colors in features and ignores the theme file", () => {
  const root = project({
    "Features/A/A.swift": "Circle().fill(Color.blue)\n",
    "Features/A/B.swift": "Text(\"x\").foregroundStyle(AppTheme.ink)\n",
    "DesignSystem/Foundation/AppTheme.swift": "static let a = color(light: 0xFFFFFF, dark: 0x000000)\n"
  });
  const problems = checkColors(root);
  assert.equal(problems.length, 1);
  assert.match(problems[0], /Features\/A\/A\.swift:1/u);
});
