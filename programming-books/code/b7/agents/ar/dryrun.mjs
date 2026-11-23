import fs from "node:fs";
import {execFileSync} from "node:child_process";
import {runAgent} from "./lib/agent.mjs";

// تشغيل تجريبي: الكتابات تُسجَّل ولا تُطبَّق، وتُعرض فرقاً ليوافق عليه
// إنسان.
const {log, writes} = await runAgent({
  root: "cafe4",
  system: "أنت وكيل برمجة يعمل في مشروع JavaScript صغير. استخدم الأدوات: انظر في الملفات، واقرأ ما تحتاجه، وغيّر الكود، وشغّل الاختبارات حتى تنجح. لا تغيّر الاختبارات. وحين تنتهي، قل ما غيّرته في جملة واحدة.",
  task: "الاختبارات تفشل. اجعلها تنجح.",
  dryRun: true,
});
console.log(log.join("\n"));
for (const {file, content} of writes) {
  fs.writeFileSync("proposed.tmp", content);
  try {
    const labels = ["--label", file, "--label", `${file} (proposed)`];
    execFileSync("diff", ["-u", ...labels, `cafe4/${file}`, "proposed.tmp"], {encoding: "utf8"});
  } catch (error) {
    console.log(error.stdout);
  }
}
console.log(`--- ${writes.length} change(s) proposed, none applied`);
