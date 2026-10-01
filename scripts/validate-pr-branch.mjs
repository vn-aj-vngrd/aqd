import { readFileSync } from "node:fs";

const event = JSON.parse(readFileSync(process.env.GITHUB_EVENT_PATH, "utf8"));
const branch = event.pull_request?.head?.ref ?? "";
const author = event.pull_request?.user;
const taskBranch = /^van\/(?:issue-[1-9]\d*\/)?[a-z0-9]+(?:-[a-z0-9]+)*$/u;
const managedBot = author?.type === "Bot" && /^(dependabot|renovate)\//u.test(branch);
if (!taskBranch.test(branch) && !managedBot) {
  console.error("Use van/issue-<real-number>/<kebab-description> or van/<kebab-description>. See docs/delivery/workflow.md.");
  process.exitCode = 1;
}
