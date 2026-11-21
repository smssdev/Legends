// three ways to run Bit Booking's background jobs (reminders, receipts, reports)
const options = ["PostgreSQL queue", "Redis queue", "cloud queue"];

// what matters to this team, now: weights add up to 100
const criteria = [
  // 1 = poor, 5 = excellent, agreed in the design review, with a reason for each
  { name: "operations", weight: 30, scores: [5, 3, 4] },
  { name: "team knows it", weight: 25, scores: [5, 3, 2] },
  { name: "cost", weight: 20, scores: [5, 4, 3] },
  { name: "scale headroom", weight: 15, scores: [2, 4, 5] },
  { name: "no lock-in", weight: 10, scores: [5, 4, 1] },
];

// the weighted score: a summary of the discussion, not a replacement for it
function totals(weights: number[]) {
  const sum = weights.reduce((a, b) => a + b, 0);
  return options.map((_, o) =>
    criteria.reduce((t, c, i) => t + (weights[i]! * c.scores[o]!) / sum, 0),
  );
}
const best = (scores: number[]) => scores.indexOf(Math.max(...scores));

const weights = criteria.map((c) => c.weight);
const score = totals(weights);
console.log("option".padEnd(18), "score".padStart(6));
for (const [o, name] of options.entries()) {
  console.log(name.padEnd(18), score[o]!.toFixed(2).padStart(6));
}
const winner = best(score);
console.log("winner:", options[winner]);
console.log();

// would the decision change if we had weighed one criterion half or half again?
let stable = true;
for (const [i, c] of criteria.entries()) {
  for (const factor of [0.5, 1.5]) {
    const changed = weights.map((w, j) => (j === i ? w * factor : w));
    const other = best(totals(changed));
    if (other !== winner) {
      stable = false;
      console.log(`${c.name} ×${factor}: changes the winner to ${options[other]}`);
    }
  }
}
if (stable) console.log("stable: no single weight change alters the winner");
