import fs from "node:fs";
import {ask} from "./lib/ask.mjs";

// A thread too long for one request: summarise each part, then merge the
// summaries.
const lines = fs.readFileSync("meeting.txt", "utf8").trim().split("\n");
const parts = [lines.slice(0, 9), lines.slice(9, 15), lines.slice(15)].map((p) => p.join("\n"));
const summaries = [];
for (const [i, part] of parts.entries()) {
  summaries.push(await ask(`Summarise this part of a discussion in at most three lines: the decisions only.\n\n${part}`, {maxTokens: 150}));
  console.log(`part ${i + 1}: ${summaries.at(-1).replace(/\s*\n\s*/g, " / ")}`);
}
console.log("--- merged");
console.log(await ask(`Here are summaries of the parts of one discussion. Merge them into one list of decisions, without repeating.\n\n${summaries.join("\n\n")}`, {maxTokens: 300}));
