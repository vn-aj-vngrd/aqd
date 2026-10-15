import { spawnSync } from "node:child_process";
import { resolve } from "node:path";
import { pathToFileURL } from "node:url";

const targetName = "iPhone 17 Pro Max";

export function selectMvpDestination(inventory) {
  if (!Array.isArray(inventory?.runtimes) || !inventory?.devices || typeof inventory.devices !== "object") {
    throw new Error("Expected simctl inventory with runtimes and devices.");
  }
  const runtimes = inventory.runtimes.filter((runtime) => runtime.isAvailable === true &&
    runtime.identifier?.startsWith("com.apple.CoreSimulator.SimRuntime.iOS-") &&
    /^\d+(\.\d+)*$/u.test(runtime.version));
  runtimes.sort((left, right) => {
    const a = left.version.split(".").map(Number);
    const b = right.version.split(".").map(Number);
    for (let index = 0; index < Math.max(a.length, b.length); index++) {
      const difference = (b[index] ?? 0) - (a[index] ?? 0);
      if (difference) return difference;
    }
    return left.identifier.localeCompare(right.identifier);
  });
  for (const runtime of runtimes) {
    const devices = inventory.devices[runtime.identifier];
    if (!Array.isArray(devices)) continue;
    const device = devices.filter((candidate) => candidate.name === targetName && candidate.isAvailable === true &&
      /^[0-9a-f]{8}-(?:[0-9a-f]{4}-){3}[0-9a-f]{12}$/iu.test(candidate.udid))
      .sort((left, right) => left.udid.localeCompare(right.udid))[0];
    if (device) return { name: device.name, os: runtime.version, udid: device.udid,
      destination: `platform=iOS Simulator,id=${device.udid}` };
  }
  throw new Error(`No available ${targetName} simulator on an available iOS runtime. Install the matching simulator or record this check as blocked; no fallback phone was selected.`);
}

if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
  try {
    const args = process.argv.slice(2);
    if (args.length > 1 || (args[0] && !["--json", "--help"].includes(args[0]))) {
      throw new Error("Usage: node scripts/ios-destination.mjs [--json|--help]");
    }
    if (args[0] === "--help") {
      console.log("Select an installed available iPhone 17 Pro Max on the newest available iOS runtime. Prints an xcodebuild destination, or metadata with --json. Does not boot/create devices.");
    } else {
      const result = spawnSync("xcrun", ["simctl", "list", "--json"], { encoding: "utf8", timeout: 15000 });
      if (result.error || result.status !== 0) {
        throw new Error(`Cannot read simulator inventory: ${result.error?.message ?? result.stderr.trim()}. No destination selected.`);
      }
      const selected = selectMvpDestination(JSON.parse(result.stdout));
      console.log(args[0] === "--json" ? JSON.stringify(selected, null, 2) : selected.destination);
    }
  } catch (error) {
    console.error(error.message);
    process.exitCode = 1;
  }
}
