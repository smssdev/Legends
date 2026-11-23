import fs from "node:fs";
import {ask, codeOf} from "./lib/ask.mjs";
import {errorLine, run} from "./lib/run.mjs";

const log = fs.readFileSync("logs/night.log", "utf8");
const code = codeOf(await ask(`من هذا السجل، اكتب أصغر سكربت Node مستقل (وحدة ES، بلا ملفات، بلا شبكة) يرمي الخطأ نفسه. أعِد الكود فقط، في كتلة كود واحدة.\n\n${log}`));
fs.writeFileSync("repro/attempt.mjs", code ?? "");
console.log(`--- repro/attempt.mjs\n${code}`);

// إعادة الإنتاج لا تنفع إلا إن فشلت بالطريقة نفسها: شغّلها وقارن الخطأ.
const wanted = errorLine(log);
const got = errorLine(run("repro/attempt.mjs").output);
console.log(`wanted: ${wanted}`);
console.log(`got:    ${got}`);
console.log(got === wanted ? "same error: a reproduction" : "different: not a reproduction yet");
