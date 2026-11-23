import fs from "node:fs";
import {ask} from "./lib/ask.mjs";

// نقاش أطول من طلب واحد: لخّص كل جزء، ثم ادمج الملخصات.
const lines = fs.readFileSync("meeting.txt", "utf8").trim().split("\n");
const parts = [lines.slice(0, 9), lines.slice(9, 15), lines.slice(15)].map((p) => p.join("\n"));
const summaries = [];
for (const [i, part] of parts.entries()) {
  summaries.push(await ask(`لخّص هذا الجزء من نقاش في ثلاثة أسطر على الأكثر: القرارات وحدها.\n\n${part}`, {maxTokens: 150}));
  console.log(`part ${i + 1}: ${summaries.at(-1).replace(/\s*\n\s*/g, " / ")}`);
}
console.log("--- merged");
console.log(await ask(`هذه ملخصات أجزاء نقاش واحد. ادمجها في قائمة قرارات واحدة، بلا تكرار.\n\n${summaries.join("\n\n")}`, {maxTokens: 300}));
