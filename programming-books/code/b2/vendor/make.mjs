// Builds one shared copy of React as browser ES modules, for every React example in the book.
// Run: node vendor/make.mjs   (from code/b2). Pages load it through an import map:
//   <script type="importmap">{"imports": {"react": "/vendor/react.js", ...}}</script>
import { build } from "esbuild";
import { createRequire } from "node:module";
import { mkdirSync, writeFileSync, rmSync } from "node:fs";

const require = createRequire(import.meta.url);
const tmp = new URL("./.entries/", import.meta.url).pathname;
rmSync(tmp, { recursive: true, force: true });
mkdirSync(tmp, { recursive: true });

// React is published as CommonJS, so its named exports are listed for esbuild one by one.
const entries = {
  "react": "react",
  "react-dom": "react-dom",
  "react-dom-client": "react-dom/client",
  "jsx-runtime": "react/jsx-runtime",
};
for (const [file, pkg] of Object.entries(entries)) {
  const names = Object.keys(require(pkg)).filter((n) => /^[A-Za-z_$][\w$]*$/.test(n) && n !== "default");
  writeFileSync(`${tmp}${file}.js`,
    `import * as m from "${pkg}";\nexport default m;\nexport const { ${names.join(", ")} } = m;\n`);
}

await build({
  entryPoints: Object.keys(entries).map((f) => `${tmp}${f}.js`),
  bundle: true, splitting: true, format: "esm", minify: true,
  outdir: new URL(".", import.meta.url).pathname, entryNames: "[name]", chunkNames: "shared-[hash]",
  define: { "process.env.NODE_ENV": '"production"' }, legalComments: "none", logLevel: "warning",
});
rmSync(tmp, { recursive: true, force: true });
console.log("vendor ready");
