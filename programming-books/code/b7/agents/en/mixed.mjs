import {runAgent, runTests} from "./lib/agent.mjs";

// The agent's instructions in English, the task in the edition's
// language.
const system =
  "You are a coding agent working in a small JavaScript project. Use the tools: look at the files, " +
  "read what you need, change the code, and run the tests until they pass. Do not change the tests. " +
  "When you are done, say what you changed in one sentence.";
const {answer, log} = await runAgent({root: "cafe5", system, task: "The tests fail. Make them pass."});
console.log(log.join("\n"));
console.log(`--- the agent: ${answer}`);
console.log(`--- the tests, run by us: ${runTests("cafe5").split("\n")[0]}`);
