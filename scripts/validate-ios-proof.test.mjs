import assert from "node:assert/strict";
import test from "node:test";
import { validateProof } from "./validate-ios-proof.mjs";

const selection = "# Case mapped to an AC\nAQDUITests/NativeFlowTests/testSaveAndRelaunch\n";
const summary = { result: "Passed", failedTests: 0, skippedTests: 0, expectedFailures: 0, passedTests: 1, totalTestCount: 1 };
const attachments = [{ testIdentifier: "NativeFlowTests/testSaveAndRelaunch()", attachments: [{ exportedFileName: "actual.png" }] }];

test("acceptance proof requires actual passes and case-associated rendered attachments", () => {
  assert.equal(validateProof(summary, selection, attachments), 1);
  for (const changed of [{ result: "Failed" }, { skippedTests: 1 }, { expectedFailures: 1 }, { failedTests: 1 }, { passedTests: 0 }, { totalTestCount: 2 }]) {
    assert.throws(() => validateProof({ ...summary, ...changed }, selection, attachments));
  }
  assert.throws(() => validateProof(summary, selection, []));
  assert.throws(() => validateProof(summary, selection, [{ ...attachments[0], testIdentifier: "NativeFlowTests/testWrongCase()" }]));
  assert.throws(() => validateProof(summary, selection, [{ ...attachments[0], attachments: [{ exportedFileName: "geometry.txt" }] }]));
  assert.throws(() => validateProof(summary, "# No cases", attachments));
  assert.throws(() => validateProof(summary, selection + selection, attachments));
});
