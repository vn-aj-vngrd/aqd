import { readdirSync, readFileSync, existsSync } from "node:fs";
import { join, relative } from "node:path";

// Every color in the app comes from AppTheme tokens. This flags literal colors in UI code so a one-off value cannot slip in.
const files = (directory) => !existsSync(directory) ? [] : readdirSync(directory, { withFileTypes: true }).flatMap((entry) => {
  const path = join(directory, entry.name);
  return entry.isDirectory() ? files(path) : entry.name.endsWith(".swift") ? [path] : [];
});

const exempt = [/DesignSystem\/Foundation\/AppTheme\.swift$/u, /\/App\/Debug\//u, /\/Services\/Media\//u];
const literals = [
  /Color\((?:red|white|hue)\s*:/u, /Color\(\.sRGB/u, /UIColor\((?:red|white|hue)\s*:/u,
  /Color\.(?:white|black|gray|red|blue|green|orange|yellow|pink|purple)\b/u, /UIColor\.(?:white|black|gray|red|blue|green|orange|yellow|pink|purple|system\w+)\b/u,
  /(?:foregroundStyle|foregroundColor|tint|fill|stroke|background)\(\s*\.(?:white|black|gray|red|blue|green|orange|yellow|pink|purple)\b/u,
  /(?:textColor|tintColor|backgroundColor)\s*=\s*\.(?:white|black|gray|red|blue|green|orange|yellow|pink|purple)\b/u, /0x[0-9A-Fa-f]{6}\b/u
];

export function checkColors(root = process.cwd()) {
  const problems = [];
  for (const file of files(join(root, "apps/ios/AQD"))) {
    if (exempt.some((pattern) => pattern.test(file))) continue;
    readFileSync(file, "utf8").split("\n").forEach((line, index) => {
      if (/^\s*\/\//u.test(line)) return;
      if (literals.some((pattern) => pattern.test(line))) problems.push(`${relative(root, file)}:${index + 1}: use an AppTheme color token instead of a literal color`);
    });
  }
  return problems;
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const problems = checkColors();
  if (problems.length) { console.error(problems.join("\n")); process.exit(1); }
  console.log("iOS colors come from AppTheme tokens.");
}
