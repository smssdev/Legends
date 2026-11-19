// Builds one shared copy of Vue and its libraries as browser ES modules, for every Vue example in the book.
// Run: node vendor/make-vue.mjs   (from code/b2). Pages load it through an import map (see vue_kit.py).
import { build } from "esbuild";
import { mkdirSync, writeFileSync, rmSync } from "node:fs";

const tmp = new URL("./.vue-entries/", import.meta.url).pathname;
rmSync(tmp, { recursive: true, force: true });
mkdirSync(tmp, { recursive: true });

const entries = {
  "vue": "vue",
  "vue-router": "vue-router",
  "pinia": "pinia",
  "vue-query": "@tanstack/vue-query",
  "vee-validate": "vee-validate",
  "vueuse": "@vueuse/core",
};
for (const [file, pkg] of Object.entries(entries)) writeFileSync(`${tmp}${file}.js`, `export * from "${pkg}";\n`);

await build({
  entryPoints: Object.keys(entries).map((f) => `${tmp}${f}.js`),
  bundle: true, splitting: true, format: "esm", minify: true,
  outdir: new URL(".", import.meta.url).pathname, entryNames: "[name]", chunkNames: "shared-vue-[hash]",
  define: {
    "process.env.NODE_ENV": '"production"',
    __VUE_OPTIONS_API__: "true",
    __VUE_PROD_DEVTOOLS__: "false",
    __VUE_PROD_HYDRATION_MISMATCH_DETAILS__: "false",
  },
  legalComments: "none", logLevel: "warning",
});
rmSync(tmp, { recursive: true, force: true });
console.log("vue vendor ready");
