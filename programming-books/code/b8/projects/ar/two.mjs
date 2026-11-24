import {chat, loadProject, text} from "./lib/project.mjs";

// سؤال واحد، ومشروعان: التعليمات تقرر الجواب.
for (const name of ["support", "marketing"]) {
  const response = await chat(loadProject(name), "اكتب منشوراً عن اللاتيه بالورد.");
  console.log(`[${name}]\n${text(response)}\n`);
}
