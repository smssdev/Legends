import {cost} from "./lib/prices.mjs";

// شهر من ميزة: الطلبات في اليوم، والـ tokens لكل طلب، والنموذج.
function monthly({model, perDay, input, output, cachedShare = 0}) {
  const cached = Math.round(input * cachedShare);
  const usage = {input_tokens: input - cached, cache_read_input_tokens: cached, output_tokens: output};
  return cost(model, usage) * perDay * 30;
}

const feature = {perDay: 5000, input: 3000, output: 300};
console.log("ملخصات التذاكر: 5,000 a day, 3,000 tokens in, 300 out");
for (const model of ["claude-opus-5-5", "claude-sonnet-5-5", "claude-haiku-5-5"]) {
  const plain = monthly({...feature, model});
  const cached = monthly({...feature, model, cachedShare: 0.8});
  console.log(`  ${model.padEnd(18)} $${plain.toFixed(2).padStart(8)} a month; with 80% cached $${cached.toFixed(2).padStart(8)}`);
}
