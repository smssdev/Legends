import fs from "node:fs";
import {ask} from "./lib/ask.mjs";

// اطلب من النموذج شرح الكود قبل أن تقبله، ومنه كيف قد يفشل.
const code = fs.readFileSync("bill/bill.mjs", "utf8");
console.log(await ask(`اشرح هذا الكود سطراً سطراً، ثم قل أي المدخلات قد تجعله يفشل.\n\n${code}`, {maxTokens: 500}));
