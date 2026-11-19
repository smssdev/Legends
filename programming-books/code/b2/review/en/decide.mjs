// code/b2/review/en/decide.ts
var criteria = { fit: 5, learn: 3, speed: 3, community: 2, cost: 2 };
var names = {
  fit: "Fits our stack",
  learn: "Easy to learn",
  speed: "Speed of the tests",
  community: "Community and docs",
  cost: "Cost"
};
var options = {
  Playwright: { fit: 5, learn: 3, speed: 4, community: 4, cost: 5 },
  Cypress: { fit: 4, learn: 5, speed: 3, community: 5, cost: 4 },
  "Manual testing only": { fit: 2, learn: 5, speed: 1, community: 3, cost: 2 }
};
function total(scores, weights) {
  return Object.keys(weights).reduce((sum, c) => sum + scores[c] * weights[c], 0);
}
function winner(weights) {
  return Object.entries(options).sort(([, a], [, b]) => total(b, weights) - total(a, weights))[0][0];
}
console.log("Option".padEnd(22) + "score");
for (const [name, scores] of Object.entries(options)) console.log(name.padEnd(22) + total(scores, criteria));
console.log(`Winner: ${winner(criteria)}`);
for (const c of Object.keys(criteria)) {
  console.log(`  If "${names[c]}" counted twice \u2192 ${winner({ ...criteria, [c]: criteria[c] * 2 })}`);
}
