import { readFileSync } from "node:fs";

// Compare the two catalogues: missing keys, extra keys, and placeholders that do not match
const load = (file: string) => JSON.parse(readFileSync(new URL(file, import.meta.url), "utf8")) as Record<string, string>;
const en = load("./en.json");
const ar = load("./ar.json");
const placeholders = (text: string) => [...text.matchAll(/\{(\w+)\}/g)].map((m) => m[1]).sort().join(",");

let problems = 0;
for (const key of Object.keys(en)) {
  if (!(key in ar)) {
    console.log(`✗ ${key}: missing in ar`);
    problems++;
  } else if (placeholders(en[key]!) !== placeholders(ar[key]!)) {
    console.log(`✗ ${key}: placeholders differ: en {${placeholders(en[key]!)}} ar {${placeholders(ar[key]!)}}`);
    problems++;
  }
}
for (const key of Object.keys(ar)) {
  if (!(key in en)) {
    console.log(`✗ ${key}: not in en`);
    problems++;
  }
}
console.log(problems === 0 ? "All keys match." : `${problems} problems`);
process.exitCode = problems ? 1 : 0;
