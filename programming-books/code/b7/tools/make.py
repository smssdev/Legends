"""Writes and runs the examples of Book 7, chapter "The AI Toolbox for Developers", in English and Arabic:
the three shapes every AI tool takes (a chat, a completion in the editor, an agent that uses tools), what a
conversation really sends, how fast a model answers, and how much code fits in its context; then a chat in
the terminal, a context budget for files, and an agent with a calculator.
Run: python3 make.py   (needs Node 22 and the book's model)
"""
import sys
from pathlib import Path

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE.parent))
from kit import chapter  # noqa: E402

T = {
    "en": dict(
        w_system="You are a concise assistant for JavaScript developers. Answer in at most two lines.",
        w_q1="How do I read a JSON file in Node?",
        w_q2="And how do I write one?",
        w_fresh="A new conversation, asked only the second question:",
        w_agent_q="What does a large latte cost, and which file sets that price?",
        w_agent_sys="You work inside a software project. Use the tools to look at its files before you answer.",
        w_agent_q2="In this project, what does a large latte cost, and which file sets that price?",
        w_c_bare="First the question alone; then a system prompt that says what the tools are for, and a "
                 "question that says it is about the project.",
        w_calc_q="An order is 48213 cups at 7.35 each, plus 14% tax. What is the total?",
        w_readme="# Bit Café\n\nThe café's ordering service. Prices are in dollars.\n",
        w_c_chat="The model remembers nothing: every turn, the whole conversation is sent again.",
        w_c_tokens="How many tokens the conversation now takes in the context.",
        w_c_fim="An editor sends the code before and after the cursor, and asks for the middle.",
        w_c_stop="Raw, the model keeps writing past the function; an editor stops at the end of the block.",
        w_c_tools="Tools the agent may call. The model chooses; this code runs them and returns the result.",
        w_c_log="Show every call, so we can see what the agent did, not only what it said.",
        w_c_speed="Time to the first token, then tokens per second, on this computer.",
        w_c_ctx="How much text a real library is, against the size of a context window.",
        w_c_repl="A chat in the terminal: one session, so the conversation grows; /reset starts again.",
        w_c_budget="Choose which files fit in a token budget: smallest first, and say what was left out.",
        w_c_calc="The same question twice: once alone, once with a calculator it can call.",
        w_c_math="The calculator: a plain JavaScript function, exact every time.",
        w_reset="(conversation reset)",
        w_repl_in="How do I read a file line by line in Node?\\nAnd in reverse order?\\n/reset\\nAnd in reverse order?\\n",
    ),
    "ar": dict(
        w_system="أنت مساعد موجز لمطوري JavaScript. أجب في سطرين على الأكثر.",
        w_q1="كيف أقرأ ملف JSON في Node؟",
        w_q2="وكيف أكتب واحداً؟",
        w_fresh="محادثة جديدة، سُئلت السؤال الثاني وحده:",
        w_agent_q="كم سعر اللاتيه الكبير، وأي ملف يحدد هذا السعر؟",
        w_agent_sys="أنت تعمل داخل مشروع برمجي. استخدم الأدوات لتنظر في ملفاته قبل أن تجيب.",
        w_agent_q2="في هذا المشروع، كم سعر اللاتيه الكبير، وأي ملف يحدد هذا السعر؟",
        w_c_bare="أولاً السؤال وحده؛ ثم أمر نظام يقول ما الغرض من الأدوات، وسؤال يقول إنه عن المشروع.",
        w_calc_q="طلب من 48213 كوباً بسعر 7.35 للكوب، مع ضريبة 14%. ما المجموع؟",
        w_readme="# مقهى بِت\n\nخدمة الطلبات في المقهى. الأسعار بالدولار.\n",
        w_c_chat="النموذج لا يتذكر شيئاً: في كل دور تُرسل المحادثة كلها من جديد.",
        w_c_tokens="كم رمزاً تأخذ المحادثة الآن في السياق.",
        w_c_fim="المحرر يرسل الكود قبل المؤشر وبعده، ويطلب ما بينهما.",
        w_c_stop="بلا قيد، يستمر النموذج في الكتابة بعد الدالة؛ والمحرر يتوقف عند نهاية الكتلة.",
        w_c_tools="أدوات يحق للوكيل استدعاؤها. النموذج يختار؛ وهذا الكود يشغّلها ويعيد النتيجة.",
        w_c_log="اعرض كل استدعاء، لنرى ما فعله الوكيل، لا ما قاله فقط.",
        w_c_speed="الوقت حتى أول رمز، ثم الرموز في الثانية، على هذا الحاسوب.",
        w_c_ctx="كم نصاً في مكتبة حقيقية، مقابل حجم نافذة السياق.",
        w_c_repl="محادثة في الطرفية: جلسة واحدة، فتكبر المحادثة؛ و/reset تبدأ من جديد.",
        w_c_budget="اختر الملفات التي تتسع لميزانية من الرموز: الأصغر أولاً، وقل ما بقي خارجها.",
        w_c_calc="السؤال نفسه مرتين: مرة وحده، ومرة مع آلة حاسبة يستطيع استدعاءها.",
        w_c_math="الآلة الحاسبة: دالة JavaScript عادية، دقيقة في كل مرة.",
        w_reset="(بدأت المحادثة من جديد)",
        w_repl_in="كيف أقرأ ملفاً سطراً سطراً في Node؟\\nوبالترتيب المعكوس؟\\n/reset\\nوبالترتيب المعكوس؟\\n",
    ),
}

FILES = {
    "chat.mjs": """import {LlamaChatSession} from "node-llama-cpp";
import {loadModel} from "./lib/model.mjs";

const model = await loadModel();
const context = await model.createContext({contextSize: 2048});
const options = {temperature: 0, maxTokens: 120};
const systemPrompt = "{w_system}";

// {w_c_chat}
const sequence = context.getSequence();
const session = new LlamaChatSession({contextSequence: sequence, systemPrompt});
for (const question of ["{w_q1}", "{w_q2}"]) {
  const answer = await session.prompt(question, options);
  // {w_c_tokens}
  console.log(`> ${question}\\n${answer}\\n[${sequence.nextTokenIndex} tokens]\\n`);
}

sequence.dispose();
console.log("{w_fresh}");
const fresh = new LlamaChatSession({
  contextSequence: context.getSequence(),
  systemPrompt,
});
console.log(`> {w_q2}\\n${await fresh.prompt("{w_q2}", options)}`);
""",
    "complete.mjs": """import {LlamaCompletion} from "node-llama-cpp";
import {loadModel} from "./lib/model.mjs";

const model = await loadModel();
const context = await model.createContext({contextSize: 1024});
const completion = new LlamaCompletion({
  contextSequence: context.getSequence(),
});

// {w_c_fim}
const before = `// Total price of an order, with tax.
export function total(items, taxRate) {
`;
const after = `
}

export const TAX_RATE = 0.14;
`;

// {w_c_stop}
for (const stop of [[], ["\\n}"]]) {
  const middle = await completion.generateInfillCompletion(before, after, {
    temperature: 0,
    maxTokens: 60,
    customStopTriggers: stop,
  });
  console.log(stop.length ? "--- stopped at the block's end:" : "--- raw:");
  console.log(middle.replace(/^\\n/, ""));
}
""",
    "agent.mjs": """import fs from "node:fs";
import {LlamaChatSession, defineChatSessionFunction} from "node-llama-cpp";
import {loadModel} from "./lib/model.mjs";

const model = await loadModel();
const context = await model.createContext({contextSize: 4096});

// {w_c_tools}
const functions = {
  listFiles: defineChatSessionFunction({
    description: "List the files of the project",
    handler() {
      return show("listFiles", {}, fs.readdirSync("cafe", {recursive: true}));
    },
  }),
  readFile: defineChatSessionFunction({
    description: "Read one file of the project",
    params: {type: "object", properties: {path: {type: "string"}}},
    handler({path}) {
      return show("readFile", {path}, fs.readFileSync(`cafe/${path}`, "utf8"));
    },
  }),
};

// {w_c_log}
function show(name, params, result) {
  console.log(`[tool] ${name}(${JSON.stringify(params)})`);
  return result;
}

// {w_c_bare}
const tries = [
  [undefined, "{w_agent_q}"],
  ["{w_agent_sys}", "{w_agent_q2}"],
];
for (const [systemPrompt, question] of tries) {
  const session = new LlamaChatSession({
    contextSequence: context.getSequence(),
    autoDisposeSequence: true,
    systemPrompt,
  });
  console.log(`--- system prompt: ${systemPrompt ?? "(default)"}`);
  console.log(`> ${question}`);
  console.log(await session.prompt(question, {functions, temperature: 0}));
  session.dispose();
}
""",
    "cafe/README.md": "{w_readme}",
    "cafe/menu.json": """{
  "drinks": ["espresso", "latte", "tea"],
  "sizes": ["small", "large"]
}
""",
    "cafe/src/prices.mjs": """export const PRICES = {
  espresso: {small: 2.5, large: 3.25},
  latte: {small: 3.75, large: 4.5},
  tea: {small: 2, large: 2.75},
};
""",
    "speed.mjs": """import {LlamaCompletion} from "node-llama-cpp";
import {loadModel} from "./lib/model.mjs";

const model = await loadModel();
const context = await model.createContext({contextSize: 1024});
const completion = new LlamaCompletion({
  contextSequence: context.getSequence(),
});

// {w_c_speed}
const start = performance.now();
let first = 0;
let tokens = 0;
await completion.generateCompletion("A short story about a café robot:", {
  temperature: 0,
  maxTokens: 64,
  onToken(chunk) {
    first ||= performance.now();
    tokens += chunk.length;
  },
});
const seconds = (performance.now() - first) / 1000;
console.log(`first token after ${Math.round(first - start)} ms`);
console.log(`${tokens} tokens at ${(tokens / seconds).toFixed(1)} tokens/s`);
""",
    "context.mjs": """import fs from "node:fs";
import path from "node:path";
import {loadModel} from "./lib/model.mjs";

const model = await loadModel();

// {w_c_ctx}
const folder = "node_modules/node-llama-cpp/dist";
let files = 0;
let tokens = 0;
for (const name of fs.readdirSync(folder, {recursive: true})) {
  if (name.endsWith(".js")) {
    const text = fs.readFileSync(path.join(folder, name), "utf8");
    files++;
    tokens += model.tokenize(text).length;
  }
}
console.log(`node-llama-cpp: ${files} JavaScript files, ${tokens} tokens`);
for (const window of [8_192, 128_000, 1_000_000]) {
  const share = Math.min(100, (100 * window) / tokens).toFixed(0);
  console.log(`a ${window}-token window holds ${share}% of it`);
}
""",
    # Projects
    "repl.mjs": """import readline from "node:readline";
import {LlamaChatSession} from "node-llama-cpp";
import {loadModel} from "./lib/model.mjs";

const model = await loadModel();
const context = await model.createContext({contextSize: 4096});
const sequence = context.getSequence();
const systemPrompt = "{w_system}";
const session = new LlamaChatSession({contextSequence: sequence, systemPrompt});
const initial = session.getChatHistory();

// {w_c_repl}
const lines = readline.createInterface({input: process.stdin});
for await (const line of lines) {
  console.log(`> ${line}`);
  if (line === "/reset") {
    session.setChatHistory(initial);
    console.log("{w_reset}\\n");
    continue;
  }
  const answer = await session.prompt(line, {temperature: 0, maxTokens: 160});
  console.log(`${answer}\\n`);
}
""",
    "budget.mjs": """import fs from "node:fs";
import path from "node:path";
import {loadModel} from "./lib/model.mjs";

const model = await loadModel();
const [folder, budget] = [process.argv[2], Number(process.argv[3])];

const count = (file) => model.tokenize(fs.readFileSync(file, "utf8")).length;

// {w_c_budget}
const files = fs
  .readdirSync(folder, {recursive: true})
  .map((name) => path.join(folder, name))
  .filter((file) => fs.statSync(file).isFile())
  .map((file) => ({file, tokens: count(file)}))
  .sort((a, b) => a.tokens - b.tokens);

let used = 0;
for (const {file, tokens} of files) {
  const fits = used + tokens <= budget;
  used += fits ? tokens : 0;
  console.log(`${fits ? "in " : "out"} ${String(tokens).padStart(6)}  ${file}`);
}
console.log(`${used} of ${budget} tokens used`);
""",
    "calc.mjs": """import {LlamaChatSession, defineChatSessionFunction} from "node-llama-cpp";
import {loadModel} from "./lib/model.mjs";

const model = await loadModel();
const context = await model.createContext({contextSize: 2048});
const question = "{w_calc_q}";

// {w_c_math}
const calculate = defineChatSessionFunction({
  description: "Evaluate an arithmetic expression, such as (2 + 3) * 4",
  params: {type: "object", properties: {expression: {type: "string"}}},
  handler({expression}) {
    if (!/^[\\d\\s.+\\-*/()]+$/.test(expression)) {
      return "error: only numbers and + - * / ( )";
    }
    const result = Function(`return (${expression});`)();
    console.log(`[tool] calculate(${expression}) = ${result}`);
    return result;
  },
});

// {w_c_calc}
for (const functions of [undefined, {calculate}]) {
  const session = new LlamaChatSession({
    contextSequence: context.getSequence(),
    autoDisposeSequence: true,
  });
  console.log(functions ? "--- with a calculator:" : "--- alone:");
  console.log(await session.prompt(question, {functions, temperature: 0}));
  session.dispose();
}
console.log(`--- exact: ${(48213 * 7.35 * 1.14).toFixed(2)}`);
""",
}

def shorten(lines):
    """The model's working alone runs to a page; keep its start and its end, and say how much is left out."""
    start = next(i for i, line in enumerate(lines) if line.startswith("--- alone"))
    end = next(i for i, line in enumerate(lines) if line.startswith("--- with"))
    body = [line for line in lines[start + 1:end] if line.strip() and line.strip() != "---"]
    if len(body) <= 30:
        return lines
    cut = len(body) - 12
    return lines[:start + 1] + body[:6] + [f"[... {cut} lines ...]"] + body[-6:] + lines[end:]


RUNS = [
    ("chat.sh", "node chat.mjs"),
    ("complete.sh", "node complete.mjs"),
    ("agent.sh", "node agent.mjs"),
    ("speed.sh", "node speed.mjs"),
    ("context.sh", "node context.mjs"),
    ("projects/repl.sh", "printf '{w_repl_in}' | node repl.mjs"),
    ("projects/budget.sh", "node budget.mjs cafe 120 && node budget.mjs cafe 60"),
    ("projects/calc.sh", "node calc.mjs", shorten),
]


def main():
    chapter(HERE, T, FILES, RUNS)


if __name__ == "__main__":
    main()
