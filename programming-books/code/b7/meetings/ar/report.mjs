import fs from "node:fs";
import {ask} from "./lib/ask.mjs";

const log = fs.readFileSync("log.txt", "utf8");
const tasks = fs.readFileSync("tasks.txt", "utf8");
const report = await ask(`اكتب تقرير حالة أسبوعياً قصيراً لمشروع بطاقة الولاء من سجل الحفظ وقائمة المهام هذين. قل أي المهام انتهت وأيها بقي.\n\n${log}\n${tasks}`, {maxTokens: 500});
console.log(report);

// المهمة التي يُقال إنها انتهت يجب أن يكون لها حفظ.
const done = {T1: "stamp a card", T2: "free drink on the 10th", T3: "refunded", T4: "both branches"};
console.log("--- the truth, from the log");
for (const line of tasks.trim().split("\n")) {
  const id = line.split(" ")[0];
  const inLog = done[id] ? log.includes(done[id]) : false;
  console.log(`${id} ${inLog ? "done   " : "not done"} ${line.slice(3)}`);
}
