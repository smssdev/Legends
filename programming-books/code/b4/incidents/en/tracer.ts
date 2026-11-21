import { randomBytes } from "node:crypto";

export type Span = {
  traceId: string;
  spanId: string;
  parentId?: string;
  name: string;
  service: string;
  start: number;
  ms?: number;
};

const done: Span[] = [];
// ids are random hex: 16 bytes for a trace, 8 for a span
const id = (bytes: number) => randomBytes(bytes).toString("hex");

export function tracer(service: string) {
  function start(name: string, parent?: { traceId: string; spanId: string }): Span {
    // a child span keeps the trace id and records who called it
    return {
      traceId: parent?.traceId ?? id(16),
      spanId: id(8),
      parentId: parent?.spanId,
      name,
      service,
      start: performance.timeOrigin + performance.now(),
    };
  }
  async function span<T>(
    name: string,
    parent: Span,
    work: (span: Span) => Promise<T>,
  ) {
    const s = start(name, parent);
    try {
      return await work(s);
    } finally {
      end(s);
    }
  }
  function end(s: Span) {
    s.ms = performance.timeOrigin + performance.now() - s.start;
    done.push(s);
  }
  return { start, span, end };
}

// W3C traceparent: version, trace id, parent span id, flags (01 = sampled)
export const inject = (s: Span) => ({
  traceparent: `00-${s.traceId}-${s.spanId}-01`,
});

export function extract(header: string | string[] | undefined) {
  const m = /^00-([0-9a-f]{32})-([0-9a-f]{16})-0[01]$/.exec(String(header ?? ""));
  return m ? { traceId: m[1]!, spanId: m[2]! } : undefined;
}

// spans are sent in batches, after the response, never in its way
export async function flush() {
  const batch = done.splice(0);
  if (batch.length)
    await fetch("http://localhost:4318/spans", {
      method: "POST",
      body: JSON.stringify(batch),
    });
}
