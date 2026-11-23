import {ask} from "./lib/ask.mjs";

const problems = [
  ["يفتح مقهى في 7:45 ويغلق بعد 9 ساعات و50 دقيقة. في أي ساعة يغلق؟", "17:35"],
  ["يبدأ اجتماع في 10:40 ويستمر ساعتين و35 دقيقة. متى ينتهي؟", "13:15"],
  ["لدى سارة ثلاثة أضعاف ما لدى عمر من الأكواب. ومعهما معاً 48. كم لدى سارة؟", "36"],
];

// هل طلب طريقة الحل يساعد؟ عُدّ، لا تخمّن.
for (const [label, suffix] of [
  ["direct", "أجب بالنتيجة فقط."],
  ["step by step", "احسبها خطوة خطوة، ثم اكتب النتيجة في السطر الأخير."],
]) {
  let right = 0;
  for (const [problem, expected] of problems) {
    const answer = await ask(`${problem} ${suffix}`, {maxTokens: 400});
    const last = answer.split("\n").filter((line) => line.trim()).at(-1);
    const ok = last.includes(expected);
    right += ok ? 1 : 0;
    console.log(`  ${ok ? "right" : "wrong"}: ${last.slice(0, 50)} (expected ${expected})`);
  }
  console.log(`${label}: ${right} of ${problems.length}\n`);
}
