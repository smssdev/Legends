import {localProvider} from "./lib/providers.mjs";
import {deadline} from "./lib/retry.mjs";

const provider = await localProvider();
const start = performance.now();
try {
  await provider.complete({system: "You answer questions from customers of a café app. Answer in one or two short sentences.", prompt: "Can I use my loyalty card in both branches?", signal: deadline(500)});
  console.log("answered in time");
} catch (error) {
  console.log(`${error.name} after ${Math.round(performance.now() - start)} ms: the app shows a fallback`);
}
