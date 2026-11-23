import fs from "node:fs";
import {ask} from "./lib/ask.mjs";

const source = fs.readFileSync("report.mjs", "utf8");
const readme = await ask(`Write the Usage section of a README for this command-line tool: how to run it, every option, and two examples. Markdown, at most 25 lines.\n\n${source}`);
console.log(readme);

// Every option the README mentions must exist in the code.
console.log("--- options in the README");
const options = new Set(readme.match(/--[a-z][\w-]*/g) ?? []);
for (const option of options) {
  const exists = source.includes(`${option.slice(2)}: {`);
  console.log(`${exists ? "exists " : "INVENTED"} ${option}`);
}
