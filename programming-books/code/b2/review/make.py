"""Writes the examples of Book 2, chapter "Code Review, Mentoring and Technical Decisions", in English and Arabic.
Run: python3 make.py

A real Git repository is made in a temporary folder: a main branch, and a pull request that mixes a new
feature with a big formatting change. What Git printed is recorded (pr.sh, split.sh), and the pull
request's diff is saved (pr.diff) for the review bot to read. Text placeholders are {w_…}.
"""
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE.parent))
import react_kit as kit  # noqa: E402

T = {
    "en": dict(
        w_title="Review", w_todo="make the codes configurable",
        w_r_size="{n} changed lines: hard to review well; split it (under 300)",
        w_r_console="console.log left in: remove it, or use the app's logger",
        w_r_any="“any” switches the type checker off here: write the real type",
        w_r_eq="“==” converts types before comparing: use “===”",
        w_r_todo="TODO without an issue number: link one (#123), or do it now",
        w_r_test="code changed, but no test changed",
        w_found="findings", w_none="Nothing for the robot to say. Over to the humans.",
        w_c1="Prices are whole piastres: no floating-point money",
        w_c2="The codes live in one table; adding a code needs no new if",
        w_c3="Unknown codes are an answer, not a silent full price",
        w_c4="The cart is not changed: the function returns a new result",
        w_c5="Reads the pull request's diff and comments on the lines a machine can judge",
        w_c6="Line numbers in the new file start from the @@ header of each part of the diff",
        w_checks="4 checks passed", w_cart="Cart", w_no_code="no code", w_unknown="unknown code",
        w_subtotal="subtotal", w_discount="discount", w_total="total",
        w_opt="Option", w_score="score", w_winner="Winner", w_if="If",
        w_counts="counted twice",
        w_crit_fit="Fits our stack", w_crit_learn="Easy to learn", w_crit_speed="Speed of the tests",
        w_crit_comm="Community and docs", w_crit_cost="Cost",
        w_manual="Manual testing only",
        w_c7="Every score is from 1 (poor) to 5 (excellent); the weights say what matters to this team",
        w_c8="Which option would win if one criterion mattered twice as much?",
        w_c_branch="A new branch for the feature", w_c_stat="What changed, file by file",
        w_c_split="Move the formatting into its own pull request", w_c_after="The feature’s pull request, after the split",
        w_feature="Add discount codes", w_format="Format the styles", w_base="Start the shop",
        w_undo="Keep only the discount codes",
    ),
    "ar": dict(
        w_title="المراجعة", w_todo="اجعل الأكواد قابلة للضبط",
        w_r_size="{n} سطراً متغيراً: يصعب مراجعتها جيداً، قسّمه (أقل من 300)",
        w_r_console="console.log متروك: احذفه، أو استخدم أداة السجلات في التطبيق",
        w_r_any="“any” يطفئ فحص الأنواع هنا: اكتب النوع الحقيقي",
        w_r_eq="“==” يحوّل الأنواع قبل المقارنة: استخدم “===”",
        w_r_todo="TODO بلا رقم مهمة: اربطه بواحدة (#123)، أو أنجزه الآن",
        w_r_test="تغيّر الكود، ولم يتغير أي اختبار",
        w_found="ملاحظات", w_none="لا شيء يقوله الروبوت. الكلمة للبشر.",
        w_c1="الأسعار بالقروش أعداداً صحيحة: لا أموال بأعداد عشرية",
        w_c2="الأكواد في جدول واحد، وإضافة كود لا تحتاج if جديدة",
        w_c3="الكود المجهول جواب، لا سعر كامل صامت",
        w_c4="السلة لا تتغير: الدالة تُرجع نتيجة جديدة",
        w_c5="يقرأ فروق طلب الدمج ويعلّق على الأسطر التي تستطيع الآلة الحكم عليها",
        w_c6="أرقام الأسطر في الملف الجديد تبدأ من ترويسة @@ لكل جزء من الفروق",
        w_checks="نجحت 4 فحوص", w_cart="السلة", w_no_code="بلا كود", w_unknown="كود مجهول",
        w_subtotal="المجموع", w_discount="الخصم", w_total="الإجمالي",
        w_opt="الخيار", w_score="النتيجة", w_winner="الفائز", w_if="إذا",
        w_counts="حُسب مرتين",
        w_crit_fit="يناسب أدواتنا", w_crit_learn="سهل التعلم", w_crit_speed="سرعة الاختبارات",
        w_crit_comm="المجتمع والتوثيق", w_crit_cost="الكلفة",
        w_manual="الاختبار اليدوي وحده",
        w_c7="كل درجة من 1 (ضعيف) إلى 5 (ممتاز)، والأوزان تقول ما يهم هذا الفريق",
        w_c8="أي خيار يفوز لو كان معيار واحد أهم بمرتين؟",
        w_c_branch="فرع جديد للميزة", w_c_stat="ما الذي تغيّر، ملفاً ملفاً",
        w_c_split="انقل التنسيق إلى طلب دمج مستقل", w_c_after="طلب دمج الميزة بعد التقسيم",
        w_feature="أضف أكواد الخصم", w_format="نسّق ملف الأنماط", w_base="ابدأ المتجر",
        w_undo="أبقِ أكواد الخصم وحدها",
    ),
}

# ------------------------------------------------------------------ the shop before the pull request
BASE = {
    "src/cart/cart.ts": '''export type Line = { name: string; price: number; qty: number };

export function subtotal(lines: Line[]): number {
  return lines.reduce((sum, line) => sum + line.price * line.qty, 0);
}
''',
    "src/cart/cart.test.ts": '''import { strict as assert } from "node:assert";
import { subtotal } from "./cart";

assert.equal(subtotal([{ name: "mug", price: 8500, qty: 2 }]), 17000);
''',
}

# The pull request: a new feature written in a hurry
DISCOUNT = '''import { subtotal } from "./cart";

export function applyDiscount(cart: any, code: string) {
  console.log("applying", code);
  let total = subtotal(cart.lines);
  if (code == "BIT10") total = total * 0.9;
  if (code == "HALF") total = total / 2;
  // TODO {w_todo}
  cart.total = total;
  return cart;
}
'''


def styles(compact):
    """A stylesheet of 60 rules; the pull request rewrote all of them from one line to three."""
    rules = []
    for i in range(1, 61):
        if compact:
            rules.append(f".c{i} {{ margin: {i % 8}px; padding: {i % 5}px; }}")
        else:
            rules.append(f".c{i} {{\n  margin: {i % 8}px;\n  padding: {i % 5}px;\n}}")
    return "\n".join(rules) + "\n"


# ------------------------------------------------------------------ the robot reviewer
NODE = {}
NODE["review-bot.ts"] = '''import { readFileSync } from "node:fs";

// {w_c5}
type Finding = { file: string; line: number; message: string };

const diff = readFileSync(process.argv[2] ?? "pr.diff", "utf8").split("\\n");
const findings: Finding[] = [];
const changedFiles = new Set<string>();
let file = "";
let line = 0;
let changed = 0;

for (const text of diff) {
  if (text.startsWith("+++ ")) {
    file = text.slice(6); // "+++ b/src/cart/discount.ts"
    changedFiles.add(file);
    continue;
  }
  const hunk = /^@@ -\\d+(?:,\\d+)? \\+(\\d+)/.exec(text);
  if (hunk) {
    line = Number(hunk[1]); // {w_c6}
    continue;
  }
  if (text.startsWith("-") && !text.startsWith("---")) {
    changed++;
    continue;
  }
  if (!text.startsWith("+") || text.startsWith("+++")) {
    if (text.startsWith(" ")) line++;
    continue;
  }
  changed++;
  const code = text.slice(1);
  const say = (message: string) => findings.push({ file, line, message });
  if (/console\\.log\\(/.test(code)) say("{w_r_console}");
  if (/:\\s*any\\b/.test(code)) say("{w_r_any}");
  if (/[^=!]==[^=]/.test(code)) say("{w_r_eq}");
  if (/TODO(?!.*#\\d+)/.test(code)) say("{w_r_todo}");
  line++;
}

const isTest = (f: string) => /\\.test\\.ts$/.test(f);
const code = [...changedFiles].filter((f) => f.endsWith(".ts") && !isTest(f));
if (code.length > 0 && ![...changedFiles].some(isTest)) findings.push({ file: code[0]!, line: 1, message: "{w_r_test}" });
if (changed > 300) findings.push({ file: "*", line: 0, message: "{w_r_size}".replace("{n}", String(changed)) });

for (const f of findings) console.log(`${f.file}:${f.line}  ${f.message}`);
console.log(findings.length ? `${findings.length} {w_found}` : "{w_none}");
'''

# ------------------------------------------------------------------ the feature, after the review
PLAIN = {}
PLAIN["discount.ts"] = '''import { subtotal, type Line } from "./cart";

// {w_c1}
// {w_c2}
const codes: Record<string, { percent: number }> = {
  BIT10: { percent: 10 },
  HALF: { percent: 50 },
};

// {w_c3}
export type Priced =
  | { ok: true; subtotal: number; discount: number; total: number }
  | { ok: false; reason: "unknown-code" };

// {w_c4}
export function price(lines: readonly Line[], code?: string): Priced {
  const sum = subtotal(lines);
  const key = code?.trim().toUpperCase();
  if (!key) return { ok: true, subtotal: sum, discount: 0, total: sum };
  const found = codes[key];
  if (!found) return { ok: false, reason: "unknown-code" };
  const discount = Math.round((sum * found.percent) / 100);
  return { ok: true, subtotal: sum, discount, total: sum - discount };
}
'''

PLAIN["cart.ts"] = '''export type Line = { name: string; price: number; qty: number };

export function subtotal(lines: readonly Line[]): number {
  return lines.reduce((sum, line) => sum + line.price * line.qty, 0);
}
'''

NODE["discount.test.ts"] = '''import { strict as assert } from "node:assert";
import { price } from "./discount";

const cart = [
  { name: "mug", price: 8500, qty: 1 },
  { name: "sticker", price: 1499, qty: 3 },
];
const egp = (piastres: number) => (piastres / 100).toFixed(2);

for (const code of [undefined, "BIT10", " half ", "NOPE"]) {
  const result = price(cart, code);
  const label = (code === undefined ? "({w_no_code})" : JSON.stringify(code)).padEnd(10);
  if (!result.ok) console.log(`${label} → {w_unknown}`);
  else console.log(`${label} → {w_subtotal} ${egp(result.subtotal)}  {w_discount} ${egp(result.discount)}  {w_total} ${egp(result.total)}`);
}

// The cases that matter, as checks that fail loudly
assert.deepEqual(price([], "BIT10"), { ok: true, subtotal: 0, discount: 0, total: 0 });
assert.equal(price(cart, "bit10").ok, true);
assert.deepEqual(price(cart, "FREE"), { ok: false, reason: "unknown-code" });
const before = structuredClone(cart);
price(cart, "HALF");
assert.deepEqual(cart, before);
console.log("✓ {w_checks}");
'''

# ------------------------------------------------------------------ a decision matrix
NODE["decide.ts"] = '''// {w_c7}
const criteria = { fit: 5, learn: 3, speed: 3, community: 2, cost: 2 } as const;
type Criterion = keyof typeof criteria;

const names: Record<Criterion, string> = {
  fit: "{w_crit_fit}", learn: "{w_crit_learn}", speed: "{w_crit_speed}", community: "{w_crit_comm}", cost: "{w_crit_cost}",
};

const options: Record<string, Record<Criterion, number>> = {
  Playwright: { fit: 5, learn: 3, speed: 4, community: 4, cost: 5 },
  Cypress: { fit: 4, learn: 5, speed: 3, community: 5, cost: 4 },
  "{w_manual}": { fit: 2, learn: 5, speed: 1, community: 3, cost: 2 },
};

function total(scores: Record<Criterion, number>, weights: Record<Criterion, number>): number {
  return (Object.keys(weights) as Criterion[]).reduce((sum, c) => sum + scores[c] * weights[c], 0);
}

function winner(weights: Record<Criterion, number>): string {
  return Object.entries(options).sort(([, a], [, b]) => total(b, weights) - total(a, weights))[0]![0];
}

console.log("{w_opt}".padEnd(22) + "{w_score}");
for (const [name, scores] of Object.entries(options)) console.log(name.padEnd(22) + total(scores, criteria));
console.log(`{w_winner}: ${winner(criteria)}`);

// {w_c8}
for (const c of Object.keys(criteria) as Criterion[]) {
  console.log(`  {w_if} "${names[c]}" {w_counts} → ${winner({ ...criteria, [c]: criteria[c] * 2 })}`);
}
'''

kit.generate(HERE, T, plain=PLAIN, node_files=NODE, title_key="w_title")

PR_TEMPLATE = {
    "en": """## What and why

<!-- One or two sentences. Link the issue: Closes #123 -->

## How to test it

1.
2.

## Screenshots

<!-- Before and after, for any change people can see. Light and dark, LTR and RTL. -->

## Checklist

- [ ] Tests added or changed, and they fail without this change
- [ ] Works with the keyboard and a screen reader
- [ ] Texts in both languages
- [ ] No secrets, no console.log
- [ ] Under 300 changed lines, or the reason it cannot be
""",
    "ar": """## ماذا ولماذا

<!-- جملة أو جملتان، واربط المهمة: Closes #123 -->

## كيف تختبره

1.
2.

## صور

<!-- قبل وبعد لأي تغيير يراه الناس، بالفاتح والداكن، ومن اليسار ومن اليمين -->

## قائمة التحقق

- [ ] أُضيفت اختبارات أو تغيّرت، وتفشل بدون هذا التغيير
- [ ] يعمل بلوحة المفاتيح وقارئ الشاشة
- [ ] النصوص باللغتين
- [ ] لا أسرار، ولا console.log
- [ ] أقل من 300 سطر متغير، أو سبب تعذر ذلك
""",
}

ADR = {
    "en": """# 7. Use Playwright for end-to-end tests

Date: 2026-03-04
Status: Accepted

## Context

Bugs reached users twice last month through the checkout, which no test covers
end to end. We need tests that click through the real app in a real browser,
and run on every pull request in under five minutes.

## Options

- Playwright: 64 points in our matrix (decide.ts)
- Cypress: 62 points; easier to learn, and wins if that counts double
- Manual testing before each release: 38 points

## Decision

We use Playwright, because it fits our tools best (TypeScript, several
browsers, runs in parallel) and is free. The vote was close: two people
on the team will pair with the others on the first tests.

## Consequences

- Good: the checkout is tested on every pull request, in three browsers.
- Bad: one more tool to learn; the tests need a running app in CI.
- We will look again if the suite takes more than five minutes.
""",
    "ar": """# 7. نستخدم Playwright لاختبارات من الطرف إلى الطرف

التاريخ: 2026-03-04
الحالة: مقبول

## السياق

وصلت أخطاء إلى المستخدمين مرتين الشهر الماضي عبر صفحة الدفع، ولا يغطيها
أي اختبار من أولها إلى آخرها. نحتاج اختبارات تضغط في التطبيق الحقيقي داخل
متصفح حقيقي، وتعمل مع كل طلب دمج في أقل من خمس دقائق.

## الخيارات

- Playwright: ‏64 نقطة في مصفوفتنا (decide.ts)
- Cypress: ‏62 نقطة، أسهل في التعلم، ويفوز لو حُسب ذلك مرتين
- الاختبار اليدوي قبل كل إصدار: ‏38 نقطة

## القرار

نستخدم Playwright لأنه الأنسب لأدواتنا (TypeScript، وعدة متصفحات، ويعمل
بالتوازي) ومجاني. كان الفارق صغيراً، فسيعمل اثنان من الفريق بالتناوب مع
الباقين على الاختبارات الأولى.

## العواقب

- الجيد: صفحة الدفع تُختبر مع كل طلب دمج، في ثلاثة متصفحات.
- السيئ: أداة أخرى للتعلم، والاختبارات تحتاج تطبيقاً يعمل في CI.
- سنعيد النظر إن تجاوزت الاختبارات خمس دقائق.
""",
}
for lang in T:
    (HERE / lang / "docs").mkdir(parents=True, exist_ok=True)
    (HERE / lang / "pull_request_template.md").write_text(PR_TEMPLATE[lang])
    (HERE / lang / "docs" / "0007-e2e-tests.md").write_text(ADR[lang])


# ------------------------------------------------------------------ the recorded Git sessions
def git_session(lang):
    t = T[lang]
    out = HERE / lang
    work = Path(tempfile.mkdtemp())
    env = dict(os.environ, GIT_AUTHOR_NAME="Sara", GIT_AUTHOR_EMAIL="sara@example.com", GIT_COMMITTER_NAME="Sara",
               GIT_COMMITTER_EMAIL="sara@example.com", GIT_CONFIG_GLOBAL="/dev/null", GIT_CONFIG_SYSTEM="/dev/null")
    when = iter(range(1, 20))

    def run(cmd, show=True):
        stamp = f"2026-03-0{min(next(when), 9)}T10:00:00+0200"
        r = subprocess.run(cmd, shell=True, cwd=work, capture_output=True, text=True,
                           env=dict(env, GIT_AUTHOR_DATE=stamp, GIT_COMMITTER_DATE=stamp))
        if r.returncode:
            raise SystemExit(f"{cmd}\n{r.stdout}{r.stderr}")
        return ([f"$ {cmd}"] + [l.rstrip() for l in (r.stdout + r.stderr).splitlines()]) if show else []

    def write(name, text):
        p = work / name
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(text)

    try:
        run("git init -q -b main")
        for name, text in BASE.items():
            write(name, text)
        write("src/ui/styles.css", styles(compact=True))
        run(f'git add -A && git commit -qm "{t["w_base"]}"')

        pr = [f"# {t['w_c_branch']}"]
        pr += run("git switch -c feature/discount-codes")
        write("src/cart/discount.ts", kit.fill(DISCOUNT, t))
        write("src/ui/styles.css", styles(compact=False))
        run(f'git add -A && git commit -qm "{t["w_feature"]}"')
        pr += [f"# {t['w_c_stat']}"]
        pr += run("git diff --stat main")
        (out / "pr.sh").write_text("\n".join(pr) + "\n")
        (out / "pr.diff").write_text(subprocess.run("git diff main", shell=True, cwd=work, capture_output=True,
                                                     text=True, env=env).stdout)
        (out / "discount-pr.diff").write_text(subprocess.run("git diff main -- src/cart/discount.ts", shell=True,
                                                             cwd=work, capture_output=True, text=True, env=env).stdout)

        split = [f"# {t['w_c_split']}"]
        split += run("git switch -c chore/format-styles main")
        split += run("git checkout feature/discount-codes -- src/ui/styles.css")
        split += run(f'git commit -qm "{t["w_format"]}"')
        split += run("git switch feature/discount-codes")
        split += run("git checkout main -- src/ui/styles.css")
        split += run(f'git commit -qm "{t["w_undo"]}"')
        split += [f"# {t['w_c_after']}"]
        split += run("git diff --stat main")
        (out / "split.sh").write_text("\n".join(split) + "\n")
        (out / "after.diff").write_text(subprocess.run("git diff main", shell=True, cwd=work, capture_output=True,
                                                       text=True, env=env).stdout)
    finally:
        shutil.rmtree(work, ignore_errors=True)


for lang in T:
    git_session(lang)
    print("recorded", lang)
