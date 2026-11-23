import fs from "node:fs";
import {ask} from "./lib/ask.mjs";

const code = fs.readFileSync("legacy/lib/calc.js", "utf8");
console.log(await ask(`اشرح بكلمات بسيطة ماذا تفعل calc، كقائمة قواعد يفهمها مدير مقهى. لا تشرح الصياغة البرمجية.\n\n${code}`));
