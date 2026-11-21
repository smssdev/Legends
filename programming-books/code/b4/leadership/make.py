"""Writes the examples of Book 4, chapter "Technical Leadership and Architecture Decisions", in English and Arabic.
Run: python3 make.py   (after `npm ci` in code/b4)

docs/adr/ holds Bit Booking's architecture decision records; adr.ts lists them with their status and creates the
next one from the template. matrix.ts compares three ways to run background jobs with weighted criteria, then
checks whether the winner survives a change in any weight. rules.ts is an architecture rule the pipeline runs:
modules talk to each other only through their public index.ts.
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
from rec import CLEAN, Session, fill  # noqa: E402

T = {
    "en": dict(
        w_c_read="each record starts with its title, then a Status line",
        w_c_super="a superseded record stays: it explains what the team believed, and when",
        w_c_next="the next number: records are superseded, never deleted or renumbered",
        w_c_template="the template keeps every record short and in the same shape",
        w_c_options="three ways to run Bit Booking's background jobs (reminders, receipts, reports)",
        w_c_scores="1 = poor, 5 = excellent, agreed in the design review, with a reason for each",
        w_c_weights="what matters to this team, now: weights add up to 100",
        w_c_total="the weighted score: a summary of the discussion, not a replacement for it",
        w_c_sensitive="would the decision change if we had weighed one criterion half or half again?",
        w_c_rule="a module may use another module only through its index.ts",
        w_c_shared="shared code depends on no module",
        w_c_imports="every import with a relative path, and the module it lands in",
        w_t_status="status", w_t_option="option", w_t_score="score", w_t_winner="winner",
        w_t_stable="stable: no single weight change alters the winner",
        w_t_flips="changes the winner to",
        w_t_ok="architecture rules: ok", w_t_broken="architecture rules broken",
        w_crit_ops="operations", w_crit_team="team knows it", w_crit_cost="cost",
        w_crit_scale="scale headroom", w_crit_lockin="no lock-in",
        w_o_pg="PostgreSQL queue", w_o_redis="Redis queue", w_o_cloud="cloud queue",
        w_s_list="The decisions so far", w_s_new="Record a new decision",
        w_s_matrix="Three options, five criteria", w_s_rules="The pipeline checks the architecture",
        w_rule_bad="go through ${to}/index.ts",
        w_rule_shared="shared code must not import a module",
    ),
    "ar": dict(
        w_c_read="يبدأ كل سجل بعنوانه، ثم سطر Status",
        w_c_super="السجل المُستبدَل يبقى: يشرح ما اعتقده الفريق، ومتى",
        w_c_next="الرقم التالي: السجلات تُستبدل، ولا تُحذف ولا يُعاد ترقيمها أبداً",
        w_c_template="القالب يُبقي كل سجل قصيراً وعلى الشكل نفسه",
        w_c_options="ثلاث طرق لتشغيل المهام الخلفية في «بِت للحجوزات» (التذكيرات، والإيصالات، والتقارير)",
        w_c_scores="1 = ضعيف، 5 = ممتاز، اتُّفق عليها في مراجعة التصميم، مع سبب لكل منها",
        w_c_weights="ما يهم هذا الفريق، الآن: مجموع الأوزان 100",
        w_c_total="الدرجة الموزونة: ملخص للنقاش، لا بديل عنه",
        w_c_sensitive="هل يتغير القرار لو وزنّا معياراً واحداً بنصف وزنه أو بمرة ونصف؟",
        w_c_rule="لا يستعمل الوحدةَ وحدةٌ أخرى إلا عبر index.ts الخاص بها",
        w_c_shared="الكود المشترك لا يعتمد على أي وحدة",
        w_c_imports="كل استيراد بمسار نسبي، والوحدة التي يصل إليها",
        w_t_status="الحالة", w_t_option="الخيار", w_t_score="الدرجة", w_t_winner="الفائز",
        w_t_stable="ثابت: لا تغيير في وزن واحد يبدّل الفائز",
        w_t_flips="يبدّل الفائز إلى",
        w_t_ok="قواعد المعمارية: سليمة", w_t_broken="قواعد معمارية مكسورة",
        w_crit_ops="التشغيل", w_crit_team="يعرفه الفريق", w_crit_cost="الكلفة",
        w_crit_scale="هامش التوسع", w_crit_lockin="بلا ارتهان",
        w_o_pg="طابور PostgreSQL", w_o_redis="طابور Redis", w_o_cloud="طابور سحابي",
        w_s_list="القرارات حتى الآن", w_s_new="سجّل قراراً جديداً",
        w_s_matrix="ثلاثة خيارات، وخمسة معايير", w_s_rules="الخط يفحص المعمارية",
        w_rule_bad="مُر عبر ${to}/index.ts",
        w_rule_shared="الكود المشترك يجب ألا يستورد وحدة",
    ),
}

FILES = {
    "adr.ts": '''import { readFileSync, readdirSync, writeFileSync } from "node:fs";

const dir = "docs/adr";
const files = readdirSync(dir).filter((f) => /^\\d{4}-.*\\.md$/.test(f)).sort();

// {w_c_read}
function read(file: string) {
  const text = readFileSync(`${dir}/${file}`, "utf8");
  const title = text.split("\\n")[0]!.replace(/^# /, "");
  const status = /^Status: (.+)$/m.exec(text)?.[1] ?? "?";
  return { number: file.slice(0, 4), title, status };
}

const [command, ...words] = process.argv.slice(2);
if (command === "new") {
  // {w_c_next}
  const number = String(files.length + 1).padStart(4, "0");
  const title = words.join(" ");
  const slug = `${number}-${title.toLowerCase().replaceAll(" ", "-")}`;
  // {w_c_template}
  const template = readFileSync(`${dir}/template.md`, "utf8");
  writeFileSync(`${dir}/${slug}.md`, template.replace("TITLE", `${number}. ${title}`));
  console.log(`${dir}/${slug}.md`);
} else {
  for (const file of files) {
    const { number, title, status } = read(file);
    // {w_c_super}
    console.log(`${number}  ${status.padEnd(26)} ${title.replace(/^\\d+\\. /, "")}`);
  }
}
''',
    "matrix.ts": '''// {w_c_options}
const options = ["{w_o_pg}", "{w_o_redis}", "{w_o_cloud}"];

// {w_c_weights}
const criteria = [
  // {w_c_scores}
  { name: "{w_crit_ops}", weight: 30, scores: [5, 3, 4] },
  { name: "{w_crit_team}", weight: 25, scores: [5, 3, 2] },
  { name: "{w_crit_cost}", weight: 20, scores: [5, 4, 3] },
  { name: "{w_crit_scale}", weight: 15, scores: [2, 4, 5] },
  { name: "{w_crit_lockin}", weight: 10, scores: [5, 4, 1] },
];

// {w_c_total}
function totals(weights: number[]) {
  const sum = weights.reduce((a, b) => a + b, 0);
  return options.map((_, o) =>
    criteria.reduce((t, c, i) => t + (weights[i]! * c.scores[o]!) / sum, 0),
  );
}
const best = (scores: number[]) => scores.indexOf(Math.max(...scores));

const weights = criteria.map((c) => c.weight);
const score = totals(weights);
console.log("{w_t_option}".padEnd(18), "{w_t_score}".padStart(6));
for (const [o, name] of options.entries()) {
  console.log(name.padEnd(18), score[o]!.toFixed(2).padStart(6));
}
const winner = best(score);
console.log("{w_t_winner}:", options[winner]);
console.log();

// {w_c_sensitive}
let stable = true;
for (const [i, c] of criteria.entries()) {
  for (const factor of [0.5, 1.5]) {
    const changed = weights.map((w, j) => (j === i ? w * factor : w));
    const other = best(totals(changed));
    if (other !== winner) {
      stable = false;
      console.log(`${c.name} ×${factor}: {w_t_flips} ${options[other]}`);
    }
  }
}
if (stable) console.log("{w_t_stable}");
''',
    "rules.ts": '''import { readFileSync, readdirSync } from "node:fs";
import { dirname, join, normalize, relative } from "node:path";

const root = "app";
const files = readdirSync(root, { recursive: true, encoding: "utf8" })
  .filter((f) => f.endsWith(".ts"))
  .map((f) => join(root, f));
const moduleOf = (file: string) => relative(root, file).split("/")[0]!;

const broken: string[] = [];
// {w_c_imports}
const imports = /from "(\\.[^"]+)"/g;
for (const file of files) {
  const from = moduleOf(file);
  for (const [, path] of readFileSync(file, "utf8").matchAll(imports)) {
    const target = normalize(join(dirname(file), path!));
    const to = moduleOf(target);
    if (to === from) continue;
    // {w_c_shared}
    if (from === "shared") broken.push(`${file} → ${to}\\n    {w_rule_shared}`);
    // {w_c_rule}
    else if (to !== "shared" && !target.endsWith(`${to}/index.ts`))
      broken.push(`${file} → ${path}\\n    {w_rule_bad}`);
  }
}
if (broken.length) {
  console.log(`{w_t_broken}: ${broken.length}`);
  for (const line of broken) console.log("  " + line);
  process.exit(1);
}
console.log("{w_t_ok}");
''',
}

APP = {
    "app/shared/money.ts": '''export const egp = (piastres: number) => `${(piastres / 100).toFixed(2)} EGP`;
''',
    "app/payments/index.ts": '''export { chargeDeposit } from "./charges.ts";
''',
    "app/payments/charges.ts": '''import { egp } from "../shared/money.ts";
import { providerClient } from "./provider.ts";

export async function chargeDeposit(bookingId: number, piastres: number) {
  return providerClient.checkout({ bookingId, amount: egp(piastres) });
}
''',
    "app/payments/provider.ts": '''export const providerClient = {
  checkout: async (order: { bookingId: number; amount: string }) => ({ id: `cs_${order.bookingId}` }),
};
''',
    "app/bookings/index.ts": '''export { book } from "./book.ts";
''',
    "app/bookings/book.ts": '''import { chargeDeposit } from "../payments/index.ts";

export async function book(slot: number) {
  return chargeDeposit(slot, 5000);
}
''',
    "app/bookings/refund.ts": '''import { providerClient } from "../payments/provider.ts";

export async function refund(bookingId: number) {
  return providerClient.checkout({ bookingId, amount: "-50.00 EGP" });
}
''',
}

ADR = {
    "en": {
        "template.md": '''# TITLE

Status: Proposed
Date: YYYY-MM-DD · Deciders: names

## Context
What forces us to decide now? Facts, numbers, constraints.

## Decision
What we will do, in one or two sentences.

## Options considered
Each option, with its main benefit and its main cost.

## Consequences
What becomes easier, what becomes harder, and what we will watch.
''',
        "0001-one-postgresql-database.md": '''# 1. One PostgreSQL database for the whole product

Status: Accepted
Date: 2026-02-03 · Deciders: Mona, Karim, Sara

## Context
Three developers, one product, fewer than 1,000 bookings a day.
Bookings must never be double-sold (Chapter 6).

## Decision
All modules share one managed PostgreSQL database, each in its own schema.

## Options considered
- One database: one backup, real transactions; modules can couple through tables.
- A database per service: independent deploys; no transactions across them.

## Consequences
Easier: transactions, reports, operations. Harder: keeping schemas apart.
A module reads another module's tables only through its code, never directly.
Revisit when one module needs to scale or deploy on its own.
''',
        "0002-jobs-in-redis.md": '''# 2. Background jobs in a Redis queue

Status: Superseded by 0004
Date: 2026-03-10 · Deciders: Karim, Omar

## Context
Reminders and receipts must not slow down the booking request.

## Decision
Use a Redis-based queue for every background job.

## Options considered
- Redis queue: fast, popular; one more service to run.
- PostgreSQL queue: no new service; we were unsure it would be fast enough.

## Consequences
One more service to back up, upgrade and watch.
''',
        "0003-money-in-piastres.md": '''# 3. Money as whole piastres

Status: Accepted
Date: 2026-03-18 · Deciders: Sara, Mona

## Context
Deposits, refunds and reports add up amounts; floats give 0.30000000000000004.

## Decision
Store and compute money as integers (piastres), formatted only for display.

## Options considered
- Integers: exact, simple. Decimals: exact, slower, and each language differs.

## Consequences
Every amount in the API is an integer; the front end formats it.
''',
        "0004-jobs-in-postgresql.md": '''# 4. Background jobs in PostgreSQL

Status: Accepted
Date: 2026-09-02 · Deciders: Karim, Omar, Sara

## Context
The Redis queue lost jobs twice when Redis restarted (incidents 14 and 19).
We run 9,000 jobs a day; load tests show PostgreSQL handles 200 a second.
Supersedes 0002.

## Decision
Run background jobs from a PostgreSQL table, with SKIP LOCKED.

## Options considered
See the decision matrix in the design doc: PostgreSQL queue 4.55,
Redis queue 3.45, cloud queue 3.15.

## Consequences
Jobs are created in the same transaction as the booking: none are lost.
Redis remains for caching only. Revisit above 100 jobs a second.
''',
    },
    "ar": {
        "template.md": '''# TITLE

Status: Proposed
التاريخ: YYYY-MM-DD · أصحاب القرار: أسماء

## السياق
ما الذي يضطرنا إلى القرار الآن؟ حقائق، وأرقام، وقيود.

## القرار
ما سنفعله، في جملة أو جملتين.

## الخيارات التي دُرست
كل خيار، بأهم فائدة له وأهم كلفة.

## العواقب
ما يصبح أسهل، وما يصبح أصعب، وما سنراقبه.
''',
        "0001-one-postgresql-database.md": '''# 1. قاعدة PostgreSQL واحدة للمنتج كله

Status: Accepted
التاريخ: 2026-02-03 · أصحاب القرار: منى، وكريم، وسارة

## السياق
ثلاثة مطورين، ومنتج واحد، وأقل من 1,000 حجز في اليوم.
لا يجوز أن يُباع حجز مرتين أبداً (الفصل 6).

## القرار
تتشارك كل الوحدات قاعدة PostgreSQL مُدارة واحدة، كلٌّ في مخططها.

## الخيارات التي دُرست
- قاعدة واحدة: نسخة احتياطية واحدة، ومعاملات حقيقية؛ وقد تترابط الوحدات عبر الجداول.
- قاعدة لكل خدمة: نشر مستقل؛ ولا معاملات بينها.

## العواقب
أسهل: المعاملات، والتقارير، والتشغيل. أصعب: إبقاء المخططات منفصلة.
لا تقرأ وحدةٌ جداولَ وحدة أخرى إلا عبر كودها، لا مباشرة أبداً.
نعيد النظر حين تحتاج وحدة أن تتوسع أو تُنشر وحدها.
''',
        "0002-jobs-in-redis.md": '''# 2. المهام الخلفية في طابور Redis

Status: Superseded by 0004
التاريخ: 2026-03-10 · أصحاب القرار: كريم، وعمر

## السياق
يجب ألا تبطئ التذكيراتُ والإيصالاتُ طلبَ الحجز.

## القرار
استعمال طابور مبني على Redis لكل مهمة خلفية.

## الخيارات التي دُرست
- طابور Redis: سريع، ومنتشر؛ وخدمة إضافية نشغّلها.
- طابور PostgreSQL: بلا خدمة جديدة؛ ولم نكن متأكدين أنه سريع بما يكفي.

## العواقب
خدمة إضافية ننسخها احتياطياً ونرقّيها ونراقبها.
''',
        "0003-money-in-piastres.md": '''# 3. المال قروشاً صحيحة

Status: Accepted
التاريخ: 2026-03-18 · أصحاب القرار: سارة، ومنى

## السياق
العربون والمبالغ المستردة والتقارير تجمع مبالغ؛ والأعداد العشرية تعطي 0.30000000000000004.

## القرار
تخزين المال وحسابه أعداداً صحيحة (قروشاً)، ولا يُنسَّق إلا للعرض.

## الخيارات التي دُرست
- الأعداد الصحيحة: دقيقة وبسيطة. والعشرية الدقيقة: دقيقة، وأبطأ، وتختلف من لغة إلى أخرى.

## العواقب
كل مبلغ في الواجهة البرمجية عدد صحيح؛ والواجهة الأمامية تنسّقه.
''',
        "0004-jobs-in-postgresql.md": '''# 4. المهام الخلفية في PostgreSQL

Status: Accepted
التاريخ: 2026-09-02 · أصحاب القرار: كريم، وعمر، وسارة

## السياق
أضاع طابور Redis مهام مرتين حين أُعيد تشغيل Redis (الحادثان 14 و19).
نشغّل 9,000 مهمة في اليوم؛ واختبارات الحمل تُظهر أن PostgreSQL يتحمل 200 في الثانية.
يستبدل 0002.

## القرار
تشغيل المهام الخلفية من جدول في PostgreSQL، بـ SKIP LOCKED.

## الخيارات التي دُرست
انظر مصفوفة القرار في وثيقة التصميم: طابور PostgreSQL 4.55،
وطابور Redis 3.45، والطابور السحابي 3.15.

## العواقب
تُنشأ المهام في معاملة الحجز نفسها: لا يضيع شيء منها.
يبقى Redis للتخزين المؤقت وحده. نعيد النظر فوق 100 مهمة في الثانية.
''',
    },
}

def record(folder, t):
    s = Session(folder)
    s.note(t["w_s_list"])
    s.run("node adr.ts")
    s.note(t["w_s_new"])
    s.run("node adr.ts new Keep job payloads small")
    s.run("node adr.ts")
    s.save(folder / "adr.sh")
    s.note(t["w_s_matrix"])
    s.run("node matrix.ts")
    s.save(folder / "matrix.sh")
    s.note(t["w_s_rules"])
    s.run("node rules.ts; echo \"exit code: $?\"")
    s.save(folder / "rules.sh")


for lang, t in T.items():
    if sys.argv[1:] and lang not in sys.argv[1:]:
        continue
    folder = HERE / lang
    if folder.exists():
        shutil.rmtree(folder)
    folder.mkdir(parents=True)
    for name, text in FILES.items():
        (folder / name).write_text(fill(text, t))
    for name, text in APP.items():
        (folder / name).parent.mkdir(parents=True, exist_ok=True)
        (folder / name).write_text(text)
    (folder / "docs/adr").mkdir(parents=True)
    for name, text in ADR[lang].items():
        (folder / "docs/adr" / name).write_text(text)
    (folder / "package.json").write_text('{\n  "private": true,\n  "type": "module"\n}\n')
    os.symlink(B4 / "node_modules", folder / "node_modules")
    subprocess.run([str(B4 / "node_modules/.bin/prettier"), "--print-width", "84", "--write", "*.ts", "app"],
                   cwd=folder, check=True, capture_output=True)
    record(folder, t)
    (folder / "node_modules").unlink()
    print("wrote", lang)
