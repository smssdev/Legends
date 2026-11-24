$ claude -p "Explain price.mjs in two sentences." --model claude-opus-5-5 --no-session-persistence --output-format json | node fields.mjs
{
  subtype: 'success',
  result: 'price.mjs exports total(bill, tip), which adds the tip percentage to the bill. It reads the bill with parseInt, so the piastres of a bill like 85.50 are dropped.',
  num_turns: 2,
  total_cost_usd: 0.06547180000000001,
  tokens: { input: 0, cache_written: 12267, cache_read: 12184, output: 85 }
}
