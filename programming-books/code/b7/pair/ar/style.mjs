import fs from "node:fs";
import {ask, codeOf} from "./lib/ask.mjs";

// المهمة نفسها دون ملف من المشروع ومعه، لينسخ أسلوبه.
const task = "اكتب دالة تحمّل القائمة من menu.json.";
const house = fs.readFileSync("house/tables.mjs", "utf8");

console.log("== without an example\n" + codeOf(await ask(task)));
const withHouse = `هذا ملف من مشروعنا. اكتب الدالة الجديدة بالأسلوب نفسه.\n\n${house}\n${task}`;
console.log("== with house/tables.mjs\n" + codeOf(await ask(withHouse)));
