import {LlamaChatSession, defineChatSessionFunction} from "node-llama-cpp";
import {loadModel} from "./lib/model.mjs";

const model = await loadModel();
const context = await model.createContext({contextSize: 2048});
const question = "An order is 48213 cups at 7.35 each, plus 14% tax. What is the total?";

// The calculator: a plain JavaScript function, exact every time.
const calculate = defineChatSessionFunction({
  description: "Evaluate an arithmetic expression, such as (2 + 3) * 4",
  params: {type: "object", properties: {expression: {type: "string"}}},
  handler({expression}) {
    if (!/^[\d\s.+\-*/()]+$/.test(expression)) {
      return "error: only numbers and + - * / ( )";
    }
    const result = Function(`return (${expression});`)();
    console.log(`[tool] calculate(${expression}) = ${result}`);
    return result;
  },
});

// The same question twice: once alone, once with a calculator it can
// call.
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
