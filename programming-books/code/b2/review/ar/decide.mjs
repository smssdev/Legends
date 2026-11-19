// code/b2/review/ar/decide.ts
var criteria = { fit: 5, learn: 3, speed: 3, community: 2, cost: 2 };
var names = {
  fit: "\u064A\u0646\u0627\u0633\u0628 \u0623\u062F\u0648\u0627\u062A\u0646\u0627",
  learn: "\u0633\u0647\u0644 \u0627\u0644\u062A\u0639\u0644\u0645",
  speed: "\u0633\u0631\u0639\u0629 \u0627\u0644\u0627\u062E\u062A\u0628\u0627\u0631\u0627\u062A",
  community: "\u0627\u0644\u0645\u062C\u062A\u0645\u0639 \u0648\u0627\u0644\u062A\u0648\u062B\u064A\u0642",
  cost: "\u0627\u0644\u0643\u0644\u0641\u0629"
};
var options = {
  Playwright: { fit: 5, learn: 3, speed: 4, community: 4, cost: 5 },
  Cypress: { fit: 4, learn: 5, speed: 3, community: 5, cost: 4 },
  "\u0627\u0644\u0627\u062E\u062A\u0628\u0627\u0631 \u0627\u0644\u064A\u062F\u0648\u064A \u0648\u062D\u062F\u0647": { fit: 2, learn: 5, speed: 1, community: 3, cost: 2 }
};
function total(scores, weights) {
  return Object.keys(weights).reduce((sum, c) => sum + scores[c] * weights[c], 0);
}
function winner(weights) {
  return Object.entries(options).sort(([, a], [, b]) => total(b, weights) - total(a, weights))[0][0];
}
console.log("\u0627\u0644\u062E\u064A\u0627\u0631".padEnd(22) + "\u0627\u0644\u0646\u062A\u064A\u062C\u0629");
for (const [name, scores] of Object.entries(options)) console.log(name.padEnd(22) + total(scores, criteria));
console.log(`\u0627\u0644\u0641\u0627\u0626\u0632: ${winner(criteria)}`);
for (const c of Object.keys(criteria)) {
  console.log(`  \u0625\u0630\u0627 "${names[c]}" \u062D\u064F\u0633\u0628 \u0645\u0631\u062A\u064A\u0646 \u2192 ${winner({ ...criteria, [c]: criteria[c] * 2 })}`);
}
