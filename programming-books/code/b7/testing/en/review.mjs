import fs from "node:fs";
import {ask} from "./lib/ask.mjs";

const diff = fs.readFileSync("changes/save-order.diff", "utf8");
const review = await ask(`Review this change as a senior developer. List every problem you find, most serious first, one line each.\n\n${diff}`, {maxTokens: 500});
console.log(review);

// Three problems were planted in the diff; check which the review
// mentions.
const planted = {
  "secret in the log": /password|secret|credential|DB_PASSWORD/i,
  "off by one (<=)": /<=|off-by-one|off by one|out of bounds|undefined item/i,
  "insert not awaited": /insert[^.]*(await|promise)|(await|promise)[^.]*insert|not awaited/i,
};
console.log("--- planted problems");
for (const [name, pattern] of Object.entries(planted)) {
  console.log(`${pattern.test(review) ? "found " : "MISSED"} ${name}`);
}
