$ claude -p "اشرح price.mjs في جملتين." --model claude-opus-5-5 --no-session-persistence --output-format json | node fields.mjs
{
  subtype: 'success',
  result: 'يصدّر price.mjs الدالة total(bill, tip)، التي تضيف نسبة البقشيش إلى الفاتورة. وهو يقرأ الفاتورة بـ parseInt، فتسقط قروش فاتورة مثل 85.50.',
  num_turns: 2,
  total_cost_usd: 0.0658068,
  tokens: { input: 0, cache_written: 12270, cache_read: 12184, output: 101 }
}
