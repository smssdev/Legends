"""Writes and runs the examples of Book 8, chapter "Claude Code in the Terminal", in English and Arabic: the
real Claude Code (2.1.331) pointed at the book's practice server. The practice server plays the model, with
scripted replies; everything else is Claude Code itself: its version, its tools reading a real file and running
real tests, its permission system refusing a command and then allowing it, its JSON output and its cost
accounting, and its spending limit stopping a loop.
Run: python3 make.py   (needs Node 22 and Claude Code; B8_LANG=en runs one edition)
"""
import json
import sys
from pathlib import Path

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE.parent))
from kit import chapter  # noqa: E402

W = {
    "en": dict(
        p_explain="Explain price.mjs in two sentences.",
        p_tests="Run the tests and tell me what fails.",
        p_loop="Keep running the tests until they pass.",
        read_first="I'll read the file first.",
        explained="price.mjs exports total(bill, tip), which adds the tip percentage to the bill. It reads the "
                  "bill with parseInt, so the piastres of a bill like 85.50 are dropped.",
        run_first="I'll run the tests.",
        need_ok="I couldn't run the tests: running `node --test` needs your approval. Allow it, or run it "
                "yourself and paste the output.",
        failing="One test fails: \"a bill with piastres\". total(\"85.50\", 10) returns 93.50 instead of 94.05, "
                "because parseInt drops the .50 before the tip is added.",
        again="Still failing; running them again.",
    ),
    "ar": dict(
        p_explain="اشرح price.mjs في جملتين.",
        p_tests="شغّل الاختبارات وقل لي ما الذي يفشل.",
        p_loop="استمر في تشغيل الاختبارات حتى تنجح.",
        read_first="سأقرأ الملف أولاً.",
        explained="يصدّر price.mjs الدالة total(bill, tip)، التي تضيف نسبة البقشيش إلى الفاتورة. وهو يقرأ "
                  "الفاتورة بـ parseInt، فتسقط قروش فاتورة مثل 85.50.",
        run_first="سأشغّل الاختبارات.",
        need_ok="لم أستطع تشغيل الاختبارات: تشغيل `node --test` يحتاج موافقتك. اسمح به، أو شغّله بنفسك والصق "
                "المخرجات.",
        failing="يفشل اختبار واحد: «a bill with piastres». تعيد total(\"85.50\", 10) القيمة 93.50 بدل 94.05، "
                "لأن parseInt يُسقط .50 قبل إضافة البقشيش.",
        again="ما زالت تفشل؛ سأشغّلها مرة أخرى.",
    ),
}


def replies(lang):
    w = W[lang]
    bash = {"type": "tool_use", "name": "Bash", "input": {"command": "node --test", "description": "Run the tests"}}
    return [
        {"when": {"first": w["p_explain"], "tool_result": "Read"}, "text": w["explained"]},
        {"when": {"first": w["p_explain"]}, "blocks": [
            {"type": "text", "text": w["read_first"]},
            {"type": "tool_use", "name": "Read", "input": {"file_path": "price.mjs"}}]},
        {"when": {"first": w["p_tests"], "result_text": "requires approval"}, "text": w["need_ok"]},
        {"when": {"first": w["p_tests"], "tool_result": "Bash"}, "text": w["failing"]},
        {"when": {"first": w["p_tests"]}, "blocks": [{"type": "text", "text": w["run_first"]}, bash]},
        {"when": {"first": w["p_loop"], "tool_result": "Bash"}, "blocks": [{"type": "text", "text": w["again"]}, bash]},
        {"when": {"first": w["p_loop"]}, "blocks": [{"type": "text", "text": w["run_first"]}, bash]},
    ]


T = {}
for lang in ("en", "ar"):
    w = W[lang]
    T[lang] = {
        "w_replies": json.dumps({"replies": replies(lang)}, ensure_ascii=False, indent=2),
        "w_p_explain": w["p_explain"], "w_p_tests": w["p_tests"], "w_p_loop": w["p_loop"],
        **{
            "en": dict(
                w_c_watch="Claude Code's events, one line each: what it says, which tool it calls, what comes "
                          "back, and what it all cost.",
                w_c_fields="The fields of Claude Code's JSON result that a script needs.",
                w_c_ask="Ask Claude Code about this project, with read-only tools only.",
                w_turns="turns", w_sep=", ", w_denied="denied", w_cost="cost", w_stopped="stopped",
            ),
            "ar": dict(
                w_c_watch="أحداث Claude Code، سطر لكل حدث: ما يقوله، وأي أداة يستدعي، وما يعود، وكم كلّف كل ذلك.",
                w_c_fields="حقول نتيجة Claude Code بصيغة JSON التي يحتاجها السكربت.",
                w_c_ask="اسأل Claude Code عن هذا المشروع، بأدوات القراءة فقط.",
                w_turns="الأدوار", w_sep="، ", w_denied="رُفض", w_cost="التكلفة", w_stopped="توقف",
            ),
        }[lang],
    }

FILES = {
    "practice.json": "{w_replies}\n",
    "price.mjs": "export const total = (bill, tip) => parseInt(bill) * (1 + tip / 100);\n",
    "price.test.mjs": """import test from "node:test";
import assert from "node:assert/strict";
import {total} from "./price.mjs";

test("a round bill", () => assert.equal(total("100", 10).toFixed(2), "110.00"));
test("a bill with piastres", () => assert.equal(total("85.50", 10).toFixed(2), "94.05"));
""",
    "watch.mjs": """import readline from "node:readline";

// {w_c_watch}
// A tool's output in one line: the test results if there are any, else its start.
function short(text) {
  const lines = String(text).split("\\n").map((l) => l.trim()).filter(Boolean);
  const tests = lines.filter((l) => /^(not )?ok \\d/.test(l));
  return (tests.length ? tests : lines.slice(0, 2)).join(" | ").slice(0, 70);
}
for await (const line of readline.createInterface({input: process.stdin})) {
  const event = JSON.parse(line);
  for (const block of event.message?.content ?? []) {
    if (block.type === "text") console.log(`  says   ${block.text}`);
    if (block.type === "tool_use") console.log(`  calls  ${block.name}: ${JSON.stringify(block.input)}`);
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
""",
    "fields.mjs": """import fs from "node:fs";

// {w_c_fields}
const result = JSON.parse(fs.readFileSync(0, "utf8"));
const {usage} = result;
console.log({
  subtype: result.subtype,
  result: result.result,
  num_turns: result.num_turns,
  total_cost_usd: result.total_cost_usd,
  tokens: {
    input: usage.input_tokens,
    cache_written: usage.cache_creation_input_tokens,
    cache_read: usage.cache_read_input_tokens,
    output: usage.output_tokens,
  },
});
""",
    "ask-code.sh": """#!/bin/sh
# {w_c_ask}
exec claude -p "$*" --model claude-opus-5-5 --tools Read,Grep,Glob --no-session-persistence
""",
}

CLAUDE = "claude -p \"{prompt}\" --model claude-opus-5-5 --no-session-persistence"
STREAM = " --output-format stream-json --verbose | node watch.mjs"

RUNS = [
    ("version.sh", "claude --version"),
    ("explain.sh", CLAUDE.format(prompt="{w_p_explain}")),
    ("denied.sh", CLAUDE.format(prompt="{w_p_tests}") + STREAM),
    ("allowed.sh", CLAUDE.format(prompt="{w_p_tests}") + " --allowedTools \"Bash(node --test)\"" + STREAM),
    ("json.sh", CLAUDE.format(prompt="{w_p_explain}") + " --output-format json | node fields.mjs"),
    ("projects/ask.sh", "sh ask-code.sh \"{w_p_explain}\""),
    ("projects/budget.sh", CLAUDE.format(prompt="{w_p_loop}") + " --allowedTools \"Bash(node --test)\""
     " --max-budget-usd 0.30" + STREAM),
]


def main():
    chapter(HERE, T, FILES, RUNS)


if __name__ == "__main__":
    main()
