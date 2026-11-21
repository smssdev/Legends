import { month } from "./traffic.ts";

const objective = 0.999;
const minutes = month();
const requests = minutes.reduce((n, m) => n + m.requests, 0);
const failed = minutes.reduce((n, m) => n + m.failed, 0);
// a good request: answered, without a server error
const availability = (requests - failed) / requests;
// the error budget: how many requests may fail this month
const budget = Math.floor(requests * (1 - objective));

const n = (x: number) => x.toLocaleString("en").padStart(10);
const pct = (x: number, d = 3) => `${(x * 100).toFixed(d)}%`.padStart(10);
console.log("requests".padEnd(16), n(requests));
console.log("failed".padEnd(16), n(failed));
console.log(
  "availability".padEnd(16),
  pct(availability),
  " objective",
  pct(objective, 1).trim(),
);
console.log("error budget".padEnd(16), n(budget), " failed requests");
console.log("used".padEnd(16), pct(failed / budget, 0));
console.log(availability >= objective ? "objective kept" : "objective missed");
console.log();

// the budget left at the end of each day
let spent = 0;
console.log("day".padEnd(4), "left".padStart(5));
for (let day = 1; day <= 30; day++) {
  const before = spent;
  spent += minutes.filter((m) => m.day === day).reduce((s, m) => s + m.failed, 0);
  const left = Math.max(0, 1 - spent / budget);
  if (day % 5 === 0 || spent - before > budget * 0.02) {
    const bar = "█".repeat(Math.round(left * 40));
    console.log(String(day).padEnd(4), pct(left, 0).trim().padStart(5), bar);
  }
}
