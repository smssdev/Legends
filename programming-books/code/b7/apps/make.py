"""Writes and runs the examples of Book 7, chapter "Calling AI Models from Your Apps", in English and Arabic: a
small HTTP service that answers with the book's model, streaming the answer and measuring the first token; one
provider interface with a local and a hosted implementation (the hosted one talks to a fake server in this
book, so no key or account is needed); retries for rate limits and a timeout; and structured answers with a
schema. Then an input guard, a streaming client, and a per-user limit.
Run: python3 make.py   (needs Node 22 and the book's model; B7_LANG=en runs one edition)
"""
import sys
from pathlib import Path

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE.parent))
from kit import chapter  # noqa: E402

T = {
    "en": dict(
        w_system="You answer questions from customers of a café app. Answer in one or two short sentences.",
        w_question="Can I use my loyalty card in both branches?",
        w_order="two large lattes and a small tea for Mona",
        w_extract="Extract the order as JSON: customer, and items with drink, size and count.",
        w_long="Please summarise this: " ,
        w_c_provider="Every provider has the same shape: a prompt in, text out, optionally streamed.",
        w_c_local="The book's model, on this computer.",
        w_c_hosted="A hosted model behind an OpenAI-style HTTP API: the URL and key come from the environment.",
        w_c_retry="Retry what can succeed later (429, 503, network errors), with growing waits; never forever.",
        w_c_timeout="Every call has a deadline.",
        w_c_stream="The service streams tokens as they come, so the first words appear at once.",
        w_c_fake="A fake hosted API for the book: twice 'too many requests', then an answer.",
        w_c_guard="Refuse input that is too long before it reaches the model, by counting tokens.",
        w_c_limit="At most three requests per user per minute.",
    ),
    "ar": dict(
        w_system="أنت تجيب عن أسئلة عملاء تطبيق مقهى. أجب في جملة أو جملتين قصيرتين.",
        w_question="هل أستطيع استخدام بطاقة الولاء في الفرعين؟",
        w_order="كوبان لاتيه كبير وشاي صغير لمنى",
        w_extract="استخرج الطلب بـ JSON: العميل customer، والعناصر items لكل منها drink وsize وcount.",
        w_long="لخّص هذا من فضلك: ",
        w_c_provider="كل مزوّد له الشكل نفسه: أمر يدخل، ونص يخرج، مع بث اختياري.",
        w_c_local="نموذج الكتاب، على هذا الحاسوب.",
        w_c_hosted="نموذج مستضاف خلف واجهة HTTP بأسلوب OpenAI: العنوان والمفتاح من البيئة.",
        w_c_retry="أعد محاولة ما قد ينجح لاحقاً (429 و503 وأخطاء الشبكة)، بانتظار يكبر؛ ولا إلى الأبد.",
        w_c_timeout="لكل استدعاء موعد نهائي.",
        w_c_stream="الخدمة تبث الرموز حين تصل، فتظهر الكلمات الأولى فوراً.",
        w_c_fake="واجهة مستضافة وهمية للكتاب: «طلبات كثيرة جداً» مرتين، ثم جواب.",
        w_c_guard="ارفض المدخل الطويل جداً قبل أن يصل إلى النموذج، بعدّ الرموز.",
        w_c_limit="ثلاثة طلبات على الأكثر لكل مستخدم في الدقيقة.",
    ),
}

PROVIDERS = """import {LlamaChatSession} from "node-llama-cpp";
import {loadModel} from "./model.mjs";

// {w_c_provider}
// complete({system, prompt, grammar, onText, signal}) -> Promise<string>

// {w_c_local}
export async function localProvider() {
  const model = await loadModel();
  const context = await model.createContext({contextSize: 4096});
  return {
    name: "local",
    model,
    async complete({system, prompt, grammar, onText, signal}) {
      const session = new LlamaChatSession({
        contextSequence: context.getSequence(),
        autoDisposeSequence: true,
        systemPrompt: system,
      });
      try {
        return await session.prompt(prompt, {
          temperature: 0,
          maxTokens: 300,
          grammar,
          signal,
          onTextChunk: onText,
        });
      } finally {
        session.dispose();
      }
    },
  };
}

// {w_c_hosted}
export function hostedProvider({url = process.env.AI_URL, key = process.env.AI_KEY, model = "any"} = {}) {
  return {
    name: "hosted",
    async complete({system, prompt, signal}) {
      const response = await fetch(`${url}/v1/chat/completions`, {
        method: "POST",
        headers: {"content-type": "application/json", authorization: `Bearer ${key}`},
        body: JSON.stringify({
          model,
          temperature: 0,
          messages: [
            {role: "system", content: system},
            {role: "user", content: prompt},
          ],
        }),
        signal,
      });
      if (!response.ok) {
        const error = new Error(`HTTP ${response.status}`);
        error.status = response.status;
        throw error;
      }
      return (await response.json()).choices[0].message.content;
    },
  };
}
"""

RETRY = """// {w_c_retry}
export async function withRetry(call, {tries = 4, firstWait = 200, log = () => {}} = {}) {
  for (let attempt = 1; ; attempt++) {
    try {
      return await call();
    } catch (error) {
      const temporary = [429, 500, 502, 503].includes(error.status) || error.code === "ECONNRESET";
      if (!temporary || attempt === tries) {
        throw error;
      }
      const wait = firstWait * 2 ** (attempt - 1);
      log(`attempt ${attempt}: ${error.message}, waiting ${wait} ms`);
      await new Promise((resolve) => setTimeout(resolve, wait));
    }
  }
}

// {w_c_timeout}
export function deadline(ms) {
  return AbortSignal.timeout(ms);
}
"""

FAKE = """import http from "node:http";

// {w_c_fake}
export function fakeHostedApi() {
  let calls = 0;
  const server = http.createServer((request, response) => {
    calls++;
    let body = "";
    request.on("data", (chunk) => (body += chunk));
    request.on("end", () => {
      if (request.headers.authorization !== "Bearer test-key") {
        response.writeHead(401).end();
      } else if (calls <= 2) {
        response.writeHead(429).end();
      } else {
        const {messages} = JSON.parse(body);
        const content = `(fake model) you asked: ${messages.at(-1).content}`;
        response.writeHead(200, {"content-type": "application/json"});
        response.end(JSON.stringify({choices: [{message: {content}}]}));
      }
    });
  });
  return new Promise((resolve) => server.listen(0, () => resolve({server, port: server.address().port})));
}
"""

SERVICE = """import http from "node:http";
import {localProvider} from "./lib/providers.mjs";
import {deadline} from "./lib/retry.mjs";

const provider = await localProvider();
const system = "{w_system}";

// {w_c_stream}
const server = http.createServer(async (request, response) => {
  const url = new URL(request.url, "http://x");
  const question = url.searchParams.get("q") ?? "";
  response.writeHead(200, {"content-type": "text/plain; charset=utf-8"});
  try {
    await provider.complete({
      system,
      prompt: question,
      signal: deadline(60_000),
      onText: (text) => response.write(text),
    });
  } catch (error) {
    response.write(`\\n[error: ${error.message}]`);
  }
  response.end();
});
server.listen(8765, () => console.log("listening on 8765"));
"""

FILES = {
    "lib/providers.mjs": PROVIDERS,
    "lib/retry.mjs": RETRY,
    "lib/fake.mjs": FAKE,
    "service.mjs": SERVICE,
    "client.mjs": """// Asks the service, printing the answer as it streams, with the time to the first piece.
const question = process.argv[2];
const start = performance.now();
const response = await fetch(`http://localhost:8765/?q=${encodeURIComponent(question)}`);
let first = 0;
let text = "";
for await (const chunk of response.body) {
  first ||= performance.now() - start;
  text += new TextDecoder().decode(chunk);
}
const total = performance.now() - start;
console.log(text.trim());
console.log(`--- first piece after ${(first / 1000).toFixed(1)} s, whole answer after ${(total / 1000).toFixed(1)} s`);
""",
    "same.mjs": """import {hostedProvider, localProvider} from "./lib/providers.mjs";
import {fakeHostedApi} from "./lib/fake.mjs";
import {withRetry} from "./lib/retry.mjs";

const {server, port} = await fakeHostedApi();
const providers = [
  await localProvider(),
  hostedProvider({url: `http://localhost:${port}`, key: "test-key"}),
];

// The application code is the same for both.
for (const provider of providers) {
  const answer = await withRetry(
    () => provider.complete({system: "{w_system}", prompt: "{w_question}"}),
    {log: (line) => console.log(`[${provider.name}] ${line}`)},
  );
  console.log(`[${provider.name}] ${answer.trim()}`);
}
server.close();
""",
    "structured.mjs": """import {localProvider} from "./lib/providers.mjs";

const provider = await localProvider();
const text = {type: "string"};
const grammar = await provider.model.llama.createGrammarForJsonSchema({
  type: "object",
  properties: {
    customer: text,
    items: {
      type: "array",
      items: {
        type: "object",
        properties: {
          drink: {enum: ["latte", "tea", "espresso"]},
          size: {enum: ["small", "large"]},
          count: {type: "integer"},
        },
      },
    },
  },
});
const answer = await provider.complete({system: "{w_extract}", prompt: "{w_order}", grammar});
const order = JSON.parse(answer);
console.log(JSON.stringify(order, null, 2));
// The app works with an object, not with text.
const cups = order.items.reduce((sum, item) => sum + item.count, 0);
console.log(`--- ${order.customer}: ${cups} cups`);
""",
    "timeout.mjs": """import {localProvider} from "./lib/providers.mjs";
import {deadline} from "./lib/retry.mjs";

const provider = await localProvider();
const start = performance.now();
try {
  await provider.complete({system: "{w_system}", prompt: "{w_question}", signal: deadline(500)});
  console.log("answered in time");
} catch (error) {
  console.log(`${error.name} after ${Math.round(performance.now() - start)} ms: the app shows a fallback`);
}
""",
    "demo.sh": """# Starts the service, asks one question, and stops the service.
node service.mjs > service.log 2>&1 &
until grep -q listening service.log; do sleep 1; done
node client.mjs "{w_question}"
kill $!
""",
    # Projects
    "guard.mjs": """import {loadModel} from "./lib/model.mjs";

const model = await loadModel();
const LIMIT = 200;

// {w_c_guard}
export function check(text) {
  const tokens = model.tokenize(text).length;
  return tokens <= LIMIT ? {ok: true, tokens} : {ok: false, tokens, error: `too long: ${tokens} tokens, limit ${LIMIT}`};
}

const short = "{w_question}";
const long = "{w_long}" + "{w_question} ".repeat(40);
for (const text of [short, long]) {
  console.log(JSON.stringify(check(text)));
}
""",
    "limit.mjs": """// {w_c_limit}
const WINDOW = 60_000;
const MAX = 3;
const seen = new Map();

export function allow(user, now = Date.now()) {
  const recent = (seen.get(user) ?? []).filter((t) => now - t < WINDOW);
  if (recent.length >= MAX) {
    seen.set(user, recent);
    return false;
  }
  seen.set(user, [...recent, now]);
  return true;
}

let clock = 0;
for (const [user, step] of [["mona", 1], ["mona", 1], ["omar", 1], ["mona", 1], ["mona", 1], ["mona", 61]]) {
  clock += step * 1000;
  console.log(`${String(clock / 1000).padStart(3)} s  ${user.padEnd(5)} ${allow(user, clock) ? "allowed" : "429 too many requests"}`);
}
""",
}

RUNS = [
    ("stream.sh", "sh demo.sh"),
    ("same.sh", "node same.mjs"),
    ("structured.sh", "node structured.mjs"),
    ("timeout.sh", "node timeout.mjs"),
    ("projects/guard.sh", "node guard.mjs"),
    ("projects/limit.sh", "node limit.mjs"),
]


def main():
    chapter(HERE, T, FILES, RUNS)


if __name__ == "__main__":
    main()
