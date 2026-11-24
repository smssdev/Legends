import readline from "node:readline";

// Claude Code's events, one line each.
const brief = (input) => input.command ?? JSON.stringify(input);
for await (const line of readline.createInterface({input: process.stdin})) {
  const event = JSON.parse(line);
  for (const block of event.message?.content ?? []) {
    if (block.type === "text") console.log(`  says   ${block.text}`);
    if (block.type === "tool_use") console.log(`  calls  ${block.name} ${brief(block.input)}`);
    if (block.type === "tool_result") {
      const content = typeof block.content === "string" ? block.content : JSON.stringify(block.content);
      console.log(`  gets   ${block.is_error ? "(error) " : ""}${content.split("\n")[0].slice(0, 90)}`);
    }
  }
  if (event.type === "result") {
    const denied = event.permission_denials.length;
    console.log(`  turns: ${event.num_turns}, denied: ${denied}, ` +
      `cost: $${event.total_cost_usd.toFixed(4)}, ${event.subtype}`);
  }
}
