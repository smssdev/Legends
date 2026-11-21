import type { Span } from "./tracer.ts";

const traceId = process.argv[2];
const spans: Span[] = await (
  await fetch(`http://localhost:4318/traces/${traceId}`)
).json();
const root = spans.find((s) => !s.parentId)!;
const width = 24;
const scale = width / root.ms!;

console.log(`trace ${traceId!.slice(0, 8)}…  total ${Math.round(root.ms!)} ms`);
function draw(span: Span, depth: number) {
  // each span is a bar: where it starts and how long it lasts, on one time line
  const from = Math.min(width - 1, Math.round((span.start - root.start) * scale));
  const length = Math.max(1, Math.round(span.ms! * scale));
  const bar = " ".repeat(from) + "█".repeat(Math.min(length, width - from));
  const label = ("  ".repeat(depth) + span.name).padEnd(28);
  console.log(
    `${label}${span.service.padEnd(9)}|${bar.padEnd(width)}|${Math.round(span.ms!)
      .toString()
      .padStart(5)} ms`,
  );
  const children = spans.filter((s) => s.parentId === span.spanId);
  for (const child of children.sort((a, b) => a.start - b.start))
    draw(child, depth + 1);
}
draw(root, 0);
