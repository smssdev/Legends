import { readdirSync, statSync } from "node:fs";
import { join } from "node:path";

// Prints the sample's folders as a tree
function print(dir: string, prefix = ""): void {
  const names = readdirSync(dir).sort((a, b) => Number(statSync(join(dir, b)).isDirectory()) - Number(statSync(join(dir, a)).isDirectory()) || a.localeCompare(b));
  names.forEach((name, i) => {
    const last = i === names.length - 1;
    const path = join(dir, name);
    console.log(`${prefix}${last ? "└── " : "├── "}${name}${statSync(path).isDirectory() ? "/" : ""}`);
    if (statSync(path).isDirectory()) print(path, prefix + (last ? "    " : "│   "));
  });
}
console.log("src/");
print("sample/src");
