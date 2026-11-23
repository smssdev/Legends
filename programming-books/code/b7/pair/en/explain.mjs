import fs from "node:fs";
import {ask} from "./lib/ask.mjs";

// Ask the model to explain code before you accept it, including how it
// could fail.
const code = fs.readFileSync("bill/bill.mjs", "utf8");
console.log(await ask(`Explain this code line by line, then say which inputs could make it fail.\n\n${code}`, {maxTokens: 500}));
