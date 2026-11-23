import fs from "node:fs";
import {ask} from "./lib/ask.mjs";
import {criteria, vagueWords} from "./lib/vague.mjs";

const spec = await ask("بطاقة ولاء في تطبيق مقهانا: كل قهوة عاشرة مجانية.\nأجوبة المقهى: لا تُحسب إلا المشروبات الساخنة المدفوعة، بأي حجم؛ والطوابع لا تنتهي صلاحيتها؛ وبطاقة واحدة لكل حساب؛ والمشروب المسترد يُلغي طابعه؛ والمشروب المجاني أي مشروب ساخن حتى سعر اللاتيه الكبير؛ والفرعان يتشاركان البطاقة.\n\nاكتب مواصفات قصيرة لهذه الميزة: ملخصاً، والقواعد، ومعايير قبول بصيغة Given / When / Then، في سطر لكل منها. استخدم الأجوبة المعطاة وحدها؛ ولا تضف ميزات.", {maxTokens: 900});
fs.writeFileSync("spec.md", spec);
console.log(spec);

// كلمات تبدو متطلبات لكن لا يمكن اختبارها.
const vague = vagueWords(spec);
console.log(`--- vague words: ${[...vague].map(([w, n]) => `${w} (${n})`).join(", ") || "none"}`);

// كل معيار قبول يجب أن يكون فيه Given وWhen وThen.
const found = criteria(spec);
console.log(`--- ${found.length} acceptance criteria, ${found.filter((c) => !c.ok).length} not in the form`);
