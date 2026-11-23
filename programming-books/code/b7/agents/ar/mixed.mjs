import {runAgent, runTests} from "./lib/agent.mjs";

// تعليمات الوكيل بالإنجليزية، والمهمة بلغة النسخة.
const system =
  "You are a coding agent working in a small JavaScript project. Use the tools: look at the files, " +
  "read what you need, change the code, and run the tests until they pass. Do not change the tests. " +
  "When you are done, say what you changed in one sentence.";
const {answer, log} = await runAgent({root: "cafe5", system, task: "الاختبارات تفشل. اجعلها تنجح."});
console.log(log.join("\n"));
console.log(`--- the agent: ${answer}`);
console.log(`--- the tests, run by us: ${runTests("cafe5").split("\n")[0]}`);
