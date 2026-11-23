import fs from "node:fs";
import {ask} from "./lib/ask.mjs";
import {run} from "./lib/run.mjs";

// شغّل البرنامج، واحتفظ بمخرجات خطئه، وأعطِ الاثنين للنموذج.
const {output} = run("shop/report.mjs");
const trace = output.split("\n").filter((line) => !line.includes("node:internal"));
console.log(trace.join("\n").trim());

const files = ["shop/report.mjs", "shop/orders.mjs", "shop/menu.mjs"]
  .map((file) => `--- ${file}\n${fs.readFileSync(file, "utf8")}`)
  .join("\n");
const answer = await ask(`انهار هذا البرنامج. اشرح الخطأ في جملتين، ثم سمِّ الملف ورقم السطر حيث الخطأ (لا حيث انهار فقط)، هكذا: BUG AT file:line\n\n${trace.join("\n")}\n\n${files}`);
console.log(`\n--- the model:\n${answer}`);

// النموذج يسمّي سطراً؛ ونتحقق منه مقابل السطر الذي فيه الخطأ فعلاً.
const named = answer.match(/BUG AT\s*`?(?:file:\s*)?([\w/.]+):(\d+)/);
console.log(`\nnamed: ${named ? `${named[1]}:${named[2]}` : "(none)"}`);
console.log("the crash: shop/orders.mjs:5 (drink is undefined)");
console.log("the cause: shop/report.mjs:5 (a drink that is not on the menu)");
