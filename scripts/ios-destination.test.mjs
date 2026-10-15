import assert from "node:assert/strict";
import test from "node:test";
import { mkdtempSync, readFileSync, rmSync, writeFileSync, existsSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { spawnSync } from "node:child_process";
import { parse } from "yaml";
import { selectMvpDestination } from "./ios-destination.mjs";

const uuid = "11111111-1111-4111-8111-111111111111";
const runtime = (version, isAvailable = true) => ({ version, isAvailable, identifier: `com.apple.CoreSimulator.SimRuntime.iOS-${version.replaceAll(".", "-")}` });
const phone = (name = "iPhone 17 Pro Max", isAvailable = true) => ({ name, isAvailable, udid: uuid });

test("MVP destination selects the exact phone with numeric runtime ordering", () => {
  const runtimes = [runtime("27.2"), runtime("27.10"), runtime("28.0", false)];
  const devices = Object.fromEntries(runtimes.map((item) => [item.identifier, [phone()]]));
  const selected = selectMvpDestination({ runtimes, devices });
  assert.equal(selected.os, "27.10");
  assert.equal(selected.destination, `platform=iOS Simulator,id=${uuid}`);
});

test("MVP destination refuses other phones and unavailable/malformed devices", () => {
  const item = runtime("27.0");
  for (const candidate of [phone("iPhone 17 Pro"), phone(undefined, false), { ...phone(), udid: "not-a-uuid" }]) {
    assert.throws(() => selectMvpDestination({ runtimes: [item], devices: { [item.identifier]: [candidate] } }), /No available iPhone 17 Pro Max/u);
  }
  assert.throws(() => selectMvpDestination({}), /Expected simctl inventory/u);
});

test("MVP destination may use an older matching installed runtime and reports its OS", () => {
  const current = runtime("27.0");
  const older = runtime("26.5");
  assert.equal(selectMvpDestination({ runtimes: [current, older], devices: {
    [current.identifier]: [phone("iPhone 18 Pro Max")], [older.identifier]: [phone()],
  } }).os, "26.5");
});

test("hosted selection refuses fallback-only inventories and exports the exact MVP destination", () => {
  const workflow = parse(readFileSync(".github/workflows/ios.yml", "utf8"));
  const selection = workflow.jobs["native-tests"].steps.find((step) => step.name?.startsWith("Select installed"));
  for (const name of ["iPhone 17 Pro", "iPhone 17 Pro Max"]) {
    const directory = mkdtempSync(join(tmpdir(), "aqd-hosted-destination-"));
    try {
      const inventoryPath = join(directory, "inventory.json");
      const envPath = join(directory, "github-env");
      const item = runtime("27.0");
      writeFileSync(inventoryPath, JSON.stringify({ runtimes: [item], devices: { [item.identifier]: [phone(name)] } }));
      writeFileSync(join(directory, "xcrun"), '#!/bin/bash\ncat "$AQD_SIMULATOR_INVENTORY"\n', { mode: 0o755 });
      // Isolate the older workflow's fixed inventory path while executing its
      // actual selection logic. The shared CLI reads the same external fixture.
      const script = selection.run.replaceAll("/tmp/aqd-ci-simulators.json", inventoryPath);
      const result = spawnSync("/bin/bash", ["-e", "-c", script], { encoding: "utf8", env: {
        ...process.env, PATH: `${directory}:${dirname(process.execPath)}:/usr/bin:/bin`,
        AQD_SIMULATOR_INVENTORY: inventoryPath, GITHUB_ENV: envPath, RUNNER_TEMP: directory,
      } });
      if (name !== "iPhone 17 Pro Max") {
        assert.notEqual(result.status, 0, "Acceptance proof must refuse another iPhone");
        assert.equal(existsSync(envPath), false, "A refused inventory must not export a destination");
      } else {
        assert.equal(result.status, 0, result.stderr);
        assert.equal(readFileSync(envPath, "utf8"), `IOS_DESTINATION=platform=iOS Simulator,id=${uuid}\nIOS_DERIVED_DATA=${directory}/aqd-derived\n`);
      }
    } finally { rmSync(directory, { recursive: true, force: true }); }
  }
});
