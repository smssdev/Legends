import {ask} from "./lib/ask.mjs";
import {numbers} from "./lib/facts.mjs";

const facts = "الحقائق: من 1 يناير يصير سعر اللاتيه الكبير 50 جنيهاً بدل 45؛ وكل الأسعار الأخرى تبقى كما هي؛ وبطاقة الولاء تبدأ يوم الاثنين 8 ديسمبر في الفرعين.";
const friendly = await ask(`اكتب رسالة بريد قصيرة لطيفة من المقهى إلى عملائه تعلن هذه الحقائق. 120 كلمة على الأكثر. استخدم الحقائق المعطاة وحدها.\n\n${facts}`, {maxTokens: 400});
const formal = await ask(`أعد كتابة هذه الرسالة بنبرة أكثر رسمية، لعميل شركة. احتفظ بكل حقيقة.\n\n${friendly}`, {maxTokens: 400});
console.log(formal);

const before = numbers(friendly);
const after = numbers(formal);
const lost = [...before].filter((n) => !after.has(n));
const added = [...after].filter((n) => !before.has(n));
console.log(`--- numbers lost: ${lost.join(", ") || "none"}; added: ${added.join(", ") || "none"}`);
