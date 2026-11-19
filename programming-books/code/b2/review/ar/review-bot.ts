import { readFileSync } from "node:fs";

// يقرأ فروق طلب الدمج ويعلّق على الأسطر التي تستطيع الآلة الحكم عليها
type Finding = { file: string; line: number; message: string };

const diff = readFileSync(process.argv[2] ?? "pr.diff", "utf8").split("\n");
const findings: Finding[] = [];
const changedFiles = new Set<string>();
let file = "";
let line = 0;
let changed = 0;

for (const text of diff) {
  if (text.startsWith("+++ ")) {
    file = text.slice(6); // "+++ b/src/cart/discount.ts"
    changedFiles.add(file);
    continue;
  }
  const hunk = /^@@ -\d+(?:,\d+)? \+(\d+)/.exec(text);
  if (hunk) {
    line = Number(hunk[1]); // أرقام الأسطر في الملف الجديد تبدأ من ترويسة @@ لكل جزء من الفروق
    continue;
  }
  if (text.startsWith("-") && !text.startsWith("---")) {
    changed++;
    continue;
  }
  if (!text.startsWith("+") || text.startsWith("+++")) {
    if (text.startsWith(" ")) line++;
    continue;
  }
  changed++;
  const code = text.slice(1);
  const say = (message: string) => findings.push({ file, line, message });
  if (/console\.log\(/.test(code)) say("console.log متروك: احذفه، أو استخدم أداة السجلات في التطبيق");
  if (/:\s*any\b/.test(code)) say("“any” يطفئ فحص الأنواع هنا: اكتب النوع الحقيقي");
  if (/[^=!]==[^=]/.test(code)) say("“==” يحوّل الأنواع قبل المقارنة: استخدم “===”");
  if (/TODO(?!.*#\d+)/.test(code)) say("TODO بلا رقم مهمة: اربطه بواحدة (#123)، أو أنجزه الآن");
  line++;
}

const isTest = (f: string) => /\.test\.ts$/.test(f);
const code = [...changedFiles].filter((f) => f.endsWith(".ts") && !isTest(f));
if (code.length > 0 && ![...changedFiles].some(isTest)) findings.push({ file: code[0]!, line: 1, message: "تغيّر الكود، ولم يتغير أي اختبار" });
if (changed > 300) findings.push({ file: "*", line: 0, message: "{n} سطراً متغيراً: يصعب مراجعتها جيداً، قسّمه (أقل من 300)".replace("{n}", String(changed)) });

for (const f of findings) console.log(`${f.file}:${f.line}  ${f.message}`);
console.log(findings.length ? `${findings.length} ملاحظات` : "لا شيء يقوله الروبوت. الكلمة للبشر.");
