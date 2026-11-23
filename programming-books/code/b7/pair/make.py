"""Writes and runs the examples of Book 7, chapter "Pair Programming with AI", in English and Arabic: a feature
built in small steps with the model (plan, tests, code, then the failing tests sent back), code that matches the
house style when the model sees an example, and the model explaining its own code. Then a diff explainer, tests
written by the model and checked against a correct implementation, and a fix loop that knows when to stop.
Run: python3 make.py   (needs Node 22 and the book's model)
"""
import sys
from pathlib import Path

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE.parent))
from kit import chapter  # noqa: E402

SPEC_EN = ("splitBill(total, people, tipPercent) splits a café bill. total is in piastres (an integer), people is "
           "a whole number of at least 1, tipPercent is a whole number such as 10. The tip is total * tipPercent / "
           "100, rounded to the nearest piastre. It returns an array with one integer amount per person, adding up "
           "exactly to total plus tip; when it does not divide evenly, the first people pay one piastre more. It "
           "throws a RangeError if people is less than 1.")
SPEC_AR = ("الدالة splitBill(total, people, tipPercent) تقسم فاتورة مقهى. total بالقروش (عدد صحيح)، وpeople عدد صحيح "
           "لا يقل عن 1، وtipPercent عدد صحيح مثل 10. البقشيش هو total * tipPercent / 100، مقرّباً لأقرب قرش. وتعيد "
           "مصفوفة فيها مبلغ صحيح لكل شخص، مجموعها بالضبط total مع البقشيش؛ وحين لا تنقسم بالتساوي، يدفع الأوائل "
           "قرشاً زائداً. وترمي RangeError إن كان people أقل من 1.")

T = {
    "en": dict(
        w_spec=SPEC_EN,
        w_plan="Before writing any code, list in at most five short lines the steps you would take to implement this:",
        w_tests="Write tests for this function with node:test and node:assert/strict, importing splitBill from "
                "./bill.mjs. Cover the normal case, uneven division, a tip that needs rounding, and the error. "
                "Return only the code, in one code block.",
        w_code="Write bill.mjs, exporting splitBill. Return only the code, in one code block.",
        w_fix="The tests failed with this output. Fix bill.mjs (not the tests). Return only the code, in one code "
              "block.",
        w_task="Write a function that loads the menu from menu.json.",
        w_house="This is a file from our project. Write the new function in the same style.",
        w_explain="Explain this code line by line, then say which inputs could make it fail.",
        w_diff_q="Explain this change for a reviewer: what it does, and what could go wrong. At most six lines.",
        w_c_spec="The specification, written once and used for every step.",
        w_c_steps="Small steps: a plan, then tests, then code. Each step is a fresh request with what it needs.",
        w_c_loop="Run the real tests; if they fail, send the output back, at most three times.",
        w_c_style="The same task without and with one file of the project to copy the style from.",
        w_c_own="Ask the model to explain code before you accept it, including how it could fail.",
        w_c_diff="A diff from a real change, and a request for the reviewer's summary.",
        w_c_check="The model writes the tests; a correct implementation checks them.",
        w_c_stop="Stop when the tests pass, when the rounds run out, or when the same failure comes back.",
    ),
    "ar": dict(
        w_spec=SPEC_AR,
        w_plan="قبل كتابة أي كود، اسرد في خمسة أسطر قصيرة على الأكثر الخطوات التي ستتبعها لتنفيذ هذا:",
        w_tests="اكتب اختبارات لهذه الدالة بـ node:test وnode:assert/strict، مستورداً splitBill من ./bill.mjs. "
                "غطِّ الحالة العادية، والقسمة غير المتساوية، وبقشيشاً يحتاج تقريباً، والخطأ. "
                "أعِد الكود فقط، في كتلة كود واحدة.",
        w_code="اكتب bill.mjs، مصدّراً splitBill. أعِد الكود فقط، في كتلة كود واحدة.",
        w_fix="فشلت الاختبارات بهذه المخرجات. أصلح bill.mjs (لا الاختبارات). أعِد الكود فقط، في كتلة كود واحدة.",
        w_task="اكتب دالة تحمّل القائمة من menu.json.",
        w_house="هذا ملف من مشروعنا. اكتب الدالة الجديدة بالأسلوب نفسه.",
        w_explain="اشرح هذا الكود سطراً سطراً، ثم قل أي المدخلات قد تجعله يفشل.",
        w_diff_q="اشرح هذا التغيير لمراجع: ماذا يفعل، وما الذي قد يسوء. ستة أسطر على الأكثر.",
        w_c_spec="المواصفات، تُكتب مرة وتُستخدم في كل خطوة.",
        w_c_steps="خطوات صغيرة: خطة، ثم اختبارات، ثم كود. وكل خطوة طلب جديد فيه ما تحتاجه.",
        w_c_loop="شغّل الاختبارات الحقيقية؛ وإن فشلت، أرسل المخرجات من جديد، ثلاث مرات على الأكثر.",
        w_c_style="المهمة نفسها دون ملف من المشروع ومعه، لينسخ أسلوبه.",
        w_c_own="اطلب من النموذج شرح الكود قبل أن تقبله، ومنه كيف قد يفشل.",
        w_c_diff="فرق من تغيير حقيقي، وطلب ملخص للمراجع.",
        w_c_check="النموذج يكتب الاختبارات؛ وتنفيذ صحيح يتحقق منها.",
        w_c_stop="توقف حين تنجح الاختبارات، أو تنفد الجولات، أو يعود الفشل نفسه.",
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
    systemPrompt: options.system,
  });
  const answer = await session.prompt(prompt, {
    temperature: 0,
    maxTokens: options.maxTokens ?? 700,
  });
  session.dispose();
  return answer.trim();
}

// The first code block of an answer.
export function codeOf(answer) {
  return answer.match(/```(?:\\w+)?\\n([\\s\\S]*?)```/)?.[1] ?? answer;
}
"""

TESTS = """import {execFileSync} from "node:child_process";

// Runs node's test runner on one file, with the TAP reporter.
export function runTests(file) {
  try {
    const output = execFileSync("node", ["--test", "--test-reporter=tap", file], {
      encoding: "utf8",
    });
    return {ok: true, summary: summarize(output), output};
  } catch (error) {
    const output = `${error.stdout}${error.stderr}`;
    return {ok: false, summary: summarize(output), output};
  }
}

function summarize(output) {
  const count = (name) => output.match(new RegExp(`^# ${name} (\\\\d+)`, "m"))?.[1];
  return `${count("pass")} passed, ${count("fail")} failed`;
}

// The names of the failing tests and their first error line.
export function failures(output) {
  return output
    .split("\\n")
    .filter((line) => /^\\s*not ok|^\\s*(error|expected|actual):/.test(line))
    .slice(0, 12)
    .join("\\n");
}
"""

HOUSE = """import {readFile} from "node:fs/promises";

// Loads the list of tables from tables.json; an empty list if the file is missing.
export async function loadTables(path = "tables.json") {
  try {
    return JSON.parse(await readFile(path, "utf8"));
  } catch (error) {
    if (error.code === "ENOENT") {
      return [];
    }
    throw error;
  }
}
"""

FILES = {
    "lib/ask.mjs": ASK,
    "lib/tests.mjs": TESTS,
    "house/tables.mjs": HOUSE,
    "pair.mjs": """import fs from "node:fs";
import {ask, codeOf} from "./lib/ask.mjs";
import {failures, runTests} from "./lib/tests.mjs";

// {w_c_spec}
const spec = "{w_spec}";

// {w_c_steps}
console.log("== plan\\n" + (await ask(`{w_plan}\\n\\n${spec}`)));

const tests = codeOf(await ask(`${spec}\\n\\n{w_tests}`));
fs.writeFileSync("bill/bill.test.mjs", tests);
const count = tests.match(/\\btest\\(|\\bit\\(/g)?.length ?? 0;
console.log(`== tests: bill/bill.test.mjs, ${count} tests`);

let code = codeOf(await ask(`${spec}\\n\\n{w_code}`));

// {w_c_loop}
for (let round = 1; ; round++) {
  fs.writeFileSync("bill/bill.mjs", code);
  const result = runTests("bill/bill.test.mjs");
  console.log(`== round ${round}: ${result.summary}`);
  if (result.ok || round === 4) {
    break;
  }
  console.log(failures(result.output));
  const request = `${spec}\\n\\nbill.mjs:\\n${code}\\n\\n{w_fix}\\n${failures(result.output)}`;
  code = codeOf(await ask(request));
}
console.log("== bill/bill.mjs\\n" + code);
""",
    "bill/.keep": "",
    "style.mjs": """import fs from "node:fs";
import {ask, codeOf} from "./lib/ask.mjs";

// {w_c_style}
const task = "{w_task}";
const house = fs.readFileSync("house/tables.mjs", "utf8");

console.log("== without an example\\n" + codeOf(await ask(task)));
const withHouse = `{w_house}\\n\\n${house}\\n${task}`;
console.log("== with house/tables.mjs\\n" + codeOf(await ask(withHouse)));
""",
    "explain.mjs": """import fs from "node:fs";
import {ask} from "./lib/ask.mjs";

// {w_c_own}
const code = fs.readFileSync("bill/bill.mjs", "utf8");
console.log(await ask(`{w_explain}\\n\\n${code}`, {maxTokens: 500}));
""",
    # Projects
    "diff.mjs": """import {ask} from "./lib/ask.mjs";

// {w_c_diff}
const diff = `--- a/src/prices.mjs
+++ b/src/prices.mjs
@@ export function priceOf(drink, size) {
-  return PRICES[drink][size];
+  const price = PRICES[drink]?.[size];
+  if (price === undefined) {
+    return 0;
+  }
+  return price;
 }`;
console.log(await ask(`{w_diff_q}\\n\\n${diff}`, {maxTokens: 250}));
""",
    "checked.mjs": """import fs from "node:fs";
import {ask, codeOf} from "./lib/ask.mjs";
import {failures, runTests} from "./lib/tests.mjs";

// {w_c_check}
const correct = `export function splitBill(total, people, tipPercent) {
  if (people < 1) {
    throw new RangeError("people must be at least 1");
  }
  const sum = total + Math.round((total * tipPercent) / 100);
  const base = Math.floor(sum / people);
  const extra = sum - base * people;
  return Array.from({length: people}, (_, i) => base + (i < extra ? 1 : 0));
}
`;
fs.mkdirSync("checked", {recursive: true});
fs.writeFileSync("checked/bill.mjs", correct);
const spec = "{w_spec}";
const tests = codeOf(await ask(`${spec}\\n\\n{w_tests}`));
fs.writeFileSync("checked/bill.test.mjs", tests);
const result = runTests("checked/bill.test.mjs");
console.log(`tests written by the model, against a correct splitBill: ${result.summary}`);
console.log(failures(result.output) || "(no failures)");
""",
    "fixloop.mjs": """import fs from "node:fs";
import {ask, codeOf} from "./lib/ask.mjs";
import {failures, runTests} from "./lib/tests.mjs";

// {w_c_stop}
export async function fixLoop({spec, file, testFile, rounds = 3}) {
  let code = fs.readFileSync(file, "utf8");
  let last = "";
  for (let round = 0; ; round++) {
    const result = runTests(testFile);
    if (result.ok) {
      return `passed after ${round} fixes`;
    }
    const failed = failures(result.output);
    if (round === rounds) {
      return `gave up after ${rounds} fixes: ${result.summary}`;
    }
    if (failed === last) {
      return `stopped: the same failure twice (${result.summary})`;
    }
    last = failed;
    const request = `${spec}\\n\\n${file}:\\n${code}\\n\\n{w_fix}\\n${failed}`;
    code = codeOf(await ask(request));
    fs.writeFileSync(file, code);
  }
}

const broken = `export function splitBill(total, people, tipPercent) {
  const sum = total + (total * tipPercent) / 100;
  return Array(people).fill(sum / people);
}
`;
fs.mkdirSync("loop", {recursive: true});
fs.writeFileSync("loop/bill.mjs", broken);
fs.copyFileSync("bill/bill.test.mjs", "loop/bill.test.mjs");
const spec = "{w_spec}";
const file = "loop/bill.mjs";
console.log(await fixLoop({spec, file, testFile: "loop/bill.test.mjs"}));
""",
}

RUNS = [
    ("pair.sh", "node pair.mjs"),
    ("tests.sh", "node --test --test-reporter=tap bill/bill.test.mjs | grep -E '^ *(ok|not ok|# (pass|fail))'"),
    ("style.sh", "node style.mjs"),
    ("explain.sh", "node explain.mjs"),
    ("projects/diff.sh", "node diff.mjs"),
    ("projects/checked.sh", "node checked.mjs"),
    ("projects/fixloop.sh", "node fixloop.mjs"),
]


def main():
    chapter(HERE, T, FILES, RUNS)


if __name__ == "__main__":
    main()
