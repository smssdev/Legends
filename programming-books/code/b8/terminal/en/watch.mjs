import readline from "node:readline";

// Claude Code's events, one line each: what it says, which tool it calls,
// what comes back, and what it all cost.
// A tool's output in one line: the test results if there are any, else
// its start.
function short(text) {
  const lines = String(text).split("\n").map((l) => l.trim()).filter(Boolean);
  const tests = lines.filter((l) => /^(not )?ok \d/.test(l));
  return (tests.length ? tests : lines.slice(0, 2)).join(" | ").slice(0, 70);
}
for await (const line of readline.createInterface({input: process.stdin})) {
  const event = JSON.parse(line);
  for (const block of event.message?.content ?? []) {
    if (block.type === "text") console.log(`  says   ${block.text}`);
    if (block.type === "tool_use") console.log(`  calls  ${block.name}: ${JSON.stringify(block.input)}`);
    if (block.type === "tool_result") {
      const content = typeof block.content === "string" ? block.content : JSON.stringify(block.content);
      console.log(`  gets   ${block.is_error ? "(error) " : ""}${short(content)}`);
    }
  }
  if (event.type === "result") {
    const denied = event.permission_denials.length;
    console.log(`  turns: ${event.num_turns}, denied: ${denied}, ` +
      `cost: $${event.total_cost_usd.toFixed(4)}, ${event.subtype}`);
  }
}
