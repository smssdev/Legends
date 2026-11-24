import fs from "node:fs";

// حقول نتيجة Claude Code بصيغة JSON التي يحتاجها السكربت.
const result = JSON.parse(fs.readFileSync(0, "utf8"));
const {usage} = result;
console.log({
  subtype: result.subtype,
  result: result.result,
  num_turns: result.num_turns,
  total_cost_usd: result.total_cost_usd,
  tokens: {
    input: usage.input_tokens,
    cache_written: usage.cache_creation_input_tokens,
    cache_read: usage.cache_read_input_tokens,
    output: usage.output_tokens,
  },
});
