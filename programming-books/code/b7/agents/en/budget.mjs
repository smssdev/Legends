import {runAgent, runTests} from "./lib/agent.mjs";

// The same task with a budget of three tool calls.
const {answer, log} = await runAgent({root: "cafe3", system: "You are a coding agent working in a small JavaScript project. Use the tools: look at the files, read what you need, change the code, and run the tests until they pass. Do not change the tests. When you are done, say what you changed in one sentence.", task: "The tests fail. Make them pass.", maxSteps: 3});
console.log(log.join("\n"));
console.log(`--- the agent: ${answer}`);
console.log(`--- the tests, run by us: ${runTests("cafe3").split("\n")[0]}`);
