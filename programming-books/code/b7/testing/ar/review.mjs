import fs from "node:fs";
import {ask} from "./lib/ask.mjs";

const diff = fs.readFileSync("changes/save-order.diff", "utf8");
const review = await ask(`راجع هذا التغيير كمطور خبير. اسرد كل مشكلة تجدها، الأخطر أولاً، في سطر لكل منها.\n\n${diff}`, {maxTokens: 500});
console.log(review);

// زُرعت ثلاث مشكلات في الفرق؛ تحقق أيها تذكر المراجعة.
const planted = {
  "secret in the log": /password|secret|credential|DB_PASSWORD/i,
  "off by one (<=)": /<=|off-by-one|off by one|out of bounds|undefined item/i,
  "insert not awaited": /insert[^.]*(await|promise)|(await|promise)[^.]*insert|not awaited/i,
};
console.log("--- planted problems");
for (const [name, pattern] of Object.entries(planted)) {
  console.log(`${pattern.test(review) ? "found " : "MISSED"} ${name}`);
}
