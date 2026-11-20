// architecture/ar/vue/boundaries.ts
import { readdirSync, readFileSync, statSync } from "node:fs";
import { dirname, join, relative, resolve } from "node:path";
var root = resolve(process.argv[2] ?? "sample/src");
function files(dir) {
  return readdirSync(dir).flatMap((name) => {
    const path = join(dir, name);
    return statSync(path).isDirectory() ? files(path) : /\.(ts|vue)$/.test(name) ? [path] : [];
  });
}
function where(path) {
  const [layer = "", feature = "", ...rest] = relative(root, path).split("/");
  return { layer, feature: layer === "features" ? feature : "", rest: rest.join("/") };
}
var problems = [];
for (const file of files(root)) {
  const from = where(file);
  for (const [, target] of readFileSync(file, "utf8").matchAll(/from\s+"(\.[^"]+)"/g)) {
    const to = where(resolve(dirname(file), target));
    const at = `${relative(root, file)} \u2192 ${target}`;
    if (from.layer === "shared" && to.layer === "features") problems.push(`${at}
    \u0627\u0644\u0643\u0648\u062F \u0627\u0644\u0645\u0634\u062A\u0631\u0643 \u0644\u0627 \u064A\u0633\u062A\u0648\u0631\u062F \u0645\u064A\u0632\u0629`);
    if (to.layer === "app" && from.layer !== "app") problems.push(`${at}
    \u0644\u0627 \u0634\u064A\u0621 \u064A\u0633\u062A\u0648\u0631\u062F \u0645\u0646 app/`);
    if (from.layer === "features" && to.layer === "features" && from.feature !== to.feature && to.rest !== "") {
      problems.push(`${at}
    \u0627\u0633\u062A\u0648\u0631\u062F \u0645\u064A\u0632\u0629 \u0623\u062E\u0631\u0649 \u0639\u0628\u0631 index.ts \u0627\u0644\u062E\u0627\u0635 \u0628\u0647\u0627 \u0641\u0642\u0637`);
    }
  }
}
for (const p of problems) console.log("\u2717 " + p);
console.log(problems.length === 0 ? "\u0644\u0627 \u0645\u062E\u0627\u0644\u0641\u0627\u062A \u0644\u0644\u062D\u062F\u0648\u062F." : `${problems.length} \u0645\u062E\u0627\u0644\u0641\u0627\u062A`);
process.exitCode = problems.length ? 1 : 0;
