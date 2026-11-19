import { build, type Rollup } from "vite";
import vue from "@vitejs/plugin-vue";
import { gzipSync } from "node:zlib";

// يحزم التطبيق كما في الإنتاج، ويقارنه بالميزانية
const BUDGET_KB = 150;

const output = (await build({
  logLevel: "silent",
  plugins: [vue()],
  build: { write: false, rollupOptions: { input: "src/main.ts" } },
})) as Rollup.RolldownOutput;

const chunks = output.output.filter((file) => file.type === "chunk");
const gzipKB = (code: string) => gzipSync(code).length / 1024;
const packageOf = (id: string) => /node_modules\/((?:@[^/]+\/)?[^/]+)/.exec(id)?.[1] ?? "كودنا";

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
  else console.log(`يُحمَّل لاحقاً: ${kb.toFixed(1)} KB gzip (${[...new Set(chunk.moduleIds.map(packageOf))].join(" + ")})`);
}
console.log(`التحميل الأول: ${firstKB.toFixed(1)} KB gzip`);
console.log(firstKB <= BUDGET_KB ? `✓ ضمن ميزانية ${BUDGET_KB} KB` : `✗ فوق ميزانية ${BUDGET_KB} KB`);
