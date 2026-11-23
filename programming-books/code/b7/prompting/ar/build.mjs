import {ask} from "./lib/ask.mjs";

// خمسة أجزاء للأمر الجيد. اترك ما لا تحتاجه منها.
export function buildPrompt({context, task, format, rules}) {
  return [context, task, format, rules]
    .filter(Boolean)
    .join("\n\n");
}

const prompt = buildPrompt({
  context: "الفريق يكتب كود Node 22 بوحدات ES وبلا TypeScript.",
  task: "اشرح ما يفعله هذا السطر: const unique = [...new Set(items)];",
  format: "جملة واحدة، ثم مثال واحد بمدخله ومخرجه.",
  rules: "لا تقترح طرقاً أخرى لكتابته.",
});
const system = "أنت مطور JavaScript خبير يراجع الكود لفريق صغير.";
console.log(`[system] ${system}\n${prompt}\n---`);
console.log(await ask(prompt, {system}));
