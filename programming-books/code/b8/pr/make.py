"""Writes and runs the examples of Book 8, chapter "From Issue to Pull Request", in English and Arabic: an issue,
and Claude Code (the real one, 2.1.331, with the practice server as its model) taking it to a pull request in a
local repository: reading the issue, creating a branch, fixing the code, running the tests, committing (a git
commit-msg hook rejects the first message, and the second passes), and writing the description from the
repository's template. Then the hook tested on its own, and a check of the branch, the commits and the
description before anyone reviews them.
Run: python3 make.py   (needs Node 22, git and Claude Code; B8_LANG=en runs one edition)
"""
import json
import sys
from pathlib import Path

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE.parent))
from kit import chapter  # noqa: E402

PRICE_OLD = "export const total = (bill, tip) => parseInt(bill) * (1 + tip / 100);"
PRICE_NEW = "export const total = (bill, tip) => Number(bill) * (1 + tip / 100);"

W = {
    "en": dict(
        issue="# 42: Bills with piastres are totalled wrong\n\nA customer's bill of 85.50 EGP with a 10% tip showed "
              "93.50. It should be 94.05.\n\nSteps: open the tip page, enter 85.50 and 10.\n",
        task="Fix issue 42 (issues/42.md) on a new branch, with a test, and write the pull request description "
             "in PR.md from the template.",
        template="## What and why\n\n## How it was tested\n\n## Closes\n",
        s_read="I'll read the issue first.",
        s_branch="The bill is read wrongly when it has piastres. Creating a branch for the fix.",
        s_code="Reading the code that totals a bill.",
        s_fix="parseInt drops the piastres. Using Number, and adding a test with the issue's example.",
        s_test="Running the tests.",
        s_commit="Committing.",
        s_recommit="The repository's hook wants Conventional Commits. Committing again with a proper message.",
        s_pr="Writing the description from the template.",
        done="Done: branch fix/42-piastres has one commit, the tests pass, and PR.md is ready to paste into the "
             "pull request.",
        pr="## What and why\n\nBills with piastres were totalled as if they had none: `parseInt(\"85.50\")` is 85. "
           "`total` now reads the bill with `Number`.\n\n## How it was tested\n\nNew test: a bill of 85.50 at 10% "
           "gives 94.05, the example from the issue. All tests pass with `node --test`.\n\n## Closes\n\n#42\n",
        test_name="a bill with piastres (issue 42)",
        bad_msg="fixed stuff",
        good_msg="fix(price): keep piastres when totalling a bill (#42)",
        hook_msg="Commit messages follow Conventional Commits: type(scope): subject",
    ),
    "ar": dict(
        issue="# 42: الفواتير بالقروش تُجمع خطأً\n\nفاتورة زبون بـ 85.50 جنيهاً وبقشيش 10% أظهرت 93.50. ويجب أن "
              "تكون 94.05.\n\nالخطوات: افتح صفحة البقشيش، وأدخل 85.50 و10.\n",
        task="أصلح المهمة 42 (issues/42.md) في فرع جديد، مع اختبار، واكتب وصف طلب الدمج في PR.md من القالب.",
        template="## ماذا ولماذا\n\n## كيف اختُبر\n\n## يغلق\n",
        s_read="سأقرأ المهمة أولاً.",
        s_branch="تُقرأ الفاتورة خطأً حين يكون فيها قروش. سأنشئ فرعاً للإصلاح.",
        s_code="سأقرأ الكود الذي يجمع الفاتورة.",
        s_fix="parseInt يُسقط القروش. سأستخدم Number، وأضيف اختباراً بمثال المهمة.",
        s_test="سأشغّل الاختبارات.",
        s_commit="سأحفظ.",
        s_recommit="hook المستودع يريد Conventional Commits. سأحفظ من جديد برسالة صحيحة.",
        s_pr="سأكتب الوصف من القالب.",
        done="تم: في الفرع fix/42-piastres حفظ واحد، والاختبارات تنجح، وPR.md جاهز للصق في طلب الدمج.",
        pr="## ماذا ولماذا\n\nكانت الفواتير بالقروش تُجمع كأنها بلا قروش: `parseInt(\"85.50\")` تساوي 85. وصارت "
           "`total` تقرأ الفاتورة بـ `Number`.\n\n## كيف اختُبر\n\nاختبار جديد: فاتورة 85.50 بنسبة 10% تعطي 94.05، "
           "مثال المهمة. وكل الاختبارات تنجح بـ `node --test`.\n\n## يغلق\n\n#42\n",
        test_name="a bill with piastres (issue 42)",
        bad_msg="fixed stuff",
        good_msg="fix(price): keep piastres when totalling a bill (#42)",
        hook_msg="رسائل الحفظ تتبع Conventional Commits: type(scope): subject",
    ),
}

TEST_OLD = 'test("a round bill", () => assert.equal(total("100", 10).toFixed(2), "110.00"));'


def replies(lang):
    w = W[lang]
    t = w["task"]
    tool = lambda name, **i: {"type": "tool_use", "name": name, "input": i}  # noqa: E731
    say = lambda s: {"type": "text", "text": s}  # noqa: E731
    bash = lambda c, d: tool("Bash", command=c, description=d)  # noqa: E731
    test_new = TEST_OLD + f'\ntest("{w["test_name"]}", () => assert.equal(total("85.50", 10).toFixed(2), "94.05"));'
    when = lambda **k: {"first": t, **k}  # noqa: E731
    return [
        {"when": when(tool_result="Write"), "text": w["done"]},
        {"when": when(tool_result="Bash", result_text="] fix(price)"), "blocks": [
            say(w["s_pr"]), tool("Read", file_path=".github/pull_request_template.md")]},
        {"when": when(tool_result="Read", result_text="##"), "blocks": [tool("Write", file_path="PR.md", content=w["pr"])]},
        {"when": when(tool_result="Bash", result_text="Conventional Commits"), "blocks": [
            say(w["s_recommit"]), bash(f'git commit -am "{w["good_msg"]}"', "Commit the fix")]},
        {"when": when(tool_result="Bash", result_text="ok 2"), "blocks": [
            say(w["s_commit"]), bash(f'git commit -am "{w["bad_msg"]}"', "Commit the fix")]},
        {"when": when(tool_result="Edit", result_text="price.test.mjs"), "blocks": [
            say(w["s_test"]), bash("node --test", "Run the tests")]},
        {"when": when(tool_result="Edit"), "blocks": [
            tool("Edit", file_path="test/price.test.mjs", old_string=TEST_OLD, new_string=test_new)]},
        {"when": when(tool_result="Read", result_text="parseInt"), "blocks": [
            say(w["s_fix"]), tool("Edit", file_path="src/price.mjs", old_string=PRICE_OLD, new_string=PRICE_NEW),
            tool("Read", file_path="test/price.test.mjs")]},
        {"when": when(tool_result="Bash", result_text="Switched to a new branch"), "blocks": [
            say(w["s_code"]), tool("Read", file_path="src/price.mjs")]},
        {"when": when(tool_result="Bash", result_text="# 42"), "blocks": [
            say(w["s_branch"]), bash("git switch -c fix/42-piastres", "Create a branch")]},
        {"when": when(), "blocks": [say(w["s_read"]), bash("cat issues/42.md", "Read the issue")]},
    ]


T = {}
for lang in ("en", "ar"):
    w = W[lang]
    T[lang] = {
        "w_replies": json.dumps({"replies": replies(lang)}, ensure_ascii=False, indent=2),
        "w_issue": w["issue"], "w_task": w["task"], "w_template": w["template"], "w_hook_msg": w["hook_msg"],
        **{
            "en": dict(w_c_hook="Reject a commit message that does not follow Conventional Commits.",
                       w_c_check="Before review: the branch name, every commit message, and the description.",
                       w_c_watch="Claude Code's events, one line each.",
                       w_branch="branch name", w_commits="commit messages", w_body="description",
                       w_ok="ok", w_bad="needs work", w_turns="turns", w_sep=", ", w_denied="denied",
                       w_cost="cost", w_section="missing section", w_issue_ref="does not close an issue"),
            "ar": dict(w_c_hook="ارفض رسالة حفظ لا تتبع Conventional Commits.",
                       w_c_check="قبل المراجعة: اسم الفرع، وكل رسالة حفظ، والوصف.",
                       w_c_watch="أحداث Claude Code، سطر لكل حدث.",
                       w_branch="اسم الفرع", w_commits="رسائل الحفظ", w_body="الوصف",
                       w_ok="سليم", w_bad="يحتاج عملاً", w_turns="الأدوار", w_sep="، ", w_denied="رُفض",
                       w_cost="التكلفة", w_section="قسم ناقص", w_issue_ref="لا يغلق مهمة"),
        }[lang],
    }

WATCH = """import readline from "node:readline";

// {w_c_watch}
function short(text) {
  const lines = String(text).split("\\n").map((l) => l.trim()).filter(Boolean);
  const tests = lines.filter((l) => /^(not )?ok \\d/.test(l));
  return (tests.length ? tests : lines.slice(0, 2)).join(" | ").slice(0, 100);
}
const brief = (input) => input.command ?? input.file_path ?? JSON.stringify(input);
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

HOOK = """#!/bin/sh
# {w_c_hook}
# git runs this with the path of the file that holds the message.
if ! head -n 1 "$1" | grep -qE '^(feat|fix|docs|refactor|test|chore)(\\([a-z-]+\\))?: .+'; then
  echo "{w_hook_msg}" >&2
  exit 1
fi
"""

FILES = {
    "practice.json": "{w_replies}\n",
    "issues/42.md": "{w_issue}",
    ".github/pull_request_template.md": "{w_template}",
    "githooks/commit-msg": HOOK,
    "src/price.mjs": PRICE_OLD + "\n",
    "test/price.test.mjs": """import test from "node:test";
import assert from "node:assert/strict";
import {total} from "../src/price.mjs";

""" + TEST_OLD + "\n",
    "watch.mjs": WATCH,
    "check.mjs": """import {execFileSync} from "node:child_process";
import fs from "node:fs";

// {w_c_check}
const git = (...args) => execFileSync("git", args, {encoding: "utf8"}).trim();
const branch = git("branch", "--show-current");
const messages = git("log", "main..HEAD", "--format=%s").split("\\n").filter(Boolean);
const body = fs.readFileSync("PR.md", "utf8");
const sections = [...fs.readFileSync(".github/pull_request_template.md", "utf8").matchAll(/^## .+$/gm)];
const problems = {
  "{w_branch}": /^(fix|feat|docs|chore)\\/\\d+-[a-z0-9-]+$/.test(branch) ? [] : [branch],
  "{w_commits}": messages.filter((m) => !/^(feat|fix|docs|refactor|test|chore)(\\([a-z-]+\\))?: .+/.test(m)),
  "{w_body}": [
    ...sections.filter(([s]) => !body.includes(s)).map(([s]) => `{w_section}: ${s}`),
    ...(/#\\d+/.test(body) ? [] : ["{w_issue_ref}"]),
  ],
};
for (const [what, found] of Object.entries(problems)) {
  console.log(`${what.padEnd(16)} ${found.length ? `{w_bad}: ${found.join("; ")}` : "{w_ok}"}`);
}
""",
}

CLAUDE = "claude -p \"{prompt}\" --model claude-opus-5-5 --no-session-persistence"
ALLOW = (' --permission-mode acceptEdits --allowedTools "Bash(cat issues/42.md)"'
         ' "Bash(git switch -c fix/42-piastres)" "Bash(node --test)" "Bash(git commit:*)"')
STREAM = " --output-format stream-json --verbose | node watch.mjs"

RUNS = [
    ("setup.sh", "git init -q -b main && git config core.hooksPath githooks && chmod +x githooks/commit-msg"
     " && git add -A && git commit -qm \"chore: start\" && git log --oneline"),
    ("task.sh", CLAUDE.format(prompt="{w_task}") + ALLOW + STREAM),
    ("result.sh", "git log --oneline main..HEAD && git diff --stat main && cat PR.md"),
    ("projects/hook.sh", "git commit --allow-empty -m \"update\" 2>&1; echo \"exit $?\""),
    ("projects/check.sh", "node check.mjs"),
]


def main():
    chapter(HERE, T, FILES, RUNS)


if __name__ == "__main__":
    main()
