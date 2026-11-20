// vue/capstone/en/size.ts
import { build } from "vite";
import vue from "@vitejs/plugin-vue";
import { gzipSync } from "node:zlib";
var BUDGET_KB = 150;
var output = await build({
  logLevel: "silent",
  plugins: [vue()],
  build: { write: false, rollupOptions: { input: "src/main.ts" } }
});
var chunks = output.output.filter((file) => file.type === "chunk");
var gzipKB = (code) => gzipSync(code).length / 1024;
var packageOf = (id) => /node_modules\/((?:@[^/]+\/)?[^/]+)/.exec(id)?.[1] ?? "our code";
var first = /* @__PURE__ */ new Set();
var visit = (fileName) => {
  if (first.has(fileName)) return;
  first.add(fileName);
  for (const imported of chunks.find((c) => c.fileName === fileName)?.imports ?? []) visit(imported);
};
visit(chunks.find((c) => c.isEntry).fileName);
var firstKB = 0;
for (const chunk of chunks) {
  const kb = gzipKB(chunk.code);
  if (first.has(chunk.fileName)) firstKB += kb;
  else console.log(`loaded later: ${kb.toFixed(1)} KB gzip (${[...new Set(chunk.moduleIds.map(packageOf))].join(" + ")})`);
}
console.log(`first load: ${firstKB.toFixed(1)} KB gzip`);
console.log(firstKB <= BUDGET_KB ? `\u2713 under the budget of ${BUDGET_KB} KB` : `\u2717 over the budget of ${BUDGET_KB} KB`);
