// ثلاث طرق لتشغيل المهام الخلفية في «بِت للحجوزات» (التذكيرات، والإيصالات، والتقارير)
const options = ["طابور PostgreSQL", "طابور Redis", "طابور سحابي"];

// ما يهم هذا الفريق، الآن: مجموع الأوزان 100
const criteria = [
  // 1 = ضعيف، 5 = ممتاز، اتُّفق عليها في مراجعة التصميم، مع سبب لكل منها
  { name: "التشغيل", weight: 30, scores: [5, 3, 4] },
  { name: "يعرفه الفريق", weight: 25, scores: [5, 3, 2] },
  { name: "الكلفة", weight: 20, scores: [5, 4, 3] },
  { name: "هامش التوسع", weight: 15, scores: [2, 4, 5] },
  { name: "بلا ارتهان", weight: 10, scores: [5, 4, 1] },
];

// الدرجة الموزونة: ملخص للنقاش، لا بديل عنه
function totals(weights: number[]) {
  const sum = weights.reduce((a, b) => a + b, 0);
  return options.map((_, o) =>
    criteria.reduce((t, c, i) => t + (weights[i]! * c.scores[o]!) / sum, 0),
  );
}
const best = (scores: number[]) => scores.indexOf(Math.max(...scores));

const weights = criteria.map((c) => c.weight);
const score = totals(weights);
console.log("الخيار".padEnd(18), "الدرجة".padStart(6));
for (const [o, name] of options.entries()) {
  console.log(name.padEnd(18), score[o]!.toFixed(2).padStart(6));
}
const winner = best(score);
console.log("الفائز:", options[winner]);
console.log();

// هل يتغير القرار لو وزنّا معياراً واحداً بنصف وزنه أو بمرة ونصف؟
let stable = true;
for (const [i, c] of criteria.entries()) {
  for (const factor of [0.5, 1.5]) {
    const changed = weights.map((w, j) => (j === i ? w * factor : w));
    const other = best(totals(changed));
    if (other !== winner) {
      stable = false;
      console.log(`${c.name} ×${factor}: يبدّل الفائز إلى ${options[other]}`);
    }
  }
}
if (stable) console.log("ثابت: لا تغيير في وزن واحد يبدّل الفائز");
