// perf/ar/vue/projects/budget.ts
import { readdirSync, readFileSync, statSync } from "node:fs";
import { join } from "node:path";
import { gzipSync } from "node:zlib";
var BUDGET = { js: 60 * 1024, css: 15 * 1024 };
function files(dir) {
  return readdirSync(dir).flatMap((name) => {
    const path = join(dir, name);
    return statSync(path).isDirectory() ? files(path) : [path];
  });
}
var sizes = { js: 0, css: 0 };
for (const file of files(process.argv[2] ?? "../../../../vendor-vue")) {
  const kind = file.endsWith(".js") ? "js" : file.endsWith(".css") ? "css" : null;
  if (kind) sizes[kind] += gzipSync(readFileSync(file)).length;
}
var failed = false;
for (const kind of ["js", "css"]) {
  const over = sizes[kind] > BUDGET[kind];
  failed ||= over;
  const kb = (n) => `${(n / 1024).toFixed(1)} KB`;
  console.log(`${kind.toUpperCase().padEnd(4)} ${kb(sizes[kind]).padStart(9)}  \u0627\u0644\u0645\u064A\u0632\u0627\u0646\u064A\u0629 ${kb(BUDGET[kind]).padStart(8)}  ${over ? "\u2717 \u062A\u062C\u0627\u0648\u0632 \u0627\u0644\u0645\u064A\u0632\u0627\u0646\u064A\u0629" : "\u2713 \u0636\u0645\u0646 \u0627\u0644\u0645\u064A\u0632\u0627\u0646\u064A\u0629"}`);
}
process.exitCode = failed ? 1 : 0;
