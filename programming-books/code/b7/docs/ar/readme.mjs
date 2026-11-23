import fs from "node:fs";
import {ask} from "./lib/ask.mjs";

const source = fs.readFileSync("report.mjs", "utf8");
const readme = await ask(`اكتب قسم الاستخدام (Usage) في README لأداة سطر الأوامر هذه: كيف تُشغَّل، وكل خيار، ومثالان. بـ Markdown، 25 سطراً على الأكثر.\n\n${source}`);
console.log(readme);

// كل خيار يذكره الـ README يجب أن يكون موجوداً في الكود.
console.log("--- options in the README");
const options = new Set(readme.match(/--[a-z][\w-]*/g) ?? []);
for (const option of options) {
  const exists = source.includes(`${option.slice(2)}: {`);
  console.log(`${exists ? "exists " : "INVENTED"} ${option}`);
}
