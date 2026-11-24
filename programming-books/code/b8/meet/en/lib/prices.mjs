// Prices in dollars per million tokens, from the pricing page (November
// 2026).
// Cache writes cost 1.25 times the input price (5-minute cache); Haiku
// 5.5
// prices are for prompts up to 100K tokens.
export const PRICES = {
  "claude-fable-5-2": {input: 8, output: 40, cacheRead: 0.2},
  "claude-opus-5-5": {input: 4, output: 20, cacheRead: 0.2},
  "claude-sonnet-5-5": {input: 2, output: 10, cacheRead: 0.1},
  "claude-haiku-5-5": {input: 0.1, output: 0.5, cacheRead: 0.01},
};

// What a request costs: input, output, cache writes and cache reads, each
// at its own price.
export function cost(model, usage) {
  const p = PRICES[model];
  const written = usage.cache_creation_input_tokens ?? 0;
  const read = usage.cache_read_input_tokens ?? 0;
  const dollars = usage.input_tokens * p.input + usage.output_tokens * p.output +
    written * p.input * 1.25 + read * p.cacheRead;
  return dollars / 1_000_000;
}
