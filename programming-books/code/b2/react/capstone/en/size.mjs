// code/b2/react/capstone/en/size.ts
import { build } from "esbuild";
import { gzipSync } from "node:zlib";
var BUDGET_KB = 150;
var result = await build({
  entryPoints: ["src/main.tsx"],
  bundle: true,
  minify: true,
  splitting: true,
  // lazy routes become separate files
  format: "esm",
  write: false,
  metafile: true,
  outdir: "dist",
  define: { "process.env.NODE_ENV": '"production"' },
  logLevel: "error"
});
var outputs = result.metafile.outputs;
var gzipKB = (path) => gzipSync(result.outputFiles.find((f) => f.path.endsWith(path)).contents).length / 1024;
var packageOf = (file) => /node_modules\/((?:@[^/]+\/)?[^/]+)/.exec(file)?.[1] ?? "our code";
var first = /* @__PURE__ */ new Set();
var visit = (path) => {
  if (first.has(path)) return;
  first.add(path);
  for (const i of outputs[path].imports) if (i.kind === "import-statement") visit(i.path);
};
visit("dist/main.js");
var firstKB = 0;
for (const [path, info] of Object.entries(outputs)) {
  const kb = gzipKB(path);
  const packages = [...new Set(Object.keys(info.inputs).map(packageOf))];
  if (first.has(path)) firstKB += kb;
  else console.log(`loaded later: ${kb.toFixed(1)} KB gzip (${packages.join(" + ")})`);
}
console.log(`first load: ${firstKB.toFixed(1)} KB gzip`);
console.log(firstKB <= BUDGET_KB ? `\u2713 under the budget of ${BUDGET_KB} KB` : `\u2717 over the budget of ${BUDGET_KB} KB`);
