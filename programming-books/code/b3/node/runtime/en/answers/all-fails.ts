import { setTimeout as sleep } from "node:timers/promises";

const start = performance.now();
const ms = () => `${Math.round(performance.now() - start)} ms`;
const stock = sleep(300, 7).then((value) => {
  console.log(`stock finished anyway at ${ms()}`);
  return value;
});
const price = sleep(200).then(() => {
  throw new Error("price service down");
});
const reviews = sleep(400, 4.5);

try {
  await Promise.all([stock, price, reviews]);
} catch (error) {
  console.log(`Promise.all rejected at ${ms()}: ${(error as Error).message}`);
}
await sleep(300);
