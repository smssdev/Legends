import {ask} from "./lib/ask.mjs";

// الأسئلة أولاً، قبل أي مواصفات.
const answer = await ask("بطاقة ولاء في تطبيق مقهانا: كل قهوة عاشرة مجانية.\n\nقبل أن يكتب أحد مواصفات هذه الفكرة، ما الأسئلة التي يجب أن يجيب عنها المقهى؟ اسرد أهم عشرة، في سطر لكل منها.");
console.log(answer);

// الأسئلة المهمة لبطاقة ولاء، كأنماط؛ أيها سأل النموذج؟
const matter = {
  "which drinks count":
    /which (drinks|items|products)|what (counts|qualifies)|eligib|count toward|exclusion|certain drinks|definition of|أي المشروبات|أي مشروب|تُحسب|يُحسب/i,
  "refunds and cancellations": /refund|cancel|return|استرد|إلغاء|إرجاع/i,
  "expiry": /expir|valid for|time limit|reset|صلاحي|تنتهي|مدة/i,
  "what the free drink can be":
    /free (drink|coffee|item).*(any|which|size|price|limit)|value of the free|المجاني.*(حجم|سعر|أي)/i,
  "several branches": /branch|location|store|shop|فرع|فروع/i,
  "abuse and fraud": /fraud|abuse|cheat|misuse|share|transfer|احتيال|تلاعب|غش|مشاركة/i,
  "existing customers and past orders": /existing|past (orders|purchases)|retroactive|already|الحاليين|السابقة|الجدد/i,
};
console.log("--- the questions that matter");
for (const [name, pattern] of Object.entries(matter)) {
  console.log(`${pattern.test(answer) ? "asked " : "MISSED"} ${name}`);
}
