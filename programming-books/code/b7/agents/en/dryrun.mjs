import fs from "node:fs";
import {execFileSync} from "node:child_process";
import {runAgent} from "./lib/agent.mjs";

// A dry run: writes are recorded, not applied, and shown as a diff for a
// person to approve.
const {log, writes} = await runAgent({
  root: "cafe4",
  system: "You are a coding agent working in a small JavaScript project. Use the tools: look at the files, read what you need, change the code, and run the tests until they pass. Do not change the tests. When you are done, say what you changed in one sentence.",
  task: "The tests fail. Make them pass.",
  dryRun: true,
});
console.log(log.join("\n"));
for (const {file, content} of writes) {
  fs.writeFileSync("proposed.tmp", content);
  try {
    execFileSync("diff", ["-u", `cafe4/${file}`, "proposed.tmp"], {encoding: "utf8"});
  } catch (error) {
    console.log(error.stdout.replace("proposed.tmp", `${file} (proposed)`));
  }
}
console.log(`--- ${writes.length} change(s) proposed, none applied`);
