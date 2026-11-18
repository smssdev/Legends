const scores = [72, 95, 48, 83, 61, 90, 55, 77];

let total = 0;
let highest = scores[0];
let lowest = scores[0];
let passed = 0;

for (const score of scores) {
  total += score;
  if (score > highest) highest = score;
  if (score < lowest) lowest = score;
  if (score >= 50) passed++;
}

console.log("عدد الطلاب:", scores.length);
console.log("المتوسط:", total / scores.length);
console.log("الأعلى:", highest);
console.log("الأدنى:", lowest);
console.log("الناجحون:", passed, "/", scores.length);
