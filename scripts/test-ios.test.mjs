import assert from "node:assert/strict";
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { spawnSync } from "node:child_process";
import test from "node:test";

for (const scope of ["unit", "e2e", "all", "selected", "empty", "invalid"]) {
  test(`native runner ${scope} scope invokes the intended tools and test targets`, () => {
    const directory = mkdtempSync(join(tmpdir(), "aqd-runner-"));
    const callsPath = join(directory, "calls.jsonl");
    try {
      // Exercise the actual shell runner, replacing external tools with argument
      // recorders. No simulator, compiler, Photos library or app is contacted.
      for (const command of ["swift", "xcrun", "xcodebuild"]) {
        writeFileSync(join(directory, command), `#!${process.execPath}\nconst fs = require('node:fs'); const path = require('node:path'); fs.appendFileSync(process.env.AQD_RUNNER_CALLS, JSON.stringify({command:path.basename(process.argv[1]),args:process.argv.slice(2)})+'\\n');\n`, { mode: 0o755 });
      }
      const selected = ["AQDUITests/NativeFlowTests/testNativeRootTabsExposeDestinationsTargetsAndSelection", "AQDUITests/NativeFlowTests/testAgentFullScreenBackRestoresCloset"];
      const casesPath = join(directory, "cases.txt");
      writeFileSync(casesPath, scope === "empty" ? "# No selected cases\n" : scope === "invalid" ? "-skip-testing:AQDUITests\n" : selected.join("\n"));
      const result = spawnSync("/bin/bash", ["scripts/test-ios.sh"], { encoding: "utf8", env: {
        ...process.env, PATH: `${directory}:/usr/bin:/bin`, AQD_RUNNER_CALLS: callsPath,
        IOS_TEST_SCOPE: ["selected", "empty", "invalid"].includes(scope) ? "e2e" : scope,
        ...(["selected", "empty", "invalid"].includes(scope) ? { IOS_TEST_CASES_FILE: casesPath, IOS_RESULT_BUNDLE: join(directory, "actual.xcresult") } : {}),
        IOS_DESTINATION: "platform=iOS Simulator,id=11111111-1111-4111-8111-111111111111",
        IOS_PHOTO_DEVICE: "11111111-1111-4111-8111-111111111111", IOS_DERIVED_DATA: join(directory, "derived"),
      } });
      if (["empty", "invalid"].includes(scope)) {
        assert.equal(result.status, 1, result.stderr);
        assert.match(result.stderr, /selected|identifier/i);
        assert.equal(spawnSync("/bin/test", ["-e", callsPath]).status, 1, "Invalid selections must fail before contacting native tools");
        return;
      }
      assert.equal(result.status, 0, result.stderr);
      const calls = readFileSync(callsPath, "utf8").trim().split("\n").map((line) => JSON.parse(line));
      const build = calls.find((call) => call.command === "xcodebuild");
      assert.ok(build);
      assert.deepEqual(build.args.filter((arg) => arg.startsWith("-only-testing:")),
        scope === "selected" ? selected.map((id) => `-only-testing:${id}`) : scope === "unit" ? ["-only-testing:AQDTests"] : scope === "e2e" ? ["-only-testing:AQDUITests"] : []);
      if (scope === "selected") assert.ok(build.args.includes(join(directory, "actual.xcresult")));
      assert.equal(calls.some((call) => call.command === "swift" && call.args[0] === "test"), !["e2e", "selected"].includes(scope));
      assert.equal(calls.some((call) => call.command === "xcrun" && call.args.includes("addmedia")), scope !== "unit");
    } finally { rmSync(directory, { recursive: true, force: true }); }
  });
}
