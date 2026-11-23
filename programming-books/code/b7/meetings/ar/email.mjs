import {ask} from "./lib/ask.mjs";
import {newNumbers} from "./lib/facts.mjs";

const facts = "الحقائق: من 1 يناير يصير سعر اللاتيه الكبير 50 جنيهاً بدل 45؛ وكل الأسعار الأخرى تبقى كما هي؛ وبطاقة الولاء تبدأ يوم الاثنين 8 ديسمبر في الفرعين.";
const email = await ask(`اكتب رسالة بريد قصيرة لطيفة من المقهى إلى عملائه تعلن هذه الحقائق. 120 كلمة على الأكثر. استخدم الحقائق المعطاة وحدها.\n\n${facts}`, {maxTokens: 400});
console.log(email);

// كل رقم في الرسالة يجب أن يأتي من الحقائق المعطاة.
const words = email.split(/\s+/).length;
const invented = newNumbers(email, facts);
console.log(`--- ${words} words; numbers not in the facts: ${invented.join(", ") || "none"}`);
