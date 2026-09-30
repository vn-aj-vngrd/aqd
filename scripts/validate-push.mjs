import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { pathToFileURL } from "node:url";

export function protectedDestinations(input) {
  return input.trim().split(/\r?\n/u).filter(Boolean)
    .map((line) => line.trim().split(/\s+/u)[2])
    .filter((ref) => ref === "refs/heads/main" || ref === "refs/heads/master");
}

if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
  const refs = protectedDestinations(readFileSync(0, "utf8"));
  if (refs.length) {
    console.error(`Direct updates/deletions to ${refs.join(", ")} are blocked. Push a feature branch and use a squash PR.`);
    process.exitCode = 1;
  }
}
