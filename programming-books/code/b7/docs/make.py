"""Writes and runs the examples of Book 7, chapter "Documentation and Commit Messages", in English and Arabic:
documentation comments whose examples are run, a README whose every option is looked up in the code, and a
commit message checked against the Conventional Commits format and used for a real commit. Then a commit
message linter, a runner for documentation examples, and a check that documentation is still true after a
change.
Run: python3 make.py   (needs Node 22, git and the book's model; B7_LANG=en runs one edition)
"""
import sys
from pathlib import Path

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE.parent))
from kit import chapter  # noqa: E402

T = {
    "en": dict(
        w_jsdoc="Write a JSDoc comment for this function: one sentence, @param and @returns for each value, and "
                "three @example lines in the form: linePrice(unit, quantity) // => result. Return only the "
                "comment, in one code block.",
        w_readme="Write the Usage section of a README for this command-line tool: how to run it, every option, "
                 "and two examples. Markdown, at most 25 lines.",
        w_commit="Write a git commit message for this change in the Conventional Commits format: type(scope): "
                 "subject of at most 72 characters, a blank line, then a short body that says why. Return only "
                 "the message.",
        w_stale="Here is a function and its documentation. Is every statement in the documentation still true "
                "of the code? Answer yes or no on the first line, then list what is wrong.",
        w_c_jsdoc="A documentation example is a claim about the code: run it.",
        w_c_options="Every option the README mentions must exist in the code.",
        w_c_format="The format is checked by code, not by eye.",
        w_c_commit="If the message passes, make the real commit with it.",
        w_c_lint="type(scope): subject, at most 72 characters, no full stop, then a blank line.",
        w_c_doctest="Run every line of the form call // => value and compare.",
        w_c_changed="The code changed after the comment was written; the examples know before the model does.",
        w_relint="Your message broke these rules. Write it again:",
    ),
    "ar": dict(
        w_jsdoc="اكتب تعليق JSDoc لهذه الدالة: جملة واحدة، و@param و@returns لكل قيمة، وثلاثة أسطر @example "
                "بالشكل: linePrice(unit, quantity) // => result. أعِد التعليق فقط، في كتلة كود واحدة.",
        w_readme="اكتب قسم الاستخدام (Usage) في README لأداة سطر الأوامر هذه: كيف تُشغَّل، وكل خيار، ومثالان. "
                 "بـ Markdown، 25 سطراً على الأكثر.",
        w_commit="اكتب رسالة حفظ git لهذا التغيير بصيغة Conventional Commits: type(scope): وموضوع من 72 حرفاً "
                 "على الأكثر، ثم سطر فارغ، ثم متن قصير يقول لماذا. أعِد الرسالة فقط.",
        w_stale="هذه دالة وتوثيقها. هل كل عبارة في التوثيق ما زالت صحيحة عن الكود؟ أجب بنعم أو لا في السطر "
                "الأول، ثم اسرد ما هو خاطئ.",
        w_c_jsdoc="مثال التوثيق ادعاء عن الكود: شغّله.",
        w_c_options="كل خيار يذكره الـ README يجب أن يكون موجوداً في الكود.",
        w_c_format="الصيغة يفحصها الكود، لا العين.",
        w_c_commit="إن نجحت الرسالة، فاحفظ بها حفظاً حقيقياً.",
        w_c_lint="type(scope): وموضوع، 72 حرفاً على الأكثر، بلا نقطة في آخره، ثم سطر فارغ.",
        w_c_doctest="شغّل كل سطر بالشكل call // => value وقارن.",
        w_c_changed="تغيّر الكود بعد كتابة التعليق؛ والأمثلة تعرف قبل النموذج.",
        w_relint="رسالتك خالفت هذه القواعد. اكتبها من جديد:",
    ),
}

ASK = """import {LlamaChatSession} from "node-llama-cpp";
import {loadModel} from "./model.mjs";

const model = await loadModel();
const context = await model.createContext({contextSize: 6144});

// One question in a fresh conversation, at temperature 0.
export async function ask(prompt, options = {}) {
  const session = new LlamaChatSession({
    contextSequence: context.getSequence(),
    autoDisposeSequence: true,
  });
  const answer = await session.prompt(prompt, {
    temperature: 0,
    maxTokens: options.maxTokens ?? 500,
  });
  session.dispose();
  return answer.trim();
}

// The first code block of an answer, or the whole answer when there is none.
export function codeOf(answer) {
  return answer.match(/```(?:\\w+)?\\n([\\s\\S]*?)```/)?.[1] ?? answer;
}
"""

DOCTEST = """// Every "name(args) // => value" line of a text, run against a module's exports.
export function docExamples(text, exports) {
  const results = [];
  for (const match of text.matchAll(/(\\w+\\([^)]*\\))\\s*\\/\\/\\s*=>\\s*(.+)$/gm)) {
    const [, call, claimed] = match;
    let actual;
    try {
      actual = Function(...Object.keys(exports), `return ${call};`)(...Object.values(exports));
    } catch (error) {
      actual = error.name;
    }
    const ok = String(actual) === claimed.trim().replace(/^["']|["']$/g, "");
    results.push({call, claimed: claimed.trim(), actual, ok});
  }
  return results;
}
"""

LINT = """// The rules of a Conventional Commits message, checked one by one.
export function lintCommit(message) {
  const [subject = "", blank, ...body] = message.split("\\n");
  const problems = [];
  if (!/^(feat|fix|docs|refactor|test|chore|perf|build|ci|style)(\\([\\w-]+\\))?!?: \\S/.test(subject)) {
    problems.push("subject is not type(scope): text");
  }
  if (subject.length > 72) {
    problems.push(`subject is ${subject.length} characters, more than 72`);
  }
  if (subject.endsWith(".")) {
    problems.push("subject ends with a full stop");
  }
  if (blank !== undefined && blank !== "") {
    problems.push("no blank line after the subject");
  }
  if (/```|\\*\\*/.test(message)) {
    problems.push("markdown in the message");
  }
  return problems;
}
"""

PRICE = """// 10% off from the 10th cup, at most 5000 off.
export function linePrice(unit, quantity) {
  if (quantity < 1) {
    throw new RangeError("quantity must be at least 1");
  }
  const full = unit * quantity;
  const off = quantity >= 10 ? Math.min(Math.floor(full / 10), 5000) : 0;
  return full - off;
}
"""

PRICE_CHANGED = """/**
 * Price of an order line in piastres.
 * @example linePrice(1000, 9) // => 9000
 * @example linePrice(1000, 10) // => 9000
 * @example linePrice(6000, 10) // => 55000
 */
export function linePrice(unit, quantity) {
  if (quantity < 1) {
    throw new RangeError("quantity must be at least 1");
  }
  const full = unit * quantity;
  const off = quantity >= 12 ? Math.min(Math.floor(full / 10), 3000) : 0;
  return full - off;
}
"""

CLI = """// Prints the day's orders. Usage: node report.mjs [--date YYYY-MM-DD] [--vip] [--json]
import {parseArgs} from "node:util";

const {values} = parseArgs({
  options: {
    date: {type: "string", default: new Date().toISOString().slice(0, 10)},
    vip: {type: "boolean", default: false},
    json: {type: "boolean", default: false},
  },
});

const orders = [
  {id: 41, date: "2026-11-20", vip: true, total: 8500},
  {id: 42, date: "2026-11-20", vip: false, total: 22500},
];
const shown = orders.filter((o) => o.date === values.date && (!values.vip || o.vip));
console.log(values.json ? JSON.stringify(shown) : shown.map((o) => `${o.id} ${o.total}`).join("\\n"));
"""

FILES = {
    "lib/ask.mjs": ASK,
    "lib/doctest.mjs": DOCTEST,
    "lib/lint.mjs": LINT,
    "price.mjs": PRICE,
    "changed/price.mjs": PRICE_CHANGED,
    "report.mjs": CLI,
    "jsdoc.mjs": """import fs from "node:fs";
import {ask, codeOf} from "./lib/ask.mjs";
import {docExamples} from "./lib/doctest.mjs";
import * as price from "./price.mjs";

const source = fs.readFileSync("price.mjs", "utf8");
const comment = codeOf(await ask(`{w_jsdoc}\\n\\n${source}`));
console.log(comment);

// {w_c_jsdoc}
console.log("--- the examples, run");
for (const {call, claimed, actual, ok} of docExamples(comment, price)) {
  console.log(`${ok ? "true " : "FALSE"} ${call} // => ${claimed}   (real: ${actual})`);
}
""",
    "readme.mjs": """import fs from "node:fs";
import {ask} from "./lib/ask.mjs";

const source = fs.readFileSync("report.mjs", "utf8");
const readme = await ask(`{w_readme}\\n\\n${source}`);
console.log(readme);

// {w_c_options}
console.log("--- options in the README");
const options = new Set(readme.match(/--[a-z][\\w-]*/g) ?? []);
for (const option of options) {
  const exists = source.includes(`${option.slice(2)}: {`);
  console.log(`${exists ? "exists " : "INVENTED"} ${option}`);
}
""",
    "commit.mjs": """import {execSync} from "node:child_process";
import fs from "node:fs";
import {ask} from "./lib/ask.mjs";
import {lintCommit} from "./lib/lint.mjs";

const git = (command) => execSync(`git ${command}`, {cwd: "repo", encoding: "utf8"}).trim();
fs.rmSync("repo", {recursive: true, force: true});
fs.mkdirSync("repo");
git("init -q -b main");
git("config user.name Bit && git config user.email bit@example.com");
fs.copyFileSync("price.mjs", "repo/price.mjs");
git("add price.mjs && git commit -q -m 'feat(price): line prices with a bulk discount'");

// The change: the cap on the discount drops from 5000 to 3000.
const changed = fs.readFileSync("price.mjs", "utf8").replaceAll("5000", "3000");
fs.writeFileSync("repo/price.mjs", changed);
git("add price.mjs");
const diff = git("diff --cached");

const clean = (text) => text.replace(/^```\\w*\\n|```$/g, "").trim();
let message = clean(await ask(`{w_commit}\\n\\n${diff}`));
console.log(message);

// {w_c_format}
let problems = lintCommit(message);
console.log(`--- lint: ${problems.length ? problems.join("; ") : "ok"}`);
if (problems.length) {
  const request = `{w_commit}\\n\\n${diff}\\n\\n{w_relint}\\n${message}\\n${problems.join("\\n")}`;
  message = clean(await ask(request));
  problems = lintCommit(message);
  console.log(`--- once more:\\n${message}\\n--- lint: ${problems.length ? problems.join("; ") : "ok"}`);
}

// {w_c_commit}
if (problems.length === 0) {
  fs.writeFileSync("repo/.message", message);
  git("commit -q -F .message");
  console.log(git("log --oneline"));
}
""",
    # Projects
    "lint.mjs": """import {lintCommit} from "./lib/lint.mjs";

// {w_c_lint}
const messages = [
  "fix(price): cap the bulk discount at 3000",
  "Fixed the price thing.",
  "feat: a much longer subject line that keeps going and going past the limit of characters",
  "docs(readme): explain --vip\\nthe body comes right after the subject",
];
for (const message of messages) {
  const problems = lintCommit(message);
  console.log(`${problems.length ? "FAIL" : "ok  "} ${message.split("\\n")[0]}`);
  for (const problem of problems) {
    console.log(`       ${problem}`);
  }
}
""",
    "doctest.mjs": """import fs from "node:fs";
import {docExamples} from "./lib/doctest.mjs";

// {w_c_doctest}
const file = process.argv[2];
const exports = await import(`./${file}`);
const results = docExamples(fs.readFileSync(file, "utf8"), exports);
for (const {call, claimed, actual, ok} of results) {
  console.log(`${ok ? "pass" : "FAIL"} ${call} // => ${claimed}${ok ? "" : `   (real: ${actual})`}`);
}
console.log(`${results.filter((r) => r.ok).length} of ${results.length} examples hold`);
""",
    "stale.mjs": """import fs from "node:fs";
import {ask} from "./lib/ask.mjs";
import {docExamples} from "./lib/doctest.mjs";

// {w_c_changed}
const source = fs.readFileSync("changed/price.mjs", "utf8");
const answer = await ask(`{w_stale}\\n\\n${source}`, {maxTokens: 300});
console.log(answer);
const exports = await import("./changed/price.mjs");
const failing = docExamples(source, exports).filter((r) => !r.ok);
console.log(`--- examples run: ${failing.length} no longer true`);
for (const {call, claimed, actual} of failing) {
  console.log(`   ${call} // => ${claimed}   (real: ${actual})`);
}
""",
}

RUNS = [
    ("jsdoc.sh", "node jsdoc.mjs"),
    ("report.sh", "node report.mjs --date 2026-11-20 && node report.mjs --date 2026-11-20 --vip --json"),
    ("readme.sh", "node readme.mjs"),
    ("commit.sh", "node commit.mjs"),
    ("projects/lint.sh", "node lint.mjs"),
    ("projects/doctest.sh", "node doctest.mjs changed/price.mjs"),
    ("projects/stale.sh", "node stale.mjs"),
]


def main():
    chapter(HERE, T, FILES, RUNS)


if __name__ == "__main__":
    main()
