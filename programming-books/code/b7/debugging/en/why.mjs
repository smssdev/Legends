import {ask} from "./lib/ask.mjs";

// Any command's output, piped in: node broken.mjs 2>&1 | node why.mjs
let output = "";
for await (const chunk of process.stdin) {
  output += chunk;
}
const lines = output.split("\n").filter((line) => !line.includes("node:internal"));
console.log(await ask(`Explain this error output to a developer in at most four lines: what failed, the likely cause, and the first thing to check.\n\n${lines.join("\n")}`, {maxTokens: 200}));
