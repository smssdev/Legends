import {ask} from "./lib/ask.mjs";

// الأمر كود: شغّله على حالات أجوبتها معروفة، وأعطه درجة.
export async function score(prompt, cases) {
  let right = 0;
  for (const [message, expected] of cases) {
    const label = (await ask(`${prompt}\n\n"${message}"`)).toLowerCase();
    right += label === expected ? 1 : 0;
  }
  return right;
}

export const cases = [
  ["التطبيق يتوقف حين أفتح طلباتي", "bug"],
  ["أرجو إضافة الوضع الليلي", "feature"],
  ["خُصم مني المبلغ مرتين لكوب لاتيه واحد", "billing"],
  ["هل توصلون إلى مدينة نصر؟", "question"],
  ["سيكون جميلاً لو أستطيع حفظ طلبي المعتاد", "feature"],
  ["لا يحدث شيء حين أضغط ادفع", "bug"],
  ["لماذا توجد رسوم خدمة في إيصالي؟", "billing"],
  ["متى تفتحون يوم الجمعة؟", "question"],
];

if (process.argv[1].endsWith("harness.mjs")) {
  for (const prompt of [
    "Is this a bug, feature, question or billing?",
    "صنّف هذه الرسالة من عميل تطبيق مقهى إلى bug أو feature أو question أو billing. أجب بالتصنيف فقط.",
  ]) {
    console.log(`${await score(prompt, cases)} of ${cases.length}  ${prompt}`);
  }
}
