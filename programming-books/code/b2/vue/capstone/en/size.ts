import { build, type Rollup } from "vite";
import vue from "@vitejs/plugin-vue";
import { gzipSync } from "node:zlib";

// Bundles the app as production would, and checks it against the budget
const BUDGET_KB = 150;

const output = (await build({
  logLevel: "silent",
  plugins: [vue()],
  build: { write: false, rollupOptions: { input: "src/main.ts" } },
})) as Rollup.RolldownOutput;

const chunks = output.output.filter((file) => file.type === "chunk");
const gzipKB = (code: string) => gzipSync(code).length / 1024;
const packageOf = (id: string) => /node_modules\/((?:@[^/]+\/)?[^/]+)/.exec(id)?.[1] ?? "our code";

// The first load: the entry and every chunk it imports directly
const first = new Set<string>();
const visit = (fileName: string) => {
  if (first.has(fileName)) return;
  first.add(fileName);
  for (const imported of chunks.find((c) => c.fileName === fileName)?.imports ?? []) visit(imported);
};
visit(chunks.find((c) => c.isEntry)!.fileName);

let firstKB = 0;
for (const chunk of chunks) {
  const kb = gzipKB(chunk.code);
  if (first.has(chunk.fileName)) firstKB += kb;
  else console.log(`loaded later: ${kb.toFixed(1)} KB gzip (${[...new Set(chunk.moduleIds.map(packageOf))].join(" + ")})`);
}
console.log(`first load: ${firstKB.toFixed(1)} KB gzip`);
console.log(firstKB <= BUDGET_KB ? `✓ under the budget of ${BUDGET_KB} KB` : `✗ over the budget of ${BUDGET_KB} KB`);
