import fs from "node:fs";
import {ask} from "./lib/ask.mjs";

// Ask the model for the code once, then run the code on every row: no
// model per row.
const rows = fs.readFileSync("data/dates.txt", "utf8").trim().split("\n");
const answer = await ask(`Write a JavaScript function toIso(text) that converts dates in these formats to YYYY-MM-DD. Day comes before month when both are numbers. Return only the function, in one code block.\n\n${rows.join("\n")}`, {maxTokens: 1500});
// The code block, even when the answer stopped before closing it.
const code = answer.match(/```(?:\w+)?\n([\s\S]*?)(?:```|$)/)?.[1] ?? answer;
fs.writeFileSync("toIso.mjs", `${code}\nexport {toIso};\n`);
let toIso;
try {
  ({toIso} = await import("./toIso.mjs"));
} catch (error) {
  console.log(`toIso.mjs does not load: ${error.message}`);
  process.exit(0);
}
for (const row of rows) {
  let result;
  try {
    result = toIso(row);
  } catch (error) {
    result = `${error.name}: ${error.message}`;
  }
  console.log(`${row.padEnd(18)} -> ${result}`);
}
