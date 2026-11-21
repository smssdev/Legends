import { percentile, random } from "./random.ts";

// البنود المنجزة في كل أسبوع من الأسابيع الـ12 الماضية، من المتتبع
const done = [4, 6, 3, 5, 0, 7, 5, 4, 6, 2, 5, 6];
// ما بقي: قصص قُسمت مسبقاً إلى حجم صغير متقارب
const backlog = 38;

const next = random(7);
const weeks: number[] = [];
for (let run = 0; run < 10_000; run++) {
  let left = backlog;
  let week = 0;
  while (left > 0) {
    // الأسبوع القادم يشبه أسبوعاً ماضياً، يُختار عشوائياً
    left -= done[Math.floor(next() * done.length)]!;
    week++;
  }
  weeks.push(week);
}
weeks.sort((a, b) => a - b);

// التوقع من الأسبوع المتوسط، للمقارنة
const average = done.reduce((a, b) => a + b, 0) / done.length;
console.log(`بقي: ${backlog} بنداً؛ الأسبوع المتوسط: ${average.toFixed(1)}`);
console.log(`من المتوسط: ${Math.ceil(backlog / average)} أسابيع`);
for (const p of [50, 85, 95]) {
  console.log(`P${p}: ${percentile(weeks, p)} أسابيع`);
}
