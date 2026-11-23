import {ask} from "./lib/ask.mjs";

// سؤال جوابه ليس في التوثيق، يُسأل مرتين.
const doc = "خيارات cafe.yml:\n- port: المنفذ الذي تستمع عليه الخدمة (الافتراضي 8080).\n- menu_file: مسار القائمة (الافتراضي menu.json).\n- tax_rate: الضريبة المضافة لكل طلب (الافتراضي 0.14).";
const question = "ماذا يفعل الخيار retry_delay، وما قيمته الافتراضية؟";

console.log(`> ${question}\n${await ask(`${doc}\n\n${question}`)}\n`);
console.log(`> ${question} أجب من التوثيق أعلاه فقط. وإن لم يكن الجواب فيه، فقل: ليس في التوثيق.`);
console.log(await ask(`${doc}\n\n${question}\nأجب من التوثيق أعلاه فقط. وإن لم يكن الجواب فيه، فقل: ليس في التوثيق.`));
