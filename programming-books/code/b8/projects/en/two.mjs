import {chat, loadProject, text} from "./lib/project.mjs";

// One question, two projects: the instructions decide the answer.
for (const name of ["support", "marketing"]) {
  const response = await chat(loadProject(name), "Write a post about the rose latte.");
  console.log(`[${name}]\n${text(response)}\n`);
}
