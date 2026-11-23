import fs from "node:fs";
import {docExamples} from "./lib/doctest.mjs";

// شغّل كل سطر بالشكل call // => value وقارن.
const file = process.argv[2];
const exports = await import(`./${file}`);
const results = docExamples(fs.readFileSync(file, "utf8"), exports);
for (const {call, claimed, actual, ok} of results) {
  console.log(`${ok ? "pass" : "FAIL"} ${call} // => ${claimed}${ok ? "" : `   (real: ${actual})`}`);
}
console.log(`${results.filter((r) => r.ok).length} of ${results.length} examples hold`);
