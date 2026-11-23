import fs from "node:fs";
import {ask, codeOf} from "./lib/ask.mjs";
import {broken, failures, runTests} from "./lib/tests.mjs";

// المواصفات، تُكتب مرة وتُستخدم في كل خطوة.
const spec = "الدالة splitBill(total, people, tipPercent) تقسم فاتورة مقهى. total بالقروش (عدد صحيح)، وpeople عدد صحيح لا يقل عن 1، وtipPercent عدد صحيح مثل 10. البقشيش هو total * tipPercent / 100، مقرّباً لأقرب قرش. وتعيد مصفوفة فيها مبلغ صحيح لكل شخص، مجموعها بالضبط total مع البقشيش؛ وحين لا تنقسم بالتساوي، يدفع الأوائل قرشاً زائداً. وترمي RangeError إن كان people أقل من 1. أمثلة: splitBill(1000, 3, 10) تعيد [367, 367, 366]؛ وsplitBill(995, 2, 15) تعيد [572, 572]؛ وsplitBill(1000, 4, 0) تعيد [250, 250, 250, 250].";

// خطوات صغيرة: خطة، ثم اختبارات، ثم كود. وكل خطوة طلب جديد فيه ما تحتاجه.
console.log("== plan\n" + (await ask(`قبل كتابة أي كود، اسرد في خمسة أسطر قصيرة على الأكثر الخطوات التي ستتبعها لتنفيذ هذا:\n\n${spec}`)));

let tests = codeOf(await ask(`${spec}\n\nاكتب اختبارات لهذه الدالة بـ node:test وnode:assert/strict، مستورداً splitBill من ./bill.mjs. غطِّ الحالة العادية، والقسمة غير المتساوية، وبقشيشاً يحتاج تقريباً، والخطأ. أعِد الكود فقط، في كتلة كود واحدة.`)) ?? "";
const count = tests.match(/\btest\(|\bit\(/g)?.length ?? 0;
console.log(`== tests: bill/bill.test.mjs, ${count} tests`);

// قبل أي كود: شغّل الاختبارات على splitBill فارغة. يجب أن تفشل في
// تأكيداتها، لا لأن ملف الاختبارات نفسه معطوب.
const empty = "export function splitBill() {\n  return [];\n}\n";
for (let round = 1; ; round++) {
  fs.writeFileSync("bill/bill.mjs", empty);
  fs.writeFileSync("bill/bill.test.mjs", tests);
  const result = runTests("bill/bill.test.mjs");
  const fine = !broken(result.output);
  console.log(`== tests against an empty splitBill: ${result.summary}`);
  console.log(fine ? "   they fail on their assertions: good" : failures(result.output));
  if (fine || round === 3) {
    break;
  }
  // إن لم يستطع النموذج إصلاح اختباراته، يضيف المطور ما يعرفه، كما يفعل
  // الزميل في البرمجة الثنائية.
  const hint = round > 1 ? "\nتلميح من المطور: هذا المشروع يستخدم وحدات ES، فاستخدم import لا require أبداً؛ وassert هو التصدير الافتراضي لـ node:assert/strict." : "";
  const request = `${spec}\n\nbill.test.mjs:\n${tests}\n\nهذه الاختبارات لا تعمل: تفشل قبل أن تختبر شيئاً، بهذه المخرجات. أصلح ملف الاختبارات. أعِد الكود فقط، في كتلة كود واحدة.${hint}\n${failures(result.output)}`;
  if (hint) {
    console.log(`   (the developer adds: تلميح من المطور: هذا المشروع يستخدم وحدات ES، فاستخدم import لا require أبداً؛ وassert هو التصدير الافتراضي لـ node:assert/strict.)`);
  }
  tests = codeOf(await ask(request)) ?? tests;
}

let code = codeOf(await ask(`${spec}\n\nاكتب bill.mjs، مصدّراً splitBill. أعِد الكود فقط، في كتلة كود واحدة.`));

// شغّل الاختبارات الحقيقية؛ وإن فشلت، أرسل المخرجات من جديد، ثلاث مرات
// على الأكثر.
for (let round = 1; ; round++) {
  fs.writeFileSync("bill/bill.mjs", code);
  const result = runTests("bill/bill.test.mjs");
  console.log(`== round ${round}: ${result.summary}`);
  if (result.ok || round === 4) {
    break;
  }
  console.log(failures(result.output));
  const request = `${spec}\n\nbill.mjs:\n${code}\n\nفشلت الاختبارات بهذه المخرجات. أصلح bill.mjs (لا الاختبارات). أعِد الكود فقط، في كتلة كود واحدة.\n${failures(result.output)}`;
  // An answer without code is not written over the file.
  code = codeOf(await ask(request)) ?? code;
}
