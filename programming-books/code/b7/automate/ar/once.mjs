import fs from "node:fs";
import {ask} from "./lib/ask.mjs";

// اطلب الكود من النموذج مرة، ثم شغّل الكود على كل صف: بلا نموذج لكل صف.
const rows = fs.readFileSync("data/dates.txt", "utf8").trim().split("\n");
const answer = await ask(`اكتب دالة JavaScript باسم toIso(text) تحوّل التواريخ بهذه الصيغ إلى YYYY-MM-DD. اليوم قبل الشهر حين يكون الاثنان رقمين. أعِد الدالة فقط، في كتلة كود واحدة.\n\n${rows.join("\n")}`, {maxTokens: 1500});
// The code block, even when the answer stopped before closing it.
const code = answer.match(/```(?:\w+)?\n([\s\S]*?)(?:```|$)/)?.[1] ?? answer;
fs.writeFileSync("toIso.mjs", `${code}\nexport {toIso};\n`);
let toIso;
try {
  ({toIso} = await import("./toIso.mjs"));
} catch (error) {
  console.log(`toIso.mjs does not load: ${error.message}`);
  process.exit(0);
}
for (const row of rows) {
  let result;
  try {
    result = toIso(row);
  } catch (error) {
    result = `${error.name}: ${error.message}`;
  }
  console.log(`${row.padEnd(18)} -> ${result}`);
}
