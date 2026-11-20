// ar/projects/check-messages.ts
import { readFileSync } from "node:fs";
var load = (file) => JSON.parse(readFileSync(new URL(file, import.meta.url), "utf8"));
var en = load("./en.json");
var ar = load("./ar.json");
var placeholders = (text) => [...text.matchAll(/\{(\w+)\}/g)].map((m) => m[1]).sort().join(",");
var problems = 0;
for (const key of Object.keys(en)) {
  if (!(key in ar)) {
    console.log(`\u2717 ${key}: \u0646\u0627\u0642\u0635 \u0641\u064A ar`);
    problems++;
  } else if (placeholders(en[key]) !== placeholders(ar[key])) {
    console.log(`\u2717 ${key}: \u0627\u0644\u0623\u0645\u0627\u0643\u0646 \u0627\u0644\u0641\u0627\u0631\u063A\u0629 \u0645\u062E\u062A\u0644\u0641\u0629: en {${placeholders(en[key])}} ar {${placeholders(ar[key])}}`);
    problems++;
  }
}
for (const key of Object.keys(ar)) {
  if (!(key in en)) {
    console.log(`\u2717 ${key}: \u0644\u064A\u0633 \u0641\u064A en`);
    problems++;
  }
}
console.log(problems === 0 ? "\u0643\u0644 \u0627\u0644\u0645\u0641\u0627\u062A\u064A\u062D \u0645\u062A\u0637\u0627\u0628\u0642\u0629." : `${problems} \u0645\u0634\u0643\u0644\u0627\u062A`);
process.exitCode = problems ? 1 : 0;
