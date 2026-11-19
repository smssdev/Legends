// Bundles one Vue example, compiling .vue files with Vue's own compiler (as @vitejs/plugin-vue does in Vite).
// Usage: node vue/bundle.mjs <entry.ts> <out.js> browser|node
import { build } from "esbuild";
import { readFile } from "node:fs/promises";
import { createHash } from "node:crypto";
import { dirname } from "node:path";
import { parse, compileScript, compileTemplate, compileStyle } from "vue/compiler-sfc";

const [entry, outfile, target = "browser"] = process.argv.slice(2);
const external = ["vue", "vue-router", "pinia", "@tanstack/vue-query", "vee-validate", "@vueuse/core", "zod"];

const vue = {
  name: "vue",
  setup(b) {
    b.onLoad({ filter: /\.vue$/ }, async ({ path }) => {
      const { descriptor, errors } = parse(await readFile(path, "utf8"), { filename: path });
      if (errors.length) throw errors[0];
      const id = createHash("md5").update(path).digest("hex").slice(0, 8);
      const scoped = descriptor.styles.some((s) => s.scoped);
      let code;
      let lang = "js";
      if (descriptor.script || descriptor.scriptSetup) {
        const script = compileScript(descriptor, { id, inlineTemplate: true, genDefaultAs: "_sfc", isProd: true });
        code = script.content;
        lang = script.lang === "ts" ? "ts" : "js";
      } else {
        const t = compileTemplate({ source: descriptor.template.content, filename: path, id, scoped, compilerOptions: { scopeId: scoped ? `data-v-${id}` : undefined } });
        code = `${t.code}\nconst _sfc = { render };`;
      }
      const css = descriptor.styles
        .map((s) => compileStyle({ source: s.content, filename: path, id: `data-v-${id}`, scoped: s.scoped }).code)
        .join("\n");
      if (css) code += `\nif (typeof document !== "undefined") { const s = document.createElement("style"); s.textContent = ${JSON.stringify(css)}; document.head.append(s); }`;
      if (scoped) code += `\n_sfc.__scopeId = "data-v-${id}";`;
      code += `\nexport default _sfc;`;
      return { contents: code, loader: lang, resolveDir: dirname(path) };
    });
  },
};

const r = await build({
  entryPoints: [entry], bundle: true, format: "esm", outfile, plugins: [vue], logLevel: "warning",
  ...(target === "node" ? { platform: "node", packages: "external" } : { external }),
});
if (r.errors.length) process.exit(1);
