import assert from "node:assert/strict";
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import test from "node:test";
import { checkLayers, imports } from "./check-ios-layers.mjs";

function project(files) {
  const root = mkdtempSync(join(tmpdir(), "aqd-layers-"));
  for (const [path, source] of Object.entries(files)) {
    mkdirSync(dirname(join(root, path)), { recursive: true });
    writeFileSync(join(root, path), source);
  }
  return root;
}

test("imports reads plain, attributed and submodule imports", () => {
  assert.deepEqual(imports("import SwiftUI\n@preconcurrency import UIKit\nimport struct Foo.Bar\nimport Darwin.POSIX\n"), ["SwiftUI", "UIKit", "Foo", "Darwin"]);
});

test("layer rules flag forbidden imports and stray top-level folders", () => {
  const root = project({
    "apps/ios/Core/Sources/AQDCore/A.swift": "import SwiftUI\n",
    "apps/ios/AQD/Persistence/Store.swift": "import SwiftData\n",
    "apps/ios/AQD/Services/Weather/W.swift": "import SwiftData\n",
    "apps/ios/AQD/Features/Closet/ClosetModel.swift": "import SwiftUI\n",
    "apps/ios/AQD/Features/Closet/ClosetView.swift": "import SwiftUI\n",
    "apps/ios/AQD/UI/Old.swift": "import SwiftUI\n",
  });
  try {
    const errors = checkLayers(root);
    assert.equal(errors.length, 4, errors.join("\n"));
    assert.ok(errors.some((error) => error.includes("Core is pure")));
    assert.ok(errors.some((error) => error.includes("Services have no SwiftUI")));
    assert.ok(errors.some((error) => error.includes("ClosetModel.swift")));
    assert.ok(errors.some((error) => error.includes("apps/ios/AQD/UI")));
  } finally { rmSync(root, { recursive: true, force: true }); }
});

test("the repository follows its layer rules", () => {
  assert.deepEqual(checkLayers(), []);
});
