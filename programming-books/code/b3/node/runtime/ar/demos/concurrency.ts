import { setTimeout as sleep } from "node:timers/promises";

// Three slow services, as a real API would call over the network.
const stock = (signal?: AbortSignal) => sleep(300, 7, { signal });
const price = (signal?: AbortSignal) => sleep(200, 45000, { signal });
const reviews = (signal?: AbortSignal) => sleep(400, 4.5, { signal });

async function timed(label: string, work: () => Promise<unknown>) {
  const start = performance.now();
  const result = await work();
  console.log(`${label}: ${Math.round(performance.now() - start)} ms`, result);
}

await timed("واحداً بعد الآخر", async () => {
  return [await stock(), await price(), await reviews()];
});

await timed("كلها معاً", () => Promise.all([stock(), price(), reviews()]));

const down = () => Promise.reject(new Error("خدمة المراجعات متوقفة"));
await timed("يفشل واحد، ويبقى الباقي", async () => {
  const results = await Promise.allSettled([stock(), price(), down()]);
  return results.map((r) => (r.status === "fulfilled" ? r.value : "فشل"));
});

await timed("بمهلة 250 ms", async () => {
  const limit = AbortSignal.timeout(250);
  const results = await Promise.allSettled([stock(), price(), reviews(limit)]);
  return results.map((r) =>
    r.status === "fulfilled" ? r.value : "تُخطّيت (بطيئة جداً)",
  );
});
