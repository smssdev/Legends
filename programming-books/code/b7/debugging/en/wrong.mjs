import fs from "node:fs";
import {ask, codeOf} from "./lib/ask.mjs";
import {run} from "./lib/run.mjs";
import {MENU} from "./shop/menu.mjs";

const source = fs.readFileSync("shop/top.mjs", "utf8");
const menu = fs.readFileSync("shop/menu.mjs", "utf8");
const answer = await ask(`This function should return the three most expensive drinks, most expensive first. For the menu below it returns the wrong drinks. Give your most likely cause in one sentence, then the fixed function in one code block.\n\n${source}\n${menu}`, {maxTokens: 500});
console.log(answer);

// Take the model's fix, run it, and compare with the right answer.
const fixed = codeOf(answer);
if (!fixed) {
  console.log("(no code in the answer)");
  process.exit(0);
}
const code = fixed.replace(/^import .*$/gm, "").replace(/^console.log.*$/gm, "");
const topThree = Function(`${code.replace("export ", "")}; return topThree;`)();
console.log("\n--- run:");
console.log(`before: ${run("shop/top.mjs").output.trim()}`);
console.log(`fixed:  ${JSON.stringify(topThree(MENU))}`);
console.log(`right:  ${JSON.stringify(["mocha", "cold brew", "latte"])}`);
