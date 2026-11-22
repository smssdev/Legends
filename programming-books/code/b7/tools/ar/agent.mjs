import fs from "node:fs";
import {LlamaChatSession, defineChatSessionFunction} from "node-llama-cpp";
import {loadModel} from "./lib/model.mjs";

const model = await loadModel();
const context = await model.createContext({contextSize: 4096});

// أدوات يحق للوكيل استدعاؤها. النموذج يختار؛ وهذا الكود يشغّلها ويعيد
// النتيجة.
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

// اعرض كل استدعاء، لنرى ما فعله الوكيل، لا ما قاله فقط.
function show(name, params, result) {
  console.log(`[tool] ${name}(${JSON.stringify(params)})`);
  return result;
}

// أولاً السؤال وحده؛ ثم أمر نظام يقول ما الغرض من الأدوات، وسؤال يقول إنه
// عن المشروع.
const tries = [
  [undefined, "كم سعر اللاتيه الكبير، وأي ملف يحدد هذا السعر؟"],
  ["أنت تعمل داخل مشروع برمجي. استخدم الأدوات لتنظر في ملفاته قبل أن تجيب.", "في هذا المشروع، كم سعر اللاتيه الكبير، وأي ملف يحدد هذا السعر؟"],
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
