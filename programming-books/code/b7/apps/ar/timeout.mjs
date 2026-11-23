import {localProvider} from "./lib/providers.mjs";
import {deadline} from "./lib/retry.mjs";

const provider = await localProvider();
const start = performance.now();
try {
  await provider.complete({system: "أنت تجيب عن أسئلة عملاء تطبيق مقهى. أجب في جملة أو جملتين قصيرتين.", prompt: "هل أستطيع استخدام بطاقة الولاء في الفرعين؟", signal: deadline(500)});
  console.log("answered in time");
} catch (error) {
  console.log(`${error.name} after ${Math.round(performance.now() - start)} ms: the app shows a fallback`);
}
