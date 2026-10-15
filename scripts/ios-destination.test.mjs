import assert from "node:assert/strict";
import test from "node:test";
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
