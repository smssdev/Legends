import {ask} from "./lib/ask.mjs";

// الطلب نفسه، غامضاً ومحدداً. والمحدد وحده يقول ما معنى «صحيح».
const vague = "اكتب دالة تتحقق من رقم هاتف.";
const specific =
  "اكتب دالة JavaScript باسم isEgyptianMobile(text) تعيد true فقط " +
  "لأرقام الجوال المصرية: 11 رقماً تبدأ بـ 010 أو 011 أو 012 أو 015، أو الرقم نفسه " +
  "مع +20 بدل الصفر الأول. والمسافات والشرطات بين الأرقام مسموحة. " +
  "أعِد الكود فقط، في كتلة كود واحدة.";

for (const prompt of [vague, specific]) {
  console.log(`> ${prompt}\n${await ask(prompt)}\n`);
}

// ثم يُشغَّل الجواب المحدد على حالات كتبناها، كما يجب مع أي كود.
const answer = await ask(specific);
const code = answer.match(/```(?:\w+)?\n([\s\S]*?)```/)[1];
const isEgyptianMobile = Function(`${code}; return isEgyptianMobile;`)();
const cases = [
  ["01012345678", true],
  ["+20 101 234 5678", true],
  ["015-1234-5678", true],
  ["01312345678", false],
  ["0101234567", false],
  ["phone: 01012345678", false],
];
for (const [text, expected] of cases) {
  const got = isEgyptianMobile(text);
  console.log(`${got === expected ? "pass" : "FAIL"}  ${JSON.stringify(text)} -> ${got}`);
}
