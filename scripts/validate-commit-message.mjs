import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { pathToFileURL } from "node:url";

const conventional = /^(build|chore|ci|docs|feat|fix|perf|refactor|revert|style|test)(\([a-z0-9][a-z0-9._/-]*\))?!?: \S.*$/u;
const generated = /^(Merge |Revert ")/u;

export function validMessage(message, { isPullRequest = false } = {}) {
  if (typeof message !== "string" || !message.trim()) return false;
  if (isPullRequest && /[\r\n]/u.test(message)) return false;
  const subject = message.split(/\r?\n/u, 1)[0];
  return subject.length <= 100 &&
    (conventional.test(subject) || (!isPullRequest && generated.test(subject)));
}

if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
  try {
    const argument = process.argv[2];
    if (!argument) throw new Error("Expected a commit-message file or --pr-title.");
    const isPullRequest = argument === "--pr-title";
    // Treat PR titles as data; never interpolate them into a shell command.
    const message = isPullRequest
      ? JSON.parse(readFileSync(process.env.GITHUB_EVENT_PATH, "utf8")).pull_request?.title
      : readFileSync(argument, "utf8");
    if (!validMessage(message, { isPullRequest })) {
      throw new Error("Use <type>(optional-scope)!: Summary (100 characters maximum). Example: feat(closet): Add item capture. Put ticket references in the body. See docs/DEVELOPMENT-WORKFLOW.md.");
    }
  } catch (error) {
    console.error(error.message);
    process.exitCode = 1;
  }
}
