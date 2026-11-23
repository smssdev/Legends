import {ask} from "./lib/ask.mjs";

const problems = [
  ["A café opens at 7:45 and closes 9 hours and 50 minutes later. At what time does it close?", "17:35"],
  ["A meeting starts at 10:40 and lasts 2 hours and 35 minutes. When does it end?", "13:15"],
  ["Sara has 3 times as many cups as Omar. Together they have 48. How many does Sara have?", "36"],
];

// Does asking for the working help? Count, do not guess.
for (const [label, suffix] of [
  ["direct", "Answer with the result only."],
  ["step by step", "Work it out step by step, then give the result on the last line."],
]) {
  let right = 0;
  for (const [problem, expected] of problems) {
    const answer = await ask(`${problem} ${suffix}`, {maxTokens: 400});
    const last = answer.split("\n").filter((line) => line.trim()).at(-1);
    const ok = last.includes(expected);
    right += ok ? 1 : 0;
    console.log(`  ${ok ? "right" : "wrong"}: ${last.slice(0, 50)} (expected ${expected})`);
  }
  console.log(`${label}: ${right} of ${problems.length}\n`);
}
