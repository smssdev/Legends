import fs from "node:fs";
import {createRequire} from "node:module";
import {ask, model} from "./lib/ask.mjs";

const require = createRequire(import.meta.url);
const {calc} = require("./legacy/lib/calc.js");
const code = fs.readFileSync("legacy/lib/calc.js", "utf8");

const calls = [
  [{c: "STD", l: [{p: 4500, q: 2}]}, true],
  [{c: "STD", l: [{p: 2500, q: 10}]}, true],
  [{c: "STD", l: [{p: 2500, q: 10}]}, false],
  [{c: "VIP", l: [{p: 300, q: 1}]}, true],
  [{c: "STD", l: [{p: 10000, q: 2}]}, true],
  [{c: "vip", l: [{p: 4500, q: 2}]}, true],
];

// الشرح مجموعة ادعاءات. حوّلها إلى تنبؤات، وشغّل الكود الحقيقي.
const written = calls.map(([o, d]) => `calc(${JSON.stringify(o)}, ${d})`).join("\n");
// The answer can only be an array of numbers (Chapter 3).
const numbers = await model.llama.createGrammarForJsonSchema({
  type: "array",
  items: {type: "number"},
});
const prompt = `${code}\n\nلكل استدعاء من هذه، ماذا تعيد calc؟ أجب بمصفوفة JSON من الأرقام فقط، بالترتيب.\n${written}`;
const predicted = JSON.parse(await ask(prompt, {grammar: numbers}));
let right = 0;
calls.forEach(([o, d], i) => {
  const actual = calc(o, d);
  right += predicted[i] === actual ? 1 : 0;
  const mark = predicted[i] === actual ? "same " : "WRONG";
  console.log(`${mark} predicted ${String(predicted[i]).padStart(6)}  actual ${String(actual).padStart(6)}`);
});
console.log(`${right} of ${calls.length} predictions right`);
