import {ask} from "./lib/ask.mjs";

const messages = [
  ["The app crashes when I open my orders", "bug"],
  ["Please add a dark mode", "feature"],
  ["I was charged twice for one latte", "billing"],
  ["Do you deliver to Nasr City?", "question"],
  ["It would be nice to save my usual order", "feature"],
  ["Nothing happens when I press Pay", "bug"],
  ["Why is there a service fee on my receipt?", "billing"],
  ["What time do you open on Friday?", "question"],
];

// Instructions alone, then the same instructions with four examples.
const instruction = "Classify this message from a customer of a café app as bug, feature, question or billing. Reply with the label only.";
const examples = "Examples:\n“The menu shows yesterday's prices” -> bug\n“Can I pay with a gift card in the future?” -> feature\n“My refund has not arrived” -> billing\n“Is the café open on holidays?” -> question";

for (const [label, prompt] of [
  ["instructions only", instruction],
  ["with examples", `${instruction}\n\n${examples}`],
]) {
  let right = 0;
  for (const [message, expected] of messages) {
    const label = (await ask(`${prompt}\n\n"${message}"`)).toLowerCase();
    if (label === expected) {
      right++;
    } else {
      console.log(`  wrong: "${message}" -> ${label} (expected ${expected})`);
    }
  }
  console.log(`${label}: ${right} of ${messages.length}\n`);
}
