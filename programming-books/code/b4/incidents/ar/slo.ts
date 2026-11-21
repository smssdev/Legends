import { month } from "./traffic.ts";

const objective = 0.999;
const minutes = month();
const requests = minutes.reduce((n, m) => n + m.requests, 0);
const failed = minutes.reduce((n, m) => n + m.failed, 0);
// الطلب الجيد: أُجيب، بلا خطأ خادم
const availability = (requests - failed) / requests;
// ميزانية الأخطاء: كم طلباً يجوز أن يفشل هذا الشهر
const budget = Math.floor(requests * (1 - objective));

const n = (x: number) => x.toLocaleString("en").padStart(10);
const pct = (x: number, d = 3) => `${(x * 100).toFixed(d)}%`.padStart(10);
console.log("الطلبات".padEnd(16), n(requests));
console.log("فشل".padEnd(16), n(failed));
console.log(
  "التوفر".padEnd(16),
  pct(availability),
  " الهدف",
  pct(objective, 1).trim(),
);
console.log("ميزانية الأخطاء".padEnd(16), n(budget), " طلب فاشل");
console.log("استُهلك".padEnd(16), pct(failed / budget, 0));
console.log(availability >= objective ? "تحقق الهدف" : "لم يتحقق الهدف");
console.log();

// ما بقي من الميزانية في نهاية كل يوم
let spent = 0;
console.log("اليوم".padEnd(4), "بقي".padStart(5));
for (let day = 1; day <= 30; day++) {
  const before = spent;
  spent += minutes.filter((m) => m.day === day).reduce((s, m) => s + m.failed, 0);
  const left = Math.max(0, 1 - spent / budget);
  if (day % 5 === 0 || spent - before > budget * 0.02) {
    const bar = "█".repeat(Math.round(left * 40));
    console.log(String(day).padEnd(4), pct(left, 0).trim().padStart(5), bar);
  }
}
