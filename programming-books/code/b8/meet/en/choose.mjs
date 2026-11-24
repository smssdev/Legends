// A first choice of model from three questions about the task.
export function chooseModel({hard, longRunning, highVolume}) {
  if (highVolume && !hard) return "claude-haiku-5-5";
  if (hard && longRunning) return "claude-fable-5-2";
  if (hard) return "claude-opus-5-5";
  return "claude-sonnet-5-5";
}

const tasks = [
  ["classify support tickets", {hard: false, longRunning: false, highVolume: true}],
  ["answer customers in a chat", {hard: false, longRunning: false, highVolume: false}],
  ["refactor a large codebase", {hard: true, longRunning: false, highVolume: false}],
  ["plan a migration with many unknowns", {hard: true, longRunning: true, highVolume: false}],
];
for (const [task, answers] of tasks) {
  console.log(`${task.padEnd(38)} ${chooseModel(answers)}`);
}
