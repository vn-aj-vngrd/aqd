import { readdirSync, readFileSync, existsSync } from "node:fs";
import { join, relative } from "node:path";
import { pathToFileURL } from "node:url";

// Layer rules for apps/ios. Each rule lists frameworks a layer must never import.
// Dependencies flow downward: App → Features → DesignSystem, Services, Persistence → Core.
export const rules = [
  { name: "Core is pure", dir: "apps/ios/Core/Sources", forbid: ["SwiftUI", "UIKit", "SwiftData"] },
  { name: "Persistence has no UI", dir: "apps/ios/AQD/Persistence", forbid: ["SwiftUI", "UIKit"] },
  { name: "Services have no SwiftUI or SwiftData", dir: "apps/ios/AQD/Services", forbid: ["SwiftUI", "SwiftData"] },
  { name: "DesignSystem does not touch storage", dir: "apps/ios/AQD/DesignSystem", forbid: ["SwiftData"] },
  { name: "Features reach storage through AppState", dir: "apps/ios/AQD/Features", forbid: ["SwiftData"] },
  { name: "View models have no SwiftUI", dir: "apps/ios/AQD/Features", match: /Model\.swift$/u, forbid: ["SwiftUI"] },
];

const allowedTopLevel = new Set(["App", "DesignSystem", "Features", "Persistence", "Resources", "Services"]);

function swiftFiles(directory) {
  if (!existsSync(directory)) return [];
  return readdirSync(directory, { withFileTypes: true }).flatMap((entry) => {
    const path = join(directory, entry.name);
    return entry.isDirectory() ? swiftFiles(path) : entry.name.endsWith(".swift") ? [path] : [];
  });
}

export function imports(source) {
  return [...source.matchAll(/^\s*(?:@\w+\s+)*import\s+(?:(?:struct|class|enum|protocol|func|var|let|typealias)\s+)?([A-Za-z_][\w.]*)/gmu)].map((match) => match[1].split(".")[0]);
}

export function checkLayers(root = process.cwd()) {
  const errors = [];
  for (const rule of rules) {
    for (const file of swiftFiles(join(root, rule.dir))) {
      if (rule.match && !rule.match.test(file)) continue;
      const used = imports(readFileSync(file, "utf8"));
      for (const framework of rule.forbid) {
        if (used.includes(framework)) errors.push(`${relative(root, file)}: ${rule.name}; remove import ${framework}`);
      }
    }
  }
  const app = join(root, "apps/ios/AQD");
  if (existsSync(app)) {
    for (const entry of readdirSync(app, { withFileTypes: true })) {
      if (!allowedTopLevel.has(entry.name) && !entry.name.startsWith(".")) errors.push(`apps/ios/AQD/${entry.name}: place it in App, DesignSystem, Features, Persistence, Services or Resources`);
    }
  }
  return errors;
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const errors = checkLayers();
  for (const error of errors) console.error(error);
  console.log(errors.length ? `${errors.length} layering violation(s).` : "iOS layering rules hold.");
  process.exitCode = errors.length ? 1 : 0;
}
