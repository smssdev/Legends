"""Writes and runs the examples of Book 7, chapter "Tests, Refactoring and Code Review", in English and Arabic:
tests written by the model, run on the real code and on mutants (copies with one planted bug each); a refactor
checked against the original on 500 random inputs; and a review of a diff with three planted problems.
Then edge cases run on the real function, a review with severities scored for misses and false alarms, and a
loop that shows the model the mutants its tests missed.
Run: python3 make.py   (needs Node 22 and the book's model; B7_LANG=en runs one edition)
"""
import sys
from pathlib import Path

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE.parent))
from kit import chapter  # noqa: E402

T = {
    "en": dict(
        w_tests="Write tests for this module, importing test from node:test, assert from node:assert/strict and "
                "linePrice from ./price.mjs. Cover normal cases and every boundary. Return only the code, in one "
                "code block.",
        w_refactor="Refactor this file for readability: modern JavaScript, clear names, no var. It must behave "
                   "exactly the same for every input, and keep module.exports = {calc}. Return only the code, in "
                   "one code block.",
        w_review="Review this change as a senior developer. List every problem you find, most serious first, "
                 "one line each.",
        w_edges="List the inputs that best test the boundaries of linePrice, as JSON: unit, quantity, and why.",
        w_review_json="Review this change. Reply with JSON: a list of problems, each with severity (high, "
                      "medium or low), the line, and the problem in one sentence.",
        w_survivors="These tests pass, but they also pass on each of these broken versions of the module, so "
                    "they miss real bugs. Add tests that fail on the broken versions and pass on the real one. "
                    "Return the complete test file, in one code block.",
        w_c_real="First, the tests must pass on the real code: a failure here is a wrong test.",
        w_c_mutants="Then on each mutant: a good test suite fails on every one of them.",
        w_c_diff="500 random orders, including the edges: the refactor must give the same total for every one.",
        w_c_planted="Three problems were planted in the diff; check which the review mentions.",
        w_c_edges="Run each edge case on the real function and show the result.",
        w_c_severity="Score the review: planted problems found, and anything else it reported.",
        w_c_loop="Show the model the mutants its tests missed, and score the new tests.",
        w_fix_tests="Some of these tests fail on the real module, so they are wrong. Fix the expected values "
                    "(not the module). Return the complete test file, in one code block.",
        w_c_wrong="A test that fails on the real code is a wrong test: send the failures back once.",
    ),
    "ar": dict(
        w_tests="اكتب اختبارات لهذه الوحدة، مستورداً test من node:test وassert من node:assert/strict وlinePrice من "
                "./price.mjs. غطِّ الحالات العادية وكل حد. أعِد الكود فقط، في كتلة كود واحدة.",
        w_refactor="أعد هيكلة هذا الملف ليكون أسهل قراءة: JavaScript حديثة، وأسماء واضحة، وبلا var. ويجب أن "
                   "يتصرف بالضبط كما هو لكل مدخل، وأن يُبقي module.exports = {calc}. أعِد الكود فقط، في كتلة كود "
                   "واحدة.",
        w_review="راجع هذا التغيير كمطور خبير. اسرد كل مشكلة تجدها، الأخطر أولاً، في سطر لكل منها.",
        w_edges="اسرد المدخلات التي تختبر حدود linePrice أفضل اختبار، بـ JSON: unit وquantity وwhy.",
        w_review_json="راجع هذا التغيير. أجب بـ JSON: قائمة مشكلات، لكل منها severity (high أو medium أو low)، "
                      "والسطر، والمشكلة في جملة واحدة.",
        w_survivors="هذه الاختبارات تنجح، لكنها تنجح أيضاً على كل نسخة معطوبة من هذه النسخ من الوحدة، فهي "
                    "تفوّت أخطاء حقيقية. أضف اختبارات تفشل على النسخ المعطوبة وتنجح على الحقيقية. "
                    "أعِد ملف الاختبارات كاملاً، في كتلة كود واحدة.",
        w_c_real="أولاً، يجب أن تنجح الاختبارات على الكود الحقيقي: الفشل هنا اختبار خاطئ.",
        w_c_mutants="ثم على كل نسخة متحوّرة: مجموعة الاختبارات الجيدة تفشل على كل واحدة منها.",
        w_c_diff="500 طلب عشوائي، ومعها الحدود: يجب أن تعطي إعادة الهيكلة المجموع نفسه لكل واحد.",
        w_c_planted="زُرعت ثلاث مشكلات في الفرق؛ تحقق أيها تذكر المراجعة.",
        w_c_edges="شغّل كل حالة حدّية على الدالة الحقيقية واعرض النتيجة.",
        w_c_severity="قيّم المراجعة: المشكلات المزروعة التي وجدتها، وكل ما ذكرته غيرها.",
        w_c_loop="أرِ النموذج النسخ المتحوّرة التي فاتت اختباراته، وقيّم الاختبارات الجديدة.",
        w_fix_tests="بعض هذه الاختبارات يفشل على الوحدة الحقيقية، فهي خاطئة. أصلح القيم المتوقعة "
                    "(لا الوحدة). أعِد ملف الاختبارات كاملاً، في كتلة كود واحدة.",
        w_c_wrong="الاختبار الذي يفشل على الكود الحقيقي اختبار خاطئ: أرسل الفشل مرة واحدة.",
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
    maxTokens: options.maxTokens ?? 900,
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

MUTANTS = """import fs from "node:fs";
import {execFileSync} from "node:child_process";

// Each mutant is the real module with one small change: a planted bug.
export const MUTANTS = [
  [">= 10", "> 10"],
  ["Math.min(", "Math.max("],
  ["full / 10", "full / 5"],
  ["quantity < 1", "quantity < 0"],
  ["Math.floor(", "Math.round("],
];

// Runs a test file next to a given price.mjs; "" when every test passes,
// otherwise the failing tests with their expected and actual values.
export function failures(tests, source, dir) {
  fs.mkdirSync(dir, {recursive: true});
  fs.writeFileSync(`${dir}/price.mjs`, source);
  fs.writeFileSync(`${dir}/price.test.mjs`, tests);
  try {
    const output = execFileSync("node", ["--test", "--test-reporter=tap", `${dir}/price.test.mjs`], {
      encoding: "utf8",
    });
    // A file with no tests passes too: that is not a passing test suite.
    return /^# tests 0$/m.test(output) ? "no tests ran" : "";
  } catch (error) {
    const lines = `${error.stdout}`.split("\\n");
    return lines
      .filter((line) => /^\\s*(not ok|expected:|actual:)|^# \\w*Error/.test(line))
      .map((line) => line.trim())
      .slice(0, 20)
      .join("\\n") || "the test file does not run";
  }
}

// The code block of an answer that contains tests (an answer may also quote the module).
export function testsOf(answer) {
  const blocks = [...answer.matchAll(/```(?:\\w+)?\\n([\\s\\S]*?)```/g)].map((m) => m[1]);
  return blocks.find((block) => /\\btest\\(/.test(block)) ?? null;
}

export function passes(tests, source, dir) {
  return failures(tests, source, dir) === "";
}

// How many mutants the tests catch, and which survive. Tests that fail on the
// real code would "catch" every mutant, so they score nothing.
export function score(tests, source) {
  if (!passes(tests, source, "mutants/real")) {
    return {killed: 0, survivors: MUTANTS};
  }
  const survivors = MUTANTS.filter(([from, to], i) => {
    return passes(tests, source.replace(from, to), `mutants/m${i + 1}`);
  });
  return {killed: MUTANTS.length - survivors.length, survivors};
}
"""

PRICE = """// Price of an order line in piastres: unit price times quantity,
// 10% off from the 10th cup, and never more than 5000 off.
export function linePrice(unit, quantity) {
  if (quantity < 1) {
    throw new RangeError("quantity must be at least 1");
  }
  const full = unit * quantity;
  const off = quantity >= 10 ? Math.min(Math.floor(full / 10), 5000) : 0;
  return full - off;
}
"""

CALC = """// do not touch - MK 2019
function calc(o, d) {
  var t = 0;
  for (var i = 0; i < o.l.length; i++) {
    var x = o.l[i];
    t += x.p * x.q;
  }
  if (d && t > 20000) t = t - Math.floor(t * 0.1);
  if (o.c == "VIP") t = t - 500;
  return t < 0 ? 0 : t;
}

module.exports = {calc: calc};
"""

DIFF = """--- a/src/orders.mjs
+++ b/src/orders.mjs
@@ -10,3 +10,11 @@ export async function loadOrder(db, id) {
   return db.get("orders", id);
 }
+
+export async function saveOrder(db, order) {
+  console.log("saving", order.id, "with", process.env.DB_PASSWORD);
+  for (let i = 0; i <= order.items.length; i++) {
+    db.insert("items", order.items[i]);
+  }
+  await db.commit();
+  return order.id;
+}
"""

FILES = {
    "lib/ask.mjs": ASK,
    "lib/mutants.mjs": MUTANTS,
    "price.mjs": PRICE,
    "legacy/calc.js": CALC,
    "legacy/package.json": '{"type": "commonjs"}\n',
    "changes/save-order.diff": DIFF,
    "tests.mjs": """import fs from "node:fs";
import {ask} from "./lib/ask.mjs";
import {MUTANTS, failures, score, testsOf} from "./lib/mutants.mjs";

const source = fs.readFileSync("price.mjs", "utf8");
let tests = testsOf(await ask(`{w_tests}\\n\\n${source}`)) ?? "";
console.log(`tests written: ${tests.match(/\\btest\\(|\\bit\\(/g)?.length ?? 0}`);

// {w_c_real}
const failed = failures(tests, source, "mutants/real");
console.log(`on the real code: ${failed ? `FAIL\\n${failed}` : "pass"}`);

// {w_c_wrong}
if (failed) {
  const request = `{w_fix_tests}\\n\\n${source}\\n\\n${tests}\\n\\n${failed}`;
  tests = testsOf(await ask(request, {maxTokens: 1400})) ?? tests;
  const again = failures(tests, source, "mutants/real");
  console.log(`after one fix: ${again ? `FAIL\\n${again}` : "pass"}`);
}
fs.writeFileSync("price.test.mjs", tests);

// {w_c_mutants}
const {killed, survivors} = score(tests, source);
console.log(`mutants caught: ${killed} of ${MUTANTS.length}`);
for (const [from, to] of survivors) {
  console.log(`  survived: ${from}  ->  ${to}`);
}
""",
    "refactor.mjs": """import fs from "node:fs";
import {createRequire} from "node:module";
import {ask, codeOf} from "./lib/ask.mjs";

const require = createRequire(import.meta.url);
const original = fs.readFileSync("legacy/calc.js", "utf8");
const code = codeOf(await ask(`{w_refactor}\\n\\n${original}`)) ?? "";
fs.writeFileSync("legacy/calc2.js", code);
console.log(code);

// {w_c_diff}
const before = require("./legacy/calc.js").calc;
let after;
try {
  after = require("./legacy/calc2.js").calc;
} catch (error) {
  console.log(`--- the refactor does not load: ${error.message.split("\\n")[0]}`);
  process.exit(0);
}
let seed = 7;
const random = (n) => ((seed = (seed * 1103515245 + 12345) % 2147483648) % n);
const types = ["VIP", "vip", "STD"];
let differ = 0;
let example = "";
for (let i = 0; i < 500; i++) {
  const lines = Array.from({length: 1 + random(3)}, () => ({p: 100 * random(80), q: 1 + random(9)}));
  const order = {c: types[random(3)], l: i < 3 ? [{p: 10000, q: 2}] : lines};
  const d = random(2) === 1;
  const [x, y] = [before(order, d), after(order, d)];
  if (x !== y) {
    differ++;
    example ||= `${JSON.stringify(order)}, ${d}: before ${x}, after ${y}`;
  }
}
console.log(`--- 500 random orders: ${differ} differ`);
console.log(example || "(none)");
""",
    "review.mjs": """import fs from "node:fs";
import {ask} from "./lib/ask.mjs";

const diff = fs.readFileSync("changes/save-order.diff", "utf8");
const review = await ask(`{w_review}\\n\\n${diff}`, {maxTokens: 500});
console.log(review);

// {w_c_planted}
const planted = {
  "secret in the log": /password|secret|credential|DB_PASSWORD/i,
  "off by one (<=)": /<=|off-by-one|off by one|out of bounds|undefined item/i,
  "insert not awaited": /insert[^.]*(await|promise)|(await|promise)[^.]*insert|not awaited/i,
};
console.log("--- planted problems");
for (const [name, pattern] of Object.entries(planted)) {
  console.log(`${pattern.test(review) ? "found " : "MISSED"} ${name}`);
}
""",
    # Projects
    "edges.mjs": """import fs from "node:fs";
import {ask, model} from "./lib/ask.mjs";
import {linePrice} from "./price.mjs";

const grammar = await model.llama.createGrammarForJsonSchema({
  type: "array",
  items: {
    type: "object",
    properties: {unit: {type: "integer"}, quantity: {type: "integer"}, why: {type: "string"}},
  },
  maxItems: 8,
});
const source = fs.readFileSync("price.mjs", "utf8");
const edges = JSON.parse(await ask(`{w_edges}\\n\\n${source}`, {grammar}));

// {w_c_edges}
for (const {unit, quantity, why} of edges) {
  let result;
  try {
    result = linePrice(unit, quantity);
  } catch (error) {
    result = error.name;
  }
  console.log(`${String(unit).padStart(6)} x ${String(quantity).padEnd(4)} = ${String(result).padEnd(10)} ${why}`);
}
""",
    "severity.mjs": """import fs from "node:fs";
import {ask, model} from "./lib/ask.mjs";

const grammar = await model.llama.createGrammarForJsonSchema({
  type: "array",
  items: {
    type: "object",
    properties: {
      severity: {enum: ["high", "medium", "low"]},
      line: {type: "string"},
      problem: {type: "string"},
    },
  },
  minItems: 1,
  maxItems: 8,
});
const diff = fs.readFileSync("changes/save-order.diff", "utf8");
const problems = JSON.parse(await ask(`{w_review_json}\\n\\n${diff}`, {grammar}));

// {w_c_severity}
const planted = [
  /password|secret|credential|DB_PASSWORD/i,
  /<=|off-by-one|off by one|out of bounds|undefined/i,
  /insert[^.]*(await|promise)|(await|promise)[^.]*insert|not awaited/i,
];
const found = new Set();
for (const {severity, line, problem} of problems) {
  const hit = planted.findIndex((pattern) => pattern.test(`${line} ${problem}`));
  if (hit >= 0) {
    found.add(hit);
  }
  console.log(`${severity.padEnd(6)} ${hit >= 0 ? "planted" : "other  "} ${problem}`);
}
console.log(`--- ${found.size} of 3 planted problems, ${problems.length} reported`);
""",
    "improve.mjs": """import fs from "node:fs";
import {ask} from "./lib/ask.mjs";
import {MUTANTS, passes, score, testsOf} from "./lib/mutants.mjs";

// {w_c_loop}
const source = fs.readFileSync("price.mjs", "utf8");
const tests = fs.readFileSync("price.test.mjs", "utf8");
const first = score(tests, source);
console.log(`before: ${first.killed} of ${MUTANTS.length} caught`);
if (first.survivors.length === 0) {
  process.exit(0);
}
const broken = first.survivors
  .map(([from, to]) => `--- ${from} changed to ${to}:\\n${source.replace(from, to)}`)
  .join("\\n");
const request = `{w_survivors}\\n\\n--- price.mjs:\\n${source}\\n\\n${broken}\\n\\n--- price.test.mjs:\\n${tests}`;
const better = testsOf(await ask(request, {maxTokens: 1400})) ?? tests;
const real = passes(better, source, "mutants/real2");
const second = score(better, source);
console.log(`after:  ${second.killed} of ${MUTANTS.length} caught; on the real code: ${real ? "pass" : "FAIL"}`);
""",
}

RUNS = [
    ("tests.sh", "node tests.mjs"),
    ("refactor.sh", "node refactor.mjs"),
    ("review.sh", "node review.mjs"),
    ("projects/edges.sh", "node edges.mjs"),
    ("projects/severity.sh", "node severity.mjs"),
    ("projects/improve.sh", "node improve.mjs"),
]


def main():
    chapter(HERE, T, FILES, RUNS, made=["price.test.mjs", "legacy/calc2.js"])


if __name__ == "__main__":
    main()
