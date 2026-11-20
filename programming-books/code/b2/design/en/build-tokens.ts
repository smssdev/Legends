import { readFileSync } from "node:fs";

// Reads tokens.json and writes CSS variables for the light and dark themes
type Tokens = {
  primitive: Record<string, string>;
  semantic: Record<"light" | "dark", Record<string, string>>;
  space: Record<string, string>;
  radius: Record<string, string>;
};

const tokens = JSON.parse(readFileSync(new URL("./tokens.json", import.meta.url), "utf8")) as Tokens;

function resolve(name: string): string {
  const value = tokens.primitive[name];
  if (!value) throw new Error(`Unknown primitive token: ${name}`);
  return value;
}

function block(selector: string, vars: Record<string, string>): string {
  const lines = Object.entries(vars).map(([k, v]) => `  --${k}: ${v};`);
  return `${selector} {\n${lines.join("\n")}\n}`;
}

const light = Object.fromEntries(Object.entries(tokens.semantic.light).map(([k, v]) => [`color-${k}`, resolve(v)]));
const dark = Object.fromEntries(Object.entries(tokens.semantic.dark).map(([k, v]) => [`color-${k}`, resolve(v)]));
const space = Object.fromEntries(Object.entries(tokens.space).map(([k, v]) => [`space-${k}`, v]));
const radius = Object.fromEntries(Object.entries(tokens.radius).map(([k, v]) => [`radius-${k}`, v]));

const css = [block(":root", { ...light, ...space, ...radius }), block('[data-theme="dark"]', dark)].join("\n\n");
console.log(css.split("\n").slice(0, 8).join("\n"));
console.log("  …");
console.log(`(${Object.keys(light).length} colours × 2 themes, ${Object.keys(space).length} spaces, ${Object.keys(radius).length} radii)`);
