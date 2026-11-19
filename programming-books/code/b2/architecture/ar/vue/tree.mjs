// architecture/ar/vue/tree.ts
import { readdirSync, statSync } from "node:fs";
import { join } from "node:path";
function print(dir, prefix = "") {
  const names = readdirSync(dir).sort((a, b) => Number(statSync(join(dir, b)).isDirectory()) - Number(statSync(join(dir, a)).isDirectory()) || a.localeCompare(b));
  names.forEach((name, i) => {
    const last = i === names.length - 1;
    const path = join(dir, name);
    console.log(`${prefix}${last ? "\u2514\u2500\u2500 " : "\u251C\u2500\u2500 "}${name}${statSync(path).isDirectory() ? "/" : ""}`);
    if (statSync(path).isDirectory()) print(path, prefix + (last ? "    " : "\u2502   "));
  });
}
console.log("src/");
print("sample/src");
