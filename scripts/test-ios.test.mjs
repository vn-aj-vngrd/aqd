import assert from "node:assert/strict";
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { spawnSync } from "node:child_process";
import test from "node:test";

for (const scope of ["unit", "selected", "empty", "invalid"]) {
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
        ...process.env, GITHUB_ACTIONS: "true", PATH: `${directory}:/usr/bin:/bin`, AQD_RUNNER_CALLS: callsPath,
        IOS_TEST_SCOPE: ["selected", "empty", "invalid"].includes(scope) ? "e2e" : scope,
        ...(["selected", "empty", "invalid"].includes(scope) ? { IOS_TEST_CASES_FILE: casesPath, IOS_RESULT_BUNDLE: join(directory, "actual.xcresult") } : {}),
        IOS_DESTINATION: "platform=iOS,id=00008150-0000000000000000",
        IOS_DEVICE_READY: "1", IOS_DEVELOPMENT_TEAM: "TEAM123456", AQD_E2E_ISSUE: "30",
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
      assert.equal(calls.some((call) => call.command === "xcrun" && call.args.includes("addmedia")), false);
    } finally { rmSync(directory, { recursive: true, force: true }); }
  });
}

test("local native runner refuses missing and simulator destinations before native tools", () => {
  const directory = mkdtempSync(join(tmpdir(), "aqd-local-device-"));
  const callsPath = join(directory, "calls.jsonl");
  try {
    for (const command of ["swift", "xcrun", "xcodebuild", "node"]) {
      writeFileSync(join(directory, command), `#!${process.execPath}\nrequire('node:fs').appendFileSync(process.env.AQD_RUNNER_CALLS, '${command}\\n'); if ('${command}' === 'node') process.stdout.write('platform=iOS Simulator,id=11111111-1111-4111-8111-111111111111\\n');\n`, { mode: 0o755 });
    }
    for (const hosted of ["", "true"]) for (const destination of ["", "platform=iOS Simulator,id=11111111-1111-4111-8111-111111111111"]) {
      const result = spawnSync("/bin/bash", ["scripts/test-ios.sh"], { encoding: "utf8", env: {
        ...process.env, GITHUB_ACTIONS: hosted, PATH: `${directory}:/usr/bin:/bin`,
        AQD_RUNNER_CALLS: callsPath, IOS_DESTINATION: destination, IOS_TEST_SCOPE: "unit",
      } });
      assert.notEqual(result.status, 0, "Local native checks require the explicit physical phone");
      assert.match(result.stderr, /physical iPhone|physical.*destination/i);
      assert.equal(spawnSync("/bin/test", ["-e", callsPath]).status, 1, "Refusal must precede native tools and simulator discovery");
    }
  } finally { rmSync(directory, { recursive: true, force: true }); }
});

test("physical unit runner keeps signing enabled and does not touch Photos or simulator tools", () => {
  const directory = mkdtempSync(join(tmpdir(), "aqd-physical-runner-"));
  const callsPath = join(directory, "calls.jsonl");
  try {
    for (const command of ["swift", "xcrun", "xcodebuild"]) {
      writeFileSync(join(directory, command), `#!${process.execPath}\nconst fs = require('node:fs'); const path = require('node:path'); fs.appendFileSync(process.env.AQD_RUNNER_CALLS, JSON.stringify({command:path.basename(process.argv[1]),args:process.argv.slice(2)})+'\\n');\n`, { mode: 0o755 });
    }
    const result = spawnSync("/bin/bash", ["scripts/test-ios.sh"], { encoding: "utf8", env: {
      ...process.env, GITHUB_ACTIONS: "", PATH: `${directory}:/usr/bin:/bin`, AQD_RUNNER_CALLS: callsPath,
      IOS_DESTINATION: "platform=iOS,id=00008150-0000000000000000", IOS_DEVELOPMENT_TEAM: "TEAM123456",
      IOS_DEVICE_READY: "1", IOS_TEST_SCOPE: "unit", IOS_DERIVED_DATA: join(directory,"derived"),
    } });
    assert.equal(result.status, 0, result.stderr);
    const calls = readFileSync(callsPath,"utf8").trim().split("\n").map(line=>JSON.parse(line));
    const build = calls.find(call=>call.command==="xcodebuild");
    assert.ok(build);
    assert.ok(!build.args.includes("CODE_SIGNING_ALLOWED=NO"), "The physical build must be signable");
    assert.ok(build.args.includes("DEVELOPMENT_TEAM=TEAM123456"));
    assert.equal(calls.some(call=>call.command==="xcrun"),false,"Unit verification must not seed a Photos library");
  } finally { rmSync(directory, { recursive: true, force: true }); }
});

test("local entry points require readiness and preserve focused physical-test boundaries", () => {
  const directory = mkdtempSync(join(tmpdir(), "aqd-device-readiness-"));
  const callsPath = join(directory, "calls");
  try {
    for (const command of ["swift", "xcrun", "xcodebuild", "node"]) {
      writeFileSync(join(directory, command), `#!${process.execPath}\nrequire('node:fs').appendFileSync(process.env.AQD_RUNNER_CALLS, '${command}\\n');\n`, { mode: 0o755 });
    }
    const env = { ...process.env, GITHUB_ACTIONS: "", PATH: `${directory}:/usr/bin:/bin`,
      AQD_RUNNER_CALLS: callsPath, IOS_DESTINATION: "platform=iOS,id=00008150-0000000000000000",
      IOS_DEVICE_READY: "1", IOS_DEVELOPMENT_TEAM: "TEAM123456", AQD_E2E_ISSUE: "30", IOS_TEST_CASES_FILE: "", IOS_TEST_SCOPE: "unit" };
    for (const [script,args,overrides,message] of [
      ["scripts/test-ios.sh",[],{IOS_DEVICE_READY:""},/readiness response/],
      ["scripts/test-ios.sh",[],{IOS_DEVELOPMENT_TEAM:""},/signing identity/],
      ["scripts/test-ios.sh",[],{IOS_TEST_SCOPE:"e2e"},/explicit focused test selection/],

      ["scripts/test-ios.sh",[],{IOS_TEST_SCOPE:"e2e",AQD_E2E_ISSUE:""},/deferred to issue #30/],
      ["scripts/seed-ios-test-photo.sh",["11111111-1111-4111-8111-111111111111"],{},/seeding is disabled/],
    ]) {
      const result=spawnSync("/bin/bash",[script,...args],{encoding:"utf8",env:{...env,...overrides}});
      assert.notEqual(result.status,0,script);
      assert.match(result.stderr,message);
      assert.equal(spawnSync("/bin/test",["-e",callsPath]).status,1,"Readiness refusal must precede native tools");
    }
  } finally { rmSync(directory,{recursive:true,force:true}); }
});
