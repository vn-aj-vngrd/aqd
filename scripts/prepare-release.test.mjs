import assert from "node:assert/strict";
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { spawnSync } from "node:child_process";
import test from "node:test";

const script = resolve("scripts/prepare-release.sh");

function fixture(run) {
  const directory = mkdtempSync(join(tmpdir(), "aqd-release-"));
  const remote = join(directory, "remote.git");
  const local = join(directory, "local");
  function git(...args) {
    const result = spawnSync("git", args, { cwd: local, encoding: "utf8" });
    assert.equal(result.status, 0, result.stderr);
    return result.stdout.trim();
  }
  try {
    assert.equal(spawnSync("git", ["init", "--bare", remote]).status, 0);
    assert.equal(spawnSync("git", ["init", "-b", "main", local]).status, 0);
    git("config", "user.name", "Release fixture");
    git("config", "user.email", "fixture@example.invalid");
    git("config", "commit.gpgsign", "false");
    git("config", "tag.gpgsign", "false");
    git("remote", "add", "origin", remote);
    function commit(name) {
      writeFileSync(join(local, "content.txt"), name);
      git("add", "content.txt");
      git("commit", "-m", `docs: ${name}`);
      return git("rev-parse", "HEAD");
    }
    function prepare(sha) {
      const output = join(directory, "output");
      writeFileSync(output, "");
      const result = spawnSync("bash", [script], { cwd: local, encoding: "utf8",
        env: { ...process.env, RELEASE_SHA: sha, GITHUB_OUTPUT: output,
          GITHUB_STEP_SUMMARY: join(directory, "summary") } });
      return { ...result, output: readFileSync(output, "utf8") };
    }
    run({ git, commit, prepare, local });
  } finally { rmSync(directory, { recursive: true, force: true }); }
}

test("publish successful A while newer main B has not passed CI; retry A safely", () => {
  fixture(({ git, commit, prepare, local }) => {
    const a = commit("Successful A");
    commit("Newer failing B");
    git("push", "origin", "main");
    git("checkout", "--detach", a);
    // Reproduce semantic-release's failed authorization probe against newer main.
    assert.notEqual(spawnSync("git", ["push", "--dry-run", "origin", "HEAD:main"], { cwd: local }).status, 0);
    for (let attempt = 0; attempt < 2; attempt++) {
      const result = prepare(a);
      assert.equal(result.status, 0, result.stderr);
      assert.equal(result.output, "release=true\n");
      assert.ok(git("ls-remote", "origin", "refs/heads/release").startsWith(a));
      assert.equal(spawnSync("git", ["push", "--dry-run", "origin", "HEAD:release"], { cwd: local }).status, 0);
    }
  });
});

test("advance to successful C, refresh tags, and skip delayed A without rewinding", () => {
  fixture(({ git, commit, prepare }) => {
    const a = commit("Successful A");
    git("push", "origin", "main");
    assert.equal(prepare(a).status, 0);
    git("tag", "v1.0.0");
    git("push", "origin", "v1.0.0");
    git("checkout", "main");
    const c = commit("Successful C");
    git("push", "origin", "main");
    git("tag", "-d", "v1.0.0");
    const next = prepare(c);
    assert.equal(next.status, 0, next.stderr);
    assert.equal(next.output, "release=true\n");
    assert.equal(git("rev-parse", "v1.0.0"), a);
    git("checkout", "--detach", a);
    const delayed = prepare(a);
    assert.equal(delayed.status, 0, delayed.stderr);
    assert.equal(delayed.output, "release=false\n");
    assert.ok(git("ls-remote", "origin", "refs/heads/release").startsWith(c));
  });
});

test("mismatched checkout and divergent publication history fail without pushing", () => {
  fixture(({ git, commit, prepare }) => {
    const a = commit("Successful A");
    git("push", "origin", "main");
    const mismatch = prepare("0".repeat(40));
    assert.notEqual(mismatch.status, 0);
    assert.equal(mismatch.output, "");
    assert.equal(prepare(a).status, 0);
    const divergent = commit("Unvalidated publication branch edit");
    git("push", "origin", "release");
    git("checkout", "main");
    const b = commit("Successful B");
    git("push", "origin", "main");
    const result = prepare(b);
    assert.notEqual(result.status, 0);
    assert.equal(result.output, "");
    assert.ok(git("ls-remote", "origin", "refs/heads/release").startsWith(divergent));
  });
});
