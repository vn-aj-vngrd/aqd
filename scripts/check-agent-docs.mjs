import { existsSync, readFileSync, readdirSync, statSync } from "node:fs";
import { dirname, extname, join, resolve } from "node:path";
import { pathToFileURL } from "node:url";
import { parse } from "yaml";

function markdownFiles(directory) {
  if (!existsSync(directory)) return [];
  return readdirSync(directory, { withFileTypes: true }).flatMap((entry) => {
    const path = join(directory, entry.name);
    return entry.isDirectory() ? markdownFiles(path) : entry.name.endsWith(".md") ? [path] : [];
  });
}

function prose(source) {
  return source.replace(/^(`{3,}|~{3,})[^\n]*\n[\s\S]*?^\1\s*$/gmu, "");
}

function anchors(source) {
  const counts = new Map();
  const result = new Set();
  for (const match of prose(source).matchAll(/^#{1,6}\s+(.+?)\s*#*$/gmu)) {
    const slug = match[1].toLowerCase().replace(/<[^>]*>/gu, "").replace(/[^\p{L}\p{N}\p{M}_\-\s]/gu, "").replace(/\s/gu, "-");
    const count = counts.get(slug) ?? 0;
    counts.set(slug, count + 1);
    result.add(count ? `${slug}-${count}` : slug);
  }
  for (const match of source.matchAll(/<(?:a|\w+)\s+[^>]*(?:id|name)=["']([^"']+)["']/gu)) result.add(match[1]);
  return result;
}

export function checkDocuments(paths) {
  const errors = [];
  let links = 0;
  let fragments = 0;
  for (const path of paths) {
    const source = readFileSync(path, "utf8");
    if (path.endsWith("/SKILL.md")) {
      try {
        const frontmatter = source.match(/^---\n([\s\S]*?)\n---/u);
        if (!frontmatter) throw new Error("Missing skill frontmatter");
        const metadata = parse(frontmatter[1]);
        if (metadata.name !== dirname(path).split("/").at(-1) || !/^[a-z0-9-]{1,64}$/u.test(metadata.name)) throw new Error("Skill name must match its folder");
        if (typeof metadata.description !== "string" || !metadata.description.trim()) throw new Error("Missing skill description");
      } catch (error) { errors.push(`${path}: ${error.message}`); }
    }
    for (const match of prose(source).matchAll(/!?\[[^\]\n]*\]\((<[^>\n]+>|[^\s)]+)(?:\s+"[^"]*")?\)/gu)) {
      const reference = match[1].replace(/^<|>$/gu, "");
      if (/^(?:[a-z][a-z\d+.-]*:|\/)/iu.test(reference)) continue;
      const [relative, fragment] = reference.split("#", 2);
      let target;
      try { target = relative ? resolve(dirname(path), decodeURIComponent(relative)) : resolve(path); }
      catch { errors.push(`${path}: malformed link ${reference}`); continue; }
      links++;
      if (!existsSync(target)) { errors.push(`${path}: missing ${reference}`); continue; }
      if (fragment && extname(target) === ".md" && statSync(target).isFile()) {
        fragments++;
        let decoded;
        try { decoded = decodeURIComponent(fragment); }
        catch { errors.push(`${path}: malformed fragment ${reference}`); continue; }
        if (!anchors(readFileSync(target, "utf8")).has(decoded)) errors.push(`${path}: missing anchor ${reference}`);
      }
    }
  }
  return { files: paths.length, links, fragments, errors };
}

export function repositoryDocuments(root = process.cwd()) {
  return [...readdirSync(root).filter((name) => name.endsWith(".md")).map((name) => join(root, name)),
    ...markdownFiles(join(root, "docs")), ...markdownFiles(join(root, ".agents/skills")),
    ...readdirSync(join(root, "apps/ios")).filter((name) => name.endsWith(".md")).map((name) => join(root, "apps/ios", name))];
}

if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
  const result = checkDocuments(repositoryDocuments());
  console.log(`Checked ${result.files} Markdown files, ${result.links} local links and ${result.fragments} heading fragments.`);
  for (const error of result.errors) console.error(error);
  process.exitCode = result.errors.length ? 1 : 0;
}
