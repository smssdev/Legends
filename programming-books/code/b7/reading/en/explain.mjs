import fs from "node:fs";
import {ask} from "./lib/ask.mjs";

const code = fs.readFileSync("legacy/lib/calc.js", "utf8");
console.log(await ask(`Explain in plain words what calc does, as a list of rules a café manager would understand. Do not explain the syntax.\n\n${code}`));
