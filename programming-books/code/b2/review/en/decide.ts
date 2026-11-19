// Every score is from 1 (poor) to 5 (excellent); the weights say what matters to this team
const criteria = { fit: 5, learn: 3, speed: 3, community: 2, cost: 2 } as const;
type Criterion = keyof typeof criteria;

const names: Record<Criterion, string> = {
  fit: "Fits our stack", learn: "Easy to learn", speed: "Speed of the tests", community: "Community and docs", cost: "Cost",
};

const options: Record<string, Record<Criterion, number>> = {
  Playwright: { fit: 5, learn: 3, speed: 4, community: 4, cost: 5 },
  Cypress: { fit: 4, learn: 5, speed: 3, community: 5, cost: 4 },
  "Manual testing only": { fit: 2, learn: 5, speed: 1, community: 3, cost: 2 },
};

function total(scores: Record<Criterion, number>, weights: Record<Criterion, number>): number {
  return (Object.keys(weights) as Criterion[]).reduce((sum, c) => sum + scores[c] * weights[c], 0);
}

function winner(weights: Record<Criterion, number>): string {
  return Object.entries(options).sort(([, a], [, b]) => total(b, weights) - total(a, weights))[0]![0];
}

console.log("Option".padEnd(22) + "score");
for (const [name, scores] of Object.entries(options)) console.log(name.padEnd(22) + total(scores, criteria));
console.log(`Winner: ${winner(criteria)}`);

// Which option would win if one criterion mattered twice as much?
for (const c of Object.keys(criteria) as Criterion[]) {
  console.log(`  If "${names[c]}" counted twice → ${winner({ ...criteria, [c]: criteria[c] * 2 })}`);
}
