import { spawnSync } from "node:child_process";
import { existsSync } from "node:fs";

// CI and source archives do not need local Git hooks.
if (!process.env.CI && existsSync(".git")) {
  const result = spawnSync("lefthook", ["install"], {
    stdio: "inherit",
    shell: process.platform === "win32",
  });
  if (result.error) throw result.error;
  if (result.status !== 0) process.exit(result.status ?? 1);
}
