"""Writes and runs the examples of Book 7, chapter "Prompting That Works", in English and Arabic: a vague and a
specific request for the same function, tested; JSON with and without a grammar; instructions with and without
examples, scored; answering only from a document; and whether "step by step" helps, measured. Then a prompt
builder, a prompt test harness, and a model that rewrites a vague prompt, scored on the same tests.
Run: python3 make.py   (needs Node 22 and the book's model)
"""
import sys
from pathlib import Path

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE.parent))
from kit import chapter  # noqa: E402

T = {
    "en": dict(
        w_vague="Write a function that checks a phone number.",
        w_specific1="Write a JavaScript function isEgyptianMobile(text) that returns true only for ",
        w_specific2="Egyptian mobile numbers: 11 digits starting with 010, 011, 012 or 015, or the same ",
        w_specific3="number with +20 instead of the first 0. Spaces and dashes between digits are allowed. ",
        w_specific4="Return only the code, in one code block.",
        w_orders='"Two large lattes for Omar", "Sara wants one small tea", "an espresso for Ali, small please", '
                 '"Mona: 3 large teas", "a latte for Hassan"',
        w_extract="Read this coffee order and reply with JSON only, with the fields name, drink, size and count. Order: ",
        w_classify="Classify this message from a customer of a café app as bug, feature, question or billing. "
                   "Reply with the label only.",
        w_messages='["The app crashes when I open my orders", "bug"],\n'
                   '  ["Please add a dark mode", "feature"],\n'
                   '  ["I was charged twice for one latte", "billing"],\n'
                   '  ["Do you deliver to Nasr City?", "question"],\n'
                   '  ["It would be nice to save my usual order", "feature"],\n'
                   '  ["Nothing happens when I press Pay", "bug"],\n'
                   '  ["Why is there a service fee on my receipt?", "billing"],\n'
                   '  ["What time do you open on Friday?", "question"]',
        w_examples='Examples:\\n“The menu shows yesterday\'s prices” -> bug\\n'
                   '“Can I pay with a gift card in the future?” -> feature\\n'
                   '“My refund has not arrived” -> billing\\n“Is the café open on holidays?” -> question',
        w_doc="cafe.yml options:\\n- port: the port the service listens on (default 8080).\\n"
              "- menu_file: the path of the menu (default menu.json).\\n- tax_rate: the tax added to every order "
              "(default 0.14).",
        w_doc_q="What does the retry_delay option do, and what is its default?",
        w_only="Answer only from the documentation above. If the answer is not there, say: Not in the documentation.",
        w_problems='["A café opens at 7:45 and closes 9 hours and 50 minutes later. At what time does it close?", '
                   '"17:35"],\n  ["A meeting starts at 10:40 and lasts 2 hours and 35 minutes. When does it end?", '
                   '"13:15"],\n  ["Sara has 3 times as many cups as Omar. Together they have 48. How many does Sara '
                   'have?", "36"]',
        w_direct="Answer with the result only.",
        w_steps="Work it out step by step, then give the result on the last line.",
        w_role="You are a senior JavaScript developer who reviews code for a small team.",
        w_context="The team writes Node 22 code with ES modules and no TypeScript.",
        w_task="Explain what this line does: const unique = [...new Set(items)];",
        w_format="One sentence, then one example with input and output.",
        w_rules="Do not suggest other ways to write it.",
        w_improve="Rewrite this prompt for a language model so that it is clear and specific. Keep the task the same. "
                  "Reply with the new prompt only.",
        w_c_vague="The same request, vague and specific. Only the specific one says what correct means.",
        w_c_test="Then the specific answer is run against cases we wrote, as any code should be.",
        w_c_json="Without a grammar, the model is asked for JSON and may or may not give it.",
        w_c_schema="With a grammar built from a JSON schema, it cannot produce anything else.",
        w_c_shots="Instructions alone, then the same instructions with four examples.",
        w_c_doc="A question whose answer is not in the documentation, asked twice.",
        w_c_steps="Does asking for the working help? Count, do not guess.",
        w_c_build="Five parts of a good prompt. Leave out the ones you do not need.",
        w_c_harness="A prompt is code: run it against cases with known answers, and score it.",
        w_c_rewrite="Let the model rewrite a vague prompt, then score both on the same cases.",
    ),
    "ar": dict(
        w_vague="اكتب دالة تتحقق من رقم هاتف.",
        w_specific1="اكتب دالة JavaScript باسم isEgyptianMobile(text) تعيد true فقط ",
        w_specific2="لأرقام الجوال المصرية: 11 رقماً تبدأ بـ 010 أو 011 أو 012 أو 015، أو الرقم نفسه ",
        w_specific3="مع +20 بدل الصفر الأول. والمسافات والشرطات بين الأرقام مسموحة. ",
        w_specific4="أعِد الكود فقط، في كتلة كود واحدة.",
        w_orders='"كوبان لاتيه كبيران لعمر", "سارة تريد شاياً صغيراً واحداً", "إسبريسو لعلي، صغير من فضلك", '
                 '"منى: 3 أكواب شاي كبيرة", "لاتيه لحسن"',
        w_extract="اقرأ طلب القهوة هذا وأجب بـ JSON فقط، بالحقول name وdrink وsize وcount. الطلب: ",
        w_classify="صنّف هذه الرسالة من عميل تطبيق مقهى إلى bug أو feature أو question أو billing. "
                   "أجب بالتصنيف فقط.",
        w_messages='["التطبيق يتوقف حين أفتح طلباتي", "bug"],\n'
                   '  ["أرجو إضافة الوضع الليلي", "feature"],\n'
                   '  ["خُصم مني المبلغ مرتين لكوب لاتيه واحد", "billing"],\n'
                   '  ["هل توصلون إلى مدينة نصر؟", "question"],\n'
                   '  ["سيكون جميلاً لو أستطيع حفظ طلبي المعتاد", "feature"],\n'
                   '  ["لا يحدث شيء حين أضغط ادفع", "bug"],\n'
                   '  ["لماذا توجد رسوم خدمة في إيصالي؟", "billing"],\n'
                   '  ["متى تفتحون يوم الجمعة؟", "question"]',
        w_examples='أمثلة:\\n«القائمة تعرض أسعار الأمس» -> bug\\n'
                   '«هل أستطيع الدفع ببطاقة هدية مستقبلاً؟» -> feature\\n'
                   '«لم يصلني المبلغ المسترد» -> billing\\n«هل المقهى مفتوح في العطلات؟» -> question',
        w_doc="خيارات cafe.yml:\\n- port: المنفذ الذي تستمع عليه الخدمة (الافتراضي 8080).\\n"
              "- menu_file: مسار القائمة (الافتراضي menu.json).\\n- tax_rate: الضريبة المضافة لكل طلب "
              "(الافتراضي 0.14).",
        w_doc_q="ماذا يفعل الخيار retry_delay، وما قيمته الافتراضية؟",
        w_only="أجب من التوثيق أعلاه فقط. وإن لم يكن الجواب فيه، فقل: ليس في التوثيق.",
        w_problems='["يفتح مقهى في 7:45 ويغلق بعد 9 ساعات و50 دقيقة. في أي ساعة يغلق؟", "17:35"],\n'
                   '  ["يبدأ اجتماع في 10:40 ويستمر ساعتين و35 دقيقة. متى ينتهي؟", "13:15"],\n'
                   '  ["لدى سارة ثلاثة أضعاف ما لدى عمر من الأكواب. ومعهما معاً 48. كم لدى سارة؟", "36"]',
        w_direct="أجب بالنتيجة فقط.",
        w_steps="احسبها خطوة خطوة، ثم اكتب النتيجة في السطر الأخير.",
        w_role="أنت مطور JavaScript خبير يراجع الكود لفريق صغير.",
        w_context="الفريق يكتب كود Node 22 بوحدات ES وبلا TypeScript.",
        w_task="اشرح ما يفعله هذا السطر: const unique = [...new Set(items)];",
        w_format="جملة واحدة، ثم مثال واحد بمدخله ومخرجه.",
        w_rules="لا تقترح طرقاً أخرى لكتابته.",
        w_improve="أعد كتابة هذا الأمر لنموذج لغوي ليكون واضحاً ومحدداً. أبقِ المهمة نفسها. "
                  "أجب بالأمر الجديد فقط.",
        w_c_vague="الطلب نفسه، غامضاً ومحدداً. والمحدد وحده يقول ما معنى «صحيح».",
        w_c_test="ثم يُشغَّل الجواب المحدد على حالات كتبناها، كما يجب مع أي كود.",
        w_c_json="بلا قواعد، يُطلب من النموذج JSON وقد يعطيه وقد لا يعطيه.",
        w_c_schema="ومع قواعد مبنية من مخطط JSON، لا يستطيع أن ينتج غيره.",
        w_c_shots="التعليمات وحدها، ثم التعليمات نفسها مع أربعة أمثلة.",
        w_c_doc="سؤال جوابه ليس في التوثيق، يُسأل مرتين.",
        w_c_steps="هل طلب طريقة الحل يساعد؟ عُدّ، لا تخمّن.",
        w_c_build="خمسة أجزاء للأمر الجيد. اترك ما لا تحتاجه منها.",
        w_c_harness="الأمر كود: شغّله على حالات أجوبتها معروفة، وأعطه درجة.",
        w_c_rewrite="دع النموذج يعيد كتابة أمر غامض، ثم أعطِ الاثنين درجة على الحالات نفسها.",
    ),
}

ASK = """import {LlamaChatSession} from "node-llama-cpp";
import {loadModel} from "./model.mjs";

const model = await loadModel();
const context = await model.createContext({contextSize: 4096});

// One question in a fresh conversation, at temperature 0.
export async function ask(prompt, options = {}) {
  const session = new LlamaChatSession({
    contextSequence: context.getSequence(),
    autoDisposeSequence: true,
    systemPrompt: options.system,
  });
  const answer = await session.prompt(prompt, {
    temperature: 0,
    maxTokens: options.maxTokens ?? 300,
    grammar: options.grammar,
  });
  session.dispose();
  return answer.trim();
}

export {model};
"""

FILES = {
    "lib/ask.mjs": ASK,
    "specific.mjs": """import {ask} from "./lib/ask.mjs";

// {w_c_vague}
const vague = "{w_vague}";
const specific =
  "{w_specific1}" +
  "{w_specific2}" +
  "{w_specific3}" +
  "{w_specific4}";

for (const prompt of [vague, specific]) {
  console.log(`> ${prompt}\\n${await ask(prompt)}\\n`);
}

// {w_c_test}
const answer = await ask(specific);
const code = answer.match(/```(?:\\w+)?\\n([\\s\\S]*?)```/)[1];
const isEgyptianMobile = Function(`${code}; return isEgyptianMobile;`)();
const cases = [
  ["01012345678", true],
  ["+20 101 234 5678", true],
  ["015-1234-5678", true],
  ["01312345678", false],
  ["0101234567", false],
  ["phone: 01012345678", false],
];
for (const [text, expected] of cases) {
  const got = isEgyptianMobile(text);
  console.log(`${got === expected ? "pass" : "FAIL"}  ${JSON.stringify(text)} -> ${got}`);
}
""",
    "format.mjs": """import {ask, model} from "./lib/ask.mjs";

const orders = [{w_orders}];

// {w_c_json}
// {w_c_schema}
const grammar = await model.llama.createGrammarForJsonSchema({
  type: "object",
  properties: {
    name: {type: "string"},
    drink: {enum: ["latte", "tea", "espresso"]},
    size: {enum: ["small", "large", "unknown"]},
    count: {type: "integer"},
  },
});

for (const [label, options] of [["no grammar", {}], ["schema", {grammar}]]) {
  console.log(`--- ${label}`);
  for (const order of orders) {
    const answer = await ask("{w_extract}" + order, options);
    try {
      console.log(JSON.stringify(JSON.parse(answer)));
    } catch {
      console.log(`not JSON: ${JSON.stringify(answer.slice(0, 60))}...`);
    }
  }
}
""",
    "examples.mjs": """import {ask} from "./lib/ask.mjs";

const messages = [
  {w_messages},
];

// {w_c_shots}
const instruction = "{w_classify}";
const examples = "{w_examples}";

for (const [label, prompt] of [
  ["instructions only", instruction],
  ["with examples", `${instruction}\\n\\n${examples}`],
]) {
  let right = 0;
  for (const [message, expected] of messages) {
    const label = (await ask(`${prompt}\\n\\n"${message}"`)).toLowerCase();
    if (label === expected) {
      right++;
    } else {
      console.log(`  wrong: "${message}" -> ${label} (expected ${expected})`);
    }
  }
  console.log(`${label}: ${right} of ${messages.length}\\n`);
}
""",
    "grounded.mjs": """import {ask} from "./lib/ask.mjs";

// {w_c_doc}
const doc = "{w_doc}";
const question = "{w_doc_q}";

console.log(`> ${question}\\n${await ask(`${doc}\\n\\n${question}`)}\\n`);
console.log(`> ${question} {w_only}`);
console.log(await ask(`${doc}\\n\\n${question}\\n{w_only}`));
""",
    "steps.mjs": """import {ask} from "./lib/ask.mjs";

const problems = [
  {w_problems},
];

// {w_c_steps}
for (const [label, suffix] of [
  ["direct", "{w_direct}"],
  ["step by step", "{w_steps}"],
]) {
  let right = 0;
  for (const [problem, expected] of problems) {
    const answer = await ask(`${problem} ${suffix}`, {maxTokens: 400});
    const last = answer.split("\\n").filter((line) => line.trim()).at(-1);
    const ok = last.includes(expected);
    right += ok ? 1 : 0;
    console.log(`  ${ok ? "right" : "wrong"}: ${last.slice(0, 50)} (expected ${expected})`);
  }
  console.log(`${label}: ${right} of ${problems.length}\\n`);
}
""",
    # Projects
    "build.mjs": """import {ask} from "./lib/ask.mjs";

// {w_c_build}
export function buildPrompt({context, task, format, rules}) {
  return [context, task, format, rules]
    .filter(Boolean)
    .join("\\n\\n");
}

const prompt = buildPrompt({
  context: "{w_context}",
  task: "{w_task}",
  format: "{w_format}",
  rules: "{w_rules}",
});
const system = "{w_role}";
console.log(`[system] ${system}\\n${prompt}\\n---`);
console.log(await ask(prompt, {system}));
""",
    "harness.mjs": """import {ask} from "./lib/ask.mjs";

// {w_c_harness}
export async function score(prompt, cases) {
  let right = 0;
  for (const [message, expected] of cases) {
    const label = (await ask(`${prompt}\\n\\n"${message}"`)).toLowerCase();
    right += label === expected ? 1 : 0;
  }
  return right;
}

export const cases = [
  {w_messages},
];

if (process.argv[1].endsWith("harness.mjs")) {
  for (const prompt of [
    "Is this a bug, feature, question or billing?",
    "{w_classify}",
  ]) {
    console.log(`${await score(prompt, cases)} of ${cases.length}  ${prompt}`);
  }
}
""",
    "rewrite.mjs": """import {ask} from "./lib/ask.mjs";
import {cases, score} from "./harness.mjs";

// {w_c_rewrite}
const vague = "Is this a bug, feature, question or billing?";
const better = await ask(`{w_improve}\\n\\n${vague}`);
console.log(`rewritten: ${better}\\n`);
for (const prompt of [vague, better]) {
  console.log(`${await score(prompt, cases)} of ${cases.length}`);
}
""",
}

RUNS = [
    ("specific.sh", "node specific.mjs"),
    ("format.sh", "node format.mjs"),
    ("examples.sh", "node examples.mjs"),
    ("grounded.sh", "node grounded.mjs"),
    ("steps.sh", "node steps.mjs"),
    ("projects/build.sh", "node build.mjs"),
    ("projects/harness.sh", "node harness.mjs"),
    ("projects/rewrite.sh", "node rewrite.mjs"),
]


def main():
    chapter(HERE, T, FILES, RUNS)


if __name__ == "__main__":
    main()
