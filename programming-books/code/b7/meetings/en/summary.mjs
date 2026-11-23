import fs from "node:fs";
import {ask, model} from "./lib/ask.mjs";
import {TRUTH} from "./truth.mjs";

const meeting = fs.readFileSync("meeting.txt", "utf8");
const text = {type: "string"};
const grammar = await model.llama.createGrammarForJsonSchema({
  type: "object",
  properties: {
    decisions: {type: "array", items: text},
    actions: {
      type: "array",
      items: {type: "object", properties: {owner: text, task: text, due: text}},
    },
  },
});
const summary = JSON.parse(await ask(`Summarise this meeting as JSON: the decisions, and the action items, each with owner, task and due date (as written in the meeting, or none).\n\n${meeting}`, {grammar}));
console.log("decisions:");
summary.decisions.forEach((d) => console.log(`  - ${d}`));
console.log("actions:");
summary.actions.forEach((a) => console.log(`  - ${a.owner}: ${a.task} (${a.due})`));

// An owner the meeting never named, or a date it never said, is invented.
console.log("--- checked against the meeting");
console.log(`decisions: ${summary.decisions.length} listed, ${TRUTH.decisions} made`);
for (const action of summary.actions) {
  const named = TRUTH.people.some((p) => action.owner.includes(p));
  const date = (action.due.match(/\d+/g) ?? []).every((n) => meeting.includes(n));
  const problems = [!named && "owner not in the meeting", !date && "date not in the meeting"].filter(Boolean);
  console.log(`${problems.length ? "WRONG" : "ok   "} ${action.owner}: ${action.task} ${problems.join(", ")}`);
}
for (const {owner} of TRUTH.actions) {
  if (!summary.actions.some((a) => a.owner.includes(owner))) {
    console.log(`MISSED an action for ${owner}`);
  }
}
for (const idea of TRUTH.rejected) {
  console.log(`(rejected in the meeting: ${idea})`);
}
