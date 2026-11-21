import { percentile } from "./random.ts";

// the last 10 stories: estimated and actual days
const estimated = [2, 1, 3, 2, 5, 1, 3, 2, 4, 1];
const actual = [3, 1, 5, 2, 9, 2, 3, 4, 5, 3];

// how much longer than estimated each one took
const ratios = actual
  .map((days, i) => days / estimated[i]!)
  .sort((a, b) => a - b);
const over = ratios.filter((r) => r > 1).length;

console.log(`took longer than estimated: ${over} / ${ratios.length}`);
console.log(`median ratio: ×${percentile(ratios, 50).toFixed(2)}`);
const [low, high] = [10, 90].map((p) => percentile(ratios, p).toFixed(2));
console.log(`middle 80%: ×${low} … ×${high}`);
