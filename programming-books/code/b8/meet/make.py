"""Writes and runs the examples of Book 8, chapter "Meet Claude: Models, Strengths and Limits", in English and
Arabic: the models the API offers, a first message and what comes back with it (the answer, the reason it
stopped, the tokens it cost), a cost calculator from the published prices, and the errors a first program
meets. Then a model chooser, a monthly budget, and an error handler that tells the reader what to do.
Run: python3 make.py   (needs Node 22; B8_LANG=en runs one edition)
"""
import json
import sys
from pathlib import Path

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE.parent))
from kit import chapter  # noqa: E402

REPLIES = {
    "en": [
        {"when": "three sentences", "text": "I'm Claude, an AI model made by Anthropic. I can read and write text "
         "and code, look at images and documents, and use tools that you give me. I don't remember earlier "
         "conversations unless you send them again, and I can be wrong, so check what matters."},
        {"when": "what happened in the news today", "text": "I can't know that: I have no access to the news, "
         "and my knowledge stops at my training cutoff. Give me the articles, or use a tool such as web "
         "search, and I can summarise them."},
    ],
    "ar": [
        {"when": "ثلاث جمل", "text": "أنا Claude، نموذج ذكاء اصطناعي من Anthropic. أستطيع قراءة النصوص والكود "
         "وكتابتها، والنظر في الصور والمستندات، واستخدام الأدوات التي تعطيني إياها. ولا أتذكر المحادثات "
         "السابقة ما لم ترسلها مرة أخرى، وقد أخطئ، فافحص ما يهم."},
        {"when": "أخبار اليوم", "text": "لا أستطيع معرفة ذلك: ليس لدي وصول إلى الأخبار، ومعرفتي تتوقف عند "
         "تاريخ انتهاء تدريبي. أعطني المقالات، أو استخدم أداة مثل البحث في الويب، وأستطيع تلخيصها."},
    ],
}

T = {
    "en": dict(
        w_replies=json.dumps({"replies": REPLIES["en"]}, ensure_ascii=False, indent=2),
        w_hello="Introduce yourself in three sentences.",
        w_news="What happened in the news today?",
        w_c_models="Every model the API offers you, with its limits.",
        w_c_hello="A first message: the answer, why it stopped, and what it cost.",
        w_c_prices="Prices in dollars per million tokens, from the pricing page (November 2026).",
        w_c_cost="What a request costs: input, output, cache writes and cache reads, each at its own price.",
        w_c_errors="Three mistakes every first program makes, and what the API answers.",
        w_c_choose="A first choice of model from three questions about the task.",
        w_c_budget="A month of a feature: requests a day, tokens per request, and the model.",
        w_c_handle="What to tell the developer for each kind of error.",
        w_t1="classify support tickets", w_t2="answer customers in a chat",
        w_t3="refactor a large codebase", w_t4="plan a migration with many unknowns",
        w_feature="ticket summaries",
        w_e1="a misspelled model", w_e2="no max_tokens", w_e3="thinking turned off",
        w_h400="Fix the request: read the message, it names the field.",
        w_h401="Check ANTHROPIC_API_KEY: missing, mistyped or revoked.",
        w_h404="Check the model name against GET /v1/models.",
        w_h429="Too many requests: wait as long as retry-after says, then retry.",
        w_h5xx="A problem on the API's side: retry with backoff.",
        w_hnet="No connection: check the network and ANTHROPIC_BASE_URL.",
    ),
    "ar": dict(
        w_replies=json.dumps({"replies": REPLIES["ar"]}, ensure_ascii=False, indent=2),
        w_hello="عرّف بنفسك في ثلاث جمل.",
        w_news="ما أخبار اليوم؟",
        w_c_models="كل نموذج تتيحه لك الواجهة البرمجية، بحدوده.",
        w_c_hello="رسالة أولى: الجواب، ولماذا توقف، وكم كلّف.",
        w_c_prices="الأسعار بالدولار لكل مليون token، من صفحة الأسعار (نوفمبر 2026).",
        w_c_cost="كم يكلّف الطلب: المدخلات، والمخرجات، والكتابة في الذاكرة المؤقتة والقراءة منها، كلٌّ بسعره.",
        w_c_errors="ثلاثة أخطاء يقع فيها كل برنامج أول، وبماذا تجيب الواجهة البرمجية.",
        w_c_choose="اختيار أول للنموذج من ثلاثة أسئلة عن المهمة.",
        w_c_budget="شهر من ميزة: الطلبات في اليوم، والـ tokens لكل طلب، والنموذج.",
        w_c_handle="ماذا تقول للمطور عن كل نوع من الأخطاء.",
        w_t1="تصنيف تذاكر الدعم", w_t2="الرد على العملاء في محادثة",
        w_t3="إعادة هيكلة قاعدة كود كبيرة", w_t4="تخطيط ترحيل فيه مجاهيل كثيرة",
        w_feature="ملخصات التذاكر",
        w_e1="اسم نموذج فيه خطأ", w_e2="بلا max_tokens", w_e3="إيقاف التفكير",
        w_h400="أصلح الطلب: اقرأ الرسالة، فهي تسمّي الحقل.",
        w_h401="افحص ANTHROPIC_API_KEY: غائب، أو فيه خطأ، أو أُلغي.",
        w_h404="قارن اسم النموذج بـ GET /v1/models.",
        w_h429="طلبات كثيرة: انتظر المدة التي تقولها retry-after، ثم أعد المحاولة.",
        w_h5xx="مشكلة في جهة الواجهة البرمجية: أعد المحاولة مع تباعد.",
        w_hnet="لا اتصال: افحص الشبكة وANTHROPIC_BASE_URL.",
    ),
}

PRICES = """// {w_c_prices}
// Cache writes cost 1.25 times the input price (5-minute cache); Haiku 5.5
// prices are for prompts up to 100K tokens.
export const PRICES = {
  "claude-fable-5-2": {input: 8, output: 40, cacheRead: 0.2},
  "claude-opus-5-5": {input: 4, output: 20, cacheRead: 0.2},
  "claude-sonnet-5-5": {input: 2, output: 10, cacheRead: 0.1},
  "claude-haiku-5-5": {input: 0.1, output: 0.5, cacheRead: 0.01},
};

// {w_c_cost}
export function cost(model, usage) {
  const p = PRICES[model];
  const written = usage.cache_creation_input_tokens ?? 0;
  const read = usage.cache_read_input_tokens ?? 0;
  const dollars = usage.input_tokens * p.input + usage.output_tokens * p.output +
    written * p.input * 1.25 + read * p.cacheRead;
  return dollars / 1_000_000;
}
"""

FILES = {
    "practice.json": "{w_replies}\n",
    "lib/prices.mjs": PRICES,
    "models.mjs": """import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();

// {w_c_models}
for await (const model of client.models.list()) {
  const input = (model.max_input_tokens / 1000).toLocaleString("en-US");
  console.log(`${model.id.padEnd(18)} ${model.display_name.padEnd(18)} input ${input}K, output ${model.max_tokens / 1000}K`);
}
""",
    "hello.mjs": """import Anthropic from "@anthropic-ai/sdk";
import {cost} from "./lib/prices.mjs";

const client = new Anthropic();

// {w_c_hello}
const question = process.argv[2] ?? "{w_hello}";
const response = await client.messages.create({
  model: "claude-opus-5-5",
  max_tokens: 1000,
  messages: [{role: "user", content: question}],
});
for (const block of response.content) {
  if (block.type === "text") console.log(block.text);
}
const {input_tokens, output_tokens} = response.usage;
const dollars = cost(response.model, response.usage).toFixed(6);
console.log(`--- stop: ${response.stop_reason}; ` +
  `tokens: ${input_tokens} in, ${output_tokens} out; cost: $${dollars}`);
""",
    "prices.mjs": """import {cost} from "./lib/prices.mjs";

// The same request on each model: 2,000 tokens in, 500 out.
const usage = {input_tokens: 2000, output_tokens: 500};
for (const model of ["claude-fable-5-2", "claude-opus-5-5", "claude-sonnet-5-5", "claude-haiku-5-5"]) {
  const one = cost(model, usage);
  console.log(`${model.padEnd(18)} $${one.toFixed(5)} each, $${(one * 1000).toFixed(2)} per thousand`);
}
// With 1,800 of the 2,000 input tokens read from the cache:
const cached = {input_tokens: 200, cache_read_input_tokens: 1800, output_tokens: 500};
console.log(`claude-opus-5-5, cached prompt: $${cost("claude-opus-5-5", cached).toFixed(5)} each`);
""",
    "errors.mjs": """import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();
const ask = {max_tokens: 200, messages: [{role: "user", content: "Hi"}]};

// {w_c_errors}
const attempts = [
  ["{w_e1}", {...ask, model: "claude-opus-55"}],
  ["{w_e2}", {model: "claude-opus-5-5", messages: ask.messages}],
  ["{w_e3}", {...ask, model: "claude-opus-5-5", thinking: {type: "disabled"}}],
];
for (const [what, request] of attempts) {
  try {
    await client.messages.create(request);
    console.log(`${what}: ok`);
  } catch (error) {
    console.log(`${what}: ${error.status} ${error.constructor.name}\\n  ${error.error?.error?.message}`);
  }
}
""",
    # Projects
    "choose.mjs": """// {w_c_choose}
export function chooseModel({hard, longRunning, highVolume}) {
  if (highVolume && !hard) return "claude-haiku-5-5";
  if (hard && longRunning) return "claude-fable-5-2";
  if (hard) return "claude-opus-5-5";
  return "claude-sonnet-5-5";
}

const tasks = [
  ["{w_t1}", {hard: false, longRunning: false, highVolume: true}],
  ["{w_t2}", {hard: false, longRunning: false, highVolume: false}],
  ["{w_t3}", {hard: true, longRunning: false, highVolume: false}],
  ["{w_t4}", {hard: true, longRunning: true, highVolume: false}],
];
for (const [task, answers] of tasks) {
  console.log(`${task.padEnd(38)} ${chooseModel(answers)}`);
}
""",
    "budget.mjs": """import {cost} from "./lib/prices.mjs";

// {w_c_budget}
function monthly({model, perDay, input, output, cachedShare = 0}) {
  const cached = Math.round(input * cachedShare);
  const usage = {input_tokens: input - cached, cache_read_input_tokens: cached, output_tokens: output};
  return cost(model, usage) * perDay * 30;
}

const feature = {perDay: 5000, input: 3000, output: 300};
console.log("{w_feature}: 5,000 a day, 3,000 tokens in, 300 out");
for (const model of ["claude-opus-5-5", "claude-sonnet-5-5", "claude-haiku-5-5"]) {
  const plain = monthly({...feature, model});
  const cached = monthly({...feature, model, cachedShare: 0.8});
  console.log(`  ${model.padEnd(18)} $${plain.toFixed(2).padStart(8)} a month; with 80% cached $${cached.toFixed(2).padStart(8)}`);
}
""",
    "handle.mjs": """import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();

// {w_c_handle}
export function advice(error) {
  if (error instanceof Anthropic.APIConnectionError) return "{w_hnet}";
  if (error instanceof Anthropic.AuthenticationError) return "{w_h401}";
  if (error instanceof Anthropic.NotFoundError) return "{w_h404}";
  if (error instanceof Anthropic.RateLimitError) return "{w_h429}";
  if (error instanceof Anthropic.BadRequestError) return "{w_h400}";
  if (error instanceof Anthropic.InternalServerError) return "{w_h5xx}";
  throw error;
}

const cases = [
  ["claude-opus-55", {}],
  ["claude-opus-5-5", {apiKey: "wrong-key"}],
  ["claude-opus-5-5", {baseURL: "http://127.0.0.1:9"}],
];
for (const [model, options] of cases) {
  const c = new Anthropic({maxRetries: 0, ...options});
  try {
    await c.messages.create({model, max_tokens: 100, messages: [{role: "user", content: "Hi"}]});
  } catch (error) {
    console.log(`${error.constructor.name.padEnd(20)} ${advice(error)}`);
  }
}
""",
}

RUNS = [
    ("models.sh", "node models.mjs"),
    ("hello.sh", "node hello.mjs"),
    ("news.sh", "node hello.mjs \"{w_news}\""),
    ("prices.sh", "node prices.mjs"),
    ("errors.sh", "node errors.mjs"),
    ("projects/choose.sh", "node choose.mjs"),
    ("projects/budget.sh", "node budget.mjs"),
    ("projects/handle.sh", "node handle.mjs"),
]


def main():
    chapter(HERE, T, FILES, RUNS)


if __name__ == "__main__":
    main()
