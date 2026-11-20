// ar/build-tokens.ts
import { readFileSync } from "node:fs";
var tokens = JSON.parse(readFileSync(new URL("./tokens.json", import.meta.url), "utf8"));
function resolve(name) {
  const value = tokens.primitive[name];
  if (!value) throw new Error(`Unknown primitive token: ${name}`);
  return value;
}
function block(selector, vars) {
  const lines = Object.entries(vars).map(([k, v]) => `  --${k}: ${v};`);
  return `${selector} {
${lines.join("\n")}
}`;
}
var light = Object.fromEntries(Object.entries(tokens.semantic.light).map(([k, v]) => [`color-${k}`, resolve(v)]));
var dark = Object.fromEntries(Object.entries(tokens.semantic.dark).map(([k, v]) => [`color-${k}`, resolve(v)]));
var space = Object.fromEntries(Object.entries(tokens.space).map(([k, v]) => [`space-${k}`, v]));
var radius = Object.fromEntries(Object.entries(tokens.radius).map(([k, v]) => [`radius-${k}`, v]));
var css = [block(":root", { ...light, ...space, ...radius }), block('[data-theme="dark"]', dark)].join("\n\n");
console.log(css.split("\n").slice(0, 8).join("\n"));
console.log("  \u2026");
console.log(`(${Object.keys(light).length} colours \xD7 2 themes, ${Object.keys(space).length} spaces, ${Object.keys(radius).length} radii)`);
