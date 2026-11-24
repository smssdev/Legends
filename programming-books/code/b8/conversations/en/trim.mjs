import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();
const model = "claude-opus-5-5";

// Drop the oldest turns until the conversation fits a budget.
export async function trim(messages, budget) {
  let kept = [...messages];
  for (;;) {
    const counted = await client.messages.countTokens({model, messages: kept});
    const size = counted.input_tokens;
    if (size <= budget || kept.length <= 1) return {kept, size};
    kept = kept.slice(2); // one user turn and its answer
  }
}

const history = [];
const long = (words) => words.repeat(20);
for (let i = 1; i <= 6; i++) {
  history.push({role: "user", content: `Question ${i}: ${long("about the menu ")}`});
  history.push({role: "assistant", content: `Answer ${i}: ${long("on the menu ")}`});
}
history.push({role: "user", content: "And the last question?"});
for (const budget of [1000, 400, 150]) {
  const {kept, size} = await trim(history, budget);
  const count = `${kept.length} of ${history.length} messages`;
  console.log(`budget ${String(budget).padStart(4)}: kept ${count}, ${size} tokens`);
}
