import assert from "node:assert/strict";
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { spawnSync } from "node:child_process";
import test from "node:test";
import { analyzeCommits } from "@semantic-release/commit-analyzer";
import { generateNotes } from "@semantic-release/release-notes-generator";
import { parse } from "yaml";
import { validMessage } from "./validate-commit-message.mjs";

const config = JSON.parse(readFileSync(".releaserc.json", "utf8"));
const pluginOptions = (name) => config.plugins.find(([plugin]) => plugin === name)[1];
const logger = { log() {}, error() {} };

for (const message of [
  "feat: Add closet", "fix(planner): Preserve dates", "chore: Update tools",
  "docs: Refine scope", "refactor(core)!: Change ownership",
  "feat: Change schema\n\nBREAKING CHANGE: Replace the ownership format",
  "fix: Resolve duplicate wears\r\n\r\nDetails",
]) {
  test(`accept conventional message: ${message.split("\n")[0]}`, () => {
    assert.equal(validMessage(message), true);
  });
}

for (const message of ["", "Add closet", "feat:", "feat:  ", "Feat: Add closet",
  "feature: Add closet", "feat(Closet): Add closet", "feat: " + "x".repeat(100)]) {
  test(`reject invalid subject: ${JSON.stringify(message)}`, () => {
    assert.equal(validMessage(message), false);
  });
}

test("maintenance messages are local-only; PR titles must be one line", () => {
  for (const subject of ["Merge branch 'main'", 'Revert "Previous change"']) {
    assert.equal(validMessage(subject), true);
    assert.equal(validMessage(subject, { isPullRequest: true }), false);
  }
  assert.equal(validMessage("feat: Add closet\nExtra", { isPullRequest: true }), false);
});

test("CLI reads PR titles as data and rejects missing/invalid metadata", () => {
  const directory = mkdtempSync(join(tmpdir(), "aqd-commits-"));
  try {
    const eventPath = join(directory, "event.json");
    for (const [title, status] of [["feat: Add `code` $(data)", 0], ["Add closet", 1], [null, 1]]) {
      writeFileSync(eventPath, JSON.stringify({ pull_request: { title } }));
      const result = spawnSync(process.execPath, ["scripts/validate-commit-message.mjs", "--pr-title"], {
        env: { ...process.env, GITHUB_EVENT_PATH: eventPath }, encoding: "utf8",
      });
      assert.equal(result.status, status, result.stderr);
    }
    const messagePath = join(directory, "message.txt");
    writeFileSync(messagePath, "fix(closet): Keep item identity\n\nDetails");
    assert.equal(spawnSync(process.execPath, ["scripts/validate-commit-message.mjs", messagePath]).status, 0);
    assert.equal(spawnSync(process.execPath, ["scripts/validate-commit-message.mjs"]).status, 1);
  } finally { rmSync(directory, { recursive: true, force: true }); }
});

for (const [message, expected] of [
  ["feat: Add closet", "minor"], ["fix: Preserve drafts", "patch"],
  ["docs: Refine product", "patch"], ["chore: Update dependencies", "patch"],
  ["ci: Add release workflow", "patch"], ["refactor!: Replace data format", "major"],
  ["fix: Change storage\n\nBREAKING CHANGE: Existing data requires migration", "major"],
]) {
  test(`actual release analyzer: ${expected} for ${message.split("\n")[0]}`, async () => {
    const release = await analyzeCommits(pluginOptions("@semantic-release/commit-analyzer"), {
      cwd: process.cwd(), logger, commits: [{ message }],
    });
    assert.equal(release, expected);
  });
}

test("strongest change wins and an empty range produces no release", async () => {
  const options = pluginOptions("@semantic-release/commit-analyzer");
  assert.equal(await analyzeCommits(options, { cwd: process.cwd(), logger, commits: [] }), null);
  assert.equal(await analyzeCommits(options, { cwd: process.cwd(), logger,
    commits: [{ message: "chore: Update tooling" }, { message: "feat: Add planner" }] }), "minor");
});

test("release notes retain feature, documentation, and maintenance entries", async () => {
  const notes = await generateNotes(pluginOptions("@semantic-release/release-notes-generator"), {
    cwd: process.cwd(), logger, options: { repositoryUrl: "https://github.com/example/aqd.git" },
    lastRelease: { version: "1.0.0", gitTag: "v1.0.0" },
    nextRelease: { version: "1.1.0", gitTag: "v1.1.0" },
    commits: ["feat: Add planner", "docs: Refine wardrobe", "chore: Update tooling"].map((message, index) => ({
      message, hash: String(index + 1).repeat(40),
    })),
  });
  for (const text of ["Add planner", "Refine wardrobe", "Update tooling"]) assert.ok(notes.includes(text), notes);
});

test("workflow publishes only after successful trusted main push CI", () => {
  const ci = parse(readFileSync(".github/workflows/ci.yml", "utf8"));
  const release = parse(readFileSync(".github/workflows/release.yml", "utf8"));
  assert.equal(ci.name, "CI");
  assert.deepEqual(ci.on.push.branches, ["main"]);
  assert.ok(ci.on.pull_request.types.includes("edited"));
  assert.deepEqual(release.on.workflow_run.workflows, [ci.name]);
  assert.deepEqual(release.on.workflow_run.branches, ["main"]);
  const job = release.jobs.release;
  for (const guard of ["conclusion == 'success'", "event == 'push'", "head_repository.full_name == github.repository"]) {
    assert.ok(job.if.includes(guard));
  }
  assert.equal(release.permissions.contents, "read");
  assert.equal(job.permissions.contents, "write");
  assert.equal(release.concurrency["cancel-in-progress"], false);
  assert.equal(job.steps[0].with["fetch-depth"], 0);
  assert.equal(job.steps[0].with.ref, "${{ github.event.workflow_run.head_sha }}");
  const current = job.steps.find((step) => step.id === "current");
  assert.equal(current.run, "bash scripts/prepare-release.sh");
  assert.equal(current.env.RELEASE_SHA, "${{ github.event.workflow_run.head_sha }}");
  const publish = job.steps.find((step) => step.run?.includes("pnpm exec semantic-release"));
  assert.equal(publish.if, "steps.current.outputs.release == 'true'");
  assert.equal(publish.env.GITHUB_TOKEN, "${{ secrets.GITHUB_TOKEN }}");
  assert.ok(publish.run.includes("git tag --points-at HEAD"));
  assert.ok(publish.run.includes("gh release view"));
  assert.ok(publish.run.includes("select(.isDraft == false)"));
  assert.ok(publish.run.includes("export GITHUB_REF=refs/heads/release"));
  assert.deepEqual(config.branches, ["release"]);
  assert.equal(config.tagFormat, "v${version}");
  assert.ok(!config.plugins.some(([name]) => ["@semantic-release/npm", "@semantic-release/git"].includes(name)));
});

test("push guard checks destination refs, including deletion and multi-ref pushes", async () => {
  const { protectedDestinations } = await import("./validate-push.mjs");
  const sha = "a".repeat(40);
  assert.deepEqual(protectedDestinations(`refs/heads/van/task ${sha} refs/heads/main ${sha}`), ["refs/heads/main"]);
  assert.deepEqual(protectedDestinations(`(delete) ${"0".repeat(40)} refs/heads/master ${sha}`), ["refs/heads/master"]);
  assert.deepEqual(protectedDestinations(`refs/heads/van/task ${sha} refs/heads/van/task ${sha}\nrefs/tags/v1.0.0 ${sha} refs/tags/v1.0.0 ${sha}`), []);
  assert.deepEqual(protectedDestinations(""), []);
  assert.equal(spawnSync(process.execPath, ["scripts/validate-push.mjs"], {
    input: `refs/heads/van/task ${sha} refs/heads/main ${sha}`,
  }).status, 1);
});

test("PR branches validate task naming and allow only managed bot exceptions", () => {
  const directory = mkdtempSync(join(tmpdir(), "aqd-branches-"));
  try {
    const eventPath = join(directory, "event.json");
    for (const [branch, type, status] of [
      ["van/project-foundation", "User", 0], ["van/issue-12/item-capture", "User", 0],
      ["feature/test", "User", 1], ["van/issue-0/test", "User", 1],
      ["van/Bad-Name", "User", 1], ["dependabot/npm/deps", "User", 1],
      ["dependabot/npm/deps", "Bot", 0],
    ]) {
      writeFileSync(eventPath, JSON.stringify({ pull_request: { head: { ref: branch }, user: { type } } }));
      const result = spawnSync(process.execPath, ["scripts/validate-pr-branch.mjs"], {
        env: { ...process.env, GITHUB_EVENT_PATH: eventPath }, encoding: "utf8",
      });
      assert.equal(result.status, status, result.stderr);
    }
  } finally { rmSync(directory, { recursive: true, force: true }); }
});

test("issue forms and PR template load with useful completion/evidence fields", () => {
  for (const name of ["feature", "bug", "maintenance"]) {
    const form = parse(readFileSync(`.github/ISSUE_TEMPLATE/${name}.yml`, "utf8"));
    assert.ok(form.labels.includes("needs-triage"));
    assert.ok(form.body.some((field) => field.validations?.required));
  }
  const template = readFileSync(".github/pull_request_template.md", "utf8");
  assert.ok(template.includes("Action and reason"));
  assert.ok(template.includes("Verification and result"));
  const hook = parse(readFileSync("lefthook.yml", "utf8"));
  assert.equal(hook["pre-push"].commands["protected-branches"].use_stdin, true);
});
