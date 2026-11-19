import { readFile } from "node:fs/promises";

console.log("يبدأ السكربت");
setTimeout(() => console.log("المؤقت (0 ms)"), 0);
Promise.resolve().then(() => console.log("دالة الوعد"));
process.nextTick(() => console.log("process.nextTick"));
console.log("ينتهي السكربت");

// wait for some I/O, then a second experiment
await readFile(import.meta.filename);
const asked = performance.now();
setTimeout(() => {
  const late = Math.round(performance.now() - asked);
  console.log(`مؤقت طلب 10 ms، فعمل بعد ${late} ms`);
}, 10);
const until = performance.now() + 200;
while (performance.now() < until); // مشغول 200 ms
