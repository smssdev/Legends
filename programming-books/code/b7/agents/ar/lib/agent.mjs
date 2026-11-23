import fs from "node:fs";
import path from "node:path";
import {execFileSync} from "node:child_process";
import {LlamaChatSession, defineChatSessionFunction} from "node-llama-cpp";
import {loadModel} from "./model.mjs";

const model = await loadModel();
const context = await model.createContext({contextSize: 8192});

// Runs the project's tests; returns the summary and the failures.
export function runTests(root) {
  try {
    const out = execFileSync("node", ["--test", "--test-reporter=tap"], {cwd: root, encoding: "utf8"});
    return `pass\n${out.match(/^# (pass|fail) \d+$/gm).join("\n")}`;
  } catch (error) {
    const lines = `${error.stdout}`.split("\n");
    return `fail\n${lines.filter((l) => /^\s*(not ok|expected:|actual:)|^# (pass|fail)/.test(l)).join("\n")}`;
  }
}

// السياسة: ما يحق للوكيل فعله، يقرره الكود لا النموذج.
function allowed(tool, file = "") {
  if (tool === "deleteFile") {
    return "denied: no agent may delete files";
  }
  if (tool === "writeFile" && !file.startsWith("src/")) {
    return "denied: the agent may write only in src/";
  }
  if (file.includes("..")) {
    return "denied: outside the project";
  }
  return "";
}

export async function runAgent({root, system, task, maxSteps = 12, dryRun = false}) {
  const log = [];
  const writes = [];
  let steps = 0;
  // كل استدعاء يُسجَّل، مسموحاً كان أم لا.
  const call = (tool, args, action) => {
    steps++;
    // حد صارم للخطوات: الوكيل الذي يدور في حلقة يتوقف.
    if (steps > maxSteps) {
      log.push(`${steps}. ${tool} ${JSON.stringify(args)} -> stopped: step limit`);
      throw new Error("step limit reached");
    }
    const denied = allowed(tool, args.path);
    const result = denied || action();
    log.push(`${steps}. ${tool} ${JSON.stringify(args)} -> ${String(result).split("\n")[0].slice(0, 60)}`);
    return result;
  };
  const p = (file) => path.join(root, file);
  const text = {type: "string"};
  const functions = {
    listFiles: defineChatSessionFunction({
      description: "List the project's files",
      handler: () => call("listFiles", {}, () => fs.readdirSync(root, {recursive: true}).join("\n")),
    }),
    readFile: defineChatSessionFunction({
      description: "Read a file of the project",
      params: {type: "object", properties: {path: text}},
      handler: ({path: file}) => call("readFile", {path: file}, () => fs.readFileSync(p(file), "utf8")),
    }),
    writeFile: defineChatSessionFunction({
      description: "Replace the whole content of a file",
      params: {type: "object", properties: {path: text, content: text}},
      handler: ({path: file, content}) =>
        call("writeFile", {path: file}, () => {
          writes.push({file, content});
          if (!dryRun) {
            fs.writeFileSync(p(file), content);
          }
          return dryRun ? "recorded (dry run)" : "written";
        }),
    }),
    deleteFile: defineChatSessionFunction({
      description: "Delete a file",
      params: {type: "object", properties: {path: text}},
      handler: ({path: file}) => call("deleteFile", {path: file}, () => "deleted"),
    }),
    runTests: defineChatSessionFunction({
      description: "Run the project's tests",
      handler: () => call("runTests", {}, () => runTests(root)),
    }),
  };
  const session = new LlamaChatSession({contextSequence: context.getSequence(), systemPrompt: system});
  let answer;
  try {
    answer = await session.prompt(task, {functions, temperature: 0, maxTokens: 1500});
  } catch (error) {
    answer = `(${error.message})`;
  }
  session.dispose();
  return {answer: answer.trim(), log, writes, steps};
}
