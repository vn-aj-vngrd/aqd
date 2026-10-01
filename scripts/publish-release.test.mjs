import assert from "node:assert/strict";
import { chmodSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { delimiter, join, resolve } from "node:path";
import { spawnSync } from "node:child_process";
import test from "node:test";

const script = resolve("scripts/publish-release.sh");

function fixture(run) {
  const directory = mkdtempSync(join(tmpdir(), "aqd-publish-"));
  const local = join(directory, "local");
  const remote = join(directory, "remote.git");
  function git(...args) {
    const result = spawnSync("git", args, { cwd: local, encoding: "utf8" });
    assert.equal(result.status, 0, result.stderr);
    return result.stdout.trim();
  }
  try {
    assert.equal(spawnSync("git", ["init", "--bare", remote]).status, 0);
    assert.equal(spawnSync("git", ["init", "-b", "release", local]).status, 0);
    git("config", "user.name", "Publication fixture");
    git("config", "user.email", "fixture@example.invalid");
    git("config", "commit.gpgsign", "false");
    git("config", "tag.gpgsign", "false");
    git("remote", "add", "origin", remote);
    writeFileSync(join(local, "content.txt"), "Validated commit");
    git("add", "content.txt");
    git("commit", "-m", "docs: Validated commit");
    git("push", "origin", "release");
    writeFileSync(join(directory, "pnpm"), `#!/usr/bin/env bash
set -euo pipefail
printf 'semantic-release\\n' >> "$FIXTURE_LOG"
test "$GITHUB_REF" = refs/heads/release
test "$GITHUB_SHA" = "$(git rev-parse HEAD)"
if [[ "\${NO_TAG:-}" == 1 ]]; then exit 0; fi
git tag v1.0.0
git push origin v1.0.0
if [[ "\${SEMANTIC_FAIL:-}" == 1 ]]; then exit 1; fi
`);
    writeFileSync(join(directory, "gh"), `#!/usr/bin/env bash
set -euo pipefail
if [[ "$2" == view ]]; then
  test -f "$FIXTURE_RELEASE"
  if [[ "$(cat "$FIXTURE_RELEASE")" == draft ]]; then
    if [[ "$*" == *select* ]]; then :
    elif [[ "$*" == *--jq* ]]; then echo true
    else echo '{"isDraft":true,"tagName":"v1.0.0"}'; fi
  elif [[ "$*" == *select* ]]; then echo v1.0.0
  elif [[ "$*" == *--jq* ]]; then echo false
  else echo '{"isDraft":false,"tagName":"v1.0.0"}'; fi
elif [[ "$2" == edit ]]; then
  [[ "$*" == *--draft=false* ]]
  if [[ "\${EDIT_FAIL:-}" == 1 ]]; then exit 1; fi
  printf 'publish-draft\\n' >> "$FIXTURE_LOG"
  printf published > "$FIXTURE_RELEASE"
elif [[ "$2" == create ]]; then
  test "$3" = v1.0.0
  [[ "$*" == *--verify-tag* && "$*" == *--generate-notes* ]]
  git ls-remote --exit-code origin refs/tags/v1.0.0 > /dev/null
  if [[ "\${CREATE_FAIL:-}" == 1 ]]; then exit 1; fi
  printf 'create-release\\n' >> "$FIXTURE_LOG"
  touch "$FIXTURE_RELEASE"
else exit 1; fi
`);
    for (const name of ["pnpm", "gh"]) chmodSync(join(directory, name), 0o755);
    const log = join(directory, "calls");
    writeFileSync(log, "");
    const release = join(directory, "published");
    function publish(overrides = {}) {
      return spawnSync("bash", [script], { cwd: local, encoding: "utf8", env: {
        ...process.env, PATH: directory + delimiter + process.env.PATH,
        FIXTURE_LOG: log, FIXTURE_RELEASE: release, ...overrides,
      } });
    }
    run({ git, publish, calls: () => readFileSync(log, "utf8"), release });
  } finally { rmSync(directory, { recursive: true, force: true }); }
}

test("recover existing exact-HEAD tag after semantic-release GitHub publication failed", () => {
  fixture(({ git, publish, calls }) => {
    assert.notEqual(publish({ SEMANTIC_FAIL: "1" }).status, 0);
    const original = git("rev-parse", "v1.0.0");
    const retry = publish();
    assert.equal(retry.status, 0, retry.stderr);
    assert.equal(git("rev-parse", "v1.0.0"), original);
    assert.equal(original, git("rev-parse", "HEAD"));
    assert.equal(calls(), "semantic-release\ncreate-release\n");
  });
});

test("publish new release and retry without generating or creating it twice", () => {
  fixture(({ publish, calls }) => {
    for (let attempt = 0; attempt < 2; attempt++) {
      const result = publish();
      assert.equal(result.status, 0, result.stderr);
    }
    assert.equal(calls(), "semantic-release\ncreate-release\n");
  });
});

test("GitHub creation outage fails then recovers without changing the tag", () => {
  fixture(({ git, publish, calls }) => {
    assert.notEqual(publish({ CREATE_FAIL: "1" }).status, 0);
    const original = git("rev-parse", "v1.0.0");
    const retry = publish();
    assert.equal(retry.status, 0, retry.stderr);
    assert.equal(git("rev-parse", "v1.0.0"), original);
    assert.equal(calls(), "semantic-release\ncreate-release\n");
  });
});

test("missing version tag fails; draft publication outage fails then recovers", () => {
  fixture(({ publish, calls, release }) => {
    assert.notEqual(publish({ NO_TAG: "1" }).status, 0);
    assert.equal(calls(), "semantic-release\n");
    const initial = publish();
    assert.equal(initial.status, 0, initial.stderr);
    writeFileSync(release, "draft");
    assert.notEqual(publish({ EDIT_FAIL: "1" }).status, 0);
    const retry = publish();
    assert.equal(retry.status, 0, retry.stderr);
    assert.equal(calls(), "semantic-release\nsemantic-release\ncreate-release\npublish-draft\n");
  });
});
