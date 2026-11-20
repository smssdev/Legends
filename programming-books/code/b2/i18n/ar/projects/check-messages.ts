import { readFileSync } from "node:fs";

// قارن الفهرسين: المفاتيح الناقصة، والزائدة، والأماكن الفارغة غير المتطابقة
const load = (file: string) => JSON.parse(readFileSync(new URL(file, import.meta.url), "utf8")) as Record<string, string>;
const en = load("./en.json");
const ar = load("./ar.json");
const placeholders = (text: string) => [...text.matchAll(/\{(\w+)\}/g)].map((m) => m[1]).sort().join(",");

let problems = 0;
for (const key of Object.keys(en)) {
  if (!(key in ar)) {
    console.log(`✗ ${key}: ناقص في ar`);
    problems++;
  } else if (placeholders(en[key]!) !== placeholders(ar[key]!)) {
    console.log(`✗ ${key}: الأماكن الفارغة مختلفة: en {${placeholders(en[key]!)}} ar {${placeholders(ar[key]!)}}`);
    problems++;
  }
}
for (const key of Object.keys(ar)) {
  if (!(key in en)) {
    console.log(`✗ ${key}: ليس في en`);
    problems++;
  }
}
console.log(problems === 0 ? "كل المفاتيح متطابقة." : `${problems} مشكلات`);
process.exitCode = problems ? 1 : 0;
