"""Writes and runs the examples of Book 7, chapter "Judgement: When Not to Trust the AI", in English and Arabic:
the model's stated confidence against its real accuracy on questions with known answers; agreement between
several samples as a signal of reliability; and whether asking the model to check its own answer catches its
mistakes. Then a router that sends arithmetic to code, and a small scorer for deciding how much to trust a
model on a task.
Run: python3 make.py   (needs Node 22 and the book's model; B7_LANG=en runs one edition)
"""
import json
import sys
from pathlib import Path

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE.parent))
from kit import chapter  # noqa: E402

QUESTIONS_EN = [
    ["What is 17 × 24?", "408"],
    ["What is 48213 × 7.35? Give the exact result.", "354365.55"],
    ["What is the capital of Egypt?", "cairo"],
    ["How many days are in a leap year?", "366"],
    ["Which is larger, 9.11 or 9.9?", "9.9"],
    ["How many times does the letter r appear in the word strawberry?", "3"],
    ["In which year was the first iPhone released?", "2007"],
    ["What is 2 to the power of 20?", "1048576"],
    ["What does a large latte cost at Bit Café in Cairo?", "unknown"],
    ["Who won the 2034 football World Cup?", "unknown"],
]
QUESTIONS_AR = [
    ["كم يساوي 17 × 24؟", "408"],
    ["كم يساوي 48213 × 7.35؟ أعطِ النتيجة الدقيقة.", "354365.55"],
    ["ما عاصمة مصر؟", "القاهرة"],
    ["كم يوماً في السنة الكبيسة؟", "366"],
    ["أيهما أكبر، 9.11 أم 9.9؟", "9.9"],
    ["كم مرة يظهر الحرف r في الكلمة strawberry؟", "3"],
    ["في أي سنة صدر أول آيفون؟", "2007"],
    ["كم يساوي 2 أُس 20؟", "1048576"],
    ["كم سعر اللاتيه الكبير في مقهى بِت في القاهرة؟", "unknown"],
    ["من فاز بكأس العالم لكرة القدم 2034؟", "unknown"],
]

T = {
    "en": dict(
        w_questions=json.dumps(QUESTIONS_EN, ensure_ascii=False, indent=1),
        w_ask_conf="Answer the question briefly. If you cannot know the answer, answer unknown. Also give your "
                   "confidence that the answer is right, from 0 to 100.",
        w_check="Here is a question and an answer. Check the answer carefully. Reply with JSON: is it correct, "
                "and if not, the correct answer.",
        w_c_truth="Ten questions with known answers; the last two cannot be known by any model.",
        w_c_conf="Ask for the answer and a confidence, with a schema.",
        w_c_samples="Five samples at temperature 0.8: do they agree?",
        w_c_self="Ask the model to check its own answer, in a new conversation.",
        w_c_route="Arithmetic goes to code; everything else to the model.",
        w_c_score="Impact, reversibility and checkability decide how much to trust a model on a task.",
        w_only="Answer with the result only.", w_brief="Answer briefly.",
        w_route='"What is 48213 × 7.35?", "What is 2 ^ 20?", "What is the capital of Egypt?"',
        w_t1="use it: a quick look is enough", w_t2="use it, and verify before acting",
        w_t3="do not rely on it: a person decides",
        w_task1="name ideas for a new drink", w_task2="first draft of a test file",
        w_task3="summary of a meeting for the team", w_task4="price announcement to all customers",
        w_task5="deciding a customer's refund",
    ),
    "ar": dict(
        w_questions=json.dumps(QUESTIONS_AR, ensure_ascii=False, indent=1),
        w_ask_conf="أجب عن السؤال باختصار. وإن كنت لا تستطيع معرفة الجواب، فأجب unknown. وأعطِ أيضاً ثقتك بأن "
                   "الجواب صحيح، من 0 إلى 100.",
        w_check="هذا سؤال وجواب. افحص الجواب بعناية. أجب بـ JSON: هل هو صحيح، وإن لم يكن، فما الجواب الصحيح.",
        w_c_truth="عشرة أسئلة أجوبتها معروفة؛ والأخيران لا يستطيع أي نموذج معرفتهما.",
        w_c_conf="اطلب الجواب ودرجة ثقة، بمخطط.",
        w_c_samples="خمس عيّنات بدرجة 0.8: هل تتفق؟",
        w_c_self="اطلب من النموذج فحص جوابه هو، في محادثة جديدة.",
        w_c_route="الحساب يذهب إلى الكود؛ وكل شيء آخر إلى النموذج.",
        w_c_score="الأثر، وإمكان التراجع، وإمكان الفحص تقرر كم تثق بالنموذج في مهمة.",
        w_only="أجب بالنتيجة فقط.", w_brief="أجب باختصار.",
        w_route='"كم يساوي 48213 × 7.35؟", "كم يساوي 2 ^ 20؟", "ما عاصمة مصر؟"',
        w_t1="استخدمه: نظرة سريعة تكفي", w_t2="استخدمه، وتحقق قبل التنفيذ",
        w_t3="لا تعتمد عليه: يقرر إنسان",
        w_task1="أفكار أسماء لمشروب جديد", w_task2="مسودة أولى لملف اختبارات",
        w_task3="ملخص اجتماع للفريق", w_task4="إعلان سعر لكل العملاء",
        w_task5="قرار استرداد مبلغ لعميل",
    ),
}

ASK = """import {LlamaChatSession} from "node-llama-cpp";
import {loadModel} from "./model.mjs";

const model = await loadModel();
const context = await model.createContext({contextSize: 2048});

// One question in a fresh conversation.
export async function ask(prompt, options = {}) {
  const session = new LlamaChatSession({contextSequence: context.getSequence(), autoDisposeSequence: true});
  const answer = await session.prompt(prompt, {
    temperature: options.temperature ?? 0,
    seed: options.seed,
    maxTokens: options.maxTokens ?? 120,
    grammar: options.grammar,
  });
  session.dispose();
  return answer.trim();
}

// Right if the expected answer appears, ignoring case, spaces and thousands separators.
export function isRight(answer, expected) {
  const clean = (s) => String(s).toLowerCase().replace(/[\\s,]/g, "");
  return clean(answer).includes(clean(expected));
}

export {model};
"""

FILES = {
    "lib/ask.mjs": ASK,
    "data/questions.mjs": "// {w_c_truth}\nexport const QUESTIONS = {w_questions};\n",
    "confidence.mjs": """import {ask, isRight, model} from "./lib/ask.mjs";
import {QUESTIONS} from "./data/questions.mjs";

// {w_c_conf}
const grammar = await model.llama.createGrammarForJsonSchema({
  type: "object",
  properties: {answer: {type: "string"}, confidence: {type: "integer"}},
});
let wrongButSure = 0;
for (const [question, expected] of QUESTIONS) {
  const {answer, confidence} = JSON.parse(await ask(`{w_ask_conf}\\n\\n${question}`, {grammar}));
  const right = isRight(answer, expected);
  wrongButSure += !right && confidence >= 90 ? 1 : 0;
  console.log(`${right ? "right" : "WRONG"} ${String(confidence).padStart(3)}%  ${answer.slice(0, 40)}`);
}
console.log(`--- wrong answers given with 90% confidence or more: ${wrongButSure}`);
""",
    "agreement.mjs": """import {ask, isRight} from "./lib/ask.mjs";
import {QUESTIONS} from "./data/questions.mjs";

// {w_c_samples}
for (const [question, expected] of QUESTIONS.slice(0, 8)) {
  const answers = [];
  for (const seed of [1, 2, 3, 4, 5]) {
    answers.push(await ask(`${question} {w_only}`, {temperature: 0.8, seed, maxTokens: 30}));
  }
  const counts = new Map();
  answers.forEach((a) => counts.set(a, (counts.get(a) ?? 0) + 1));
  const [top, n] = [...counts].sort((a, b) => b[1] - a[1])[0];
  const right = isRight(top, expected);
  console.log(`${n}/5 agree  ${right ? "right" : "WRONG"}  ${top.slice(0, 40)}`);
}
""",
    "selfcheck.mjs": """import {ask, isRight, model} from "./lib/ask.mjs";
import {QUESTIONS} from "./data/questions.mjs";

const grammar = await model.llama.createGrammarForJsonSchema({
  type: "object",
  properties: {correct: {type: "boolean"}, correctAnswer: {type: "string"}},
});
// {w_c_self}
for (const [question, expected] of QUESTIONS.slice(0, 8)) {
  const answer = await ask(`${question} {w_only}`, {maxTokens: 30});
  const verdict = JSON.parse(await ask(`{w_check}\\n\\n${question}\\n${answer}`, {grammar, maxTokens: 200}));
  const right = isRight(answer, expected);
  const caught = !right && !verdict.correct;
  const label = right ? (verdict.correct ? "right, confirmed" : "right, DOUBTED") : caught ? "wrong, caught" : "WRONG, confirmed";
  console.log(`${label.padEnd(18)} ${answer.slice(0, 30)}`);
}
""",
    # Projects
    "route.mjs": """import {ask} from "./lib/ask.mjs";

// {w_c_route}
const ARITHMETIC = /^[\\d\\s.+\\-*/×÷^()]+$/;
async function answer(question) {
  const expression = question.replace(/[^\\d\\s.+\\-*/×÷^()]/g, "").trim();
  if (expression.length > 2 && ARITHMETIC.test(expression) && /\\d\\s*[-+*/×÷^]\\s*\\d/.test(expression)) {
    const js = expression.replaceAll("×", "*").replaceAll("÷", "/").replaceAll("^", "**");
    return {by: "code", result: String(Function(`return (${js});`)())};
  }
  return {by: "model", result: await ask(`${question} {w_brief}`, {maxTokens: 40})};
}

for (const question of [{w_route}]) {
  const {by, result} = await answer(question);
  console.log(`${by.padEnd(5)} ${question} -> ${result}`);
}
""",
    "trust.mjs": """// {w_c_score}
// Each factor from 1 (low) to 3 (high).
export function trustLevel({impact, irreversible, hardToCheck}) {
  const risk = impact * irreversible * hardToCheck;
  if (risk <= 4) return "{w_t1}";
  if (risk <= 12) return "{w_t2}";
  return "{w_t3}";
}

const tasks = [
  ["{w_task1}", {impact: 1, irreversible: 1, hardToCheck: 1}],
  ["{w_task2}", {impact: 2, irreversible: 1, hardToCheck: 1}],
  ["{w_task3}", {impact: 2, irreversible: 2, hardToCheck: 2}],
  ["{w_task4}", {impact: 3, irreversible: 3, hardToCheck: 1}],
  ["{w_task5}", {impact: 3, irreversible: 3, hardToCheck: 2}],
];
for (const [task, factors] of tasks) {
  console.log(`${task.padEnd(38)} ${trustLevel(factors)}`);
}
""",
}

RUNS = [
    ("confidence.sh", "node confidence.mjs"),
    ("agreement.sh", "node agreement.mjs"),
    ("selfcheck.sh", "node selfcheck.mjs"),
    ("projects/route.sh", "node route.mjs"),
    ("projects/trust.sh", "node trust.mjs"),
]


def main():
    chapter(HERE, T, FILES, RUNS)


if __name__ == "__main__":
    main()
