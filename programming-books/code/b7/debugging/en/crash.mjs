import fs from "node:fs";
import {ask} from "./lib/ask.mjs";
import {run} from "./lib/run.mjs";

// Run the program, keep its error output, and give both to the model.
const {output} = run("shop/report.mjs");
const trace = output.split("\n").filter((line) => !line.includes("node:internal"));
console.log(trace.join("\n").trim());

const files = ["shop/report.mjs", "shop/orders.mjs", "shop/menu.mjs"]
  .map((file) => `--- ${file}\n${fs.readFileSync(file, "utf8")}`)
  .join("\n");
const answer = await ask(`This program crashed. Explain the error in two sentences, then name the file and line number where the bug is (not only where it crashed), as: BUG AT file:line\n\n${trace.join("\n")}\n\n${files}`);
console.log(`\n--- the model:\n${answer}`);

// The model names a line; we check it against the line that really has
// the bug.
const named = answer.match(/BUG AT\s*`?([\w/.]+):(\d+)/);
console.log(`\nnamed: ${named ? `${named[1]}:${named[2]}` : "(none)"}`);
console.log("the crash: shop/orders.mjs:5 (drink is undefined)");
console.log("the cause: shop/report.mjs:5 (a drink that is not on the menu)");
