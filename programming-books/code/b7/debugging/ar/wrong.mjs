import fs from "node:fs";
import {ask} from "./lib/ask.mjs";
import {run} from "./lib/run.mjs";
import {MENU} from "./shop/menu.mjs";

const source = fs.readFileSync("shop/top.mjs", "utf8");
const menu = fs.readFileSync("shop/menu.mjs", "utf8");
const answer = await ask(`يجب أن تعيد هذه الدالة أغلى ثلاثة مشروبات، الأغلى أولاً. ولقائمة الطعام أدناه تعيد مشروبات خاطئة. أعطِ السبب الأرجح في جملة، ثم الدالة المصححة في كتلة كود واحدة.\n\n${source}\n${menu}`, {maxTokens: 800});
console.log(answer);

// خذ إصلاح النموذج، وشغّله، وقارنه بالجواب الصحيح.
// The code block that defines topThree; an answer may also quote other
// code.
const blocks = [...answer.matchAll(/```(?:\w+)?\n([\s\S]*?)```/g)].map((m) => m[1]);
const fixed = blocks.findLast((block) => block.includes("function topThree"));
if (!fixed) {
  console.log("\n(no fixed function in the answer)");
  process.exit(0);
}
const code = fixed.replace(/^import .*$/gm, "").replace(/^console.log.*$/gm, "");
const topThree = Function(`${code.replace("export ", "")}; return topThree;`)();
console.log("\n--- run:");
console.log(`before: ${run("shop/top.mjs").output.trim()}`);
console.log(`fixed:  ${JSON.stringify(topThree(MENU))}`);
console.log(`right:  ${JSON.stringify(["mocha", "cold brew", "latte"])}`);
