import fs from "node:fs";

// The verdict as a comment for the pull request.
const {structured_output: v, total_cost_usd: cost} = JSON.parse(fs.readFileSync("review.json", "utf8"));
const lines = [`### Claude review`, ""];
if (v.ok) lines.push("No blockers found.");
else lines.push("**Blockers:**", ...v.blockers.map((b) => `- ${b}`));
lines.push("", `_An automatic review: a person still approves. ($${cost.toFixed(2)})_`);
console.log(lines.join("\n"));
