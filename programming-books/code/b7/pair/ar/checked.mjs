import fs from "node:fs";
import {ask, codeOf} from "./lib/ask.mjs";
import {failures, runTests} from "./lib/tests.mjs";

// النموذج يكتب الاختبارات؛ وتنفيذ صحيح يتحقق منها.
const correct = `export function splitBill(total, people, tipPercent) {
  if (people < 1) {
    throw new RangeError("people must be at least 1");
  }
  const sum = total + Math.round((total * tipPercent) / 100);
  const base = Math.floor(sum / people);
  const extra = sum - base * people;
  return Array.from({length: people}, (_, i) => base + (i < extra ? 1 : 0));
}
`;
fs.mkdirSync("checked", {recursive: true});
fs.writeFileSync("checked/bill.mjs", correct);
const spec = "الدالة splitBill(total, people, tipPercent) تقسم فاتورة مقهى. total بالقروش (عدد صحيح)، وpeople عدد صحيح لا يقل عن 1، وtipPercent عدد صحيح مثل 10. البقشيش هو total * tipPercent / 100، مقرّباً لأقرب قرش. وتعيد مصفوفة فيها مبلغ صحيح لكل شخص، مجموعها بالضبط total مع البقشيش؛ وحين لا تنقسم بالتساوي، يدفع الأوائل قرشاً زائداً. وترمي RangeError إن كان people أقل من 1. أمثلة: splitBill(1000, 3, 10) تعيد [367, 367, 366]؛ وsplitBill(995, 2, 15) تعيد [572, 572]؛ وsplitBill(1000, 4, 0) تعيد [250, 250, 250, 250].";
const tests = codeOf(await ask(`${spec}\n\nاكتب اختبارات لهذه الدالة بـ node:test وnode:assert/strict، مستورداً splitBill من ./bill.mjs. غطِّ الحالة العادية، والقسمة غير المتساوية، وبقشيشاً يحتاج تقريباً، والخطأ. أعِد الكود فقط، في كتلة كود واحدة.`)) ?? "";
fs.writeFileSync("checked/bill.test.mjs", tests);
const result = runTests("checked/bill.test.mjs");
console.log(`tests written by the model, against a correct splitBill: ${result.summary}`);
console.log(failures(result.output) || "(no failures)");
