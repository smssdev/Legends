import {LlamaCompletion} from "node-llama-cpp";
import {loadModel} from "./lib/model.mjs";

const model = await loadModel();
const context = await model.createContext({contextSize: 1024});
const completion = new LlamaCompletion({
  contextSequence: context.getSequence(),
});

// An editor sends the code before and after the cursor, and asks for the
// middle.
const before = `// Total price of an order, with tax.
export function total(items, taxRate) {
`;
const after = `
}

export const TAX_RATE = 0.14;
`;

// Raw, the model keeps writing past the function; an editor stops at the
// end of the block.
for (const stop of [[], ["\n}"]]) {
  const middle = await completion.generateInfillCompletion(before, after, {
    temperature: 0,
    maxTokens: 60,
    customStopTriggers: stop,
  });
  console.log(stop.length ? "--- stopped at the block's end:" : "--- raw:");
  console.log(middle.replace(/^\n/, ""));
}
