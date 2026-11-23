"""Writes and runs the examples of Book 7, chapter "Reading and Explaining Unfamiliar Code", in English and Arabic:
a small legacy project with cryptic names; the model maps it, explains its central function, predicts its
results (checked by running the real code), and finds where a rule lives (checked with a search). Then a
one-line summary per file, a predict-and-run checker, and a glossary whose every term is checked in the code.
Run: python3 make.py   (needs Node 22 and the book's model; B7_LANG=en runs one edition)
"""
import sys
from pathlib import Path

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE.parent))
from kit import chapter  # noqa: E402

T = {
    "en": dict(
        w_map="This is a project I have never seen. From the files below, say in one line each what every file "
              "does, then which file runs first. Be brief.",
        w_explain="Explain in plain words what calc does, as a list of rules a café manager would understand. "
                  "Do not explain the syntax.",
        w_predict="For each of these calls, what does calc return? Reply with a JSON array of numbers only, in order.",
        w_where="In this project, where is it decided that VIP customers pay less, and by how much? Name the file "
                "and quote the line.",
        w_summary="Describe this file in one line, for a developer new to the project.",
        w_glossary="List the business terms this code uses (customer types, prices, discounts, limits), each with "
                   "the exact word or value as it appears in the code and its meaning. Reply as JSON: "
                   "[{\\\"term\\\": ..., \\\"inCode\\\": ..., \\\"meaning\\\": ...}]",
        w_c_files="Every file of the project, with its name, as a newcomer would open them.",
        w_c_claims="An explanation is a set of claims. Turn them into predictions, and run the real code.",
        w_c_where="An answer about where something is can be checked in a second: search for it.",
        w_c_each="One request per file, so each summary sees only its file.",
        w_c_glossary="Every term the model names must appear in the code, exactly as quoted.",
        w_chk1="Here are the rules of a function calc:",
        w_chk2="Using only these rules, what does each call return? Reply with a JSON array of numbers only.",
        w_vague="It adds up the order and gives discounts to big orders and VIP customers.",
        w_exact1="Sum price times quantity over the lines. If d is true and the sum is above 20000, ",
        w_exact2="subtract 10% rounded down. Then if c is exactly VIP, subtract 500. Never below 0.",
        w_c_check="Check an explanation by asking it, not the code, for the results.",
    ),
    "ar": dict(
        w_map="هذا مشروع لم أره من قبل. من الملفات أدناه، قل في سطر واحد لكل ملف ماذا يفعل، ثم أي ملف يعمل أولاً. "
              "باختصار.",
        w_explain="اشرح بكلمات بسيطة ماذا تفعل calc، كقائمة قواعد يفهمها مدير مقهى. لا تشرح الصياغة البرمجية.",
        w_predict="لكل استدعاء من هذه، ماذا تعيد calc؟ أجب بمصفوفة JSON من الأرقام فقط، بالترتيب.",
        w_where="في هذا المشروع، أين يتقرر أن عملاء VIP يدفعون أقل، وبكم؟ سمِّ الملف واقتبس السطر.",
        w_summary="صف هذا الملف في سطر واحد، لمطور جديد على المشروع.",
        w_glossary="اسرد مصطلحات العمل التي يستخدمها هذا الكود (أنواع العملاء، والأسعار، والخصومات، والحدود)، "
                   "كلٌّ مع الكلمة أو القيمة كما تظهر في الكود بالضبط ومعناها. أجب بـ JSON: "
                   "[{\\\"term\\\": ..., \\\"inCode\\\": ..., \\\"meaning\\\": ...}]",
        w_c_files="كل ملفات المشروع، بأسمائها، كما يفتحها قادم جديد.",
        w_c_claims="الشرح مجموعة ادعاءات. حوّلها إلى تنبؤات، وشغّل الكود الحقيقي.",
        w_c_where="الجواب عن مكان شيء يُتحقق منه في ثانية: ابحث عنه.",
        w_c_each="طلب لكل ملف، فلا يرى كل ملخص إلا ملفه.",
        w_c_glossary="كل مصطلح يسميه النموذج يجب أن يظهر في الكود، كما اقتُبس بالضبط.",
        w_chk1="هذه قواعد دالة اسمها calc:",
        w_chk2="باستخدام هذه القواعد وحدها، ماذا يعيد كل استدعاء؟ أجب بمصفوفة JSON من الأرقام فقط.",
        w_vague="تجمع الطلب وتعطي خصومات للطلبات الكبيرة ولعملاء VIP.",
        w_exact1="اجمع السعر مضروباً في الكمية لكل الأسطر. وإن كان d صحيحاً والمجموع أكبر من 20000، ",
        w_exact2="فاطرح 10% مقرّبة للأسفل. ثم إن كان c هو VIP بالضبط، فاطرح 500. ولا تنزل تحت 0.",
        w_c_check="تحقق من الشرح بأن تسأله هو، لا الكود، عن النتائج.",
    ),
}

ASK = """import fs from "node:fs";
import path from "node:path";
import {LlamaChatSession} from "node-llama-cpp";
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

export {model};

// Every file of a folder as "--- path" followed by its text.
export function readProject(folder) {
  return fs
    .readdirSync(folder, {recursive: true})
    .map((name) => path.join(folder, name))
    .filter((file) => fs.statSync(file).isFile())
    .sort()
    .map((file) => `--- ${file}\\n${fs.readFileSync(file, "utf8")}`)
    .join("\\n");
}
"""

LEGACY = {
    "legacy/package.json": '{"name": "orders-nightly", "version": "0.3.1"}\n',
    "legacy/index.js": """// nightly job
var store = require("./lib/store");
var report = require("./lib/report");

store.load("data/orders.json", function (err, orders) {
  if (err) return console.log("ERR " + err);
  console.log(report.make(orders, true));
});
""",
    "legacy/lib/store.js": """var fs = require("fs");

function load(f, cb) {
  fs.readFile(f, "utf8", function (err, txt) {
    if (err) return cb(err);
    try {
      cb(null, JSON.parse(txt));
    } catch (e) {
      cb(e);
    }
  });
}

module.exports = {load: load};
""",
    "legacy/lib/calc.js": """// do not touch - MK 2019
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
""",
    "legacy/lib/report.js": """var calc = require("./calc").calc;

function make(orders, d) {
  var sum = 0;
  var lines = orders.map(function (o) {
    var t = calc(o, d);
    sum += t;
    return o.id + " " + (t / 100).toFixed(2);
  });
  return lines.join("\\n") + "\\nTOTAL " + (sum / 100).toFixed(2);
}

module.exports = {make: make};
""",
    "legacy/data/orders.json": """[
  {"id": "A1", "c": "VIP", "l": [{"p": 4500, "q": 2}]},
  {"id": "A2", "c": "STD", "l": [{"p": 2500, "q": 10}]},
  {"id": "A3", "c": "VIP", "l": [{"p": 300, "q": 1}]}
]
""",
}

CALLS = """const calls = [
  [{c: "STD", l: [{p: 4500, q: 2}]}, true],
  [{c: "STD", l: [{p: 2500, q: 10}]}, true],
  [{c: "STD", l: [{p: 2500, q: 10}]}, false],
  [{c: "VIP", l: [{p: 300, q: 1}]}, true],
  [{c: "STD", l: [{p: 10000, q: 2}]}, true],
  [{c: "vip", l: [{p: 4500, q: 2}]}, true],
];"""

FILES = {
    "lib/ask.mjs": ASK,
    **LEGACY,
    "map.mjs": """import {ask, readProject} from "./lib/ask.mjs";

// {w_c_files}
const project = readProject("legacy");
console.log(await ask(`{w_map}\\n\\n${project}`));
""",
    "explain.mjs": """import fs from "node:fs";
import {ask} from "./lib/ask.mjs";

const code = fs.readFileSync("legacy/lib/calc.js", "utf8");
console.log(await ask(`{w_explain}\\n\\n${code}`));
""",
    "predict.mjs": """import fs from "node:fs";
import {createRequire} from "node:module";
import {ask, model} from "./lib/ask.mjs";

const require = createRequire(import.meta.url);
const {calc} = require("./legacy/lib/calc.js");
const code = fs.readFileSync("legacy/lib/calc.js", "utf8");

""" + CALLS + """

// {w_c_claims}
const written = calls.map(([o, d]) => `calc(${JSON.stringify(o)}, ${d})`).join("\\n");
// The answer can only be an array of numbers (Chapter 3).
const numbers = await model.llama.createGrammarForJsonSchema({
  type: "array",
  items: {type: "number"},
});
const prompt = `${code}\\n\\n{w_predict}\\n${written}`;
const predicted = JSON.parse(await ask(prompt, {grammar: numbers}));
let right = 0;
calls.forEach(([o, d], i) => {
  const actual = calc(o, d);
  right += predicted[i] === actual ? 1 : 0;
  const mark = predicted[i] === actual ? "same " : "WRONG";
  console.log(`${mark} predicted ${String(predicted[i]).padStart(6)}  actual ${String(actual).padStart(6)}`);
});
console.log(`${right} of ${calls.length} predictions right`);
""",
    "where.mjs": """import {execSync} from "node:child_process";
import {ask, readProject} from "./lib/ask.mjs";

console.log(await ask(`{w_where}\\n\\n${readProject("legacy")}`));

// {w_c_where}
console.log("--- grep -rn VIP legacy/lib");
console.log(execSync("grep -rn VIP legacy/lib", {encoding: "utf8"}).trim());
""",
    # Projects
    "summary.mjs": """import fs from "node:fs";
import path from "node:path";
import {ask} from "./lib/ask.mjs";

// {w_c_each}
const folder = process.argv[2];
for (const name of fs.readdirSync(folder, {recursive: true}).sort()) {
  const file = path.join(folder, name);
  if (fs.statSync(file).isFile() && file.endsWith(".js")) {
    const text = fs.readFileSync(file, "utf8");
    const line = await ask(`{w_summary}\\n\\n${text}`, {maxTokens: 60});
    console.log(`${file}: ${line.split("\\n")[0]}`);
  }
}
""",
    "checker.mjs": """import {createRequire} from "node:module";
import {ask, model} from "./lib/ask.mjs";

const require = createRequire(import.meta.url);
const {calc} = require("./legacy/lib/calc.js");
const numbers = await model.llama.createGrammarForJsonSchema({
  type: "array",
  items: {type: "number"},
});

// {w_c_check}
export async function checkExplanation(explanation, calls) {
  const written = calls.map(([o, d]) => `calc(${JSON.stringify(o)}, ${d})`);
  const prompt =
    `{w_chk1}\\n${explanation}\\n\\n` +
    `{w_chk2}\\n${written.join("\\n")}`;
  const predicted = JSON.parse(await ask(prompt, {grammar: numbers}));
  return calls.map(([o, d], i) => [predicted[i], calc(o, d)]);
}

""" + CALLS + """

const explanations = {
  vague: "{w_vague}",
  exact: "{w_exact1}" + "{w_exact2}",
};
for (const [name, text] of Object.entries(explanations)) {
  const pairs = await checkExplanation(text, calls);
  const right = pairs.filter(([p, a]) => p === a).length;
  console.log(`${name}: ${right} of ${calls.length}  ${JSON.stringify(pairs.map(([p]) => p))}`);
}
console.log(`actual: ${JSON.stringify(calls.map(([o, d]) => calc(o, d)))}`);
""",
    "glossary.mjs": """import {ask, model, readProject} from "./lib/ask.mjs";

const project = readProject("legacy/lib") + readProject("legacy/data");
const text = {type: "string"};
const grammar = await model.llama.createGrammarForJsonSchema({
  type: "array",
  items: {type: "object", properties: {term: text, inCode: text, meaning: text}},
  maxItems: 8,
});
const answer = await ask(`{w_glossary}\\n\\n${project}`, {maxTokens: 1200, grammar});
const terms = JSON.parse(answer);

// {w_c_glossary}
for (const {term, inCode, meaning} of terms) {
  const found = project.includes(String(inCode));
  console.log(`${found ? "found  " : "MISSING"} ${String(inCode).padEnd(10)} ${term}: ${meaning}`);
}
""",
}

RUNS = [
    ("run.sh", "cd legacy && node index.js"),
    ("map.sh", "node map.mjs"),
    ("explain.sh", "node explain.mjs"),
    ("predict.sh", "node predict.mjs"),
    ("where.sh", "node where.mjs"),
    ("projects/summary.sh", "node summary.mjs legacy"),
    ("projects/checker.sh", "node checker.mjs"),
    ("projects/glossary.sh", "node glossary.mjs"),
]


def main():
    chapter(HERE, T, FILES, RUNS)


if __name__ == "__main__":
    main()
