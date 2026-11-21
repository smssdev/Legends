"""Writes the examples of Book 4, chapter "Interviews and Growing Your Career", in English and Arabic.
Run: python3 make.py

slots.ts is a classic interview question solved twice: a salon's free gaps between bookings, first by
comparing every pair, then by sorting once. slots.test.ts checks both with node:test, edge cases included;
bench.ts times them on a busy day and a busy month. envelope.ts does the back-of-the-envelope numbers of a
system design round. brag.md is the record of your own work that a promotion or an interview needs.
Transcripts are *.sh.
"""
import os
import shutil
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).parent
B4 = HERE.parent
sys.path.insert(0, str(B4.parent / "b3"))
from rec import Session, fill  # noqa: E402

T = {
    "en": dict(
        w_c_type="a booking from start to end, in minutes since the salon opened",
        w_c_naive="first version: check every minute against every booking",
        w_c_sorted="better: sort once, walk once, and remember where the last booking ended",
        w_c_overlap="overlapping bookings merge: the gap starts after the latest end",
        w_c_edges="what interviewers ask: empty, overlapping, touching, unsorted, full",
        w_c_same="on random days, both versions must agree",
        w_c_day="bigger and bigger calendars: one booking every 30 minutes",
        w_c_inputs="what the interviewer gave, and what we assumed out loud",
        w_c_reads="customers look at free slots about 20 times for each booking",
        w_c_peak="traffic is not flat: the busiest hour has a fifth of the day",
        w_c_size="one booking row, with its indexes",
        w_t_bookings="bookings", w_t_minutes="minutes", w_t_naive="every minute", w_t_sorted="sort once",
        w_t_salons="salons", w_t_per_day="bookings a day", w_t_avg="average writes/s",
        w_t_peak="peak writes/s", w_t_reads="peak reads/s", w_t_year="data per year",
        w_t_verdict="fits one PostgreSQL primary with replicas for reads",
        w_s_test="Both versions, against the tricky cases", w_s_bench="How they grow",
        w_s_envelope="The numbers, before the boxes",
        w_n_none="an empty day is one gap", w_n_overlap="overlapping bookings",
        w_n_touch="bookings that touch leave no gap", w_n_unsorted="unsorted input",
        w_n_full="a full day has no gaps", w_n_random="both agree on 200 random days",
    ),
    "ar": dict(
        w_c_type="حجز من بدايته إلى نهايته، بالدقائق منذ فتح الصالون",
        w_c_naive="النسخة الأولى: افحص كل دقيقة أمام كل حجز",
        w_c_sorted="أفضل: رتّب مرة، وامشِ مرة، وتذكّر أين انتهى آخر حجز",
        w_c_overlap="الحجوزات المتداخلة تندمج: تبدأ الفجوة بعد أبعد نهاية",
        w_c_edges="الحالات التي يسأل عنها المقابِلون: لا شيء، ومتداخلة، ومتلامسة، وغير مرتبة، وممتلئ",
        w_c_same="في أيام عشوائية، يجب أن تتفق النسختان",
        w_c_day="تقاويم أكبر فأكبر: حجز كل 30 دقيقة",
        w_c_inputs="ما أعطاه المقابِل، وما افترضناه بصوت عالٍ",
        w_c_reads="ينظر الزبائن في المواعيد الفارغة نحو 20 مرة لكل حجز",
        w_c_peak="الحركة ليست مستوية: أزحم ساعة تحمل نحو خُمس اليوم",
        w_c_size="صف حجز واحد، بفهارسه",
        w_t_bookings="حجز", w_t_minutes="دقيقة", w_t_naive="كل دقيقة", w_t_sorted="رتّب مرة",
        w_t_salons="صالون", w_t_per_day="حجز في اليوم", w_t_avg="متوسط الكتابة/ث",
        w_t_peak="ذروة الكتابة/ث", w_t_reads="ذروة القراءة/ث", w_t_year="البيانات في السنة",
        w_t_verdict="يكفيه PostgreSQL رئيسي واحد مع نسخ للقراءة",
        w_s_test="النسختان، أمام الحالات الصعبة", w_s_bench="كيف تكبران",
        w_s_envelope="الأرقام، قبل المربعات",
        w_n_none="اليوم الفارغ فجوة واحدة", w_n_overlap="حجوزات متداخلة",
        w_n_touch="الحجوزات المتلامسة لا تترك فجوة", w_n_unsorted="مدخلات غير مرتبة",
        w_n_full="اليوم الممتلئ بلا فجوات", w_n_random="تتفقان في 200 يوم عشوائي",
    ),
}

FILES = {
    "slots.ts": '''// {w_c_type}
export type Booking = { start: number; end: number };

// {w_c_naive}
export function gapsNaive(bookings: Booking[], open: number, close: number) {
  const gaps: Booking[] = [];
  for (let minute = open; minute < close; minute++) {
    const busy = bookings.some((b) => b.start <= minute && minute < b.end);
    const last = gaps.at(-1);
    if (busy) continue;
    if (last && last.end === minute) last.end++;
    else gaps.push({ start: minute, end: minute + 1 });
  }
  return gaps;
}

// {w_c_sorted}
export function gaps(bookings: Booking[], open: number, close: number) {
  const sorted = [...bookings].sort((a, b) => a.start - b.start);
  const result: Booking[] = [];
  let free = open;
  for (const b of sorted) {
    if (b.start > free) result.push({ start: free, end: Math.min(b.start, close) });
    // {w_c_overlap}
    free = Math.max(free, b.end);
  }
  if (free < close) result.push({ start: free, end: close });
  return result;
}
''',
    "slots.test.ts": '''import assert from "node:assert/strict";
import { test } from "node:test";
import { type Booking, gaps, gapsNaive } from "./slots.ts";

// {w_c_edges}
const cases: [string, Booking[], Booking[]][] = [
  ["{w_n_none}", [], [{ start: 0, end: 600 }]],
  [
    "{w_n_overlap}",
    [{ start: 60, end: 120 }, { start: 90, end: 150 }],
    [{ start: 0, end: 60 }, { start: 150, end: 600 }],
  ],
  [
    "{w_n_touch}",
    [{ start: 0, end: 300 }, { start: 300, end: 600 }],
    [],
  ],
  [
    "{w_n_unsorted}",
    [{ start: 400, end: 450 }, { start: 100, end: 200 }],
    [{ start: 0, end: 100 }, { start: 200, end: 400 }, { start: 450, end: 600 }],
  ],
  ["{w_n_full}", [{ start: 0, end: 600 }], []],
];

for (const [name, bookings, expected] of cases) {
  test(name, () => {
    assert.deepEqual(gaps(bookings, 0, 600), expected);
    assert.deepEqual(gapsNaive(bookings, 0, 600), expected);
  });
}

// {w_c_same}
test("{w_n_random}", () => {
  for (let day = 0; day < 200; day++) {
    const bookings = Array.from({ length: 12 }, () => {
      const start = Math.floor(Math.random() * 570);
      return { start, end: start + 15 + Math.floor(Math.random() * 60) };
    });
    assert.deepEqual(gaps(bookings, 0, 600), gapsNaive(bookings, 0, 600));
  }
});
''',
    "bench.ts": '''import { type Booking, gaps, gapsNaive } from "./slots.ts";

function calendar(minutes: number, count: number): Booking[] {
  return Array.from({ length: count }, (_, i) => {
    const start = Math.floor((i * minutes) / count);
    return { start, end: start + 20 };
  });
}

function time(work: () => unknown) {
  const start = performance.now();
  work();
  return `${(performance.now() - start).toFixed(1)} ms`;
}

// {w_c_day}
for (const count of [20, 200, 2_000, 20_000]) {
  const minutes = count * 30;
  const bookings = calendar(minutes, count);
  const naive = time(() => gapsNaive(bookings, 0, minutes));
  const sorted = time(() => gaps(bookings, 0, minutes));
  const label = `${count.toLocaleString("en")} {w_t_bookings}`.padEnd(16);
  console.log(`${label} {w_t_naive} ${naive.padStart(11)}   {w_t_sorted} ${sorted}`);
}
''',
    "envelope.ts": '''// {w_c_inputs}
const salons = 50_000;
const bookingsPerSalonPerDay = 30;
// {w_c_reads}
const readsPerBooking = 20;
// {w_c_peak}
const busiestHourShare = 0.2;
// {w_c_size}
const bytesPerBooking = 400;

const perDay = salons * bookingsPerSalonPerDay;
const avgWrites = perDay / 86_400;
const peakWrites = (perDay * busiestHourShare) / 3_600;
const peakReads = peakWrites * readsPerBooking;
const perYear = perDay * 365 * bytesPerBooking;

const n = (x: number) => Math.round(x).toLocaleString("en");
console.log(`${n(salons)} {w_t_salons}, ${n(perDay)} {w_t_per_day}`);
console.log(`{w_t_avg}: ${n(avgWrites)}`);
console.log(`{w_t_peak}: ${n(peakWrites)}`);
console.log(`{w_t_reads}: ${n(peakReads)}`);
console.log(`{w_t_year}: ${(perYear / 1e9).toFixed(0)} GB`);
console.log(`=> {w_t_verdict}`);
''',
}

BRAG = {
    "en": '''# Brag document: Sara Hassan, 2026

## Impact (what changed because of my work)
- Moved background jobs to PostgreSQL (ADR 4): lost jobs went from 2 incidents
  to 0 in six months; Redis now serves only the cache.
- Led the postmortem of the day-17 outage; 5 of 5 actions done within 3 weeks.
- Cut the booking page's P85 load time from 2.4 s to 1.1 s.

## Decisions I drove
- ADR 4 (jobs in PostgreSQL): wrote the design doc, ran the review, approver Mona.
- Fitness function for module boundaries, now in every pipeline run.

## People
- Mentored Omar from his first PR to owning the reports module.
- Interviewed 9 candidates; wrote the system design rubric now used by the team.

## Learned
- OpenTelemetry in production; estimating with ranges and forecasts.

## Next
- Lead the deposits project end to end, including the plan with product.
''',
    "ar": '''# سجل إنجازات: سارة حسن، 2026

## الأثر (ما تغيّر بسبب عملي)
- نقلت المهام الخلفية إلى PostgreSQL (القرار 4): من حادثين لضياع مهام
  إلى صفر في ستة أشهر؛ ويخدم Redis الآن الذاكرة المؤقتة وحدها.
- قدت مراجعة ما بعد عطل اليوم 17؛ أُنجزت 5 إجراءات من 5 خلال 3 أسابيع.
- خفّضت P85 لزمن تحميل صفحة الحجز من 2.4 ثانية إلى 1.1.

## قرارات قدتها
- القرار 4 (المهام في PostgreSQL): كتبت وثيقة التصميم، وأدرت المراجعة، والمعتمدة منى.
- دالة لياقة لحدود الوحدات، تعمل الآن في كل تشغيل للخط.

## الناس
- رافقت عمر من أول طلب سحب له حتى تولّى وحدة التقارير.
- قابلت 9 مرشحين؛ وكتبت معايير تقييم تصميم الأنظمة التي يستعملها الفريق الآن.

## ما تعلمته
- OpenTelemetry في الإنتاج؛ والتقدير بالنطاقات والتوقعات.

## التالي
- قيادة مشروع العربون من أوله إلى آخره، ومعه الخطة مع فريق المنتج.
''',
}


def record(folder, t):
    s = Session(folder)
    s.note(t["w_s_test"])
    out = s.run("node --test --test-reporter=spec slots.test.ts", shown="node --test slots.test.ts")
    keep = [l for l in out.split("\n") if l.startswith(("✔", "✖", "ℹ tests", "ℹ pass", "ℹ fail"))]
    s.lines[-len(out.split("\n")):] = keep
    s.save(folder / "test.sh")
    s.note(t["w_s_bench"])
    s.run("node bench.ts")
    s.save(folder / "bench.sh")
    s.note(t["w_s_envelope"])
    s.run("node envelope.ts")
    s.save(folder / "envelope.sh")


for lang, t in T.items():
    if sys.argv[1:] and lang not in sys.argv[1:]:
        continue
    folder = HERE / lang
    if folder.exists():
        shutil.rmtree(folder)
    folder.mkdir(parents=True)
    for name, text in FILES.items():
        (folder / name).write_text(fill(text, t))
    (folder / "brag.md").write_text(BRAG[lang])
    (folder / "package.json").write_text('{\n  "private": true,\n  "type": "module"\n}\n')
    subprocess.run([str(B4 / "node_modules/.bin/prettier"), "--print-width", "76", "--write", "*.ts"],
                   cwd=folder, check=True, capture_output=True)
    record(folder, t)
    print("wrote", lang)
