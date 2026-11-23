import {execSync} from "node:child_process";
import {ask, readProject} from "./lib/ask.mjs";

console.log(await ask(`في هذا المشروع، أين يتقرر أن عملاء VIP يدفعون أقل، وبكم؟ سمِّ الملف واقتبس السطر.\n\n${readProject("legacy")}`));

// الجواب عن مكان شيء يُتحقق منه في ثانية: ابحث عنه.
console.log("--- grep -rn VIP legacy/lib");
console.log(execSync("grep -rn VIP legacy/lib", {encoding: "utf8"}).trim());
