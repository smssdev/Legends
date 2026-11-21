import { percentile, random } from "./random.ts";

// the deposits feature, in days: [best case, most likely, worst case]
type Range = [best: number, likely: number, worst: number];
const tasks: [string, Range][] = [
  ["Checkout with the provider", [2, 3, 6]],
  ["Webhook and payment states", [2, 4, 10]],
  ["Refunds on cancellation", [1, 2, 6]],
  ["Booking page: pay a deposit", [2, 3, 5]],
  ["Owner screen: deposits and refunds", [1, 2, 4]],
  ["End-to-end tests and release", [1, 2, 5]],
];

// one possible duration: a triangle from best to worst, highest at likely
function draw(next: () => number, [best, likely, worst]: Range) {
  const u = next();
  const cut = (likely - best) / (worst - best);
  return u < cut
    ? best + Math.sqrt(u * (worst - best) * (likely - best))
    : worst - Math.sqrt((1 - u) * (worst - best) * (worst - likely));
}

// what is usually quoted: the sum of the most likely numbers
const naive = tasks.reduce((sum, [, range]) => sum + range[1], 0);

// 10,000 possible projects, each task drawn on its own
const next = random(14);
const runs = Array.from({ length: 10_000 }, () =>
  tasks.reduce((sum, [, range]) => sum + draw(next, range), 0),
).sort((a, b) => a - b);

const chance = Math.round(
  (runs.filter((d) => d <= naive).length / runs.length) * 100,
);
console.log(
  `sum of likely: ${naive} days, chance to finish within it: ${chance}%`,
);
for (const p of [50, 85, 95]) {
  console.log(`P${p}: ${Math.ceil(percentile(runs, p))} days`);
}
