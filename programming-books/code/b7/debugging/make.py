"""Writes and runs the examples of Book 7, chapter "Debugging with AI", in English and Arabic: a real crash and
its stack trace (the line the model names is checked), a wrong result without a crash (the model's fix is run
against a test), and a minimal reproduction written by the model and run to see that it fails the same way.
Then an error explainer for any command, a log triage checked by counting, and a reproduction loop.
Run: python3 make.py   (needs Node 22 and the book's model; B7_LANG=en runs one edition)
"""
import sys
from pathlib import Path

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE.parent))
from kit import chapter  # noqa: E402

T = {
    "en": dict(
        w_trace="This program crashed. Explain the error in two sentences, then name the file and line number "
                "where the bug is (not only where it crashed), as: BUG AT file:line",
        w_wrong="This function should return the three most expensive drinks, most expensive first. For the menu "
                "below it returns the wrong drinks. Give your most likely cause in one sentence, then the fixed "
                "function in one code block.",
        w_repro="From this log, write the smallest standalone Node script (ES module, no files, no network) that "
                "throws the same error. Return only the code, in one code block.",
        w_explain_err="Explain this error output to a developer in at most four lines: what failed, the likely "
                      "cause, and the first thing to check.",
        w_triage="Read this log. Reply with JSON: the first error message, and how many times each distinct "
                 "error message appears.",
        w_c_trace="Run the program, keep its error output, and give both to the model.",
        w_c_check="The model names a line; we check it against the line that really has the bug.",
        w_c_fix="Take the model's fix, run it, and compare with the right answer.",
        w_c_repro="A reproduction is only useful if it fails the same way: run it and compare the error.",
        w_c_pipe="Any command's output, piped in: node broken.mjs 2>&1 | node why.mjs",
        w_c_count="The model reads the log; the program counts the same things to check it.",
        w_c_loop="Up to three attempts; each failure is sent back with what actually happened.",
    ),
    "ar": dict(
        w_trace="انهار هذا البرنامج. اشرح الخطأ في جملتين، ثم سمِّ الملف ورقم السطر حيث الخطأ (لا حيث انهار "
                "فقط)، هكذا: BUG AT file:line",
        w_wrong="يجب أن تعيد هذه الدالة أغلى ثلاثة مشروبات، الأغلى أولاً. ولقائمة الطعام أدناه تعيد مشروبات "
                "خاطئة. أعطِ السبب الأرجح في جملة، ثم الدالة المصححة في كتلة كود واحدة.",
        w_repro="من هذا السجل، اكتب أصغر سكربت Node مستقل (وحدة ES، بلا ملفات، بلا شبكة) يرمي الخطأ نفسه. "
                "أعِد الكود فقط، في كتلة كود واحدة.",
        w_explain_err="اشرح مخرجات الخطأ هذه لمطور في أربعة أسطر على الأكثر: ما الذي فشل، والسبب المحتمل، "
                      "وأول ما يجب فحصه.",
        w_triage="اقرأ هذا السجل. أجب بـ JSON: أول رسالة خطأ، وكم مرة تظهر كل رسالة خطأ مختلفة.",
        w_c_trace="شغّل البرنامج، واحتفظ بمخرجات خطئه، وأعطِ الاثنين للنموذج.",
        w_c_check="النموذج يسمّي سطراً؛ ونتحقق منه مقابل السطر الذي فيه الخطأ فعلاً.",
        w_c_fix="خذ إصلاح النموذج، وشغّله، وقارنه بالجواب الصحيح.",
        w_c_repro="إعادة الإنتاج لا تنفع إلا إن فشلت بالطريقة نفسها: شغّلها وقارن الخطأ.",
        w_c_pipe="مخرجات أي أمر، عبر أنبوب: node broken.mjs 2>&1 | node why.mjs",
        w_c_count="النموذج يقرأ السجل؛ والبرنامج يعدّ الأشياء نفسها ليتحقق منه.",
        w_c_loop="ثلاث محاولات على الأكثر؛ وكل فشل يُرسل مع ما حدث فعلاً.",
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
    maxTokens: options.maxTokens ?? 400,
    grammar: options.grammar,
  });
  session.dispose();
  return answer.trim();
}

// The first code block of an answer, or null when there is none.
export function codeOf(answer) {
  return answer.match(/```(?:\\w+)?\\n([\\s\\S]*?)```/)?.[1] ?? null;
}

export {model};
"""

RUN = """import {spawnSync} from "node:child_process";

// Runs a Node file; returns its exit code and everything it printed.
export function run(file) {
  const result = spawnSync("node", [file], {encoding: "utf8"});
  return {code: result.status, output: `${result.stdout}${result.stderr}`};
}

// The "Name: message" of the first error in an output, anywhere on its line
// (a log line starts with a time and a level).
export function errorLine(output) {
  const found = output.match(/\\b(\\w*Error): (.*)$/m);
  return found ? `${found[1]}: ${found[2]}` : "(no error)";
}
"""

FILES = {
    "lib/ask.mjs": ASK,
    "lib/run.mjs": RUN,
    "shop/menu.mjs": """export const MENU = [
  {name: "espresso", price: 250},
  {name: "latte", price: 450},
  {name: "tea", price: 200},
  {name: "mocha", price: 1050},
  {name: "cold brew", price: 900},
];
""",
    "shop/orders.mjs": """import {MENU} from "./menu.mjs";

export function priceOf(name) {
  const drink = MENU.find((d) => d.name === name);
  return drink.price;
}

export function total(order) {
  return order.items.reduce((sum, item) => sum + priceOf(item.name) * item.count, 0);
}
""",
    "shop/report.mjs": """import {total} from "./orders.mjs";

const orders = [
  {id: 41, items: [{name: "latte", count: 2}]},
  {id: 42, items: [{name: "flat white", count: 1}]},
  {id: 43, items: [{name: "tea", count: 3}]},
];

for (const order of orders) {
  console.log(`order ${order.id}: ${total(order)}`);
}
""",
    "shop/top.mjs": """import {MENU} from "./menu.mjs";

export function topThree(menu) {
  return menu
    .map((drink) => drink.price)
    .sort()
    .reverse()
    .slice(0, 3)
    .map((price) => menu.find((drink) => drink.price === price).name);
}

console.log(topThree(MENU));
""",
    "crash.mjs": """import fs from "node:fs";
import {ask} from "./lib/ask.mjs";
import {run} from "./lib/run.mjs";

// {w_c_trace}
const {output} = run("shop/report.mjs");
const trace = output.split("\\n").filter((line) => !line.includes("node:internal"));
console.log(trace.join("\\n").trim());

const files = ["shop/report.mjs", "shop/orders.mjs", "shop/menu.mjs"]
  .map((file) => `--- ${file}\\n${fs.readFileSync(file, "utf8")}`)
  .join("\\n");
const answer = await ask(`{w_trace}\\n\\n${trace.join("\\n")}\\n\\n${files}`);
console.log(`\\n--- the model:\\n${answer}`);

// {w_c_check}
const named = answer.match(/BUG AT\\s*`?(?:file:\\s*)?([\\w/.]+):(\\d+)/);
console.log(`\\nnamed: ${named ? `${named[1]}:${named[2]}` : "(none)"}`);
console.log("the crash: shop/orders.mjs:5 (drink is undefined)");
console.log("the cause: shop/report.mjs:5 (a drink that is not on the menu)");
""",
    "wrong.mjs": """import fs from "node:fs";
import {ask} from "./lib/ask.mjs";
import {run} from "./lib/run.mjs";
import {MENU} from "./shop/menu.mjs";

const source = fs.readFileSync("shop/top.mjs", "utf8");
const menu = fs.readFileSync("shop/menu.mjs", "utf8");
const answer = await ask(`{w_wrong}\\n\\n${source}\\n${menu}`, {maxTokens: 800});
console.log(answer);

// {w_c_fix}
// The code block that defines topThree; an answer may also quote other code.
const blocks = [...answer.matchAll(/```(?:\\w+)?\\n([\\s\\S]*?)```/g)].map((m) => m[1]);
const fixed = blocks.findLast((block) => block.includes("function topThree"));
if (!fixed) {
  console.log("\\n(no fixed function in the answer)");
  process.exit(0);
}
const code = fixed.replace(/^import .*$/gm, "").replace(/^console.log.*$/gm, "");
const topThree = Function(`${code.replace("export ", "")}; return topThree;`)();
console.log("\\n--- run:");
console.log(`before: ${run("shop/top.mjs").output.trim()}`);
console.log(`fixed:  ${JSON.stringify(topThree(MENU))}`);
console.log(`right:  ${JSON.stringify(["mocha", "cold brew", "latte"])}`);
""",
    "repro.mjs": """import fs from "node:fs";
import {ask, codeOf} from "./lib/ask.mjs";
import {errorLine, run} from "./lib/run.mjs";

const log = fs.readFileSync("logs/night.log", "utf8");
const code = codeOf(await ask(`{w_repro}\\n\\n${log}`));
fs.writeFileSync("repro/attempt.mjs", code ?? "");
console.log(`--- repro/attempt.mjs\\n${code}`);

// {w_c_repro}
const wanted = errorLine(log);
const got = errorLine(run("repro/attempt.mjs").output);
console.log(`wanted: ${wanted}`);
console.log(`got:    ${got}`);
console.log(got === wanted ? "same error: a reproduction" : "different: not a reproduction yet");
""",
    "repro/.keep": "",
    "logs/night.log": """2026-11-20T02:00:01Z INFO  nightly report started
2026-11-20T02:00:01Z INFO  loaded 3 orders
2026-11-20T02:00:02Z INFO  order 41: 900
2026-11-20T02:00:02Z ERROR TypeError: Cannot read properties of undefined (reading 'price')
    at priceOf (file:///srv/shop/orders.mjs:5:16)
    at file:///srv/shop/orders.mjs:9:52
    at Array.reduce (<anonymous>)
    at total (file:///srv/shop/orders.mjs:9:22)
2026-11-20T02:00:02Z INFO  nightly report stopped
""",
    # Projects
    "why.mjs": """import {ask} from "./lib/ask.mjs";

// {w_c_pipe}
let output = "";
for await (const chunk of process.stdin) {
  output += chunk;
}
const lines = output.split("\\n").filter((line) => !line.includes("node:internal"));
console.log(await ask(`{w_explain_err}\\n\\n${lines.join("\\n")}`, {maxTokens: 200}));
""",
    "triage.mjs": """import fs from "node:fs";
import {ask, model} from "./lib/ask.mjs";

const log = fs.readFileSync("logs/week.log", "utf8");
const grammar = await model.llama.createGrammarForJsonSchema({
  type: "object",
  properties: {
    first: {type: "string"},
    counts: {
      type: "array",
      items: {type: "object", properties: {message: {type: "string"}, times: {type: "integer"}}},
    },
  },
});
const answer = JSON.parse(await ask(`{w_triage}\\n\\n${log}`, {grammar, maxTokens: 600}));

// {w_c_count}
const errors = log.split("\\n").filter((line) => line.includes(" ERROR "));
const actual = new Map();
for (const line of errors) {
  const message = line.split(" ERROR ")[1];
  actual.set(message, (actual.get(message) ?? 0) + 1);
}
console.log(`first: ${answer.first}`);
console.log(`       ${errors[0].split(" ERROR ")[1] === answer.first ? "right" : "WRONG"}`);
for (const {message, times} of answer.counts) {
  const real = actual.get(message) ?? 0;
  console.log(`${String(times).padStart(3)} said, ${String(real).padStart(3)} counted  ${message}`);
}
""",
    "logs/week.log": "".join(
        f"2026-11-{14 + i // 6:02d}T{i % 6:02d}:00:00Z {kind.strip()} {msg}\n"
        for i, (kind, msg) in enumerate(
            [("INFO ", "report started"), ("ERROR", "Error: menu.json not found"),
             ("INFO ", "report started"), ("ERROR", "TypeError: total is not a function"),
             ("INFO ", "report started"), ("ERROR", "Error: menu.json not found"),
             ("WARN ", "slow order 42"), ("ERROR", "Error: menu.json not found"),
             ("INFO ", "report started"), ("ERROR", "RangeError: people must be at least 1"),
             ("ERROR", "Error: menu.json not found"), ("INFO ", "report started"),
             ("ERROR", "TypeError: total is not a function"), ("INFO ", "report finished"),
             ("ERROR", "Error: menu.json not found"), ("INFO ", "report finished")])
    ),
    "reproloop.mjs": """import fs from "node:fs";
import {ask, codeOf} from "./lib/ask.mjs";
import {errorLine, run} from "./lib/run.mjs";

// {w_c_loop}
export async function reproduce(log, file, tries = 3) {
  const wanted = errorLine(log);
  let request = `{w_repro}\\n\\n${log}`;
  for (let attempt = 1; attempt <= tries; attempt++) {
    const code = codeOf(await ask(request));
    fs.writeFileSync(file, code ?? "");
    const got = errorLine(run(file).output);
    console.log(`attempt ${attempt}: ${got}`);
    if (got === wanted) {
      return `reproduced in ${attempt}`;
    }
    request += `\\n\\nYour script:\\n${code}\\nIt printed: ${got}\\nIt must throw: ${wanted}`;
  }
  return "not reproduced";
}

const log = `2026-11-21T02:00:02Z ERROR RangeError: Invalid array length
    at splitBill (file:///srv/shop/bill.mjs:7:10)
    at file:///srv/shop/report.mjs:12:3`;
console.log(await reproduce(log, "repro/loop.mjs"));
""",
}

RUNS = [
    ("report.sh", "node shop/report.mjs 2>&1 | grep -v node:internal", None),
    ("crash.sh", "node crash.mjs"),
    ("top.sh", "node shop/top.mjs"),
    ("wrong.sh", "node wrong.mjs"),
    ("repro.sh", "node repro.mjs"),
    ("projects/why.sh", "node shop/report.mjs 2>&1 | node why.mjs"),
    ("projects/triage.sh", "node triage.mjs"),
    ("projects/reproloop.sh", "node reproloop.mjs"),
]


def main():
    chapter(HERE, T, FILES, RUNS)


if __name__ == "__main__":
    main()
