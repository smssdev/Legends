"""Writes the examples of Book 4, chapter "Estimation, Planning and Working with Product", in English and Arabic.
Run: python3 make.py

estimate.ts adds up the tasks of the deposits feature as ranges (best, likely, worst days) by simulating the
project 10,000 times, and compares the result with the sum of the "likely" numbers. forecast.ts forecasts when
the remaining backlog will be done from the team's real weekly throughput. calibrate.ts compares past estimates
with what the work really took. All three use a fixed seed, so the book's output is always the same.
Transcripts are *.sh.
"""
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
        w_c_seed="a fixed seed: the same 10,000 runs every time",
        w_c_tasks="the deposits feature, in days: [best case, most likely, worst case]",
        w_c_tri="one possible duration: a triangle from best to worst, highest at likely",
        w_c_naive="what is usually quoted: the sum of the most likely numbers",
        w_c_runs="10,000 possible projects, each task drawn on its own",
        w_c_pct="the duration that p% of the runs finished within",
        w_c_history="items finished in each of the last 12 weeks, from the tracker",
        w_c_backlog="what is left: stories already sliced to a similar small size",
        w_c_week="a future week looks like a past week, picked at random",
        w_c_average="the forecast from the average week, for comparison",
        w_c_past="the last 10 stories: estimated and actual days",
        w_c_ratio="how much longer than estimated each one took",
        w_t_naive="sum of likely", w_t_days="days", w_t_chance="chance to finish within it",
        w_t_within="finished within", w_t_left="left", w_t_items="items", w_t_avg="average week",
        w_t_weeks="weeks", w_t_byavg="from the average", w_sep=", ", w_t_median="median ratio", w_t_range="middle 80%",
        w_t_over="took longer than estimated",
        w_task_checkout="Checkout with the provider", w_task_webhook="Webhook and payment states",
        w_task_refund="Refunds on cancellation", w_task_ui="Booking page: pay a deposit",
        w_task_owner="Owner screen: deposits and refunds", w_task_tests="End-to-end tests and release",
        w_s_estimate="The deposits feature, as a range", w_s_forecast="When will the backlog be done?",
        w_s_calibrate="How good were our last estimates?",
    ),
    "ar": dict(
        w_c_seed="بذرة ثابتة: الـ10,000 تشغيل نفسها في كل مرة",
        w_c_tasks="ميزة العربون، بالأيام: [أفضل حال، والأرجح، وأسوأ حال]",
        w_c_tri="مدة ممكنة واحدة: مثلث من الأفضل إلى الأسوأ، قمته عند الأرجح",
        w_c_naive="ما يُقال عادةً: مجموع الأرقام الأرجح",
        w_c_runs="10,000 مشروع ممكن، كل مهمة فيه تُسحب وحدها",
        w_c_pct="المدة التي انتهت خلالها p% من التشغيلات",
        w_c_history="البنود المنجزة في كل أسبوع من الأسابيع الـ12 الماضية، من المتتبع",
        w_c_backlog="ما بقي: قصص قُسمت مسبقاً إلى حجم صغير متقارب",
        w_c_week="الأسبوع القادم يشبه أسبوعاً ماضياً، يُختار عشوائياً",
        w_c_average="التوقع من الأسبوع المتوسط، للمقارنة",
        w_c_past="آخر 10 قصص: الأيام المقدّرة والفعلية",
        w_c_ratio="كم استغرقت كل واحدة أطول مما قُدّر",
        w_t_naive="مجموع الأرجح", w_t_days="يوماً", w_t_chance="فرصة الانتهاء خلالها",
        w_t_within="انتهى خلال", w_t_left="بقي", w_t_items="بنداً", w_t_avg="الأسبوع المتوسط",
        w_t_weeks="أسابيع", w_t_byavg="من المتوسط", w_sep="؛ ", w_t_median="النسبة الوسيطة", w_t_range="الـ80% الوسطى",
        w_t_over="استغرقت أطول مما قُدّر",
        w_task_checkout="الدفع لدى المزوّد", w_task_webhook="Webhook وحالات الدفع",
        w_task_refund="الاسترداد عند الإلغاء", w_task_ui="صفحة الحجز: دفع العربون",
        w_task_owner="شاشة المالك: العربون والاسترداد", w_task_tests="اختبارات شاملة وإطلاق",
        w_s_estimate="ميزة العربون، نطاقاً", w_s_forecast="متى ينتهي ما بقي من العمل؟",
        w_s_calibrate="ما مدى جودة تقديراتنا الأخيرة؟",
    ),
}

RANDOM = '''// {w_c_seed}
export function random(seed: number) {
  return () => {
    seed = (seed * 1664525 + 1013904223) % 4294967296;
    return seed / 4294967296;
  };
}

// {w_c_pct}
export function percentile(sorted: number[], p: number) {
  return sorted[Math.min(sorted.length - 1, Math.floor((sorted.length * p) / 100))]!;
}
'''

FILES = {
    "random.ts": RANDOM,
    "estimate.ts": '''import { percentile, random } from "./random.ts";

// {w_c_tasks}
type Range = [best: number, likely: number, worst: number];
const tasks: [string, Range][] = [
  ["{w_task_checkout}", [2, 3, 6]],
  ["{w_task_webhook}", [2, 4, 10]],
  ["{w_task_refund}", [1, 2, 6]],
  ["{w_task_ui}", [2, 3, 5]],
  ["{w_task_owner}", [1, 2, 4]],
  ["{w_task_tests}", [1, 2, 5]],
];

// {w_c_tri}
function draw(next: () => number, [best, likely, worst]: Range) {
  const u = next();
  const cut = (likely - best) / (worst - best);
  return u < cut
    ? best + Math.sqrt(u * (worst - best) * (likely - best))
    : worst - Math.sqrt((1 - u) * (worst - best) * (worst - likely));
}

// {w_c_naive}
const naive = tasks.reduce((sum, [, range]) => sum + range[1], 0);

// {w_c_runs}
const next = random(14);
const runs = Array.from({ length: 10_000 }, () =>
  tasks.reduce((sum, [, range]) => sum + draw(next, range), 0),
).sort((a, b) => a - b);

const chance = Math.round((runs.filter((d) => d <= naive).length / runs.length) * 100);
console.log(`{w_t_naive}: ${naive} {w_t_days}{w_sep}{w_t_chance}: ${chance}%`);
for (const p of [50, 85, 95]) {
  console.log(`P${p}: ${Math.ceil(percentile(runs, p))} {w_t_days}`);
}
''',
    "forecast.ts": '''import { percentile, random } from "./random.ts";

// {w_c_history}
const done = [4, 6, 3, 5, 0, 7, 5, 4, 6, 2, 5, 6];
// {w_c_backlog}
const backlog = 38;

const next = random(7);
const weeks: number[] = [];
for (let run = 0; run < 10_000; run++) {
  let left = backlog;
  let week = 0;
  while (left > 0) {
    // {w_c_week}
    left -= done[Math.floor(next() * done.length)]!;
    week++;
  }
  weeks.push(week);
}
weeks.sort((a, b) => a - b);

// {w_c_average}
const average = done.reduce((a, b) => a + b, 0) / done.length;
console.log(`{w_t_left}: ${backlog} {w_t_items}{w_sep}{w_t_avg}: ${average.toFixed(1)}`);
console.log(`{w_t_byavg}: ${Math.ceil(backlog / average)} {w_t_weeks}`);
for (const p of [50, 85, 95]) {
  console.log(`P${p}: ${percentile(weeks, p)} {w_t_weeks}`);
}
''',
    "calibrate.ts": '''import { percentile } from "./random.ts";

// {w_c_past}
const estimated = [2, 1, 3, 2, 5, 1, 3, 2, 4, 1];
const actual = [3, 1, 5, 2, 9, 2, 3, 4, 5, 3];

// {w_c_ratio}
const ratios = actual.map((days, i) => days / estimated[i]!).sort((a, b) => a - b);
const over = ratios.filter((r) => r > 1).length;

console.log(`{w_t_over}: ${over} / ${ratios.length}`);
console.log(`{w_t_median}: ×${percentile(ratios, 50).toFixed(2)}`);
const [low, high] = [10, 90].map((p) => percentile(ratios, p).toFixed(2));
console.log(`{w_t_range}: ×${low} … ×${high}`);
''',
}


def record(folder, t):
    s = Session(folder)
    s.note(t["w_s_estimate"])
    s.run("node estimate.ts")
    s.save(folder / "estimate.sh")
    s.note(t["w_s_forecast"])
    s.run("node forecast.ts")
    s.save(folder / "forecast.sh")
    s.note(t["w_s_calibrate"])
    s.run("node calibrate.ts")
    s.save(folder / "calibrate.sh")


for lang, t in T.items():
    if sys.argv[1:] and lang not in sys.argv[1:]:
        continue
    folder = HERE / lang
    if folder.exists():
        shutil.rmtree(folder)
    folder.mkdir(parents=True)
    for name, text in FILES.items():
        (folder / name).write_text(fill(text, t))
    (folder / "package.json").write_text('{\n  "private": true,\n  "type": "module"\n}\n')
    subprocess.run([str(B4 / "node_modules/.bin/prettier"), "--print-width", "76", "--write", "*.ts"],
                   cwd=folder, check=True, capture_output=True)
    record(folder, t)
    print("wrote", lang)
