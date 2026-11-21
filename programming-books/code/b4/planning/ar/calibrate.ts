import { percentile } from "./random.ts";

// آخر 10 قصص: الأيام المقدّرة والفعلية
const estimated = [2, 1, 3, 2, 5, 1, 3, 2, 4, 1];
const actual = [3, 1, 5, 2, 9, 2, 3, 4, 5, 3];

// كم استغرقت كل واحدة أطول مما قُدّر
const ratios = actual
  .map((days, i) => days / estimated[i]!)
  .sort((a, b) => a - b);
const over = ratios.filter((r) => r > 1).length;

console.log(`استغرقت أطول مما قُدّر: ${over} / ${ratios.length}`);
console.log(`النسبة الوسيطة: ×${percentile(ratios, 50).toFixed(2)}`);
const [low, high] = [10, 90].map((p) => percentile(ratios, p).toFixed(2));
console.log(`الـ80% الوسطى: ×${low} … ×${high}`);
