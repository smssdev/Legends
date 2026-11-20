// vue/capstone/ar/size.ts
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
var packageOf = (id) => /node_modules\/((?:@[^/]+\/)?[^/]+)/.exec(id)?.[1] ?? "\u0643\u0648\u062F\u0646\u0627";
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
  else console.log(`\u064A\u064F\u062D\u0645\u064E\u0651\u0644 \u0644\u0627\u062D\u0642\u0627\u064B: ${kb.toFixed(1)} KB gzip (${[...new Set(chunk.moduleIds.map(packageOf))].join(" + ")})`);
}
console.log(`\u0627\u0644\u062A\u062D\u0645\u064A\u0644 \u0627\u0644\u0623\u0648\u0644: ${firstKB.toFixed(1)} KB gzip`);
console.log(firstKB <= BUDGET_KB ? `\u2713 \u0636\u0645\u0646 \u0645\u064A\u0632\u0627\u0646\u064A\u0629 ${BUDGET_KB} KB` : `\u2717 \u0641\u0648\u0642 \u0645\u064A\u0632\u0627\u0646\u064A\u0629 ${BUDGET_KB} KB`);
