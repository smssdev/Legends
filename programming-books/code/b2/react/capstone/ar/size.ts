import { build } from "esbuild";
import { gzipSync } from "node:zlib";

// يحزم التطبيق كما في الإنتاج، ويقارنه بالميزانية
const BUDGET_KB = 150;

const result = await build({
  entryPoints: ["src/main.tsx"],
  bundle: true,
  minify: true,
  splitting: true, // lazy routes become separate files
  format: "esm",
  write: false,
  metafile: true,
  outdir: "dist",
  define: { "process.env.NODE_ENV": '"production"' },
  logLevel: "error",
});
const outputs = result.metafile.outputs;
const gzipKB = (path: string) => gzipSync(result.outputFiles.find((f) => f.path.endsWith(path))!.contents).length / 1024;
const packageOf = (file: string) => /node_modules\/((?:@[^/]+\/)?[^/]+)/.exec(file)?.[1] ?? "كودنا";

// التحميل الأول: ملف البداية وكل ملف يستورده مباشرة
const first = new Set<string>();
const visit = (path: string) => {
  if (first.has(path)) return;
  first.add(path);
  for (const i of outputs[path]!.imports) if (i.kind === "import-statement") visit(i.path);
};
visit("dist/main.js");

let firstKB = 0;
for (const [path, info] of Object.entries(outputs)) {
  const kb = gzipKB(path);
  const packages = [...new Set(Object.keys(info.inputs).map(packageOf))];
  if (first.has(path)) firstKB += kb;
  else console.log(`يُحمَّل لاحقاً: ${kb.toFixed(1)} KB gzip (${packages.join(" + ")})`);
}
console.log(`التحميل الأول: ${firstKB.toFixed(1)} KB gzip`);
console.log(firstKB <= BUDGET_KB ? `✓ ضمن ميزانية ${BUDGET_KB} KB` : `✗ فوق ميزانية ${BUDGET_KB} KB`);
