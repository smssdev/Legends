import fs from "node:fs";
import path from "node:path";
import {loadModel} from "./lib/model.mjs";

const model = await loadModel();

// كم نصاً في مكتبة حقيقية، مقابل حجم نافذة السياق.
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
