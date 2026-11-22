import {LlamaCompletion} from "node-llama-cpp";
import {loadModel} from "./lib/model.mjs";

const model = await loadModel();
const context = await model.createContext({contextSize: 1024});
const completion = new LlamaCompletion({
  contextSequence: context.getSequence(),
});

// الوقت حتى أول رمز، ثم الرموز في الثانية، على هذا الحاسوب.
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
