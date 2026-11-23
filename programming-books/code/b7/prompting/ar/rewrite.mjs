import {ask} from "./lib/ask.mjs";
import {cases, score} from "./harness.mjs";

// دع النموذج يعيد كتابة أمر غامض، ثم أعطِ الاثنين درجة على الحالات نفسها.
const vague = "Is this a bug, feature, question or billing?";
const better = await ask(`أعد كتابة هذا الأمر لنموذج لغوي ليكون واضحاً ومحدداً. أبقِ المهمة نفسها. أجب بالأمر الجديد فقط.\n\n${vague}`);
console.log(`rewritten: ${better}\n`);
for (const prompt of [vague, better]) {
  console.log(`${await score(prompt, cases)} of ${cases.length}`);
}
