import { readFile } from "node:fs/promises";

console.log("script starts");
setTimeout(() => console.log("timer (0 ms)"), 0);
Promise.resolve().then(() => console.log("promise callback"));
process.nextTick(() => console.log("process.nextTick"));
console.log("script ends");

// wait for some I/O, then a second experiment
await readFile(import.meta.filename);
const asked = performance.now();
setTimeout(() => {
  const late = Math.round(performance.now() - asked);
  console.log(`timer asked for 10 ms, ran after ${late} ms`);
}, 10);
const until = performance.now() + 200;
while (performance.now() < until); // busy for 200 ms
