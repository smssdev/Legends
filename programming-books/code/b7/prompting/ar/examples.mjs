import {ask} from "./lib/ask.mjs";

const messages = [
  ["التطبيق يتوقف حين أفتح طلباتي", "bug"],
  ["أرجو إضافة الوضع الليلي", "feature"],
  ["خُصم مني المبلغ مرتين لكوب لاتيه واحد", "billing"],
  ["هل توصلون إلى مدينة نصر؟", "question"],
  ["سيكون جميلاً لو أستطيع حفظ طلبي المعتاد", "feature"],
  ["لا يحدث شيء حين أضغط ادفع", "bug"],
  ["لماذا توجد رسوم خدمة في إيصالي؟", "billing"],
  ["متى تفتحون يوم الجمعة؟", "question"],
];

// التعليمات وحدها، ثم التعليمات نفسها مع أربعة أمثلة.
const instruction = "صنّف هذه الرسالة من عميل تطبيق مقهى إلى bug أو feature أو question أو billing. أجب بالتصنيف فقط.";
const examples = "أمثلة:\n«القائمة تعرض أسعار الأمس» -> bug\n«هل أستطيع الدفع ببطاقة هدية مستقبلاً؟» -> feature\n«لم يصلني المبلغ المسترد» -> billing\n«هل المقهى مفتوح في العطلات؟» -> question";

for (const [label, prompt] of [
  ["instructions only", instruction],
  ["with examples", `${instruction}\n\n${examples}`],
]) {
  let right = 0;
  for (const [message, expected] of messages) {
    const label = (await ask(`${prompt}\n\n"${message}"`)).toLowerCase();
    if (label === expected) {
      right++;
    } else {
      console.log(`  wrong: "${message}" -> ${label} (expected ${expected})`);
    }
  }
  console.log(`${label}: ${right} of ${messages.length}\n`);
}
