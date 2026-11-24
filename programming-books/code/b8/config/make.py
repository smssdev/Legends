"""Writes and runs the examples of Book 8, chapter "CLAUDE.md, Skills and Hooks", in English and Arabic: a project
configured for Claude Code (the real one, 2.1.331, with the practice server as its model): CLAUDE.md sent with
every request, permissions in .claude/settings.json ignored until the folder is trusted and then applied, a
hook that blocks a push before it runs, and a skill launched by name. Then a hook tested on its own, with no
model at all.
Run: python3 make.py   (needs Node 22, git and Claude Code; B8_LANG=en runs one edition)
"""
import json
import sys
from pathlib import Path

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE.parent))
from kit import chapter  # noqa: E402

W = {
    "en": dict(
        claude_md="# Bit Cafe app\n\n- Money is stored in piastres, as integers; format it only for display.\n"
                  "- Run the tests with `node --test`; every change needs a passing test.\n"
                  "- Never push: a person pushes after review.\n",
        marker="piastres",
        p_money="How should I store the price of a latte?",
        p_tests="Run the tests.",
        p_push="The fix is committed. Push it.",
        p_notes="Write the release notes.",
        money="As an integer number of piastres: a latte at 45 EGP is 4500. Format it as 45.00 only when you "
              "display it, as CLAUDE.md asks.",
        run="Running the tests.",
        need_ok="I couldn't run the tests: `node --test` needs approval here.",
        passed="All 3 tests pass.",
        push_try="Pushing to main.",
        blocked="The push was blocked by the project's hook: pushing is done by a person, after review. The "
                "commit is ready on the branch.",
        notes="Added\n- Receipts show VAT.\nChanged\n- Prices are shown with two decimals.\nFixed\n- Bills with "
              "piastres are totalled correctly.",
        hook_msg="Pushing is done by a person, after review.",
        skill_desc="Write release notes for the café app from the commits since the last release.",
        skill_body="List the changes under Added, Changed and Fixed, one line each, in words a customer "
                   "understands. Leave out changes customers cannot see.",
    ),
    "ar": dict(
        claude_md="# تطبيق مقهى بِت\n\n- المبالغ محفوظة بالقروش، أعداداً صحيحة؛ ولا تُنسّق إلا للعرض.\n"
                  "- شغّل الاختبارات بـ `node --test`؛ وكل تغيير يحتاج اختباراً ناجحاً.\n"
                  "- لا تدفع (push) أبداً: إنسان يدفع بعد المراجعة.\n",
        marker="بالقروش",
        p_money="كيف أحفظ سعر اللاتيه؟",
        p_tests="شغّل الاختبارات.",
        p_push="الإصلاح محفوظ. ادفعه.",
        p_notes="اكتب ملاحظات الإصدار.",
        money="عدداً صحيحاً من القروش: لاتيه بـ 45 جنيهاً هو 4500. ونسّقه 45.00 فقط حين تعرضه، كما يطلب "
              "CLAUDE.md.",
        run="سأشغّل الاختبارات.",
        need_ok="لم أستطع تشغيل الاختبارات: `node --test` يحتاج موافقة هنا.",
        passed="الاختبارات الثلاثة تنجح.",
        push_try="سأدفع إلى main.",
        blocked="أوقف hook المشروع الدفع: الدفع يقوم به إنسان، بعد المراجعة. والحفظ جاهز على الفرع.",
        notes="أُضيف\n- الإيصالات تُظهر الضريبة.\nتغيّر\n- الأسعار تُعرض بخانتين عشريتين.\nأُصلح\n- الفواتير "
              "بالقروش تُجمع بشكل صحيح.",
        hook_msg="الدفع يقوم به إنسان، بعد المراجعة.",
        skill_desc="اكتب ملاحظات الإصدار لتطبيق المقهى من الحفظات منذ آخر إصدار.",
        skill_body="اسرد التغييرات تحت أُضيف وتغيّر وأُصلح، سطراً لكل منها، بكلمات يفهمها الزبون. واترك "
                   "التغييرات التي لا يراها الزبائن.",
    ),
}


def replies(lang):
    w = W[lang]
    tool = lambda name, **i: {"type": "tool_use", "name": name, "input": i}  # noqa: E731
    say = lambda s: {"type": "text", "text": s}  # noqa: E731
    bash = tool("Bash", command="node --test", description="Run the tests")
    return [
        # Only if CLAUDE.md reached the model: its words are in the first message Claude Code sends.
        {"when": {"first": w["marker"], "text": w["p_money"]}, "text": w["money"]},
        {"when": {"first": w["p_tests"], "result_text": "requires approval"}, "text": w["need_ok"]},
        {"when": {"first": w["p_tests"], "tool_result": "Bash"}, "text": w["passed"]},
        {"when": {"first": w["p_tests"]}, "blocks": [say(w["run"]), bash]},
        {"when": {"first": w["p_push"], "tool_result": "Bash"}, "text": w["blocked"]},
        {"when": {"first": w["p_push"]}, "blocks": [
            say(w["push_try"]), tool("Bash", command="git push origin main", description="Push the fix")]},
        {"when": {"first": w["p_notes"], "tool_result": "Skill"}, "text": w["notes"]},
        {"when": {"first": w["p_notes"]}, "blocks": [tool("Skill", skill="release-notes")]},
    ]


T = {}
for lang in ("en", "ar"):
    w = W[lang]
    T[lang] = {
        "w_replies": json.dumps({"replies": replies(lang)}, ensure_ascii=False, indent=2),
        "w_claude_md": w["claude_md"], "w_hook_msg": w["hook_msg"],
        "w_skill_desc": w["skill_desc"], "w_skill_body": w["skill_body"],
        "w_p_money": w["p_money"], "w_p_tests": w["p_tests"], "w_p_push": w["p_push"], "w_p_notes": w["p_notes"],
        **{
            "en": dict(w_c_trust="Mark this folder as trusted, as Claude Code's own message suggests.",
                       w_c_hook="Block any command that pushes: pushing is for a person, after review.",
                       w_c_watch="Claude Code's events, one line each.",
                       w_turns="turns", w_sep=", ", w_denied="denied", w_cost="cost"),
            "ar": dict(w_c_trust="علّم هذا المجلد موثوقاً، كما تقترح رسالة Claude Code نفسها.",
                       w_c_hook="أوقف أي أمر يدفع: الدفع لإنسان، بعد المراجعة.",
                       w_c_watch="أحداث Claude Code، سطر لكل حدث.",
                       w_turns="الأدوار", w_sep="، ", w_denied="رُفض", w_cost="التكلفة"),
        }[lang],
    }

WATCH = """import readline from "node:readline";

// {w_c_watch}
function short(text) {
  const lines = String(text).split("\\n").map((l) => l.trim()).filter(Boolean);
  const tests = lines.filter((l) => /^(not )?ok \\d/.test(l));
  return (tests.length ? tests : lines.slice(0, 1)).join(" | ").slice(0, 110);
}
const brief = (input) => input.command ?? input.skill ?? input.file_path ?? JSON.stringify(input);
for await (const line of readline.createInterface({input: process.stdin})) {
  const event = JSON.parse(line);
  for (const block of event.message?.content ?? []) {
    const who = event.type === "user" ? "loads" : "says ";
    if (block.type === "text") console.log(`  ${who}  ${block.text.split("\\n").join(" / ")}`);
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
    "CLAUDE.md": "{w_claude_md}",
    ".claude/settings.json": json.dumps({
        "permissions": {"allow": ["Bash(node --test)"]},
        "hooks": {"PreToolUse": [{"matcher": "Bash", "hooks": [
            {"type": "command", "command": "sh .claude/hooks/no-push.sh"}]}]},
    }, indent=2) + "\n",
    ".claude/hooks/no-push.sh": """#!/bin/sh
# {w_c_hook}
# Claude Code sends the tool call as JSON on standard input; exit code 2 blocks it,
# and what is written to standard error is told to Claude.
input=$(cat)
case "$input" in
  *"git push"*) echo "{w_hook_msg}" >&2; exit 2 ;;
esac
exit 0
""",
    ".claude/skills/release-notes/SKILL.md": """---
name: release-notes
description: {w_skill_desc}
---
{w_skill_body}
""",
    "src/money.mjs": "export const format = (piastres) => (piastres / 100).toFixed(2);\n",
    "test/money.test.mjs": """import test from "node:test";
import assert from "node:assert/strict";
import {format} from "../src/money.mjs";

test("whole pounds", () => assert.equal(format(4500), "45.00"));
test("piastres", () => assert.equal(format(8550), "85.50"));
test("zero", () => assert.equal(format(0), "0.00"));
""",
    "watch.mjs": WATCH,
    "trust.mjs": """import fs from "node:fs";
import os from "node:os";
import path from "node:path";

// {w_c_trust}
const file = path.join(os.homedir(), ".claude.json");
const config = fs.existsSync(file) ? JSON.parse(fs.readFileSync(file, "utf8")) : {};
config.projects ??= {};
config.projects[process.cwd()] = {...config.projects[process.cwd()], hasTrustDialogAccepted: true};
fs.writeFileSync(file, JSON.stringify(config, null, 2));
console.log(`trusted: ${process.cwd()}`);
""",
}

CLAUDE = "claude -p \"{prompt}\" --model claude-opus-5-5 --no-session-persistence"
STREAM = " --output-format stream-json --verbose | node watch.mjs"

RUNS = [
    ("tree.sh", "git init -q && find CLAUDE.md .claude -type f | sort"),
    ("money.sh", CLAUDE.format(prompt="{w_p_money}")),
    ("untrusted.sh", CLAUDE.format(prompt="{w_p_tests}") + STREAM),
    ("trust.sh", "node trust.mjs"),
    ("trusted.sh", CLAUDE.format(prompt="{w_p_tests}") + STREAM),
    ("hook.sh", CLAUDE.format(prompt="{w_p_push}") + STREAM),
    ("skill.sh", CLAUDE.format(prompt="{w_p_notes}") + STREAM),
    ("projects/hook-test.sh", "echo '{\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"git push origin main\"}}'"
     " | sh .claude/hooks/no-push.sh 2>&1; echo \"exit $?\"; echo '{\"tool_name\":\"Bash\",\"tool_input\":"
     "{\"command\":\"node --test\"}}' | sh .claude/hooks/no-push.sh 2>&1; echo \"exit $?\""),
]


def main():
    chapter(HERE, T, FILES, RUNS)


if __name__ == "__main__":
    main()
