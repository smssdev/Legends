"""Writes and runs the examples of Book 8, chapter "Working on a Real Codebase", in English and Arabic: a small
project in git, and Claude Code (the real one, 2.1.331, with the practice server as its model) finding its way
around with search, reading before it edits, changing two files with its Edit tool, running the tests, and
the change reviewed with git as a person would. Then a read-only search, a review of a diff piped in, and a
check of the agent's claims against what git says changed.
Run: python3 make.py   (needs Node 22, git and Claude Code; B8_LANG=en runs one edition)
"""
import json
import sys
from pathlib import Path

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE.parent))
from kit import chapter  # noqa: E402

RECEIPT = """import {priceOf} from "./menu.mjs";

// A receipt for an order: one line per item, then the total.
export function receipt(items) {
  const lines = items.map(({name, qty}) => ({name, qty, amount: priceOf(name) * qty}));
  const total = lines.reduce((sum, line) => sum + line.amount, 0);
  return {lines, total};
}
"""
RECEIPT_OLD = """  const total = lines.reduce((sum, line) => sum + line.amount, 0);
  return {lines, total};"""
RECEIPT_NEW = """  const subtotal = lines.reduce((sum, line) => sum + line.amount, 0);
  const vat = Math.round(subtotal * VAT_RATE * 100) / 100;
  return {lines, subtotal, vat, total: subtotal + vat};"""
TEST = """import test from "node:test";
import assert from "node:assert/strict";
import {receipt} from "../src/receipt.mjs";

test("a receipt adds up its lines", () => {
  const r = receipt([{name: "latte", qty: 2}, {name: "croissant", qty: 1}]);
  assert.equal(r.total, 120);
});
"""
TEST_OLD = """  assert.equal(r.total, 120);
});"""
TEST_NEW = """  assert.equal(r.subtotal, 120);
  assert.equal(r.vat, 16.8);
  assert.equal(r.total, 136.8);
});"""

W = {
    "en": dict(
        task="Add 14% VAT to receipts: a subtotal, the VAT, and the total including it. Update the test.",
        find="where is the total of a receipt computed?",
        diff_review="Review this diff",
        s_search="I'll find where receipts are totalled.",
        s_read="Found src/receipt.mjs. Reading it, and the menu module beside it, before I change anything.",
        s_edit="I'll add the VAT after the subtotal.",
        s_test_edit="Now the test, which still expects the old total.",
        s_run="Running the tests.",
        done="Done. src/receipt.mjs now returns subtotal, vat (14%, rounded to piastres) and total; VAT_RATE is "
             "exported from src/menu.mjs. The test checks all three, and it passes.",
        found="The total is computed in src/receipt.mjs, in receipt(): the amounts of the lines are added with "
              "reduce. Prices come from priceOf in src/menu.mjs.",
        review="1. menu.mjs: VAT_RATE = 0.14 is a good single place for the rate.\n2. receipt.mjs: the VAT is "
               "rounded to piastres, but total is subtotal + vat without rounding; with other prices the sum "
               "can show a floating-point tail: a subtotal of 16 gives a total of 18.240000000000002.\n3. The test covers one order; add "
               "one whose VAT needs rounding.",
    ),
    "ar": dict(
        task="أضف ضريبة القيمة المضافة 14% إلى الإيصالات: مجموعاً فرعياً، والضريبة، والإجمالي شاملاً لها. وحدّث الاختبار.",
        find="أين يُحسب إجمالي الإيصال؟",
        diff_review="راجع هذا الفرق",
        s_search="سأجد أين تُجمع الإيصالات.",
        s_read="وجدت src/receipt.mjs. سأقرؤه، ووحدة القائمة بجانبه، قبل أن أغيّر أي شيء.",
        s_edit="سأضيف الضريبة بعد المجموع الفرعي.",
        s_test_edit="والآن الاختبار، الذي ما زال يتوقع الإجمالي القديم.",
        s_run="سأشغّل الاختبارات.",
        done="تم. صار src/receipt.mjs يعيد subtotal وvat (14%، مقرّبة إلى القروش) وtotal؛ وVAT_RATE يُصدَّر من "
             "src/menu.mjs. والاختبار يفحص الثلاثة، وهو ينجح.",
        found="يُحسب الإجمالي في src/receipt.mjs، في receipt(): تُجمع مبالغ السطور بـ reduce. والأسعار تأتي من "
              "priceOf في src/menu.mjs.",
        review="1. menu.mjs: الثابت VAT_RATE = 0.14 مكان واحد جيد للنسبة.\n2. receipt.mjs: الضريبة مقرّبة إلى "
               "القروش، لكن total هو subtotal + vat بلا تقريب؛ ومع أسعار أخرى قد يظهر ذيل عشري: مجموع فرعي "
               "16 يعطي إجمالياً 18.240000000000002.\n3. الاختبار يغطي طلباً واحداً؛ أضف طلباً تحتاج ضريبته إلى تقريب.",
    ),
}


RECEIPT_AFTER = RECEIPT.replace('import {priceOf} from "./menu.mjs";',
                                'import {priceOf, VAT_RATE} from "./menu.mjs";').replace(RECEIPT_OLD, RECEIPT_NEW)


def replies(lang):
    w = W[lang]
    t = w["task"]
    tool = lambda name, **i: {"type": "tool_use", "name": name, "input": i}  # noqa: E731
    say = lambda s: {"type": "text", "text": s}  # noqa: E731
    return [
        # The task: search; read two files; edit both; edit the test; run the tests; report.
        {"when": {"first": t, "tool_result": "Bash", "result_text": "ok 1"}, "text": w["done"]},
        {"when": {"first": t, "tool_result": "Edit", "result_text": "receipt.test.mjs"}, "blocks": [
            say(w["s_run"]), tool("Bash", command="node --test", description="Run the tests")]},
        {"when": {"first": t, "tool_result": "Edit"}, "blocks": [
            say(w["s_test_edit"]),
            tool("Edit", file_path="test/receipt.test.mjs", old_string=TEST_OLD, new_string=TEST_NEW)]},
        {"when": {"first": t, "tool_result": "Read"}, "blocks": [
            say(w["s_edit"]),
            tool("Edit", file_path="src/receipt.mjs", old_string=RECEIPT.rstrip("\n"),
                 new_string=RECEIPT_AFTER.rstrip("\n")),
            tool("Edit", file_path="src/menu.mjs", old_string="export const PRICES = {",
                 new_string="export const VAT_RATE = 0.14;\n\nexport const PRICES = {")]},
        {"when": {"first": t, "tool_result": "Bash", "result_text": "src/"}, "blocks": [
            say(w["s_read"]), tool("Read", file_path="src/receipt.mjs"), tool("Read", file_path="src/menu.mjs")]},
        {"when": {"first": t}, "blocks": [
            say(w["s_search"]), tool("Bash", command="grep -rln total src", description="Find files")]},
        # A read-only question.
        {"when": {"first": w["find"], "tool_result": "Bash", "result_text": "src/receipt.mjs"}, "text": w["found"]},
        {"when": {"first": w["find"]}, "blocks": [
            tool("Bash", command="grep -rn total src", description="Search the sources")]},
        # A review of a diff given on standard input.
        {"when": {"first": w["diff_review"]}, "text": w["review"]},
    ]


T = {}
for lang in ("en", "ar"):
    w = W[lang]
    T[lang] = {
        "w_replies": json.dumps({"replies": replies(lang)}, ensure_ascii=False, indent=2),
        "w_task": w["task"], "w_find": w["find"], "w_diff_review": w["diff_review"],
        **{
            "en": dict(w_c_watch="Claude Code's events, one line each.",
                       w_c_claims="Which files the agent says it changed, against what git says changed.",
                       w_claimed="claimed", w_changed="changed in git", w_missing="changed but not mentioned",
                       w_turns="turns", w_sep=", ", w_denied="denied", w_cost="cost"),
            "ar": dict(w_c_watch="أحداث Claude Code، سطر لكل حدث.",
                       w_c_claims="الملفات التي يقول الوكيل إنه غيّرها، مقابل ما يقول git إنه تغيّر.",
                       w_claimed="يقول إنه غيّر", w_changed="تغيّر في git", w_missing="تغيّر ولم يُذكر",
                       w_turns="الأدوار", w_sep="، ", w_denied="رُفض", w_cost="التكلفة"),
        }[lang],
    }

WATCH = """import readline from "node:readline";

// {w_c_watch}
function short(text) {
  const lines = String(text).split("\\n").map((l) => l.trim()).filter(Boolean);
  const tests = lines.filter((l) => /^(not )?ok \\d/.test(l));
  return (tests.length ? tests : lines.slice(0, 1)).join(" | ").slice(0, 66);
}
const brief = (input) => input.command ?? input.pattern ?? input.file_path ?? JSON.stringify(input);
for await (const line of readline.createInterface({input: process.stdin})) {
  const event = JSON.parse(line);
  for (const block of event.message?.content ?? []) {
    if (block.type === "text") console.log(`  says   ${block.text}`);
    if (block.type === "tool_use") console.log(`  calls  ${block.name} ${brief(block.input)}`);
    if (block.type === "tool_result") {
      const content = typeof block.content === "string" ? block.content : JSON.stringify(block.content);
      console.log(`  gets   ${block.is_error ? "(error) " : ""}${short(content)}`);
    }
  }
  if (event.type === "result") {
    const denied = event.permission_denials.length;
    console.log(`  {w_turns}: ${event.num_turns}{w_sep}{w_denied}: ${denied}{w_sep}` +
      `{w_cost}: $${event.total_cost_usd.toFixed(4)}{w_sep}${event.subtype}`);
  }
}
"""

FILES = {
    "practice.json": "{w_replies}\n",
    "package.json": '{"type": "module", "private": true, "scripts": {"test": "node --test"}}\n',
    "src/menu.mjs": """export const PRICES = {
  latte: 45,
  croissant: 30,
  "mint tea": 30,
};

export function priceOf(name) {
  if (!(name in PRICES)) throw new Error(`not on the menu: ${name}`);
  return PRICES[name];
}
""",
    "src/receipt.mjs": RECEIPT,
    "test/receipt.test.mjs": TEST,
    "watch.mjs": WATCH,
    "claims.mjs": """import {execFileSync} from "node:child_process";
import fs from "node:fs";

// {w_c_claims}
const said = fs.readFileSync(0, "utf8");
const changed = execFileSync("git", ["diff", "--name-only"], {encoding: "utf8"}).split("\\n").filter(Boolean);
const claimed = changed.filter((file) => said.includes(file));
console.log(`{w_claimed}: ${claimed.join(", ") || "-"}`);
console.log(`{w_changed}: ${changed.join(", ")}`);
const missing = changed.filter((file) => !claimed.includes(file));
console.log(`{w_missing}: ${missing.join(", ") || "-"}`);
""",
}

CLAUDE = "claude -p \"{prompt}\" --model claude-opus-5-5 --no-session-persistence"
STREAM = " --output-format stream-json --verbose | node watch.mjs"
ALLOW = " --allowedTools \"Bash(grep -rln total src)\" \"Bash(node --test)\""

RUNS = [
    ("setup.sh", "git init -q && git add -A && git -c user.name=Bit -c user.email=bit@example.com commit -qm start"
     " && git log --oneline && node --test 2>&1 | grep -E '^# (pass|fail)'"),
    ("task.sh", CLAUDE.format(prompt="{w_task}") + " --permission-mode acceptEdits" + ALLOW + STREAM),
    ("diff.sh", "git diff --stat && git diff src/receipt.mjs"),
    ("projects/find.sh", CLAUDE.format(prompt="{w_find}") + " --tools Read,Bash"
     " --allowedTools \"Bash(grep -rn total src)\""),
    ("projects/review.sh", "git diff | " + CLAUDE.format(prompt="{w_diff_review}.") + " --tools \"\""),
    ("projects/claims.sh", "git checkout -q -- . && " + CLAUDE.format(prompt="{w_task}")
     + " --permission-mode acceptEdits" + ALLOW + " | node claims.mjs"),
]


def main():
    chapter(HERE, T, FILES, RUNS)


if __name__ == "__main__":
    main()
