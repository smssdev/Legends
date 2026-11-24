"""Writes and runs the examples of Book 8, chapter "The Claude API", in English and Arabic: a streamed answer
arriving in pieces; the SDK retrying a rate-limited request by itself, counted through its fetch; a timeout
on a slow reply; an answer cut off at max_tokens and continued properly; the error for an assistant prefill
on a current model. Then a call that always completes, request ids for support, and a fallback to a smaller
model when one is overloaded.
Run: python3 make.py   (needs Node 22; B8_LANG=en runs one edition)
"""
import json
import math
import re
import sys
from pathlib import Path

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE.parent))
from kit import chapter  # noqa: E402

W = {
    "en": dict(
        q_describe="Describe our rose latte for the menu board in two sentences.",
        describe="A latte made with our Ethiopian espresso, steamed milk and a touch of rose syrup. Floral, "
                 "gentle and only here for the spring.",
        q_busy="Suggest a name for our new iced drink.",
        busy="\"Nile Frost\": cold, clear, and from here.",
        q_rush="List three ways to shorten the queue at lunch.",
        q_slow="Summarise last month's 4,000 customer reviews.",
        slow="Customers like the coffee and the staff; they complain about the queue at lunch and the noise "
             "in the evening.",
        q_long="Write the welcome text for our new website.",
        long_1="Welcome to Bit Cafe, where every cup starts with beans we roast ourselves in small batches. "
               "We opened in Zamalek in 2019 with one machine and a long table, and today we serve three "
               "neighbourhoods, but the table is still",
        long_2="the heart of every branch: a place to work, to meet, or to read slowly. Come for the coffee; "
               "stay for the company.",
        continue_="Continue exactly where you stopped.",
        q_overload="Translate 'oat milk' for the menu.",
        overload_ok="Oat milk.",
    ),
    "ar": dict(
        q_describe="صِف اللاتيه بالورد للوحة القائمة في جملتين.",
        describe="لاتيه بإسبريسو إثيوبي وحليب مبخّر ولمسة من شراب الورد. زهري ولطيف، وموجود في الربيع فقط.",
        q_busy="اقترح اسماً لمشروبنا المثلج الجديد.",
        busy="«صقيع النيل»: بارد، وصافٍ، ومن هنا.",
        q_rush="اسرد ثلاث طرق لتقصير الطابور وقت الغداء.",
        q_slow="لخّص 4,000 مراجعة زبائن من الشهر الماضي.",
        slow="يحب الزبائن القهوة والعاملين؛ ويشتكون من الطابور وقت الغداء ومن الضجيج في المساء.",
        q_long="اكتب نص الترحيب لموقعنا الجديد.",
        long_1="أهلاً بك في مقهى بِت، حيث يبدأ كل كوب ببن نحمّصه بأنفسنا على دفعات صغيرة. افتتحنا في الزمالك "
               "عام 2019 بآلة واحدة وطاولة طويلة، واليوم نخدم ثلاثة أحياء، لكن الطاولة ما زالت",
        long_2="قلب كل فرع: مكاناً للعمل، أو اللقاء، أو القراءة على مهل. تعالَ من أجل القهوة؛ وابقَ من أجل الصحبة.",
        continue_="أكمل من حيث توقفت بالضبط.",
        q_overload="ترجم «oat milk» للقائمة.",
        overload_ok="حليب الشوفان.",
    ),
}


def tokens(text):
    """The practice server's estimate for one text block: four characters a token in English, two otherwise."""
    raw = json.dumps([{"type": "text", "text": text}], ensure_ascii=False, separators=(",", ":"))
    other = sum(1 for ch in raw if ord(ch) > 127)
    return math.ceil((len(raw) - other) / 4 + other / 2)


def cut(text, max_tokens=40):
    """As the practice server cuts an answer longer than max_tokens: at max_tokens x 4 characters, back to a
    whole word."""
    if tokens(text) <= max_tokens:
        return text, ""
    head = re.sub(r"\s+\S*$", "", text[: max_tokens * 4])
    return head, text[len(head):].strip()


def replies(lang):
    w = W[lang]
    full = w["long_1"] + " " + w["long_2"]
    rest = cut(full)[1]            # after the first cut: what "continue" returns
    rest2 = cut(rest)[1]           # after a second cut, when the continuation is cut too
    return [
        {"when": w["q_describe"], "text": w["describe"]},
        {"when": w["q_busy"], "error": {"status": 429, "type": "rate_limit_error", "message": "Number of requests "
                                        "has exceeded your rate limit", "retry_after": 1, "times": 2}},
        {"when": w["q_busy"], "text": w["busy"]},
        {"when": w["q_rush"], "error": {"status": 429, "type": "rate_limit_error", "message": "Number of requests "
                                        "has exceeded your rate limit", "retry_after": 1}},
        {"when": w["q_slow"], "delay_ms": 3000, "text": w["slow"]},
        {"when": {"text": w["continue_"], "messages": 3}, "text": rest},
        {"when": {"text": w["continue_"], "messages": 5}, "text": rest2},
        {"when": w["q_long"], "text": full},
        {"when": {"text": w["q_overload"], "model": "claude-opus-5-5"},
         "error": {"status": 529, "type": "overloaded_error", "message": "Overloaded"}},
        {"when": w["q_overload"], "text": w["overload_ok"]},
    ]


T = {}
for lang in ("en", "ar"):
    w = W[lang]
    T[lang] = {
        "w_replies": json.dumps({"replies": replies(lang)}, ensure_ascii=False, indent=2),
        **{f"w_{k}": v for k, v in w.items() if k.startswith("q_") or k == "continue_"},
        **{
            "en": dict(w_c_stream="The answer as it is written: each piece printed as it arrives.",
                       w_c_retry="The SDK retries a rate-limited request by itself; a fetch wrapper counts the "
                                 "attempts.",
                       w_c_timeout="A slow reply against a short timeout, then a longer one.",
                       w_c_truncate="An answer cut off at max_tokens, continued with the cut text in the history.",
                       w_c_prefill="Starting Claude's answer for it (prefill) is refused by current models.",
                       w_c_complete="Ask until the answer is complete, at most three times.",
                       w_c_ids="Every response and every error has a request id: log it.",
                       w_c_fallback="If the preferred model is overloaded, fall back to the next one.",
                       w_pieces="pieces", w_attempts="attempts", w_parts="parts", w_by="answered by",
                       w_after="after"),
            "ar": dict(w_c_stream="الجواب وهو يُكتب: كل قطعة تُطبع لحظة وصولها.",
                       w_c_retry="تعيد الحزمة الطلب المحدود بنفسها؛ وغلاف حول fetch يعدّ المحاولات.",
                       w_c_timeout="رد بطيء مقابل مهلة قصيرة، ثم مهلة أطول.",
                       w_c_truncate="جواب قُطع عند max_tokens، يُكمل والنص المقطوع في السجل.",
                       w_c_prefill="بدء جواب Claude عنه (prefill) ترفضه النماذج الحالية.",
                       w_c_complete="اسأل حتى يكتمل الجواب، ثلاث مرات على الأكثر.",
                       w_c_ids="لكل رد ولكل خطأ معرّف طلب: سجّله.",
                       w_c_fallback="إن كان النموذج المفضل مثقلاً، فانتقل إلى التالي.",
                       w_pieces="قطعة", w_attempts="المحاولات", w_parts="أجزاء", w_by="أجاب",
                       w_after="بعد"),
        }[lang],
    }

TEXT = """const text = (r) => r.content.filter((b) => b.type === "text").map((b) => b.text).join("");
"""

FILES = {
    "practice.json": "{w_replies}\n",
    "stream.mjs": """import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();

// {w_c_stream}
const stream = client.messages.stream({
  model: "claude-opus-5-5",
  max_tokens: 1000,
  messages: [{role: "user", content: "{w_q_describe}"}],
});
let pieces = 0;
stream.on("text", (piece) => {
  process.stdout.write(pieces++ % 4 === 0 ? `|${piece}` : piece);
});
const message = await stream.finalMessage();
console.log(`\\n--- ${pieces} {w_pieces}; stop: ${message.stop_reason}; ${message.usage.output_tokens} tokens out`);
""",
    "retry.mjs": """import Anthropic from "@anthropic-ai/sdk";

// {w_c_retry}
const statuses = [];
const counting = async (url, init) => {
  const response = await fetch(url, init);
  statuses.push(response.status);
  return response;
};

for (const [question, maxRetries] of [["{w_q_busy}", 2], ["{w_q_rush}", 0]]) {
  statuses.length = 0;
  const client = new Anthropic({fetch: counting, maxRetries});
  try {
    const r = await client.messages.create({
      model: "claude-opus-5-5",
      max_tokens: 200,
      messages: [{role: "user", content: question}],
    });
    console.log(r.content[0].text);
  } catch (error) {
    console.log(`${error.constructor.name}: ${error.status}`);
  }
  console.log(`  maxRetries ${maxRetries}, {w_attempts}: ${statuses.join(" → ")}`);
}
""",
    "timeout.mjs": """import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();
const request = {
  model: "claude-opus-5-5",
  max_tokens: 500,
  messages: [{role: "user", content: "{w_q_slow}"}],
};

// {w_c_timeout}
for (const timeout of [1000, 10000]) {
  const start = Date.now();
  try {
    const r = await client.messages.create(request, {timeout, maxRetries: 0});
    console.log(`timeout ${timeout} ms: ${r.content[0].text}`);
  } catch (error) {
    console.log(`timeout ${timeout} ms: ${error.constructor.name}`);
  }
  console.log(`  {w_after} ${Math.round((Date.now() - start) / 1000)} s`);
}
""",
    "truncate.mjs": """import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();
""" + TEXT + """
// {w_c_truncate}
const messages = [{role: "user", content: "{w_q_long}"}];
const first = await client.messages.create({model: "claude-opus-5-5", max_tokens: 40, messages});
console.log(`[${first.stop_reason}] ${text(first)}`);

messages.push({role: "assistant", content: first.content});
messages.push({role: "user", content: "{w_continue_}"});
const rest = await client.messages.create({model: "claude-opus-5-5", max_tokens: 1000, messages});
console.log(`[${rest.stop_reason}] ${text(rest)}`);
""",
    "prefill.mjs": """import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();

// {w_c_prefill}
try {
  await client.messages.create({
    model: "claude-opus-5-5",
    max_tokens: 200,
    messages: [
      {role: "user", content: "{w_q_long}"},
      {role: "assistant", content: "Welcome to Bit Cafe,"},
    ],
  });
} catch (error) {
  console.log(`${error.status} ${error.constructor.name}\\n  ${error.error?.error?.message}`);
}
""",
    # Projects
    "complete.mjs": """import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();
""" + TEXT + """
// {w_c_complete}
export async function complete(question, maxTokens) {
  const messages = [{role: "user", content: question}];
  let answer = "";
  for (let part = 1; part <= 3; part++) {
    const r = await client.messages.create({model: "claude-opus-5-5", max_tokens: maxTokens, messages});
    answer += (answer ? " " : "") + text(r);
    if (r.stop_reason !== "max_tokens") return {answer, parts: part};
    messages.push({role: "assistant", content: r.content}, {role: "user", content: "{w_continue_}"});
  }
  return {answer, parts: 3, cut: true};
}

const {answer, parts} = await complete("{w_q_long}", 40);
console.log(`(${parts} {w_parts}) ${answer}`);
""",
    "ids.mjs": """import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic({maxRetries: 0});

// {w_c_ids}
const {data, response} = await client.messages
  .create({model: "claude-opus-5-5", max_tokens: 200, messages: [{role: "user", content: "{w_q_describe}"}]})
  .withResponse();
console.log(`ok     ${data.id}  request-id: ${response.headers.get("request-id")}`);
try {
  await client.messages.create({model: "claude-opus-5-5", max_tokens: 200,
    messages: [{role: "user", content: "{w_q_rush}"}]});
} catch (error) {
  console.log(`${error.status}    request-id: ${error.requestID}`);
}
""",
    "fallback.mjs": """import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic({maxRetries: 1});
const MODELS = ["claude-opus-5-5", "claude-sonnet-5-5"];

// {w_c_fallback}
async function ask(content) {
  for (const model of MODELS) {
    try {
      const r = await client.messages.create({model, max_tokens: 200, messages: [{role: "user", content}]});
      return {model, text: r.content[0].text};
    } catch (error) {
      if (!(error instanceof Anthropic.InternalServerError) || model === MODELS.at(-1)) throw error;
      console.log(`  ${model}: ${error.status} ${error.error?.error?.type}`);
    }
  }
}

const {model, text} = await ask("{w_q_overload}");
console.log(`${text}  ({w_by} ${model})`);
""",
}

RUNS = [
    ("stream.sh", "node stream.mjs"),
    ("retry.sh", "node retry.mjs"),
    ("timeout.sh", "node timeout.mjs"),
    ("truncate.sh", "node truncate.mjs"),
    ("prefill.sh", "node prefill.mjs"),
    ("projects/complete.sh", "node complete.mjs"),
    ("projects/ids.sh", "node ids.mjs"),
    ("projects/fallback.sh", "node fallback.mjs"),
]


def main():
    chapter(HERE, T, FILES, RUNS)


if __name__ == "__main__":
    main()
