import fs from "node:fs";
import {ask, codeOf} from "./lib/ask.mjs";
import {errorLine, run} from "./lib/run.mjs";

const log = fs.readFileSync("logs/night.log", "utf8");
const code = codeOf(await ask(`From this log, write the smallest standalone Node script (ES module, no files, no network) that throws the same error. Return only the code, in one code block.\n\n${log}`));
fs.writeFileSync("repro/attempt.mjs", code ?? "");
console.log(`--- repro/attempt.mjs\n${code}`);

// A reproduction is only useful if it fails the same way: run it and
// compare the error.
const wanted = errorLine(log);
const got = errorLine(run("repro/attempt.mjs").output);
console.log(`wanted: ${wanted}`);
console.log(`got:    ${got}`);
console.log(got === wanted ? "same error: a reproduction" : "different: not a reproduction yet");
