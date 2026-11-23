import {ask} from "./lib/ask.mjs";

// A prompt is code: run it against cases with known answers, and score
// it.
export async function score(prompt, cases) {
  let right = 0;
  for (const [message, expected] of cases) {
    const label = (await ask(`${prompt}\n\n"${message}"`)).toLowerCase();
    right += label === expected ? 1 : 0;
  }
  return right;
}

export const cases = [
  ["The app crashes when I open my orders", "bug"],
  ["Please add a dark mode", "feature"],
  ["I was charged twice for one latte", "billing"],
  ["Do you deliver to Nasr City?", "question"],
  ["It would be nice to save my usual order", "feature"],
  ["Nothing happens when I press Pay", "bug"],
  ["Why is there a service fee on my receipt?", "billing"],
  ["What time do you open on Friday?", "question"],
];

if (process.argv[1].endsWith("harness.mjs")) {
  for (const prompt of [
    "Is this a bug, feature, question or billing?",
    "Classify this message from a customer of a café app as bug, feature, question or billing. Reply with the label only.",
  ]) {
    console.log(`${await score(prompt, cases)} of ${cases.length}  ${prompt}`);
  }
}
