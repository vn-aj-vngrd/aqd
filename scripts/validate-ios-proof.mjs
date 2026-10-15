import { readFileSync } from "node:fs";
import { pathToFileURL } from "node:url";

export function validateProof(summary, selection, attachments) {
  const cases = selection.split(/\r?\n/).filter((line) => line && !line.startsWith("#"));
  if (!cases.length || new Set(cases).size !== cases.length || cases.some((id) => !/^AQDUITests\/[A-Za-z_][A-Za-z_0-9]*\/test[A-Za-z_0-9]+$/.test(id))) {
    throw new Error("Acceptance selection must contain unique, explicit UI test identifiers");
  }
  if (summary.result !== "Passed" || summary.failedTests !== 0 || summary.skippedTests !== 0 || summary.expectedFailures !== 0 || summary.passedTests !== cases.length || summary.totalTestCount !== cases.length) {
    throw new Error("Every selected acceptance case must actually pass, with no missing, failed, expected-failure or skipped cases");
  }
  const rendered = new Set(attachments.filter((test) => test.attachments.some((item) => item.exportedFileName.endsWith(".png")))
    .map((test) => `AQDUITests/${test.testIdentifier.replace(/\(\)$/, "")}`));
  if (cases.some((id) => !rendered.has(id)) || [...rendered].some((id) => !cases.includes(id))) {
    throw new Error("Rendered attachments must identify every selected UI case and no unexpected cases");
  }
  return cases.length;
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  try {
    const count = validateProof(JSON.parse(readFileSync(process.argv[2], "utf8")), readFileSync(process.argv[3], "utf8"), JSON.parse(readFileSync(process.argv[4], "utf8")));
    console.log(`Verified ${count} executed acceptance cases with rendered attachments. Visual inspection remains required.`);
  } catch (error) {
    console.error(error.message);
    process.exitCode = 1;
  }
}
