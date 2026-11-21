import { readFileSync, readdirSync } from "node:fs";
import { dirname, join, normalize, relative } from "node:path";

const root = "app";
const files = readdirSync(root, { recursive: true, encoding: "utf8" })
  .filter((f) => f.endsWith(".ts"))
  .map((f) => join(root, f));
const moduleOf = (file: string) => relative(root, file).split("/")[0]!;

const broken: string[] = [];
// كل استيراد بمسار نسبي، والوحدة التي يصل إليها
const imports = /from "(\.[^"]+)"/g;
for (const file of files) {
  const from = moduleOf(file);
  for (const [, path] of readFileSync(file, "utf8").matchAll(imports)) {
    const target = normalize(join(dirname(file), path!));
    const to = moduleOf(target);
    if (to === from) continue;
    // الكود المشترك لا يعتمد على أي وحدة
    if (from === "shared")
      broken.push(`${file} → ${to}\n    الكود المشترك يجب ألا يستورد وحدة`);
    // لا يستعمل الوحدةَ وحدةٌ أخرى إلا عبر index.ts الخاص بها
    else if (to !== "shared" && !target.endsWith(`${to}/index.ts`))
      broken.push(`${file} → ${path}\n    مُر عبر ${to}/index.ts`);
  }
}
if (broken.length) {
  console.log(`قواعد معمارية مكسورة: ${broken.length}`);
  for (const line of broken) console.log("  " + line);
  process.exit(1);
}
console.log("قواعد المعمارية: سليمة");
