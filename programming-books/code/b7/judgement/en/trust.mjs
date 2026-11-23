// Impact, reversibility and checkability decide how much to trust a model
// on a task.
// Each factor from 1 (low) to 3 (high).
export function trustLevel({impact, irreversible, hardToCheck}) {
  const risk = impact * irreversible * hardToCheck;
  if (risk <= 4) return "use it: a quick look is enough";
  if (risk <= 12) return "use it, and verify before acting";
  return "do not rely on it: a person decides";
}

const tasks = [
  ["name ideas for a new drink", {impact: 1, irreversible: 1, hardToCheck: 1}],
  ["first draft of a test file", {impact: 2, irreversible: 1, hardToCheck: 1}],
  ["summary of a meeting for the team", {impact: 2, irreversible: 2, hardToCheck: 2}],
  ["price announcement to all customers", {impact: 3, irreversible: 3, hardToCheck: 1}],
  ["deciding a customer's refund", {impact: 3, irreversible: 3, hardToCheck: 2}],
];
for (const [task, factors] of tasks) {
  console.log(`${task.padEnd(38)} ${trustLevel(factors)}`);
}
