// en/projects/check-messages.ts
import { readFileSync } from "node:fs";
var load = (file) => JSON.parse(readFileSync(new URL(file, import.meta.url), "utf8"));
var en = load("./en.json");
var ar = load("./ar.json");
var placeholders = (text) => [...text.matchAll(/\{(\w+)\}/g)].map((m) => m[1]).sort().join(",");
var problems = 0;
for (const key of Object.keys(en)) {
  if (!(key in ar)) {
    console.log(`\u2717 ${key}: missing in ar`);
    problems++;
  } else if (placeholders(en[key]) !== placeholders(ar[key])) {
    console.log(`\u2717 ${key}: placeholders differ: en {${placeholders(en[key])}} ar {${placeholders(ar[key])}}`);
    problems++;
  }
}
for (const key of Object.keys(ar)) {
  if (!(key in en)) {
    console.log(`\u2717 ${key}: not in en`);
    problems++;
  }
}
console.log(problems === 0 ? "All keys match." : `${problems} problems`);
process.exitCode = problems ? 1 : 0;
