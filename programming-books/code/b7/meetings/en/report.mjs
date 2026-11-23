import fs from "node:fs";
import {ask} from "./lib/ask.mjs";

const log = fs.readFileSync("log.txt", "utf8");
const tasks = fs.readFileSync("tasks.txt", "utf8");
const report = await ask(`Write a short weekly status report for the loyalty card project from this commit log and task list. Say which tasks are done and which remain.\n\n${log}\n${tasks}`, {maxTokens: 500});
console.log(report);

// A task reported as done must have a commit.
const done = {T1: "stamp a card", T2: "free drink on the 10th", T3: "refunded", T4: "both branches"};
console.log("--- the truth, from the log");
for (const line of tasks.trim().split("\n")) {
  const id = line.split(" ")[0];
  const inLog = done[id] ? log.includes(done[id]) : false;
  console.log(`${id} ${inLog ? "done   " : "not done"} ${line.slice(3)}`);
}
