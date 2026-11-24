import readline from "node:readline";

// أحداث Claude Code، سطر لكل حدث.
function short(text) {
  const lines = String(text).split("\n").map((l) => l.trim()).filter(Boolean);
  const tests = lines.filter((l) => /^(not )?ok \d/.test(l));
  return (tests.length ? tests : lines.slice(0, 1)).join(" | ").slice(0, 110);
}
const brief = (input) => input.command ?? input.skill ?? input.file_path ?? JSON.stringify(input);
for await (const line of readline.createInterface({input: process.stdin})) {
  const event = JSON.parse(line);
  for (const block of event.message?.content ?? []) {
    const who = event.type === "user" ? "loads" : "says ";
    if (block.type === "text") console.log(`  ${who}  ${block.text.split("\n").join(" / ")}`);
    if (block.type === "tool_use") console.log(`  calls  ${block.name} ${brief(block.input)}`);
    if (block.type === "tool_result") {
      const content = typeof block.content === "string" ? block.content : JSON.stringify(block.content);
      console.log(`  gets   ${block.is_error ? "(error) " : ""}${short(content)}`);
    }
  }
  if (event.type === "result") {
    const denied = event.permission_denials.length;
    console.log(`  الأدوار: ${event.num_turns}، رُفض: ${denied}، ` +
      `التكلفة: $${event.total_cost_usd.toFixed(4)}، ${event.subtype}`);
  }
}
