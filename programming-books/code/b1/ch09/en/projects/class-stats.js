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

console.log("Students:", scores.length);
console.log("Average:", total / scores.length);
console.log("Highest:", highest);
console.log("Lowest:", lowest);
console.log("Passed:", passed, "/", scores.length);
