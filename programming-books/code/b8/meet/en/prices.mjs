import {cost} from "./lib/prices.mjs";

// The same request on each model: 2,000 tokens in, 500 out.
const usage = {input_tokens: 2000, output_tokens: 500};
for (const model of ["claude-fable-5-2", "claude-opus-5-5", "claude-sonnet-5-5", "claude-haiku-5-5"]) {
  const one = cost(model, usage);
  console.log(`${model.padEnd(18)} $${one.toFixed(5)} each, $${(one * 1000).toFixed(2)} per thousand`);
}
// With 1,800 of the 2,000 input tokens read from the cache:
const cached = {input_tokens: 200, cache_read_input_tokens: 1800, output_tokens: 500};
console.log(`claude-opus-5-5, cached prompt: $${cost("claude-opus-5-5", cached).toFixed(5)} each`);
