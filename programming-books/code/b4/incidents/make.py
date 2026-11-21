"""Writes the examples of Book 4, chapter "Observability and Incidents", in English and Arabic.
Run: python3 make.py   (after `npm ci` in code/b4)

traffic.ts makes one month of Bit Booking's traffic, minute by minute, always the same: a small background of
failures, a 4-minute blip, a 35-minute outage and a two-day slow burn. slo.ts measures it against a 99.9%
objective and follows the error budget through the month; alerts.ts compares a naive alert with burn-rate
alerts on the same month.

Then one booking is traced from the browser to the database: browser.ts (what the page's code does), api.ts
and payments.ts send their spans to collector.ts, and waterfall.ts draws the trace. Run again with the
payment provider slow, the waterfall shows where the time went. postmortem.md is the write-up of the outage.
Transcripts are *.sh.
"""
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).parent
B4 = HERE.parent
sys.path.insert(0, str(B4.parent / "b3"))
from rec import CLEAN, Server, Session, fill  # noqa: E402

T = {
    "en": dict(
        w_c_same="the same month every time: a fixed seed, not Math.random()",
        w_c_wave="quiet at 03:00, busiest at 15:00: from 40 to 340 requests a minute",
        w_c_events="what went wrong this month (day, hour, minute, how long, failure rate)",
        w_c_blip="a deploy fails for 4 minutes and is rolled back",
        w_c_outage="the database runs out of connections",
        w_c_burn="a new release fails one payment page in 250, for two days",
        w_c_good="a good request: answered, without a server error",
        w_c_budget="the error budget: how many requests may fail this month",
        w_c_daily="the budget left at the end of each day",
        w_c_rules="page a person only when the budget burns fast; open a ticket when it burns slowly",
        w_c_windows="a long window proves it matters, a short one proves it is still happening",
        w_c_naive="the alert many teams start with: more than 1% failed in the last minute",
        w_c_prefix="running totals, so any window is one subtraction",
        w_c_ids="ids are random hex: 16 bytes for a trace, 8 for a span",
        w_c_parent="a child span keeps the trace id and records who called it",
        w_c_header="W3C traceparent: version, trace id, parent span id, flags (01 = sampled)",
        w_c_export="spans are sent in batches, after the response, never in its way",
        w_c_root="the trace starts in the browser, when the customer clicks",
        w_c_inject="the same header that Book 3 passed between services, now from the browser",
        w_c_mode="SLOW=1: the payment provider takes about a second",
        w_c_store="a real collector (OpenTelemetry) samples, stores and indexes; this one just keeps",
        w_c_bars="each span is a bar: where it starts and how long it lasts, on one time line",
        w_click="click Book", w_service_web="web",
        w_t_requests="requests", w_t_failed="failed", w_t_avail="availability", w_t_objective="objective",
        w_t_budget="error budget", w_t_used="used", w_t_left="left", w_t_day="day", w_t_missed="objective missed",
        w_t_kept="objective kept", w_t_reqs="failed requests", w_t_rule="rule", w_t_fired="fired",
        w_t_real="real", w_t_false="false", w_t_trace="trace", w_t_total="total",
        w_r_naive="naive: >1% in 1 min", w_r_fast="page: 14.4x for 1 h and 5 min",
        w_r_mid="page: 6x for 6 h and 30 min", w_r_slow="ticket: 3x for 1 d and 2 h",
        w_s_slo="One month against a 99.9% objective",
        w_s_alerts="The same month, two ways to alert",
        w_s_trace="Book a slot, and draw its trace",
        w_s_slow="The payment provider is slow: where did the time go?",
    ),
    "ar": dict(
        w_c_same="الشهر نفسه في كل مرة: بذرة ثابتة، لا Math.random()",
        w_c_wave="هادئ في 03:00، وأزحم في 15:00: من 40 إلى 340 طلباً في الدقيقة",
        w_c_events="ما تعطل هذا الشهر (اليوم، والساعة، والدقيقة، والمدة، ونسبة الفشل)",
        w_c_blip="نشرٌ يفشل 4 دقائق ثم يُتراجع عنه",
        w_c_outage="تنفد اتصالات قاعدة البيانات",
        w_c_burn="إصدار جديد يُفشل صفحة دفع من كل 250، يومين",
        w_c_good="الطلب الجيد: أُجيب، بلا خطأ خادم",
        w_c_budget="ميزانية الأخطاء: كم طلباً يجوز أن يفشل هذا الشهر",
        w_c_daily="ما بقي من الميزانية في نهاية كل يوم",
        w_c_rules="نبّه شخصاً فقط حين تحترق الميزانية بسرعة؛ وافتح تذكرة حين تحترق ببطء",
        w_c_windows="النافذة الطويلة تثبت أن الأمر مهم، والقصيرة تثبت أنه ما زال يحدث",
        w_c_naive="التنبيه الذي يبدأ به فرق كثيرة: فشل أكثر من 1% في الدقيقة الأخيرة",
        w_c_prefix="مجاميع متراكمة، فكل نافذة عملية طرح واحدة",
        w_c_ids="المعرّفات hex عشوائية: 16 بايت للتتبع، و8 للامتداد",
        w_c_parent="الامتداد الابن يحتفظ بمعرّف التتبع ويسجل من ناداه",
        w_c_header="W3C traceparent: الإصدار، ومعرّف التتبع، ومعرّف الامتداد الأب، والأعلام (01 = مُختار للعينة)",
        w_c_export="تُرسل الامتدادات دفعات، بعد الاستجابة، لا في طريقها أبداً",
        w_c_root="يبدأ التتبع في المتصفح، حين ينقر الزبون",
        w_c_inject="الترويسة نفسها التي مرّرها الكتاب الثالث بين الخدمات، الآن من المتصفح",
        w_c_mode="SLOW=1: يستغرق مزوّد الدفع نحو ثانية",
        w_c_store="المجمّع الحقيقي (OpenTelemetry) يأخذ عينات ويخزن ويفهرس؛ وهذا يحتفظ بها فقط",
        w_c_bars="كل امتداد شريط: أين يبدأ وكم يدوم، على خط زمني واحد",
        w_click="click Book", w_service_web="web",
        w_t_requests="الطلبات", w_t_failed="فشل", w_t_avail="التوفر", w_t_objective="الهدف",
        w_t_budget="ميزانية الأخطاء", w_t_used="استُهلك", w_t_left="بقي", w_t_day="اليوم", w_t_missed="لم يتحقق الهدف",
        w_t_kept="تحقق الهدف", w_t_reqs="طلب فاشل", w_t_rule="القاعدة", w_t_fired="أطلق",
        w_t_real="حقيقي", w_t_false="كاذب", w_t_trace="التتبع", w_t_total="المجموع",
        w_r_naive="ساذج: >1% في دقيقة", w_r_fast="استدعاء: 14.4x لساعة و5 دقائق",
        w_r_mid="استدعاء: 6x لـ6 ساعات و30 دقيقة", w_r_slow="تذكرة: 3x ليوم وساعتين",
        w_s_slo="شهر واحد أمام هدف 99.9%",
        w_s_alerts="الشهر نفسه، وطريقتان للتنبيه",
        w_s_trace="احجز موعداً، وارسم تتبعه",
        w_s_slow="مزوّد الدفع بطيء: أين ذهب الوقت؟",
    ),
}

FILES = {
    "traffic.ts": '''// {w_c_same}
function random(seed: number) {
  return () => {
    seed = (seed * 1664525 + 1013904223) % 4294967296;
    return seed / 4294967296;
  };
}

// {w_c_events}
export const events = [
  // {w_c_blip}
  { day: 9, at: 14 * 60 + 2, minutes: 4, rate: 0.04 },
  // {w_c_outage}
  { day: 17, at: 20 * 60 + 15, minutes: 35, rate: 0.25 },
  // {w_c_burn}
  { day: 24, at: 0, minutes: 2 * 1440, rate: 0.004 },
];

const eventAt = (i: number) =>
  events.find((e) => i >= (e.day - 1) * 1440 + e.at && i < (e.day - 1) * 1440 + e.at + e.minutes);
export const during = (i: number) => eventAt(i) !== undefined;

export type Minute = { day: number; time: string; requests: number; failed: number };

export function month(): Minute[] {
  const next = random(2026);
  const minutes: Minute[] = [];
  for (let i = 0; i < 30 * 1440; i++) {
    const day = Math.floor(i / 1440) + 1;
    const ofDay = i % 1440;
    // {w_c_wave}
    const requests = Math.round(190 - 150 * Math.cos(((ofDay - 180) / 1440) * 2 * Math.PI));
    const rate = eventAt(i)?.rate ?? 0.0002;
    let failed = 0;
    for (let r = 0; r < requests; r++) if (next() < rate) failed++;
    const time = [Math.floor(ofDay / 60), ofDay % 60]
      .map((x) => String(x).padStart(2, "0"))
      .join(":");
    minutes.push({ day, time, requests, failed });
  }
  return minutes;
}
''',
    "slo.ts": '''import { month } from "./traffic.ts";

const objective = 0.999;
const minutes = month();
const requests = minutes.reduce((n, m) => n + m.requests, 0);
const failed = minutes.reduce((n, m) => n + m.failed, 0);
// {w_c_good}
const availability = (requests - failed) / requests;
// {w_c_budget}
const budget = Math.floor(requests * (1 - objective));

const n = (x: number) => x.toLocaleString("en").padStart(10);
const pct = (x: number, d = 3) => `${(x * 100).toFixed(d)}%`.padStart(10);
console.log("{w_t_requests}".padEnd(16), n(requests));
console.log("{w_t_failed}".padEnd(16), n(failed));
console.log("{w_t_avail}".padEnd(16), pct(availability), " {w_t_objective}", pct(objective, 1).trim());
console.log("{w_t_budget}".padEnd(16), n(budget), " {w_t_reqs}");
console.log("{w_t_used}".padEnd(16), pct(failed / budget, 0));
console.log(availability >= objective ? "{w_t_kept}" : "{w_t_missed}");
console.log();

// {w_c_daily}
let spent = 0;
console.log("{w_t_day}".padEnd(4), "{w_t_left}".padStart(5));
for (let day = 1; day <= 30; day++) {
  const before = spent;
  spent += minutes.filter((m) => m.day === day).reduce((s, m) => s + m.failed, 0);
  const left = Math.max(0, 1 - spent / budget);
  if (day % 5 === 0 || spent - before > budget * 0.02) {
    const bar = "█".repeat(Math.round(left * 40));
    console.log(String(day).padEnd(4), pct(left, 0).trim().padStart(5), bar);
  }
}
''',
    "alerts.ts": '''import { during, month } from "./traffic.ts";

const minutes = month();
const budgetRate = 1 - 0.999;
// {w_c_prefix}
const req = [0];
const bad = [0];
for (const m of minutes) {
  req.push(req.at(-1)! + m.requests);
  bad.push(bad.at(-1)! + m.failed);
}
const rate = (end: number, length: number) => {
  const start = Math.max(0, end - length);
  return (bad[end]! - bad[start]!) / (req[end]! - req[start]!);
};

// {w_c_rules}
const rules = [
  // {w_c_naive}
  { name: "{w_r_naive}", check: (i: number) => rate(i, 1) > 0.01 },
  // {w_c_windows}
  { name: "{w_r_fast}", check: (i: number) => burns(i, 14.4, 60, 5) },
  { name: "{w_r_mid}", check: (i: number) => burns(i, 6, 360, 30) },
  { name: "{w_r_slow}", check: (i: number) => burns(i, 3, 1440, 120) },
];
function burns(i: number, factor: number, long: number, short: number) {
  return rate(i, long) > factor * budgetRate && rate(i, short) > factor * budgetRate;
}

console.log("{w_t_rule}".padEnd(31), "{w_t_fired}".padStart(6), "{w_t_real}".padStart(6), "{w_t_false}".padStart(7));
for (const rule of rules) {
  const fired: number[] = [];
  let firing = false;
  for (let i = 1; i <= minutes.length; i++) {
    const now = rule.check(i);
    if (now && !firing) fired.push(i - 1);
    firing = now;
  }
  const real = fired.filter(during).length;
  const at = (i: number) => `{w_t_day} ${minutes[i]!.day} ${minutes[i]!.time}`;
  const when = fired.length < 4 ? fired.map(at).join(", ") : "";
  console.log(
    [rule.name.padEnd(31), String(fired.length).padStart(6), String(real).padStart(6),
      String(fired.length - real).padStart(7), when].join(" ").trimEnd(),
  );
}
''',
    "tracer.ts": '''import { randomBytes } from "node:crypto";

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
// {w_c_ids}
const id = (bytes: number) => randomBytes(bytes).toString("hex");

export function tracer(service: string) {
  function start(name: string, parent?: { traceId: string; spanId: string }): Span {
    // {w_c_parent}
    return {
      traceId: parent?.traceId ?? id(16),
      spanId: id(8),
      parentId: parent?.spanId,
      name,
      service,
      start: performance.timeOrigin + performance.now(),
    };
  }
  async function span<T>(name: string, parent: Span, work: (span: Span) => Promise<T>) {
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

// {w_c_header}
export const inject = (s: Span) => ({ traceparent: `00-${s.traceId}-${s.spanId}-01` });

export function extract(header: string | string[] | undefined) {
  const m = /^00-([0-9a-f]{32})-([0-9a-f]{16})-0[01]$/.exec(String(header ?? ""));
  return m ? { traceId: m[1]!, spanId: m[2]! } : undefined;
}

// {w_c_export}
export async function flush() {
  const batch = done.splice(0);
  if (batch.length)
    await fetch("http://localhost:4318/spans", { method: "POST", body: JSON.stringify(batch) });
}
''',
    "api.ts": '''import { createServer } from "node:http";
import { setTimeout as sleep } from "node:timers/promises";
import { extract, flush, inject, tracer } from "./tracer.ts";

const { start, span, end } = tracer("api");

createServer(async (request, response) => {
  const root = start(`${request.method} ${request.url}`, extract(request.headers.traceparent));
  await span("db SELECT slot", root, () => sleep(6));
  const charge = await span("call payments", root, async (s) => {
    const answer = await fetch("http://localhost:4001/charges", {
      method: "POST",
      headers: inject(s),
    });
    return answer.json();
  });
  await span("db INSERT booking", root, () => sleep(4));
  await span("queue booking.created", root, () => sleep(1));
  end(root);
  response.end(JSON.stringify({ booking: 812, ...charge }));
  await flush();
}).listen(4000);
''',
    "payments.ts": '''import { createServer } from "node:http";
import { setTimeout as sleep } from "node:timers/promises";
import { extract, flush, tracer } from "./tracer.ts";

const { start, span, end } = tracer("payments");
// {w_c_mode}
const providerMs = process.env.SLOW ? 1000 : 40;

createServer(async (request, response) => {
  const root = start(`${request.method} ${request.url}`, extract(request.headers.traceparent));
  await span("fraud check", root, () => sleep(10));
  await span("provider checkout", root, () => sleep(providerMs));
  end(root);
  response.end(JSON.stringify({ checkout: "cs_812" }));
  await flush();
}).listen(4001);
''',
    "browser.ts": '''import { flush, inject, tracer } from "./tracer.ts";

const { start, span, end } = tracer("{w_service_web}");
// {w_c_root}
const click = start("{w_click}");
await span("fetch POST /bookings", click, async (s) => {
  // {w_c_inject}
  const answer = await fetch("http://localhost:4000/bookings", {
    method: "POST",
    headers: inject(s),
  });
  return answer.json();
});
end(click);
await flush();
console.log(click.traceId);
''',
    "collector.ts": '''import { createServer } from "node:http";
import type { Span } from "./tracer.ts";

// {w_c_store}
const spans: Span[] = [];

createServer(async (request, response) => {
  if (request.method === "POST") {
    let body = "";
    for await (const chunk of request) body += chunk;
    spans.push(...(JSON.parse(body) as Span[]));
    return response.writeHead(204).end();
  }
  const traceId = request.url?.split("/").pop();
  response.end(JSON.stringify(spans.filter((s) => s.traceId === traceId)));
}).listen(4318);
''',
    "waterfall.ts": '''import type { Span } from "./tracer.ts";

const traceId = process.argv[2];
const spans: Span[] = await (await fetch(`http://localhost:4318/traces/${traceId}`)).json();
const root = spans.find((s) => !s.parentId)!;
const width = 24;
const scale = width / root.ms!;

console.log(`{w_t_trace} ${traceId!.slice(0, 8)}…  {w_t_total} ${Math.round(root.ms!)} ms`);
function draw(span: Span, depth: number) {
  // {w_c_bars}
  const from = Math.min(width - 1, Math.round((span.start - root.start) * scale));
  const length = Math.max(1, Math.round(span.ms! * scale));
  const bar = " ".repeat(from) + "█".repeat(Math.min(length, width - from));
  const label = ("  ".repeat(depth) + span.name).padEnd(28);
  console.log(`${label}${span.service.padEnd(9)}|${bar.padEnd(width)}|${Math.round(span.ms!)
    .toString()
    .padStart(5)} ms`);
  const children = spans.filter((s) => s.parentId === span.spanId);
  for (const child of children.sort((a, b) => a.start - b.start)) draw(child, depth + 1);
}
draw(root, 0);
''',
}

POSTMORTEM = {
    "en": '''# Postmortem: bookings failed for 35 minutes (day 17)

Status: final · Severity: SEV-1 · Incident commander: Mona · Written by: Karim

## Summary
From 20:15 to 20:50, one booking request in four failed with "Server error".
1,822 of 7,289 requests failed: 22% of the month's error budget in 35 minutes.

## Impact
- Customers: 1,822 failed requests; an estimated 270 people could not book.
- Business: about 90 bookings lost, on a busy evening.
- Budget left this month: 66%; releases go on, after the actions below.

## Timeline (Cairo time)
- 20:00  Release 4.12 deployed; it opens a new database connection for each report.
- 20:15  The connection pool is exhausted; requests start to fail.
- 20:18  The fast burn-rate alert pages the on-call engineer (Karim).
- 20:21  Karim declares a SEV-1; Mona takes incident command; status page updated.
- 20:34  Rolling back 4.12 does not help: the open connections remain.
- 20:46  Reports are switched off with their feature flag; failures stop.
- 20:50  Error rate back to normal; monitoring for 30 minutes.
- 21:20  Incident closed; status page resolved.

## Root cause and why it was possible
- Reports opened a connection per request instead of using the pool.
- The load test used 10 reports a minute; real evenings have 400.
- The database had no limit per application user, so reports used every connection.

## What went well
- The alert paged three minutes after the start.
- Roles were clear; the status page was updated within 6 minutes.

## What went badly
- 13 minutes were spent on a rollback that could not work.
- The runbook did not mention the reports feature flag.

## Actions
| Action                                             | Owner  | Due    |
|----------------------------------------------------|--------|--------|
| Use the shared pool for reports                    | Karim  | day 19 |
| Connection limit per database user                 | Sara   | day 21 |
| Load test with production-like report volume       | Omar   | day 24 |
| Runbook: "database connections exhausted"          | Mona   | day 20 |
| Alert when the pool is 80% used                    | Sara   | day 21 |
''',
    "ar": '''# مراجعة ما بعد الحادث: فشلت الحجوزات 35 دقيقة (اليوم 17)

الحالة: نهائية · الخطورة: SEV-1 · قائد الحادث: منى · كتبها: كريم

## الملخص
من 20:15 إلى 20:50، فشل طلب حجز من كل أربعة برسالة «خطأ في الخادم».
فشل 1,822 طلباً من 7,289: 22% من ميزانية أخطاء الشهر في 35 دقيقة.

## الأثر
- الزبائن: 1,822 طلباً فاشلاً؛ ونحو 270 شخصاً لم يستطيعوا الحجز.
- العمل: ضاع نحو 90 حجزاً، في مساء مزدحم.
- ما بقي من ميزانية الشهر: 66%، فتستمر الإصدارات، والإجراءات أدناه أولاً.

## الخط الزمني (بتوقيت القاهرة)
- 20:00  نُشر الإصدار 4.12؛ يفتح اتصالاً جديداً بقاعدة البيانات لكل تقرير.
- 20:15  نفدت مجموعة الاتصالات؛ بدأت الطلبات تفشل.
- 20:18  تنبيه معدل الاحتراق السريع يستدعي المهندس المناوب (كريم).
- 20:21  يعلن كريم SEV-1؛ وتتولى منى قيادة الحادث؛ وتُحدَّث صفحة الحالة.
- 20:34  التراجع عن 4.12 لا يفيد: الاتصالات المفتوحة باقية.
- 20:46  تُطفأ التقارير بعلَم الميزة؛ ويتوقف الفشل.
- 20:50  معدل الأخطاء عاد طبيعياً؛ مراقبة 30 دقيقة.
- 21:20  أُغلق الحادث؛ وحُلّ في صفحة الحالة.

## السبب الجذري ولماذا كان ممكناً
- فتحت التقارير اتصالاً لكل طلب بدل استعمال المجموعة.
- استعمل اختبار الحمل 10 تقارير في الدقيقة؛ والأمسيات الحقيقية فيها 400.
- لم يكن لقاعدة البيانات حد لكل مستخدم تطبيق، فاستهلكت التقارير كل الاتصالات.

## ما سار جيداً
- استدعى التنبيه المناوب بعد ثلاث دقائق من البداية.
- كانت الأدوار واضحة؛ وحُدّثت صفحة الحالة خلال 6 دقائق.

## ما سار سيئاً
- صُرفت 13 دقيقة على تراجع لا يمكن أن ينجح.
- لم يذكر دليل التشغيل علَم ميزة التقارير.

## الإجراءات
| الإجراء                                           | المسؤول | الموعد   |
|---------------------------------------------------|---------|----------|
| استعمال المجموعة المشتركة للتقارير                 | كريم    | اليوم 19 |
| حد اتصالات لكل مستخدم في قاعدة البيانات           | سارة    | اليوم 21 |
| اختبار حمل بحجم تقارير يشبه الإنتاج               | عمر     | اليوم 24 |
| دليل تشغيل: «نفدت اتصالات قاعدة البيانات»          | منى     | اليوم 20 |
| تنبيه حين تُستعمل 80% من المجموعة                 | سارة    | اليوم 21 |
''',
}


def record(folder, t):
    s = Session(folder)
    s.note(t["w_s_slo"])
    s.run("node slo.ts")
    s.save(folder / "slo.sh")
    s.note(t["w_s_alerts"])
    s.run("node alerts.ts")
    s.save(folder / "alerts.sh")
    with Server("node collector.ts", folder, "http://localhost:4318/traces/none"), \
            Server("node payments.ts", folder, "http://localhost:4001/"), \
            Server("node api.ts", folder, "http://localhost:4000/warm"):
        for _ in range(3):  # warm up: the first requests of a fresh Node process are slower than the rest
            s.run("node browser.ts")
            s.lines.clear()
        s.note(t["w_s_trace"])
        trace = s.run("node browser.ts", shown="TRACE=$(node browser.ts)")
        s.lines.pop()
        s.run(f"node waterfall.ts {trace}", shown="node waterfall.ts $TRACE")
        s.save(folder / "trace.sh")
    with Server("node collector.ts", folder, "http://localhost:4318/traces/none"), \
            Server("SLOW=1 node payments.ts", folder, "http://localhost:4001/"), \
            Server("node api.ts", folder, "http://localhost:4000/warm"):
        for _ in range(3):
            s.run("node browser.ts")
            s.lines.clear()
        s.note(t["w_s_slow"])
        trace = s.run("node browser.ts", shown="TRACE=$(node browser.ts)")
        s.lines.pop()
        s.run(f"node waterfall.ts {trace}", shown="node waterfall.ts $TRACE")
        s.save(folder / "slow.sh")


_orig = Session.run


def run(self, cmd, shown=None, check=True, timeout=60):
    r = subprocess.run(["bash", "-c", cmd], cwd=self.cwd, capture_output=True, text=True, timeout=timeout,
                       env=CLEAN)
    out = (r.stdout + r.stderr).replace("\r", "").rstrip("\n")
    if check and r.returncode:
        raise RuntimeError(f"{cmd} failed ({r.returncode}):\n{out}")
    self.lines.append("$ " + (shown or cmd))
    if out:
        self.lines.extend(out.split("\n"))
    return out


Session.run = run

for lang, t in T.items():
    if sys.argv[1:] and lang not in sys.argv[1:]:
        continue
    folder = HERE / lang
    if folder.exists():
        shutil.rmtree(folder)
    folder.mkdir(parents=True)
    for name, text in FILES.items():
        (folder / name).write_text(fill(text, t))
    (folder / "postmortem.md").write_text(POSTMORTEM[lang])
    (folder / "package.json").write_text('{\n  "private": true,\n  "type": "module"\n}\n')
    os.symlink(B4 / "node_modules", folder / "node_modules")
    subprocess.run([str(B4 / "node_modules/.bin/prettier"), "--print-width", "84", "--write", "*.ts"],
                   cwd=folder, check=True, capture_output=True)
    record(folder, t)
    (folder / "node_modules").unlink()
    print("wrote", lang)
