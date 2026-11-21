import { readFileSync, readdirSync } from "node:fs";
import { dirname, join, normalize, relative } from "node:path";

const root = "app";
const files = readdirSync(root, { recursive: true, encoding: "utf8" })
  .filter((f) => f.endsWith(".ts"))
  .map((f) => join(root, f));
const moduleOf = (file: string) => relative(root, file).split("/")[0]!;

const broken: string[] = [];
// every import with a relative path, and the module it lands in
const imports = /from "(\.[^"]+)"/g;
for (const file of files) {
  const from = moduleOf(file);
  for (const [, path] of readFileSync(file, "utf8").matchAll(imports)) {
    const target = normalize(join(dirname(file), path!));
    const to = moduleOf(target);
    if (to === from) continue;
    // shared code depends on no module
    if (from === "shared")
      broken.push(`${file} → ${to}\n    shared code must not import a module`);
    // a module may use another module only through its index.ts
    else if (to !== "shared" && !target.endsWith(`${to}/index.ts`))
      broken.push(`${file} → ${path}\n    go through ${to}/index.ts`);
  }
}
if (broken.length) {
  console.log(`architecture rules broken: ${broken.length}`);
  for (const line of broken) console.log("  " + line);
  process.exit(1);
}
console.log("architecture rules: ok");
