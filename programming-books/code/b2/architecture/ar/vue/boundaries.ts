import { readdirSync, readFileSync, statSync } from "node:fs";
import { dirname, join, relative, resolve } from "node:path";

// الطبقات من الأسفل إلى الأعلى: كل طبقة تستورد مما تحتها فقط: shared → features → app
const root = resolve(process.argv[2] ?? "sample/src");

function files(dir: string): string[] {
  return readdirSync(dir).flatMap((name) => {
    const path = join(dir, name);
    return statSync(path).isDirectory() ? files(path) : /\.(ts|vue)$/.test(name) ? [path] : [];
  });
}

// "features/cart/store.ts" -> { layer: "features", feature: "cart", rest: "store.ts" }
function where(path: string) {
  const [layer = "", feature = "", ...rest] = relative(root, path).split("/");
  return { layer, feature: layer === "features" ? feature : "", rest: rest.join("/") };
}

const problems: string[] = [];
for (const file of files(root)) {
  const from = where(file);
  for (const [, target] of readFileSync(file, "utf8").matchAll(/from\s+"(\.[^"]+)"/g)) {
    const to = where(resolve(dirname(file), target!));
    const at = `${relative(root, file)} → ${target}`;
    if (from.layer === "shared" && to.layer === "features") problems.push(`${at}\n    الكود المشترك لا يستورد ميزة`);
    if (to.layer === "app" && from.layer !== "app") problems.push(`${at}\n    لا شيء يستورد من app/`);
    if (from.layer === "features" && to.layer === "features" && from.feature !== to.feature && to.rest !== "") {
      problems.push(`${at}\n    استورد ميزة أخرى عبر index.ts الخاص بها فقط`);
    }
  }
}

for (const p of problems) console.log("✗ " + p);
console.log(problems.length === 0 ? "لا مخالفات للحدود." : `${problems.length} مخالفات`);
process.exitCode = problems.length ? 1 : 0;
