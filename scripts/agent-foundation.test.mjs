import assert from "node:assert/strict";
import { mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { tmpdir } from "node:os";
import test from "node:test";
import { checkDocuments, repositoryDocuments } from "./check-agent-docs.mjs";

test("documentation checks actual links, anchors, duplicates and fenced examples", () => {
  const directory = mkdtempSync(join(tmpdir(), "aqd-docs-"));
  try {
    const target = join(directory, "target.md");
    const source = join(directory, "source.md");
    writeFileSync(target, "# Target\n## Repeated heading\n## Repeated heading\n");
    writeFileSync(source, "[Valid](target.md#repeated-heading-1)\n[Missing](absent.md)\n[Bad anchor](target.md#missing)\n```md\n[Example](ignored.md)\n```\n");
    const result = checkDocuments([source]);
    assert.equal(result.links, 3);
    assert.equal(result.errors.length, 2);
    assert.ok(result.errors.some((error) => error.includes("absent.md")));
    assert.ok(result.errors.some((error) => error.includes("#missing")));
  } finally { rmSync(directory, { recursive: true, force: true }); }
});

test("repository Markdown and repo-local skills have resolvable links and metadata", () => {
  assert.deepEqual(checkDocuments(repositoryDocuments()).errors, []);
});
