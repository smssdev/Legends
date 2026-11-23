import {ask} from "./lib/ask.mjs";

// First the questions, before any specification.
const answer = await ask("A loyalty card in our café app: every 10th coffee is free.\n\nBefore anyone writes a specification for this idea, what questions must the café answer? List the ten most important, one line each.");
console.log(answer);

// The questions that matter for a loyalty card, as patterns; which did
// the model ask?
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
