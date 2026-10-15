import assert from "node:assert/strict";
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { spawnSync } from "node:child_process";
import test from "node:test";

for (const scope of ["unit", "e2e", "all"]) {
  test(`native runner ${scope} scope invokes the intended tools and test targets`, () => {
    const directory = mkdtempSync(join(tmpdir(), "aqd-runner-"));
    const callsPath = join(directory, "calls.jsonl");
    try {
      // Exercise the actual shell runner, replacing external tools with argument
      // recorders. No simulator, compiler, Photos library or app is contacted.
      for (const command of ["swift", "xcrun", "xcodebuild"]) {
        writeFileSync(join(directory, command), `#!${process.execPath}\nconst fs = require('node:fs'); const path = require('node:path'); fs.appendFileSync(process.env.AQD_RUNNER_CALLS, JSON.stringify({command:path.basename(process.argv[1]),args:process.argv.slice(2)})+'\\n');\n`, { mode: 0o755 });
      }
      const result = spawnSync("/bin/bash", ["scripts/test-ios.sh"], { encoding: "utf8", env: {
        ...process.env, PATH: `${directory}:/usr/bin:/bin`, AQD_RUNNER_CALLS: callsPath,
        IOS_TEST_SCOPE: scope, IOS_DESTINATION: "platform=iOS Simulator,id=11111111-1111-4111-8111-111111111111",
        IOS_PHOTO_DEVICE: "11111111-1111-4111-8111-111111111111", IOS_DERIVED_DATA: join(directory, "derived"),
      } });
      assert.equal(result.status, 0, result.stderr);
      const calls = readFileSync(callsPath, "utf8").trim().split("\n").map((line) => JSON.parse(line));
      const build = calls.find((call) => call.command === "xcodebuild");
      assert.ok(build);
      assert.deepEqual(build.args.filter((arg) => arg.startsWith("-only-testing:")),
        scope === "unit" ? ["-only-testing:AQDTests"] : scope === "e2e" ? ["-only-testing:AQDUITests"] : []);
      assert.equal(calls.some((call) => call.command === "swift" && call.args[0] === "test"), scope !== "e2e");
      assert.equal(calls.some((call) => call.command === "xcrun" && call.args.includes("addmedia")), scope !== "unit");
    } finally { rmSync(directory, { recursive: true, force: true }); }
  });
}
