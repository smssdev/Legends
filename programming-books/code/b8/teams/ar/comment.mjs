import fs from "node:fs";

// الحكم كتعليق على طلب الدمج.
const {structured_output: v, total_cost_usd: cost} = JSON.parse(fs.readFileSync("review.json", "utf8"));
const lines = [`### مراجعة Claude`, ""];
if (v.ok) lines.push("لا عوائق.");
else lines.push("**العوائق:**", ...v.blockers.map((b) => `- ${b}`));
lines.push("", `_مراجعة آلية: ما زال إنسان يوافق. ($${cost.toFixed(2)})_`);
console.log(lines.join("\n"));
