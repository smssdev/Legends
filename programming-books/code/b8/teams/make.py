"""Writes and runs the examples of Book 8, chapter "Claude Code for Teams and CI", in English and Arabic: team
settings and personal settings, where the team's deny wins over a personal allow; and a review that runs in
continuous integration: the diff of a branch sent to Claude Code (the real one, 2.1.331, with the practice server
as its model) in print mode, with no tools, a spending limit and a JSON schema for the verdict, so that a script
can fail the build on a blocker. The same review passes once the developer fixes the problem. Then the workflow
file checked, and the verdict turned into a pull request comment.
Run: python3 make.py   (needs Node 22, git, Python with PyYAML, and Claude Code; B8_LANG=en runs one edition)
"""
import json
import sys
from pathlib import Path

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE.parent))
from kit import chapter  # noqa: E402

RECEIPT = """import {priceOf, VAT_RATE} from "./menu.mjs";

export function receipt(items) {
  const lines = items.map(({name, qty}) => ({name, qty, amount: priceOf(name) * qty}));
  const subtotal = lines.reduce((sum, line) => sum + line.amount, 0);
  const vat = Math.round(subtotal * VAT_RATE * 100) / 100;
  return {lines, subtotal, vat, total: subtotal + vat};
}
"""
FIXED = "total: Math.round((subtotal + vat) * 100) / 100"

W = {
    "en": dict(
        p_push="The release is tagged. Push it.",
        push_try="Pushing.",
        push_blocked="I couldn't push: the team's settings deny it. A person needs to push the release.",
        review="Review this diff for the café app. Report blockers only: bugs, missing tests for changed "
               "behaviour, or money handled wrongly.",
        blocker="receipt.mjs: total is subtotal + vat without rounding; a subtotal of 16 gives 18.240000000000002.",
        claude_md="# Bit Cafe app\n\n- Money is rounded to piastres at every step that produces an amount.\n",
    ),
    "ar": dict(
        p_push="الإصدار موسوم. ادفعه.",
        push_try="سأدفع.",
        push_blocked="لم أستطع الدفع: إعدادات الفريق ترفضه. يجب أن يدفع إنسان الإصدار.",
        review="راجع هذا الفرق لتطبيق المقهى. أبلغ عن العوائق فقط: الأخطاء، والاختبارات الناقصة لسلوك تغيّر، "
               "والتعامل الخاطئ مع المال.",
        blocker="receipt.mjs: الإجمالي subtotal + vat بلا تقريب؛ مجموع فرعي 16 يعطي 18.240000000000002.",
        claude_md="# تطبيق مقهى بِت\n\n- المال يُقرّب إلى القروش في كل خطوة تُنتج مبلغاً.\n",
    ),
}


def replies(lang):
    w = W[lang]
    tool = lambda name, **i: {"type": "tool_use", "name": name, "input": i}  # noqa: E731
    return [
        {"when": {"first": w["p_push"], "tool_result": "Bash"}, "text": w["push_blocked"]},
        {"when": {"first": w["p_push"]}, "blocks": [
            {"type": "text", "text": w["push_try"]},
            tool("Bash", command="git push origin main", description="Push the release")]},
        # The verdict depends on the diff: the fixed version rounds the total.
        {"when": {"first": w["review"], "tool_result": "StructuredOutput"}, "text": "-"},
        {"when": {"first": FIXED}, "blocks": [tool("StructuredOutput", ok=True, blockers=[])]},
        {"when": {"first": w["review"]}, "blocks": [tool("StructuredOutput", ok=False, blockers=[w["blocker"]])]},
    ]


T = {}
for lang in ("en", "ar"):
    w = W[lang]
    T[lang] = {
        "w_replies": json.dumps({"replies": replies(lang)}, ensure_ascii=False, indent=2),
        "w_p_push": w["p_push"], "w_review": w["review"], "w_claude_md": w["claude_md"],
        **{
            "en": dict(w_c_review="Review the branch's diff with Claude Code; fail the build on any blocker.",
                       w_c_comment="The verdict as a comment for the pull request.",
                       w_c_watch="Claude Code's events, one line each.",
                       w_c_trust="Mark this folder as trusted.",
                       w_title="Claude review", w_pass="No blockers found.", w_found="Blockers",
                       w_note="An automatic review: a person still approves.",
                       w_turns="turns", w_sep=", ", w_denied="denied", w_cost="cost"),
            "ar": dict(w_c_review="راجع فرق الفرع بـ Claude Code؛ وأفشل البناء عند أي عائق.",
                       w_c_comment="الحكم كتعليق على طلب الدمج.",
                       w_c_watch="أحداث Claude Code، سطر لكل حدث.",
                       w_c_trust="علّم هذا المجلد موثوقاً.",
                       w_title="مراجعة Claude", w_pass="لا عوائق.", w_found="العوائق",
                       w_note="مراجعة آلية: ما زال إنسان يوافق.",
                       w_turns="الأدوار", w_sep="، ", w_denied="رُفض", w_cost="التكلفة"),
        }[lang],
    }

SCHEMA = {"type": "object", "properties": {"ok": {"type": "boolean"},
                                           "blockers": {"type": "array", "items": {"type": "string"}}},
          "required": ["ok", "blockers"]}

WATCH = """import readline from "node:readline";

// {w_c_watch}
const brief = (input) => input.command ?? JSON.stringify(input);
for await (const line of readline.createInterface({input: process.stdin})) {
  const event = JSON.parse(line);
  for (const block of event.message?.content ?? []) {
    if (block.type === "text") console.log(`  says   ${block.text}`);
    if (block.type === "tool_use") console.log(`  calls  ${block.name} ${brief(block.input)}`);
    if (block.type === "tool_result") {
      const content = typeof block.content === "string" ? block.content : JSON.stringify(block.content);
      console.log(`  gets   ${block.is_error ? "(error) " : ""}${content.split("\\n")[0].slice(0, 90)}`);
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
    ".claude/settings.json": json.dumps({"permissions": {
        "allow": ["Bash(node --test)"], "deny": ["Bash(git push:*)"]}}, indent=2) + "\n",
    ".claude/settings.local.json": json.dumps({"permissions": {"allow": ["Bash(git push:*)"]}}, indent=2) + "\n",
    ".gitignore": ".claude/settings.local.json\nreview.json\n",
    "src/menu.mjs": "export const VAT_RATE = 0.14;\nexport const PRICES = {latte: 45, croissant: 30};\n"
                    "export const priceOf = (name) => PRICES[name];\n",
    "src/receipt.mjs": "import {priceOf} from \"./menu.mjs\";\n\nexport function receipt(items) {\n"
                       "  const lines = items.map(({name, qty}) => ({name, qty, amount: priceOf(name) * qty}));\n"
                       "  const total = lines.reduce((sum, line) => sum + line.amount, 0);\n"
                       "  return {lines, total};\n}\n",
    "review/schema.json": json.dumps(SCHEMA, indent=2) + "\n",
    # The branch under review, in two steps: the VAT change of Chapter 7, then its fix.
    "changes/receipt-vat.mjs": RECEIPT,
    "changes/receipt-rounded.mjs": RECEIPT.replace("total: subtotal + vat", FIXED),
    "ci/review.sh": """#!/bin/sh
# {w_c_review}
set -e
git diff origin/main...HEAD > /tmp/branch.diff 2>/dev/null || git diff main...HEAD > /tmp/branch.diff
claude -p "{w_review}" < /tmp/branch.diff \\
  --model claude-opus-5-5 --tools "" --max-budget-usd 0.50 --no-session-persistence \\
  --output-format json --json-schema "$(cat review/schema.json)" > review.json
node -e '
  const r = JSON.parse(require("fs").readFileSync("review.json", "utf8"));
  const v = r.structured_output;
  console.log(JSON.stringify(v), `($${r.total_cost_usd.toFixed(4)})`);
  process.exit(r.subtype === "success" && v.ok ? 0 : 1);
'
""",
    ".github/workflows/claude-review.yml": """name: Claude review
on:
  pull_request:
permissions:
  contents: read
jobs:
  review:
    runs-on: ubuntu-latest
    timeout-minutes: 10
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - uses: actions/setup-node@v4
        with:
          node-version: 22
      - run: npm install -g @anthropic-ai/claude-code
      - run: sh ci/review.sh
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
""",
    "comment.mjs": """import fs from "node:fs";

// {w_c_comment}
const {structured_output: v, total_cost_usd: cost} = JSON.parse(fs.readFileSync("review.json", "utf8"));
const lines = [`### {w_title}`, ""];
if (v.ok) lines.push("{w_pass}");
else lines.push("**{w_found}:**", ...v.blockers.map((b) => `- ${b}`));
lines.push("", `_{w_note} ($${cost.toFixed(2)})_`);
console.log(lines.join("\\n"));
""",
    "trust.mjs": """import fs from "node:fs";
import os from "node:os";
import path from "node:path";

// {w_c_trust}
const file = path.join(os.homedir(), ".claude.json");
const config = fs.existsSync(file) ? JSON.parse(fs.readFileSync(file, "utf8")) : {};
config.projects ??= {};
config.projects[process.cwd()] = {...config.projects[process.cwd()], hasTrustDialogAccepted: true};
fs.writeFileSync(file, JSON.stringify(config, null, 2));
""",
    "watch.mjs": WATCH,
    "workflow.py": """import yaml

# The workflow parses, and its steps are what the chapter says they are.
flow = yaml.safe_load(open(".github/workflows/claude-review.yml"))
job = flow["jobs"]["review"]
print("on:", list(flow[True]), "| permissions:", flow["permissions"], "| timeout:", job["timeout-minutes"])
for step in job["steps"]:
    print(" -", step.get("uses") or step.get("run"), "(secret)" if "env" in step else "")
""",
}

CLAUDE = "claude -p \"{prompt}\" --model claude-opus-5-5 --no-session-persistence"
STREAM = " --output-format stream-json --verbose | node watch.mjs"

RUNS = [
    ("setup.sh", "git init -q -b main && git add -A && git commit -qm \"chore: start\" && git switch -q -c feat/vat"
     " && cp changes/receipt-vat.mjs src/receipt.mjs && git commit -qam \"feat(receipt): add 14% VAT\""
     " && git log --oneline main..HEAD"),
    ("settings.sh", "cat .claude/settings.json .claude/settings.local.json"),
    ("deny.sh", "node trust.mjs && " + CLAUDE.format(prompt="{w_p_push}") + STREAM),
    ("ci-fail.sh", "sh ci/review.sh; echo \"exit $?\""),
    ("projects/comment.sh", "node comment.mjs"),
    ("ci-pass.sh", "cp changes/receipt-rounded.mjs src/receipt.mjs && git commit -qam \"fix(receipt): round the total\""
     " && sh ci/review.sh; echo \"exit $?\""),
    ("projects/workflow.sh", "python3 workflow.py"),
]


def main():
    chapter(HERE, T, FILES, RUNS)


if __name__ == "__main__":
    main()
