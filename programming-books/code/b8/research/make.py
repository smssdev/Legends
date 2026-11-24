"""Writes and runs the examples of Book 8, chapter "Research, Connectors and Tools", in English and Arabic:
Claude's web search tool from the API: the request that turns it on, the blocks that come back (the search,
its results, and text with citations), the answer printed with numbered sources, and a search that fails
inside a successful response. Then the sources listed by site and age, a check for sentences without a
citation, and the same question restricted to trusted sites.
The searches, results and answers are the practice server's; every site uses the reserved .example domain,
so none of them can be mistaken for a real source.
Run: python3 make.py   (needs Node 22; B8_LANG=en runs one edition)
"""
import json
import sys
from pathlib import Path

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE.parent))
from kit import chapter  # noqa: E402

SITES = [
    ("https://coffee-association.example/2026/11/bean-prices", 0, "3 days ago"),
    ("https://news.example/business/coffee-prices-rise", 1, "2 days ago"),
    ("https://beanblog.example/prices-will-double", 2, "5 weeks ago"),
]

TEXT = {
    "en": {
        "titles": ["Wholesale prices for Ethiopian beans from December", "Coffee prices to rise as shipping "
                   "costs climb", "Why bean prices will double next year"],
        "query": "Egyptian Coffee Association bean prices December 2026",
        "parts": [
            ("The Egyptian Coffee Association announced that wholesale prices for Ethiopian beans will rise by "
             "8% from 1 December.", 0, "wholesale prices for Ethiopian beans will rise by 8% from 1 December"),
            (" A news report links the rise to higher shipping costs through the Red Sea.", 1,
             "linked the increase to higher shipping costs through the Red Sea"),
            (" One blog expects prices to double next year.", 2, "prices will double next year"),
            (" For a café, an 8% rise on beans is a small share of the price of a drink.", None, None),
        ],
        "official": [
            ("The Egyptian Coffee Association announced that wholesale prices for Ethiopian beans will rise by "
             "8% from 1 December.", 0, "wholesale prices for Ethiopian beans will rise by 8% from 1 December"),
            (" A news report links the rise to higher shipping costs through the Red Sea.", 1,
             "linked the increase to higher shipping costs through the Red Sea"),
        ],
        "q": "What did the Egyptian Coffee Association announce about bean prices this month?",
        "q_many": "Compare bean prices in every country in Africa this month.",
    },
    "ar": {
        "titles": ["أسعار الجملة للبن الإثيوبي من ديسمبر", "أسعار القهوة إلى ارتفاع مع صعود تكاليف الشحن",
                   "لماذا ستتضاعف أسعار البن العام القادم"],
        "query": "جمعية البن المصرية أسعار البن ديسمبر 2026",
        "parts": [
            ("أعلنت جمعية البن المصرية أن أسعار الجملة للبن الإثيوبي سترتفع 8% من 1 ديسمبر.", 0,
             "أسعار الجملة للبن الإثيوبي سترتفع 8% من 1 ديسمبر"),
            (" ويربط تقرير إخباري الارتفاع بزيادة تكاليف الشحن عبر البحر الأحمر.", 1,
             "ربط الزيادة بارتفاع تكاليف الشحن عبر البحر الأحمر"),
            (" وتتوقع مدونة أن تتضاعف الأسعار العام القادم.", 2, "ستتضاعف الأسعار العام القادم"),
            (" وللمقهى، ارتفاع 8% في البن حصة صغيرة من سعر المشروب.", None, None),
        ],
        "official": [
            ("أعلنت جمعية البن المصرية أن أسعار الجملة للبن الإثيوبي سترتفع 8% من 1 ديسمبر.", 0,
             "أسعار الجملة للبن الإثيوبي سترتفع 8% من 1 ديسمبر"),
            (" ويربط تقرير إخباري الارتفاع بزيادة تكاليف الشحن عبر البحر الأحمر.", 1,
             "ربط الزيادة بارتفاع تكاليف الشحن عبر البحر الأحمر"),
        ],
        "q": "ماذا أعلنت جمعية البن المصرية عن أسعار البن هذا الشهر؟",
        "q_many": "قارن أسعار البن في كل دولة في أفريقيا هذا الشهر.",
    },
}


def blocks(lang, parts, sites):
    t = TEXT[lang]
    out = [
        {"type": "server_tool_use", "id": "srvtoolu_practice_01", "name": "web_search", "input": {"query": t["query"]}},
        {"type": "web_search_tool_result", "tool_use_id": "srvtoolu_practice_01", "content": [
            {"type": "web_search_result", "url": url, "title": t["titles"][i], "page_age": age,
             "encrypted_content": f"practice-{i}"} for url, i, age in sites]},
    ]
    for text, source, cited in t[parts]:
        block = {"type": "text", "text": text}
        if source is not None:
            url = SITES[source][0]
            block["citations"] = [{"type": "web_search_result_location", "url": url, "title": t["titles"][source],
                                   "cited_text": cited, "encrypted_index": f"practice-{source}"}]
        out.append(block)
    return out


def replies(lang):
    t = TEXT[lang]
    many = []
    for i, q in enumerate(["coffee prices Africa", "bean prices Kenya", "bean prices Ethiopia"], 1):
        many.append({"type": "server_tool_use", "id": f"srvtoolu_practice_{i}", "name": "web_search",
                     "input": {"query": q}})
        many.append({"type": "web_search_tool_result", "tool_use_id": f"srvtoolu_practice_{i}",
                     "content": [] if i < 3 else {"type": "web_search_tool_result_error",
                                                  "error_code": "max_uses_exceeded"}})
    many.append({"type": "text", "text": "I could only run two searches, and they found no reliable prices for "
                 "most countries." if lang == "en" else "لم أستطع إجراء أكثر من بحثين، ولم يجدا أسعاراً موثوقة "
                 "لمعظم الدول."})
    return [
        {"when": {"text": t["q"], "allowed_domains": True}, "blocks": blocks(lang, "official", SITES[:2]),
         "usage": {"server_tool_use": {"web_search_requests": 1}}},
        {"when": {"text": t["q"], "tools": True}, "blocks": blocks(lang, "parts", SITES),
         "usage": {"server_tool_use": {"web_search_requests": 1}}},
        {"when": {"text": t["q_many"], "tools": True}, "blocks": many,
         "usage": {"server_tool_use": {"web_search_requests": 2}}},
    ]


T = {
    "en": dict(
        w_q=TEXT["en"]["q"], w_q_many=TEXT["en"]["q_many"],
        w_c_search="Turn on web search: Claude decides when to search and what for.",
        w_c_render="The answer, with a number after each cited claim, and the sources at the end.",
        w_c_ask="Ask with web search, and print the answer with its sources.",
        w_c_errors="A failed search comes back inside a successful response.",
        w_c_sites="Every result the search returned: site, age and title.",
        w_c_uncited="Sentences with no citation: the ones to check first.",
        w_c_official="The same question, searching only the sites the team trusts.",
        w_searches="searches", w_sources="Sources", w_failed="search failed",
        w_uncited="no citation", w_all_cited="every sentence is cited",
    ),
    "ar": dict(
        w_q=TEXT["ar"]["q"], w_q_many=TEXT["ar"]["q_many"],
        w_c_search="شغّل البحث في الويب: يقرر Claude متى يبحث وعن ماذا.",
        w_c_render="الجواب، برقم بعد كل ادعاء مستشهد، والمصادر في النهاية.",
        w_c_ask="اسأل مع البحث في الويب، واطبع الجواب بمصادره.",
        w_c_errors="البحث الفاشل يعود داخل رد ناجح.",
        w_c_sites="كل نتيجة أعادها البحث: الموقع، والعمر، والعنوان.",
        w_c_uncited="جمل بلا استشهاد: أول ما يُفحص.",
        w_c_official="السؤال نفسه، والبحث في المواقع التي يثق بها الفريق فقط.",
        w_searches="عمليات البحث", w_sources="المصادر", w_failed="فشل البحث",
        w_uncited="بلا استشهاد", w_all_cited="كل جملة مستشهدة",
    ),
}
for lang in T:
    T[lang]["w_replies"] = json.dumps({"replies": replies(lang)}, ensure_ascii=False, indent=2)

RESEARCH = """import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();
export const QUESTION = "{w_q}";

// {w_c_search}
export async function research(question, search = {}) {
  return client.messages.create({
    model: "claude-opus-5-5",
    max_tokens: 4000,
    tools: [
      {type: "web_search_20260209", name: "web_search", max_uses: 3, ...search},
    ],
    messages: [{role: "user", content: question}],
  });
}

// {w_c_render}
export function render(response) {
  const sources = [];
  let text = "";
  for (const block of response.content) {
    if (block.type !== "text") continue;
    text += block.text;
    for (const c of block.citations ?? []) {
      if (!sources.includes(c.url)) sources.push(c.url);
      text += `[${sources.indexOf(c.url) + 1}]`;
    }
  }
  return {text, sources};
}
"""

FILES = {
    "practice.json": "{w_replies}\n",
    "lib/research.mjs": RESEARCH,
    "ask.mjs": """import {QUESTION, render, research} from "./lib/research.mjs";

// {w_c_ask}
const response = await research(QUESTION);
const {text, sources} = render(response);
console.log(text);
const searches = response.usage.server_tool_use.web_search_requests;
console.log(`\\n{w_sources} ({w_searches}: ${searches}):`);
sources.forEach((url, i) => console.log(`[${i + 1}] ${url}`));
""",
    "blocks.mjs": """import {QUESTION, research} from "./lib/research.mjs";

const response = await research(QUESTION);
for (const block of response.content) {
  const detail = block.type === "server_tool_use" ? JSON.stringify(block.input)
    : block.type === "web_search_tool_result" ? `${block.content.length} results`
    : `${block.text.length} chars, ${(block.citations ?? []).length} citations`;
  console.log(`${block.type.padEnd(22)} ${detail}`);
}
""",
    "errors.mjs": """import {research} from "./lib/research.mjs";

// {w_c_errors}
const question = "{w_q_many}";
const response = await research(question, {max_uses: 2});
for (const block of response.content) {
  if (block.type === "server_tool_use") console.log(`search: ${block.input.query}`);
  if (block.type !== "web_search_tool_result") continue;
  if (Array.isArray(block.content)) {
    console.log(`  ${block.content.length} results`);
  } else {
    console.log(`  {w_failed}: ${block.content.error_code}`);
  }
}
console.log(`stop: ${response.stop_reason}`);
""",
    # Projects
    "sites.mjs": """import {QUESTION, research} from "./lib/research.mjs";

// {w_c_sites}
const response = await research(QUESTION);
const results = response.content.filter((b) => b.type === "web_search_tool_result");
for (const block of results) {
  for (const r of block.content) {
    const site = new URL(r.url).hostname;
    console.log(`${site.padEnd(28)} ${r.page_age.padEnd(12)} ${r.title}`);
  }
}
""",
    "uncited.mjs": """import {QUESTION, research} from "./lib/research.mjs";

// {w_c_uncited}
export function uncited(response) {
  return response.content
    .filter((b) => b.type === "text" && b.text.trim() && !(b.citations ?? []).length)
    .map((b) => b.text.trim());
}

const found = uncited(await research(QUESTION));
if (!found.length) console.log("{w_all_cited}");
for (const sentence of found) console.log(`{w_uncited}: ${sentence}`);
""",
    "official.mjs": """import {QUESTION, render, research} from "./lib/research.mjs";

// {w_c_official}
const trusted = ["coffee-association.example", "news.example"];
const response = await research(QUESTION, {allowed_domains: trusted});
const {text, sources} = render(response);
console.log(text);
sources.forEach((url, i) => console.log(`[${i + 1}] ${url}`));
""",
}

RUNS = [
    ("ask.sh", "node ask.mjs"),
    ("blocks.sh", "node blocks.mjs"),
    ("errors.sh", "node errors.mjs"),
    ("projects/sites.sh", "node sites.mjs"),
    ("projects/uncited.sh", "node uncited.mjs"),
    ("projects/official.sh", "node official.mjs"),
]


def main():
    chapter(HERE, T, FILES, RUNS)


if __name__ == "__main__":
    main()
