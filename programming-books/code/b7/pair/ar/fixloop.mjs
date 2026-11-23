import fs from "node:fs";
import {ask, codeOf} from "./lib/ask.mjs";
import {failures, runTests} from "./lib/tests.mjs";

// توقف حين تنجح الاختبارات، أو تنفد الجولات، أو يعود الفشل نفسه.
export async function fixLoop({spec, file, testFile, rounds = 3}) {
  let code = fs.readFileSync(file, "utf8");
  let last = "";
  for (let round = 0; ; round++) {
    const result = runTests(testFile);
    if (result.ok) {
      return `passed after ${round} fixes`;
    }
    const failed = failures(result.output);
    if (round === rounds) {
      return `gave up after ${rounds} fixes: ${result.summary}`;
    }
    if (failed === last) {
      return `stopped: the same failure twice (${result.summary})`;
    }
    last = failed;
    const request = `${spec}\n\n${file}:\n${code}\n\nفشلت الاختبارات بهذه المخرجات. أصلح bill.mjs (لا الاختبارات). أعِد الكود فقط، في كتلة كود واحدة.\n${failed}`;
    code = codeOf(await ask(request)) ?? code;
    fs.writeFileSync(file, code);
  }
}

const broken = `export function splitBill(total, people, tipPercent) {
  const sum = total + (total * tipPercent) / 100;
  return Array(people).fill(sum / people);
}
`;
fs.mkdirSync("loop", {recursive: true});
fs.writeFileSync("loop/bill.mjs", broken);
fs.copyFileSync("bill/bill.test.mjs", "loop/bill.test.mjs");
const spec = "الدالة splitBill(total, people, tipPercent) تقسم فاتورة مقهى. total بالقروش (عدد صحيح)، وpeople عدد صحيح لا يقل عن 1، وtipPercent عدد صحيح مثل 10. البقشيش هو total * tipPercent / 100، مقرّباً لأقرب قرش. وتعيد مصفوفة فيها مبلغ صحيح لكل شخص، مجموعها بالضبط total مع البقشيش؛ وحين لا تنقسم بالتساوي، يدفع الأوائل قرشاً زائداً. وترمي RangeError إن كان people أقل من 1. أمثلة: splitBill(1000, 3, 10) تعيد [367, 367, 366]؛ وsplitBill(995, 2, 15) تعيد [572, 572]؛ وsplitBill(1000, 4, 0) تعيد [250, 250, 250, 250].";
const file = "loop/bill.mjs";
console.log(await fixLoop({spec, file, testFile: "loop/bill.test.mjs"}));
