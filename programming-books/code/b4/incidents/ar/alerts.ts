import { during, month } from "./traffic.ts";

const minutes = month();
const budgetRate = 1 - 0.999;
// مجاميع متراكمة، فكل نافذة عملية طرح واحدة
const req = [0];
const bad = [0];
for (const m of minutes) {
  req.push(req.at(-1)! + m.requests);
  bad.push(bad.at(-1)! + m.failed);
}
const rate = (end: number, length: number) => {
  const start = Math.max(0, end - length);
  return (bad[end]! - bad[start]!) / (req[end]! - req[start]!);
};

// نبّه شخصاً فقط حين تحترق الميزانية بسرعة؛ وافتح تذكرة حين تحترق ببطء
const rules = [
  // التنبيه الذي يبدأ به فرق كثيرة: فشل أكثر من 1% في الدقيقة الأخيرة
  { name: "ساذج: >1% في دقيقة", check: (i: number) => rate(i, 1) > 0.01 },
  // النافذة الطويلة تثبت أن الأمر مهم، والقصيرة تثبت أنه ما زال يحدث
  {
    name: "استدعاء: 14.4x لساعة و5 دقائق",
    check: (i: number) => burns(i, 14.4, 60, 5),
  },
  {
    name: "استدعاء: 6x لـ6 ساعات و30 دقيقة",
    check: (i: number) => burns(i, 6, 360, 30),
  },
  { name: "تذكرة: 3x ليوم وساعتين", check: (i: number) => burns(i, 3, 1440, 120) },
];
function burns(i: number, factor: number, long: number, short: number) {
  return (
    rate(i, long) > factor * budgetRate && rate(i, short) > factor * budgetRate
  );
}

console.log(
  "القاعدة".padEnd(31),
  "أطلق".padStart(6),
  "حقيقي".padStart(6),
  "كاذب".padStart(7),
);
for (const rule of rules) {
  const fired: number[] = [];
  let firing = false;
  for (let i = 1; i <= minutes.length; i++) {
    const now = rule.check(i);
    if (now && !firing) fired.push(i - 1);
    firing = now;
  }
  const real = fired.filter(during).length;
  const at = (i: number) => `اليوم ${minutes[i]!.day} ${minutes[i]!.time}`;
  const when = fired.length < 4 ? fired.map(at).join(", ") : "";
  console.log(
    [
      rule.name.padEnd(31),
      String(fired.length).padStart(6),
      String(real).padStart(6),
      String(fired.length - real).padStart(7),
      when,
    ]
      .join(" ")
      .trimEnd(),
  );
}
