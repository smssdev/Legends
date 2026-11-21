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
// المعرّفات hex عشوائية: 16 بايت للتتبع، و8 للامتداد
const id = (bytes: number) => randomBytes(bytes).toString("hex");

export function tracer(service: string) {
  function start(name: string, parent?: { traceId: string; spanId: string }): Span {
    // الامتداد الابن يحتفظ بمعرّف التتبع ويسجل من ناداه
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

// W3C traceparent: الإصدار، ومعرّف التتبع، ومعرّف الامتداد الأب، والأعلام (01 = مُختار للعينة)
export const inject = (s: Span) => ({
  traceparent: `00-${s.traceId}-${s.spanId}-01`,
});

export function extract(header: string | string[] | undefined) {
  const m = /^00-([0-9a-f]{32})-([0-9a-f]{16})-0[01]$/.exec(String(header ?? ""));
  return m ? { traceId: m[1]!, spanId: m[2]! } : undefined;
}

// تُرسل الامتدادات دفعات، بعد الاستجابة، لا في طريقها أبداً
export async function flush() {
  const batch = done.splice(0);
  if (batch.length)
    await fetch("http://localhost:4318/spans", {
      method: "POST",
      body: JSON.stringify(batch),
    });
}
