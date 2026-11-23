import fs from "node:fs";
import {ask, codeOf} from "./lib/ask.mjs";
import {errorLine, run} from "./lib/run.mjs";

// Up to three attempts; each failure is sent back with what actually
// happened.
export async function reproduce(log, file, tries = 3) {
  const wanted = errorLine(log);
  let request = `From this log, write the smallest standalone Node script (ES module, no files, no network) that throws the same error. Return only the code, in one code block.\n\n${log}`;
  for (let attempt = 1; attempt <= tries; attempt++) {
    const code = codeOf(await ask(request));
    fs.writeFileSync(file, code ?? "");
    const got = errorLine(run(file).output);
    console.log(`attempt ${attempt}: ${got}`);
    if (got === wanted) {
      return `reproduced in ${attempt}`;
    }
    request += `\n\nYour script:\n${code}\nIt printed: ${got}\nIt must throw: ${wanted}`;
  }
  return "not reproduced";
}

const log = `2026-11-21T02:00:02Z ERROR RangeError: Invalid array length
    at splitBill (file:///srv/shop/bill.mjs:7:10)
    at file:///srv/shop/report.mjs:12:3`;
console.log(await reproduce(log, "repro/loop.mjs"));
