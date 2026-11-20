import { CircuitBreaker, call, retry } from "./resilience.ts";

const URL = "http://localhost:4000/checkouts";
const strategy = process.argv[2] ?? "none";
const breaker = new CircuitBreaker();

const attempt: Record<string, () => Promise<unknown>> = {
  none: () => call(URL),
  timeout: () => call(URL, 500),
  retry: () => retry(() => call(URL, 500)),
  breaker: () => breaker.run(() => retry(() => call(URL, 500))),
};

let ok = 0;
let failed = 0;
let slowest = 0;
const started = performance.now();
// 4 calls at a time, 40 in all, like 4 busy customers
const queue = Array.from({ length: 40 }, (_, i) => i);
await Promise.all(
  Array.from({ length: 4 }, async () => {
    while (queue.shift() !== undefined) {
      const start = performance.now();
      try {
        await attempt[strategy]!();
        ok++;
      } catch {
        failed++;
      }
      slowest = Math.max(slowest, performance.now() - start);
    }
  }),
);
const { seen } = await (await fetch("http://localhost:4000/stats")).json();
const ms = (n: number) => `${Math.round(n)} ms`;
console.log(
  strategy.padEnd(9),
  String(ok).padStart(3),
  String(failed).padStart(7),
  ms(slowest).padStart(9),
  ms(performance.now() - started).padStart(9),
  String(seen).padStart(12),
);
