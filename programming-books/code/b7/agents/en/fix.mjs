import {runAgent, runTests} from "./lib/agent.mjs";

const {answer, log} = await runAgent({root: "cafe", system: "You are a coding agent working in a small JavaScript project. Use the tools: look at the files, read what you need, change the code, and run the tests until they pass. Do not change the tests. When you are done, say what you changed in one sentence.", task: "The tests fail. Make them pass."});
console.log(log.join("\n"));
console.log(`--- the agent: ${answer}`);

// The agent says it is done; the tests decide.
console.log(`--- the tests, run by us: ${runTests("cafe").split("\n")[0]}`);
