import { percentile, random } from "./random.ts";

// ميزة العربون، بالأيام: [أفضل حال، والأرجح، وأسوأ حال]
type Range = [best: number, likely: number, worst: number];
const tasks: [string, Range][] = [
  ["الدفع لدى المزوّد", [2, 3, 6]],
  ["Webhook وحالات الدفع", [2, 4, 10]],
  ["الاسترداد عند الإلغاء", [1, 2, 6]],
  ["صفحة الحجز: دفع العربون", [2, 3, 5]],
  ["شاشة المالك: العربون والاسترداد", [1, 2, 4]],
  ["اختبارات شاملة وإطلاق", [1, 2, 5]],
];

// مدة ممكنة واحدة: مثلث من الأفضل إلى الأسوأ، قمته عند الأرجح
function draw(next: () => number, [best, likely, worst]: Range) {
  const u = next();
  const cut = (likely - best) / (worst - best);
  return u < cut
    ? best + Math.sqrt(u * (worst - best) * (likely - best))
    : worst - Math.sqrt((1 - u) * (worst - best) * (worst - likely));
}

// ما يُقال عادةً: مجموع الأرقام الأرجح
const naive = tasks.reduce((sum, [, range]) => sum + range[1], 0);

// 10,000 مشروع ممكن، كل مهمة فيه تُسحب وحدها
const next = random(14);
const runs = Array.from({ length: 10_000 }, () =>
  tasks.reduce((sum, [, range]) => sum + draw(next, range), 0),
).sort((a, b) => a - b);

const chance = Math.round(
  (runs.filter((d) => d <= naive).length / runs.length) * 100,
);
console.log(
  `مجموع الأرجح: ${naive} يوماً؛ فرصة الانتهاء خلالها: ${chance}%`,
);
for (const p of [50, 85, 95]) {
  console.log(`P${p}: ${Math.ceil(percentile(runs, p))} يوماً`);
}
