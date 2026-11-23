"""Writes and runs the examples of Book 7, chapter "From Idea to Specification and Tasks", in English and Arabic:
clarifying questions scored against the questions that matter, a specification checked for vague words and
for acceptance criteria in Given/When/Then form, and tasks whose dependencies are checked as a graph. Then a
vagueness linter, acceptance criteria turned into pending tests, and the spread of the model's estimates.
Run: python3 make.py   (needs Node 22 and the book's model; B7_LANG=en runs one edition)
"""
import sys
from pathlib import Path

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE.parent))
from kit import chapter  # noqa: E402

T = {
    "en": dict(
        w_idea="A loyalty card in our café app: every 10th coffee is free.",
        w_questions="Before anyone writes a specification for this idea, what questions must the café answer? "
                    "List the ten most important, one line each.",
        w_answers="Answers from the café: only paid hot drinks count, any size; stamps never expire; one card "
                  "per account; a refunded drink removes its stamp; the free drink is any hot drink up to the "
                  "price of a large latte; both branches share the card.",
        w_spec="Write a short specification for this feature: a summary, the rules, and acceptance criteria "
               "written as Given / When / Then, one per line. Use only the answers given; do not add features.",
        w_tasks="Break this specification into development tasks for a small team. Reply with JSON: a list of "
                "tasks, each with id (T1, T2...), title, estimate in hours, and dependsOn (a list of ids).",
        w_c_ask="First the questions, before any specification.",
        w_c_cover="The questions that matter for a loyalty card, as patterns; which did the model ask?",
        w_c_vague="Words that sound like requirements but cannot be tested.",
        w_c_gwt="Each acceptance criterion must have a Given, a When and a Then.",
        w_c_graph="Every dependency must exist, and there must be no cycle.",
        w_c_todo="One pending test per acceptance criterion: the specification becomes the test list.",
        w_c_spread="The same request three times at temperature 0.7: how much do the estimates move?",
    ),
    "ar": dict(
        w_idea="بطاقة ولاء في تطبيق مقهانا: كل قهوة عاشرة مجانية.",
        w_questions="قبل أن يكتب أحد مواصفات هذه الفكرة، ما الأسئلة التي يجب أن يجيب عنها المقهى؟ "
                    "اسرد أهم عشرة، في سطر لكل منها.",
        w_answers="أجوبة المقهى: لا تُحسب إلا المشروبات الساخنة المدفوعة، بأي حجم؛ والطوابع لا تنتهي صلاحيتها؛ "
                  "وبطاقة واحدة لكل حساب؛ والمشروب المسترد يُلغي طابعه؛ والمشروب المجاني أي مشروب ساخن حتى سعر "
                  "اللاتيه الكبير؛ والفرعان يتشاركان البطاقة.",
        w_spec="اكتب مواصفات قصيرة لهذه الميزة: ملخصاً، والقواعد، ومعايير قبول بصيغة Given / When / Then، "
               "في سطر لكل منها. استخدم الأجوبة المعطاة وحدها؛ ولا تضف ميزات.",
        w_tasks="قسّم هذه المواصفات إلى مهام تطوير لفريق صغير. أجب بـ JSON: قائمة مهام، لكل منها id (T1، T2...)، "
                "وtitle، وestimate بالساعات، وdependsOn (قائمة معرّفات).",
        w_c_ask="الأسئلة أولاً، قبل أي مواصفات.",
        w_c_cover="الأسئلة المهمة لبطاقة ولاء، كأنماط؛ أيها سأل النموذج؟",
        w_c_vague="كلمات تبدو متطلبات لكن لا يمكن اختبارها.",
        w_c_gwt="كل معيار قبول يجب أن يكون فيه Given وWhen وThen.",
        w_c_graph="كل اعتمادية يجب أن تكون موجودة، ولا حلقة دائرية.",
        w_c_todo="اختبار معلّق لكل معيار قبول: المواصفات تصير قائمة الاختبارات.",
        w_c_spread="الطلب نفسه ثلاث مرات بدرجة 0.7: كم تتحرك التقديرات؟",
    ),
}

ASK = """import {LlamaChatSession} from "node-llama-cpp";
import {loadModel} from "./model.mjs";

const model = await loadModel();
const context = await model.createContext({contextSize: 6144});

// One question in a fresh conversation (temperature 0 unless asked).
export async function ask(prompt, options = {}) {
  const session = new LlamaChatSession({
    contextSequence: context.getSequence(),
    autoDisposeSequence: true,
  });
  const answer = await session.prompt(prompt, {
    temperature: options.temperature ?? 0,
    seed: options.seed,
    maxTokens: options.maxTokens ?? 700,
    grammar: options.grammar,
  });
  session.dispose();
  return answer.trim();
}

export {model};
"""

VAGUE = """// Words that sound like requirements and cannot be tested.
export const VAGUE = [
  "fast", "quick", "easy", "simple", "intuitive", "user-friendly", "seamless", "appropriate",
  "properly", "correctly", "efficient", "robust", "flexible", "secure", "etc", "as needed",
  "and so on", "should be able to", "if possible", "some", "various",
  "سريع", "سهل", "بسيط", "مناسب", "بشكل صحيح", "بكفاءة", "مرن", "آمن", "إلخ", "وغيرها", "قدر الإمكان",
];

export function vagueWords(text) {
  const found = new Map();
  for (const word of VAGUE) {
    // \\b only knows Latin letters, so Arabic words are counted as plain text.
    const hits = /^[a-z]/i.test(word)
      ? text.match(new RegExp(`\\\\b${word}\\\\b`, "gi"))?.length ?? 0
      : text.split(word).length - 1;
    if (hits) {
      found.set(word, hits);
    }
  }
  return found;
}

// The acceptance criteria: lines with Given, When and Then in that order.
export function criteria(text) {
  const lines = text.split("\\n").filter((line) => /\\bGiven\\b/i.test(line));
  return lines.map((line) => ({
    line: line.replace(/^[\\s*>\\-\\d.]+/, "").trim(),
    ok: /\\bGiven\\b.*\\bWhen\\b.*\\bThen\\b/i.test(line),
  }));
}
"""

GRAPH = """// Checks a task list: unknown dependencies, cycles, and an order to do them in.
export function checkTasks(tasks) {
  const ids = new Set(tasks.map((t) => t.id));
  const problems = [];
  for (const task of tasks) {
    for (const dep of task.dependsOn) {
      if (!ids.has(dep)) {
        problems.push(`${task.id} depends on ${dep}, which does not exist`);
      }
      if (dep === task.id) {
        problems.push(`${task.id} depends on itself`);
      }
    }
  }
  const order = [];
  const state = new Map();
  const visit = (id, path) => {
    if (state.get(id) === "done" || !ids.has(id)) {
      return;
    }
    if (state.get(id) === "visiting") {
      problems.push(`cycle: ${[...path, id].join(" -> ")}`);
      return;
    }
    state.set(id, "visiting");
    for (const dep of tasks.find((t) => t.id === id).dependsOn) {
      visit(dep, [...path, id]);
    }
    state.set(id, "done");
    order.push(id);
  };
  tasks.forEach((t) => visit(t.id, []));
  return {problems, order};
}
"""

FILES = {
    "lib/ask.mjs": ASK,
    "lib/vague.mjs": VAGUE,
    "lib/graph.mjs": GRAPH,
    "questions.mjs": """import {ask} from "./lib/ask.mjs";

// {w_c_ask}
const answer = await ask("{w_idea}\\n\\n{w_questions}");
console.log(answer);

// {w_c_cover}
const matter = {
  "which drinks count": /which (drinks|items|products)|what (counts|qualifies)|eligible|count toward/i,
  "refunds and cancellations": /refund|cancel|return/i,
  "expiry": /expir|valid for|time limit|reset/i,
  "what the free drink can be": /free (drink|coffee|item).*(any|which|size|price|limit)|value of the free/i,
  "several branches": /branch|location|store|shop/i,
  "abuse and fraud": /fraud|abuse|cheat|misuse|share|transfer/i,
  "existing customers and past orders": /existing|past (orders|purchases)|retroactive|already/i,
};
console.log("--- the questions that matter");
for (const [name, pattern] of Object.entries(matter)) {
  console.log(`${pattern.test(answer) ? "asked " : "MISSED"} ${name}`);
}
""",
    "spec.mjs": """import fs from "node:fs";
import {ask} from "./lib/ask.mjs";
import {criteria, vagueWords} from "./lib/vague.mjs";

const spec = await ask("{w_idea}\\n{w_answers}\\n\\n{w_spec}", {maxTokens: 900});
fs.writeFileSync("spec.md", spec);
console.log(spec);

// {w_c_vague}
const vague = vagueWords(spec);
console.log(`--- vague words: ${[...vague].map(([w, n]) => `${w} (${n})`).join(", ") || "none"}`);

// {w_c_gwt}
const found = criteria(spec);
console.log(`--- ${found.length} acceptance criteria, ${found.filter((c) => !c.ok).length} not in the form`);
""",
    "tasks.mjs": """import fs from "node:fs";
import {ask, model} from "./lib/ask.mjs";
import {checkTasks} from "./lib/graph.mjs";

const grammar = await model.llama.createGrammarForJsonSchema({
  type: "array",
  items: {
    type: "object",
    properties: {
      id: {type: "string"},
      title: {type: "string"},
      estimate: {type: "number"},
      dependsOn: {type: "array", items: {type: "string"}},
    },
  },
  minItems: 3,
  maxItems: 12,
});
const spec = fs.readFileSync("spec.md", "utf8");
const tasks = JSON.parse(await ask(`{w_tasks}\\n\\n${spec}`, {grammar, maxTokens: 1200}));
fs.writeFileSync("tasks.json", JSON.stringify(tasks, null, 2));
for (const {id, title, estimate, dependsOn} of tasks) {
  console.log(`${id.padEnd(4)} ${String(estimate).padStart(4)} h  ${title}  [${dependsOn.join(", ")}]`);
}
const total = tasks.reduce((sum, t) => sum + t.estimate, 0);
console.log(`total: ${total} hours`);

// {w_c_graph}
const {problems, order} = checkTasks(tasks);
console.log(problems.length ? problems.join("\\n") : "dependencies: ok");
console.log(`an order: ${order.join(" ")}`);
""",
    # Projects
    "vague.mjs": """import fs from "node:fs";
import {vagueWords} from "./lib/vague.mjs";

for (const file of process.argv.slice(2)) {
  const found = vagueWords(fs.readFileSync(file, "utf8"));
  const list = [...found].map(([word, n]) => `${word} (${n})`).join(", ");
  console.log(`${file}: ${list || "no vague words"}`);
}
""",
    "requirements.md": "The app should be fast and easy to use. Customers should be able to see their stamps, "
                       "and the card should work properly in both branches, etc.\n",
    "todo.mjs": """import fs from "node:fs";
import {criteria} from "./lib/vague.mjs";

// {w_c_todo}
const lines = criteria(fs.readFileSync("spec.md", "utf8"));
const tests = lines.map(({line}) => `test(${JSON.stringify(line)}, {todo: true});`);
fs.writeFileSync("loyalty.test.mjs", `import {test} from "node:test";\\n\\n${tests.join("\\n")}\\n`);
console.log(`loyalty.test.mjs: ${tests.length} pending tests`);
""",
    "spread.mjs": """import fs from "node:fs";
import {ask, model} from "./lib/ask.mjs";

// {w_c_spread}
const grammar = await model.llama.createGrammarForJsonSchema({
  type: "array",
  items: {type: "object", properties: {title: {type: "string"}, estimate: {type: "number"}}},
  minItems: 3,
  maxItems: 10,
});
const spec = fs.readFileSync("spec.md", "utf8");
for (const seed of [1, 2, 3]) {
  const answer = await ask(`{w_tasks}\\n\\n${spec}`, {grammar, temperature: 0.7, seed, maxTokens: 1000});
  const tasks = JSON.parse(answer);
  const total = tasks.reduce((sum, t) => sum + t.estimate, 0);
  console.log(`seed ${seed}: ${tasks.length} tasks, ${total} hours`);
}
""",
}

RUNS = [
    ("questions.sh", "node questions.mjs"),
    ("spec.sh", "node spec.mjs"),
    ("tasks.sh", "node tasks.mjs"),
    ("projects/vague.sh", "node vague.mjs requirements.md spec.md"),
    ("projects/todo.sh", "node todo.mjs && node --test loyalty.test.mjs 2>&1 | grep -E '^ℹ (tests|todo|pass|fail)'"),
    ("projects/spread.sh", "node spread.mjs"),
]


def main():
    chapter(HERE, T, FILES, RUNS, made=["spec.md", "tasks.json", "loyalty.test.mjs"])


if __name__ == "__main__":
    main()
