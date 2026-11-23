import {loadModel} from "./lib/model.mjs";

const model = await loadModel();
const LIMIT = 200;

// ارفض المدخل الطويل جداً قبل أن يصل إلى النموذج، بعدّ الرموز.
export function check(text) {
  const tokens = model.tokenize(text).length;
  return tokens <= LIMIT ? {ok: true, tokens} : {ok: false, tokens, error: `too long: ${tokens} tokens, limit ${LIMIT}`};
}

const short = "هل أستطيع استخدام بطاقة الولاء في الفرعين؟";
const long = "لخّص هذا من فضلك: " + "هل أستطيع استخدام بطاقة الولاء في الفرعين؟ ".repeat(40);
for (const text of [short, long]) {
  console.log(JSON.stringify(check(text)));
}
